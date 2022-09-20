import boto3
import json
import random

comprehendClient = boto3.client('comprehend')
s3Client = boto3.client('s3')
s3Resource = boto3.resource('s3')


def lambda_handler(event, context):
    
    eventKey = event['Records'][0]['s3']['object']['key']
    eventBucket = event['Records'][0]['s3']['bucket']['name']

    object = s3Client.get_object(Bucket=eventBucket, Key=eventKey)
    objectContent = object['Body'].read().decode('utf-8')
    print("TWEET CONTENT =" + objectContent)

    tweetKey = objectContent['key']
    tweetContent = objectContent['content']

    sentiment=comprehendClient.detect_sentiment(Text=tweetContent,LanguageCode='en')['Sentiment']
    print("SENTIMENT =" + sentiment)

    output = {'key': f'{tweetKey}', 'content': f'{tweetContent}', 'sentiment': f'{sentiment}'}

    putBucket = s3Resource.Bucket('sallen-sentiment-destination-bucket')

    putBucket.put_object(Key=f'{eventKey}', Body=json.dumps(output))