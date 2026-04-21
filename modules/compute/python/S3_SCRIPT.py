import boto3
import os
from botocore.exceptions import ClientError

def lambda_handler(event, context):
    aws_region = os.environ.get('APP_REGION', 'us-east-1')
    s3 = boto3.client('s3', region_name=aws_region)
    sns = boto3.client('sns', region_name=aws_region)
    
    MY_TOPIC_ARN = os.environ.get('TOPIC_ARN')
    any_remediations = False
    buckets_checked = 0
    ALL_BUCKETS = s3.list_buckets()
    for bucket in ALL_BUCKETS['Buckets']:
        buckets_checked += 1
        BUCKET_NAME = bucket['Name']
        try:
            SECURITY_CHECK = s3.get_public_access_block(Bucket=BUCKET_NAME)
            PUBLIC_ACCESS = SECURITY_CHECK['PublicAccessBlockConfiguration']    
            PUBLIC_POLICY = PUBLIC_ACCESS['BlockPublicPolicy']
            PUBLIC_ACLS = PUBLIC_ACCESS['BlockPublicAcls']
            if PUBLIC_POLICY == True and PUBLIC_ACLS == True:
                print(f"Public access settings for bucket '{BUCKET_NAME}' are compliant.")
            else: 
                any_remediations = True
                s3.put_public_access_block(
                Bucket=BUCKET_NAME,
                PublicAccessBlockConfiguration={
                    'BlockPublicAcls': True,
                    'IgnorePublicAcls': True,
                    'BlockPublicPolicy': True,
                    'RestrictPublicBuckets': True
                })
                sns.publish(
                    TopicArn=MY_TOPIC_ARN,
                    Message=f"Public access settings for bucket '{BUCKET_NAME}' have been found to be non-compliant and have been remediated.",
                    Subject=f"S3 Security Remediation Notification: Bucket '{BUCKET_NAME}'"
            )
                print(f"Public access settings for bucket '{BUCKET_NAME}' have been remediated to be compliant.")
    
        except ClientError as e:
            if e.response['Error']['Code'] == 'NoSuchPublicAccessBlockConfiguration':
                any_remediations = True
                s3.put_public_access_block(
                    Bucket=BUCKET_NAME,
                    PublicAccessBlockConfiguration={
                        'BlockPublicAcls': True,
                        'IgnorePublicAcls': True,
                        'BlockPublicPolicy': True,
                        'RestrictPublicBuckets': True
                    })
                sns.publish(
                    TopicArn=MY_TOPIC_ARN,
                    Message=f"Public access settings for bucket '{BUCKET_NAME}' have been found to be non-compliant and have been remediated.",
                    Subject=f"S3 Security Remediation Notification: Bucket '{BUCKET_NAME}'"
                )
            else:
                print(f"Unexpected S3 error on bucket {BUCKET_NAME}: {e}")    

    if not any_remediations:
        sns.publish(
            TopicArn=MY_TOPIC_ARN,
            Message=f"All S3 buckets have been found to be compliant with public access settings. No remediation actions were necessary.",
            Subject=f"S3 Security Remediation Notification: All Buckets Compliant"
        )
    return {
        'statusCode': 200,
        'body': f'Security audit for {buckets_checked} buckets completed.'
    }