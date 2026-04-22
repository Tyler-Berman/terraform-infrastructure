output "server_public_ip" {
    value = aws_instance.sentinel_server.public_ip
}

output "sentinel_lambda_arn" {
    value = aws_lambda_function.sentinel_lambda.arn
}