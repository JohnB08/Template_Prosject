terraform{
    required_providers {
      hcloud={
        source = "hetznercloud/hcloud"
        version = "~> 1.45"
      }
    }
}

locals {
    gpg_key = file("./public_key.asc")
}

provider "hcloud"{
    token = var.hcloud_token
}

resource "hcloud_ssh_key" "default" {
    name = "template_project_ssh_key"
    public_key = file("~/.ssh/id_ed25519.pub")
}

data "template_file" "cloud_init"{
    template = file("./cloud-init.yaml.tftpl")
    vars = {
        username = var.user
        gpgkey = local.gpg_key
    }
}

resource "hcloud_server" "template_project_test_server" {
    name = "testing_sops_key_extraction"
    image = "ubuntu-24.04"
    server_type = "cx22"
    location = "nbg1"
    ssh_keys = [hcloud_ssh_key.default.id]
    user_data = data.template_file.cloud_init.rendered
    connection {
      type = "ssh"
      user = "root"
      private_key = file("~/.ssh/id_ed25519")
      host = self.ipv4_address
    }
}