import boto3 # type: ignore
import csv
import json
import io

s3_client = boto3.client('s3')

def lambda_handler(event, context):
    #stackoverflow
    for record in event['Records']: #stackoverflow
        bucket_1 = record['s3']['bucket']['name']
        key = record['s3']['object']['key']
        #for obj in bucket.objects.filter(Prefix='',Delimiter='/'):

        if key[-4:] == ".csv":
            response = s3_client.get_object(Bucket=bucket_1, Key=key)
            csv_content = response['Body'].read().decode('utf-8')
            #geeksforgeeks
            csv_reader = csv.DictReader(io.StringIO(csv_content)) #csv reader called DictReader 
            data = [row for row in csv_reader] #Convert each row into a dictionary

            json_content = json.dumps(data)
            json_key = key[:-4] + '.json'
            s3_client.put_object(Bucket='this-my-bucket-n2', Key=json_key, Body=json_content)


#json_key = key.replace('.csv', '.json')
#if key.endswith('.csv'):