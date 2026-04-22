output "topicarn2"{
    value = aws_sns_topic.EC2_Topic.arn
}

output "topicarn" {
    value = aws_sns_topic.S3_Topic.arn
}

output "topicarn3" {
    value = aws_sns_topic.Sentinel_Topic.arn
}