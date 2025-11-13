import json
import boto3
import os
from datetime import datetime, timedelta
import time

def handler(event, context):
    """
    Lambda function to export CloudWatch logs to S3
    Runs hourly to export previous hour's logs
    """
    
    logs_client = boto3.client('logs')
    s3_bucket = os.environ['S3_BUCKET']
    log_groups = json.loads(os.environ['LOG_GROUPS'])
    
    # Calculate time range for previous hour
    end_time = datetime.now().replace(minute=0, second=0, microsecond=0)
    start_time = end_time - timedelta(hours=1)
    
    # Convert to epoch milliseconds
    from_time = int(start_time.timestamp() * 1000)
    to_time = int(end_time.timestamp() * 1000)
    
    export_tasks = []
    successful_exports = 0
    failed_exports = 0
    
    for log_group in log_groups:
        try:
            # Check if log group exists
            try:
                response = logs_client.describe_log_groups(logGroupNamePrefix=log_group)
                if not response['logGroups']:
                    print(f"Log group {log_group} not found, skipping...")
                    continue
            except Exception as e:
                print(f"Error checking log group {log_group}: {str(e)}")
                failed_exports += 1
                continue
            
            # Create export task with retry logic for rate limits
            max_retries = 3
            retry_delay = 30  # seconds
            
            for attempt in range(max_retries):
                try:
                    destination_prefix = f"cloudwatch-logs/{log_group.replace('/', '-')}/{start_time.strftime('%Y/%m/%d/%H')}"
                    
                    response = logs_client.create_export_task(
                        logGroupName=log_group,
                        fromTime=from_time,
                        to=to_time,
                        destination=s3_bucket,
                        destinationPrefix=destination_prefix
                    )
                    
                    export_tasks.append({
                        'taskId': response['taskId'],
                        'logGroup': log_group,
                        'status': 'PENDING'
                    })
                    
                    print(f"Created export task {response['taskId']} for {log_group}")
                    successful_exports += 1
                    
                    # Wait between export tasks to avoid hitting rate limits
                    if len(export_tasks) < len(log_groups):
                        time.sleep(5)  # 5 second delay between tasks
                    
                    break  # Success, exit retry loop
                    
                except logs_client.exceptions.LimitExceededException:
                    if attempt < max_retries - 1:
                        print(f"Rate limit hit for {log_group}, retrying in {retry_delay} seconds... (attempt {attempt + 1}/{max_retries})")
                        time.sleep(retry_delay)
                        retry_delay *= 2  # Exponential backoff
                    else:
                        print(f"Failed to create export task for {log_group} after {max_retries} attempts: Rate limit exceeded")
                        failed_exports += 1
                        break
                        
                except Exception as e:
                    print(f"Error creating export task for {log_group}: {str(e)}")
                    failed_exports += 1
                    break
                    
        except Exception as e:
            print(f"Unexpected error processing {log_group}: {str(e)}")
            failed_exports += 1
            continue
    
    # Wait for tasks to complete (with timeout)
    max_wait_time = 240  # 4 minutes
    start_wait = time.time()
    
    while export_tasks and (time.time() - start_wait) < max_wait_time:
        for task in export_tasks[:]:  # Create a copy to iterate over
            try:
                response = logs_client.describe_export_tasks(
                    taskId=task['taskId']
                )
                
                if response['exportTasks']:
                    status = response['exportTasks'][0]['status']['code']
                    task['status'] = status
                    
                    if status in ['COMPLETED', 'FAILED', 'CANCELLED']:
                        print(f"Export task {task['taskId']} for {task['logGroup']}: {status}")
                        export_tasks.remove(task)
                        
            except Exception as e:
                print(f"Error checking task {task['taskId']}: {str(e)}")
                export_tasks.remove(task)
        
        if export_tasks:
            time.sleep(10)  # Wait 10 seconds before checking again
    
    # Report final status
    result = {
        'statusCode': 200,
        'body': json.dumps({
            'message': f'Log export completed for {start_time.strftime("%Y-%m-%d %H:00")}',
            'totalLogGroups': len(log_groups),
            'successfulExports': successful_exports,
            'failedExports': failed_exports,
            'timeRange': {
                'from': start_time.isoformat(),
                'to': end_time.isoformat()
            }
        })
    }
    
    return result
