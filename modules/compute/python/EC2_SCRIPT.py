import boto3
import os
def lambda_handler(event, context):
    aws_region = os.environ.get('APP_REGION', 'us-east-1')
    ec2 = boto3.client('ec2', region_name=aws_region)
    sns = boto3.client('sns', region_name=aws_region)
    report = []
    topic_arn = os.environ.get('TOPIC_ARN_2')
    security_groups = ec2.describe_security_groups()
    for sg in security_groups['SecurityGroups']:
        print(f"Checking: {sg['GroupName']} ({sg['GroupId']})")
        vulnerabilities_found = 0
        
        for direction in ['IpPermissions', 'IpPermissionsEgress']:
            for rule in sg.get(direction, []):
                protocol = rule.get('IpProtocol')
                from_port = rule.get('FromPort')
                to_port = rule.get('ToPort')
                
                is_all_traffic = protocol == '-1'
                has_ssh_port = from_port is not None and from_port <= 22 <= to_port
                
                if is_all_traffic or has_ssh_port:
                    for ip_range in rule.get('IpRanges', []):
                        if ip_range.get('CidrIp') == '0.0.0.0/0':
                            vulnerabilities_found += 1
                            print(f"VULNERABILITY CONFIRMED ({direction})! Revoking...")
                            msg = (f"VULNERABILITY CONFIRMED in security group {sg['GroupName']} ({direction}) was open to the whole world!")
                            report.append(msg)

                            try:
                                params = {
                                    'GroupId': sg['GroupId'],
                                    'IpPermissions': [{
                                        'IpProtocol': protocol,
                                        'IpRanges': [{'CidrIp': ip_range.get('CidrIp')}]
                                    }]
                                }
                                if from_port is not None:
                                    params['IpPermissions'][0]['FromPort'] = from_port
                                    params['IpPermissions'][0]['ToPort'] = to_port

                                if direction == 'IpPermissions':
                                    ec2.revoke_security_group_ingress(**params)
                                    ingress_removal = (f"SUCCESS: Ingress rule removed from {sg['GroupName']}.")
                                    report.append(ingress_removal)
                                else:
                                    ec2.revoke_security_group_egress(**params)
                                    egress_removal = (f"SUCCESS: Egress rule removed from {sg['GroupName']}.")
                                    report.append(egress_removal)
                                print(f"SUCCESS: Rule removed from {sg['GroupName']}.")
                                
                            except Exception as e:
                                print(f"ERROR: {e}")
        if vulnerabilities_found == 0:
            print(f"No vulnerabilities found in {sg['GroupName']}.")
            
    if report:
        summary = "\n".join(report) 
        sns.publish(
            TopicArn=topic_arn,
            Subject="Sentinel EC2 Audit Report",
            Message=f"Sentinel has completed the EC2 scan. Findings:\n\n{summary}"
        ) 
    else:
        sns.publish(
            TopicArn=topic_arn,
            Subject="Sentinel EC2 Audit Report",
            Message="Sentinel has completed the EC2 scan. No vulnerabilities were found."
        )       
    return {
        'statusCode': 200,
        'body': 'Security audit completed.'
    }