
resource "aws_sns_topic" "EC2_Topic" {
    name = "${var.ec2_lambda}-topic" 
}

resource "aws_sns_topic_subscription" "user_updates_ec2" {
    topic_arn = aws_sns_topic.EC2_Topic.arn
    protocol = "email"
    endpoint = var.updates_email
}