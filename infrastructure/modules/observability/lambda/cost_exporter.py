"""
AWS Cost Exporter Lambda Function

This function fetches cost data from AWS Cost Explorer (excluding credits)
and publishes it as custom CloudWatch metrics for Grafana dashboards.
"""

import boto3
import os
from datetime import datetime, timedelta
from decimal import Decimal

ce_client = boto3.client('ce', region_name='us-east-1')
cw_client = boto3.client('cloudwatch')

PROJECT_NAME = os.environ.get('PROJECT_NAME', 'sdt')
ENVIRONMENT = os.environ.get('ENVIRONMENT', 'dev')


def handler(event, context):
    """
    Main handler function that:
    1. Fetches cost data from Cost Explorer (excluding credits)
    2. Publishes metrics to CloudWatch
    """

    try:
        # Calculate date range (yesterday, last 7 days, and month-to-date)
        end_date = datetime.now().date()
        start_date_1d = end_date - timedelta(days=1)
        start_date_7d = end_date - timedelta(days=7)
        start_date_mtd = end_date.replace(day=1)  # First day of current month

        # Format dates for Cost Explorer API
        end_str = end_date.strftime('%Y-%m-%d')
        start_1d_str = start_date_1d.strftime('%Y-%m-%d')
        start_7d_str = start_date_7d.strftime('%Y-%m-%d')
        start_mtd_str = start_date_mtd.strftime('%Y-%m-%d')

        print(f"Fetching costs from {start_1d_str} to {end_str}")
        print(f"Month-to-date period: {start_mtd_str} to {end_str}")

        # Fetch total cost (last 7 days) excluding credits
        total_cost_response = ce_client.get_cost_and_usage(
            TimePeriod={
                'Start': start_7d_str,  # Changed from start_1d_str to get 7 days
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

        # Fetch cost by service (last 7 days) excluding credits
        service_cost_response = ce_client.get_cost_and_usage(
            TimePeriod={
                'Start': start_7d_str,
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

        # Fetch month-to-date cost excluding credits
        mtd_cost_response = ce_client.get_cost_and_usage(
            TimePeriod={
                'Start': start_mtd_str,
                'End': end_str
            },
            Granularity='MONTHLY',
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

        # Process and publish total cost
        if total_cost_response['ResultsByTime']:
            latest_cost = total_cost_response['ResultsByTime'][-1]
            total_amount = float(latest_cost['Total']['UnblendedCost']['Amount'])

            print(f"Total cost (last 24h): ${total_amount:.2f}")

            # Publish total cost metric
            publish_metric(
                metric_name='TotalCost',
                value=total_amount,
                unit='None',
                dimensions=[]
            )

        # Process and publish month-to-date cost
        if mtd_cost_response['ResultsByTime']:
            mtd_cost = mtd_cost_response['ResultsByTime'][0]
            mtd_amount = float(mtd_cost['Total']['UnblendedCost']['Amount'])

            print(f"Month-to-date cost: ${mtd_amount:.2f}")

            # Publish MTD cost metric
            publish_metric(
                metric_name='MonthToDateCost',
                value=mtd_amount,
                unit='None',
                dimensions=[]
            )

        # Process and publish daily costs for the last 7 days
        print(f"\nPublishing daily cost data for last 7 days...")
        if total_cost_response['ResultsByTime']:
            for daily_result in total_cost_response['ResultsByTime']:
                daily_date = daily_result['TimePeriod']['Start']
                daily_amount = float(daily_result['Total']['UnblendedCost']['Amount'])

                # Parse the date
                result_datetime = datetime.strptime(daily_date, '%Y-%m-%d')

                print(f"Date: {daily_date}, Cost: ${daily_amount:.2f}")

                # Publish with timestamp for that specific day
                publish_metric_with_timestamp(
                    metric_name='TotalCost',
                    value=daily_amount,
                    unit='None',
                    dimensions=[],
                    timestamp=result_datetime
                )

        # Process and publish cost by service
        service_costs = {}
        for result in service_cost_response['ResultsByTime']:
            for group in result.get('Groups', []):
                service_name = group['Keys'][0]
                amount = float(group['Metrics']['UnblendedCost']['Amount'])

                if service_name not in service_costs:
                    service_costs[service_name] = 0
                service_costs[service_name] += amount

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

        # Publish service-specific metrics
        for service_name, amount in service_costs.items():
            if amount > 0:  # Only publish non-zero costs
                friendly_name = service_mapping.get(service_name, service_name)
                print(f"{friendly_name}: ${amount:.2f}")

                publish_metric(
                    metric_name='ServiceCost',
                    value=amount,
                    unit='None',
                    dimensions=[
                        {'Name': 'ServiceName', 'Value': friendly_name}
                    ]
                )

        return {
            'statusCode': 200,
            'body': f'Successfully published cost metrics. Total: ${total_amount:.2f}'
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        raise


def publish_metric(metric_name, value, unit, dimensions):
    """
    Publish a metric to CloudWatch

    Args:
        metric_name: Name of the metric
        value: Metric value
        unit: Unit of measurement
        dimensions: List of dimension dicts with Name and Value keys
    """

    metric_data = {
        'MetricName': metric_name,
        'Value': value,
        'Unit': unit,
        'Timestamp': datetime.utcnow(),
        'Dimensions': [
            {'Name': 'Project', 'Value': PROJECT_NAME},
            {'Name': 'Environment', 'Value': ENVIRONMENT}
        ]
    }

    # Add additional dimensions
    metric_data['Dimensions'].extend(dimensions)

    try:
        cw_client.put_metric_data(
            Namespace=f'{PROJECT_NAME.upper()}/Costs',
            MetricData=[metric_data]
        )
        print(f"Published metric: {metric_name} = {value}")
    except Exception as e:
        print(f"Error publishing metric {metric_name}: {str(e)}")
        raise


def publish_metric_with_timestamp(metric_name, value, unit, dimensions, timestamp):
    """
    Publish a metric to CloudWatch with a specific timestamp

    Args:
        metric_name: Name of the metric
        value: Metric value
        unit: Unit of measurement
        dimensions: List of dimension dicts with Name and Value keys
        timestamp: Datetime object for the metric timestamp
    """

    metric_data = {
        'MetricName': metric_name,
        'Value': value,
        'Unit': unit,
        'Timestamp': timestamp,
        'Dimensions': [
            {'Name': 'Project', 'Value': PROJECT_NAME},
            {'Name': 'Environment', 'Value': ENVIRONMENT}
        ]
    }

    # Add additional dimensions
    metric_data['Dimensions'].extend(dimensions)

    try:
        cw_client.put_metric_data(
            Namespace=f'{PROJECT_NAME.upper()}/Costs',
            MetricData=[metric_data]
        )
        print(f"Published metric: {metric_name} = {value} at {timestamp}")
    except Exception as e:
        print(f"Error publishing metric {metric_name}: {str(e)}")
        raise
