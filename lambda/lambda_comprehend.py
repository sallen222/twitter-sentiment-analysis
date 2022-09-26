import boto3
import json

comprehendClient = boto3.client('comprehend')
s3Client = boto3.client('s3')
ddbResource = boto3.resource('dynamodb')

def lambda_handler(event, context):
    
    eventKey = event['Records'][0]['s3']['object']['key']
    eventBucket = event['Records'][0]['s3']['bucket']['name']

    object = s3Client.get_object(Bucket=eventBucket, Key=eventKey)
    objectContent = object['Body'].read().decode('utf-8')
    print("TWEET CONTENT = " + objectContent)

    objectContent = json.loads(objectContent)
    tweetKey = objectContent['key']
    tweetContent = objectContent['content']
    tweetTimestamp = objectContent['timestamp']

    sentiment=comprehendClient.detect_sentiment(Text=tweetContent,LanguageCode='en')['Sentiment']
    print("SENTIMENT = " + sentiment)

    ddbPutItem(tweetKey, tweetContent, sentiment, tweetTimestamp)

    s3Client.delete_object(Bucket=eventBucket, Key=eventKey)

def ddbPutItem(key, content, sentiment, timestamp):
    table = ddbResource.Table('sentiment')
    table.put_item(Item={'searchterm': key, 'timestamp': timestamp, 'sentiment': sentiment, 'content': content})