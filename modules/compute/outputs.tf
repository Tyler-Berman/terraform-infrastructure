output "server_public_ip" {
    value = aws_instance.sentinel_server.public_ip
}