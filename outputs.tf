output "sentinel_dashboard_url" {
    value = module.storage.website_url
}

output "server_public_ip" {
    value = module.compute.server_public_ip
}