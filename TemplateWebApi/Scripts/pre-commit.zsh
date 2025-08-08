#!/usr/bin/env zsh

# Fail fast, undefined vars are errors, and pipeline fails if any command fails
set -e
set -u
setopt pipefail

: ${SOPS_PGP_FP:?"You need to set SOPS_PGP_FP in environment"}

typeset -a needs_encrypt=()

while IFS= read -r file; do
    echo "$file"

    if grep -qiE '(sops:|"sops":|sops_.*=|SOPS_.*=)' "$file"; then
        result=$?
        echo " grep returned a value for $file: $result."
    else
        result=1
        echo "No Grep Match"
    fi

    if [ $result -ne 0 ]; then
        needs_encrypt+=("$file")
    fi
done < <(
    find . -maxdepth 2 -type f \( -iname '*.yaml' -o -iname '*.yml' -o -iname '*.json' -o -iname '*.env' \) \
    ! -name '.sops.yaml' \
    ! -iname '*.secret.*'
)

if [ ${#needs_encrypt[@]} -gt 0 ]; then
    for file in "${needs_encrypt[@]}"; do
        base="${file%.*}"
        ext="${file##*.}"

        if [[ "$base" == "$file" ]]; then
            secrets_file="${file}.secret"
        else
            secrets_file="${base}.secret.${ext}"
        fi

        sops -e --pgp "$SOPS_PGP_FP" "$file" > "$secrets_file"

        git rm --cached "$file"
        echo "$file" >> .gitignore
        git add "$secrets_file"
    done
    git add .gitignore
fi

exit 0
