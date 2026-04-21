import boto3
import json
import os
import re

def lambda_handler(event, context):
    aws_region = os.environ.get('AWS_REGION', 'us-east-1')
    s3 = boto3.client('s3', region_name=aws_region)
    bedrock = boto3.client('bedrock-runtime', region_name=aws_region)
    sns = boto3.client('sns', region_name=aws_region)
    if 'requestContext' in event and 'http' in event['requestContext']:
        try:
            print("DEBUG - Website request detected. Fetching latest analysis...")
            response = s3.get_object(
                Bucket=os.environ['RESULTS_BUCKET'], 
                Key='analysis-attack.txt.json' 
            )
            latest_analysis = response['Body'].read().decode('utf-8')
            
            return {
                "statusCode": 200,
                "headers": {
                    "Content-Type": "application/json",
                    "Access-Control-Allow-Origin": "*", 
                    "Access-Control-Allow-Methods": "GET,OPTIONS",
                    "Access-Control-Allow-Headers": "Content-Type"
                },
                "body": latest_analysis
            }
        except Exception as e:
            print(f"Fetch Error: {e}")
            return {
                "statusCode": 404,
                "headers": {"Access-Control-Allow-Origin": "*"},
                "body": json.dumps({"threat_level": "N/A", "summary": "No analysis file found yet."})
            }

    try:
        bucket = event['Records'][0]['s3']['bucket']['name']
        key = event['Records'][0]['s3']['object']['key']
        print(f"DEBUG - S3 Trigger detected for file: {key}")
        
        file_content = s3.get_object(Bucket=bucket, Key=key)['Body'].read().decode('utf-8')
        
        prompt = (
            "You are a security analyst. Analyze these logs for threats. "
            "Return ONLY a raw JSON object with keys 'threat_level' and 'summary'. "
            "Do not include any conversational text or markdown. "
            f"Logs: {file_content}"
        )
        
        bedrock_res = bedrock.invoke_model(
            modelId="amazon.nova-micro-v1:0",
            body=json.dumps({
                "inferenceConfig": {"max_new_tokens": 1000, "temperature": 0.1},
                "messages": [{"role": "user", "content": [{"text": prompt}]}]
            })
        )
        
        result = json.loads(bedrock_res['body'].read())
        analysis_raw = result['output']['message']['content'][0]['text']
        
        match = re.search(r'\{.*\}', analysis_raw, re.DOTALL)
        analysis = match.group(0) if match else analysis_raw

        s3.put_object(
            Bucket=os.environ['RESULTS_BUCKET'],
            Key=f"analysis-{key}.json",
            Body=analysis
        )
        
        threat_data = json.loads(analysis)
        if threat_data.get('threat_level', '').lower() == 'high':
            sns.publish(
                TopicArn=os.environ['TOPIC_ARN_2'],
                Message=f"SENTINEL ALERT: {threat_data.get('summary')}",
                Subject="High Priority Threat Detected"
            )

        return {
    "statusCode": 200,
    "headers": {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
    },
    "body": analysis 
}

    except Exception as e:
        print(f"Processing Error: {e}")
        return {"statusCode": 500, "body": str(e)}