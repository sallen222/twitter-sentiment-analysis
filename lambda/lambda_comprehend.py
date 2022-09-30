import boto3
import json

comprehendClient = boto3.client('comprehend')
s3Client = boto3.client('s3')
ddbResource = boto3.resource('dynamodb')

def lambda_handler(event, context):
    
    # Pull object details from event
    eventKey = event['Records'][0]['s3']['object']['key']
    eventBucket = event['Records'][0]['s3']['bucket']['name']
    
    # Get object from s3 and pull object body
    object = s3Client.get_object(Bucket=eventBucket, Key=eventKey)
    objectContent = object['Body'].read().decode('utf-8')
    print("TWEET CONTENT = " + objectContent)
    
    # Take values from body and declare them as variables
    objectContent = json.loads(objectContent)
    tweetKey = objectContent['key']
    tweetContent = objectContent['content']
    tweetTimestamp = objectContent['timestamp']
    
    # Send the tweet content to comprehend for sentiment analysis
    sentiment = comprehendClient.detect_sentiment(Text=tweetContent,LanguageCode='en')['Sentiment']
    print("SENTIMENT = " + sentiment)
    
    # Upload output to DyanamoDB
    ddbPutItem(tweetKey, tweetContent, sentiment, tweetTimestamp)
    
    # Delete s3 object
    s3Client.delete_object(Bucket=eventBucket, Key=eventKey)

def ddbPutItem(key, content, sentiment, timestamp):
    table = ddbResource.Table('sentiment')
    table.put_item(Item={'searchterm': key, 'timestamp': timestamp, 'sentiment': sentiment, 'content': content})