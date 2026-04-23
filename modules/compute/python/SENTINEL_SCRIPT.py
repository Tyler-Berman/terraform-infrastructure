import boto3
import json
import os
import re
import gzip
import io

def lambda_handler(event, context):
    aws_region = os.environ.get('APP_REGION', 'us-east-1')
    s3 = boto3.client('s3', region_name=aws_region)
    bedrock = boto3.client('bedrock-runtime', region_name=aws_region)
    sns = boto3.client('sns', region_name=aws_region)

    if 'httpMethod' in event or 'requestContext' in event:
        try:
            print("DEBUG - Website request detected. Fetching latest analysis...")
            results_bucket = os.environ['REPORTS_BUCKET']
            objs = s3.list_objects_v2(Bucket=results_bucket, Prefix='analysis-')
        
            if 'Contents' not in objs:
                return {
                    "statusCode": 200,
                    "headers": {
                        "Content-Type": "application/json",
                        "Access-Control-Allow-Origin": "*",
                        "Access-Control-Allow-Methods": "GET,OPTIONS",
                        "Access-Control-Allow-Headers": "Content-Type"
                    },
                    "body": json.dumps({"threat_level": "N/A", "summary": "Sentinel is active. No logs analyzed yet."})
                }
        
            latest_key = sorted(objs['Contents'], key=lambda x: x['LastModified'], reverse=True)[0]['Key']
            response = s3.get_object(Bucket=results_bucket, Key=latest_key)
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
                "statusCode": 500,
                "headers": {"Access-Control-Allow-Origin": "*"},
                "body": json.dumps({"threat_level": "Error", "summary": str(e)})
            }

    try:
        bucket = event['Records'][0]['s3']['bucket']['name']
        key = event['Records'][0]['s3']['object']['key']
        print(f"DEBUG - S3 Trigger detected for file: {key}")
    
        response = s3.get_object(Bucket=bucket, Key=key)
        raw_content = response['Body'].read()
    
        if key.endswith('.gz'):
            with gzip.GzipFile(fileobj=io.BytesIO(raw_content)) as gz:
                file_content = gz.read().decode('utf-8')
        else:
            file_content = raw_content.decode('utf-8')

        safe_logs = file_content[-10000:]
        prompt = (
            "You are an expert AWS Security Analyst. Analyze the following logs (CloudTrail or VPC Flow Logs). "
            "Identify potential threats like unauthorized access, brute force, or suspicious traffic. "
            "Return ONLY a raw JSON object with keys 'threat_level' (High, Medium, Low) and 'summary'. "
            "Do not include conversational text. "
            f"\n\nLogs:\n{safe_logs}"
        )

        bedrock_res = bedrock.invoke_model(
            modelId="amazon.nova-micro-v1:0",
            body=json.dumps({
                "inferenceConfig": {"max_new_tokens": 1000, "temperature": 0.1},
                "messages": [{"role": "user", "content": [{"text": prompt}]}]
            })
        )

        result_body = json.loads(bedrock_res['body'].read())
        analysis_raw = result_body['output']['message']['content'][0]['text']
        match = re.search(r'\{.*\}', analysis_raw, re.DOTALL)
        analysis_json_str = match.group(0) if match else analysis_raw

        safe_key_name = key.replace('/', '-')
        s3.put_object(
            Bucket=os.environ['REPORTS_BUCKET'],
            Key=f"analysis-{safe_key_name}.json",
            Body=analysis_json_str,
            ContentType='application/json'
        )

        threat_data = json.loads(analysis_json_str)
        if threat_data.get('threat_level', '').lower() == 'high':
            sns.publish(
                TopicArn=os.environ['TOPIC_ARN_2'],
                Message=f"CRITICAL SENTINEL ALERT:\n\nKey: {key}\nSummary: {threat_data.get('summary')}",
                Subject="High Priority Threat Detected"
            )

        return {"statusCode": 200, "body": "Analysis Complete"}

    except Exception as e:
        print(f"Processing Error: {e}")
        return {"statusCode": 500, "body": str(e)}