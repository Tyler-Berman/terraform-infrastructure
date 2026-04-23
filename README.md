Project Sentinel, completely rebuilt in Terraform, is an automated security tool built using Generative AI (Amazon Bedrock) to examine and 
report on events in AWS. It takes logs from CloudTrail and VPC Flow Logs, and summarizes events in a way that is easy for humans to understand.
These results are then displayed in a security dashboard hosted on a static S3 bucket. 

Live Dashboard: http://sentinel-v2-frontend-2026.s3-website-us-east-1.amazonaws.com/
Architecture Diagram: 

Infrastructure as Code: Fully automated deployment using Terraform Modules.

Serverless Infrastructure: Utilizes Lambda functions, S3 buckets, API Gateways, SNS topics, and VPC to stay completely serverless.

Event-driven: Uses S3 triggers to activate the Lambda function, which uses custom logic for log decompression (gzip) and JSON parsing. 

Security: Utilizes the principal of Least Privilege, only giving access to specific resources in the AWS Account.

Frontend: A S3 hosted dashboard provides the latest security analysis results, providing end to end usability.

Tech Stack: Python, Terraform, Generative AI, AWS (S3, EC2, Lambda, VPC, API Gateway, SNS, CloudTrail, Bedrock, IAM)
