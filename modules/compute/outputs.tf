output "server_public_ip" {
    value = aws_instance.sentinel_server.public_ip
}

output "sentinel_lambda_arn" {
    value = aws_lambda_function.sentinel_lambda.arn
}

output "sentinel_lambda_invoke_arn" {
    value = aws_lambda_function.sentinel_lambda.invoke_arn
}

output "sentinel_lambda_name" {
    value = aws_lambda_function.sentinel_lambda.id
}