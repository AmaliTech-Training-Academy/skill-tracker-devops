"""
AWS Cost Backfill Script - One-time execution

This script publishes the last 7 days of cost data with current timestamps
so it can be immediately visible in Grafana dashboards.
"""

import boto3
import os
from datetime import datetime, timedelta

ce_client = boto3.client('ce', region_name='us-east-1')
cw_client = boto3.client('cloudwatch')

PROJECT_NAME = os.environ.get('PROJECT_NAME', 'sdt')
ENVIRONMENT = os.environ.get('ENVIRONMENT', 'dev')


def handler(event, context):
    """
    Backfill handler that publishes last 7 days of cost data
    with current timestamps for immediate visibility
    """

    try:
        # Calculate date range for last 7 days
        end_date = datetime.now().date()
        start_date = end_date - timedelta(days=7)

        # Format dates for Cost Explorer API
        end_str = end_date.strftime('%Y-%m-%d')
        start_str = start_date.strftime('%Y-%m-%d')

        print(f"Backfilling costs from {start_str} to {end_str}")

        # Fetch daily costs for the last 7 days excluding credits
        response = ce_client.get_cost_and_usage(
            TimePeriod={
                'Start': start_str,
                'End': end_str
            },
            Granularity='DAILY',
            Metrics=['UnblendedCost'],
            Filter={
                'Not': {
                    'Dimensions': {
                        'Key': 'RECORD_TYPE',
                        'Values': ['Credit', 'Refund', 'Tax']
                    }
                }
            }
        )

        # Also fetch service breakdown for the period
        service_response = ce_client.get_cost_and_usage(
            TimePeriod={
                'Start': start_str,
                'End': end_str
            },
            Granularity='DAILY',
            Metrics=['UnblendedCost'],
            GroupBy=[
                {
                    'Type': 'DIMENSION',
                    'Key': 'SERVICE'
                }
            ],
            Filter={
                'Not': {
                    'Dimensions': {
                        'Key': 'RECORD_TYPE',
                        'Values': ['Credit', 'Refund', 'Tax']
                    }
                }
            }
        )

        # Map AWS service names to friendly names
        service_mapping = {
            'Amazon Elastic Container Service': 'ECS',
            'Amazon Relational Database Service': 'RDS',
            'Amazon Elastic Compute Cloud - Compute': 'EC2',
            'Amazon Simple Storage Service': 'S3',
            'AWS Amplify': 'Amplify',
            'Amazon Virtual Private Cloud': 'VPC',
            'AmazonCloudWatch': 'CloudWatch',
            'AWS Lambda': 'Lambda',
            'Amazon CloudFront': 'CloudFront'
        }

        # Publish daily total costs
        print("\n=== Publishing Daily Total Costs ===")
        metrics_to_publish = []

        for i, daily_result in enumerate(response['ResultsByTime']):
            daily_date = daily_result['TimePeriod']['Start']
            daily_amount = float(daily_result['Total']['UnblendedCost']['Amount'])

            # Use current timestamp with offset to spread out the data points
            timestamp = datetime.utcnow() - timedelta(days=(6 - i))

            print(f"Day {i+1}: {daily_date} = ${daily_amount:.2f} (timestamp: {timestamp})")

            metrics_to_publish.append({
                'MetricName': 'DailyCostHistory',
                'Value': daily_amount,
                'Unit': 'None',
                'Timestamp': timestamp,
                'Dimensions': [
                    {'Name': 'Project', 'Value': PROJECT_NAME},
                    {'Name': 'Environment', 'Value': ENVIRONMENT},
                    {'Name': 'Date', 'Value': daily_date}
                ]
            })

        # Publish in batches (CloudWatch allows max 20 metrics per call)
        for i in range(0, len(metrics_to_publish), 20):
            batch = metrics_to_publish[i:i+20]
            cw_client.put_metric_data(
                Namespace=f'{PROJECT_NAME.upper()}/Costs',
                MetricData=batch
            )
            print(f"Published batch of {len(batch)} metrics")

        # Calculate and publish service costs for the entire period
        print("\n=== Publishing Service Cost Totals ===")
        service_costs = {}
        for result in service_response['ResultsByTime']:
            for group in result.get('Groups', []):
                service_name = group['Keys'][0]
                amount = float(group['Metrics']['UnblendedCost']['Amount'])

                if service_name not in service_costs:
                    service_costs[service_name] = 0
                service_costs[service_name] += amount

        service_metrics = []
        for service_name, amount in service_costs.items():
            if amount > 0:
                friendly_name = service_mapping.get(service_name, service_name)
                print(f"{friendly_name}: ${amount:.2f}")

                service_metrics.append({
                    'MetricName': 'ServiceCost',
                    'Value': amount,
                    'Unit': 'None',
                    'Timestamp': datetime.utcnow(),
                    'Dimensions': [
                        {'Name': 'Project', 'Value': PROJECT_NAME},
                        {'Name': 'Environment', 'Value': ENVIRONMENT},
                        {'Name': 'ServiceName', 'Value': friendly_name}
                    ]
                })

        # Publish service metrics
        if service_metrics:
            for i in range(0, len(service_metrics), 20):
                batch = service_metrics[i:i+20]
                cw_client.put_metric_data(
                    Namespace=f'{PROJECT_NAME.upper()}/Costs',
                    MetricData=batch
                )

        total_days = len(response['ResultsByTime'])
        return {
            'statusCode': 200,
            'body': f'Successfully backfilled {total_days} days of cost data'
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        raise
