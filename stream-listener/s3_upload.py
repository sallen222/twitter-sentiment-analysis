import boto3
import random
import json

def s3_upload(bucket,searchTerm,data):
    key = f'{searchTerm}/{random.randint(100000000, 999999999)}'
    print('OBJECT KEY = ' + key)
    s3 = boto3.resource('s3')
    data = bytes(json.dumps(data), encoding='utf-8')
    s3.Bucket(bucket).put_object(Key=key, Body=data)
    print('OBJECT UPLOADED')