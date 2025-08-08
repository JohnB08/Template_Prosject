output "ipv4_address"{
    value = hcloud_server.template_project_test_server.ipv4_address
    description = "ipv4 address"
}