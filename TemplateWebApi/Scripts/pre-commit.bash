#!/usr/bin/env bash

## -e: Avslutt umiddelbart hvis en kommando feiler
## -u: Behandle udefinerte variabler som feil
## pipefail: Returner feilstatus hvis en kommando i en pipe feiler
set -euo pipefail

## Sjekker at miljøvariabelen SOPS_PGP_FP er satt, ellers stopp med feilmelding
: "${SOPS_PGP_FP:? You need to set SOPS_PGP_FP in environment}"

## Array som skal inneholde filer som må krypteres
needs_encrypt=()

## Leser filer én og én fra find-kommandoen under
## IFS= og -r sørger for at mellomrom og \ håndteres riktig
while IFS= read -r file; do
    ## Skriver ut filnavnet for debug
    echo "$file"

    ## Sjekker om filen inneholder sops-relaterte nøkler/verdier
    if grep -qiE '(sops:|"sops":|sops_.*=|SOPS_.*=)' "$file"; then
        result=$?
        echo " grep returned a value for $file: $result."
    else
        result=1
        echo "No Grep Match"
    fi

    ## Hvis ingen match, legg filen til i needs_encrypt-listen
    if [ $result -ne 0 ]; then
        needs_encrypt+=("$file")
    fi
## Finner filer med bestemte filendelser, men ekskluderer .sops.yaml og *.secret.*
done < <(
    find . -maxdepth 2 -type f \( -iname '*.yaml' -o -iname '*.yml' -o -iname '*.json' -o -iname '*.env' \) \
    ! -name '.sops.yaml' \
    ! -iname '*.secret.*' 
)

## Hvis det finnes filer som må krypteres
if [ "${#needs_encrypt[@]}" -gt 0 ]; then
    
    ## Looper gjennom alle filene som skal krypteres
    for file in "${needs_encrypt[@]}"; do
        base="${file%.*}"    ## Filnavn uten endelse
        ext="${file##*.}"    ## Kun filendelse

        ## Lager nytt filnavn for den krypterte versjonen
        if [[ "$base" == "$file" ]]; then
            secrets_file="${file}.secret"
        else
            secrets_file="${base}.secret.${ext}"
        fi

        ## Krypterer filen med sops og skriver til ny fil
        sops -e --pgp "$SOPS_PGP_FP" "$file" > "$secrets_file"

        ## Fjerner originalfilen fra git-indeksen
        git rm --cached "$file"

        ## Legger originalfilen til .gitignore
        echo "$file" >> .gitignore

        ## Legger til den krypterte filen i git
        git add "$secrets_file"
    done
    ## Legger oppdatert .gitignore til git
    git add .gitignore
fi

exit 0
