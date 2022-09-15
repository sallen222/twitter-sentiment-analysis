#!/usr/bin/env python3

import tweepy
from dotenv import load_dotenv
import os
from kinesis_helper import KinesisStream
from text_transform import transform
import argparse
import boto3
# parse keyword to search from command
def parse_arg():
    
    parser = argparse.ArgumentParser()
    
    parser.add_argument('--keyword', type=str, required=True)
    
    params = vars(parser.parse_args())
    
    return params

if __name__ == '__main__':
    params = parse_arg()
    global searchTerm
    searchTerm = params['keyword']

bearer_token = ''

# Check if code is being run on ec2
is_aws = True if os.environ.get("AWS_DEFAULT_REGION") else False

if is_aws:
    client = boto3.client('ssm')
    bearer_token = client.get_parameter(
        Name='bearer_token',
        WithDecryption=True
    )
else:
    load_dotenv()
    bearer_token= os.getenv('bearer_token')

# Name of the AWS Kinesis stream
streamName = 'twitter-stream'

class MyStream(tweepy.StreamingClient):

    def on_connect(self):
        print('Connected to Twitter API.')

    def on_tweet(self, tweet):
        tweet = transform(tweet.text)
        output = {'key': f'{searchTerm}', 'content': f'{tweet}'}
        print(output)
        stream = KinesisStream(streamName)
        stream.send_stream(data=output)
        return True

    def on_error(self, status):
        print(status)
        # Stops stream if rate limit is reached (status code 420)
        if status == 420:
            print('Rate limit reached. Stopping stream.')
            return False
        if status == 401:
            print('Authentication Error. Stopping stream.')
            return False

rule = tweepy.StreamRule((f"{searchTerm} lang:en -is:retweet -is:reply"))

stream = MyStream(bearer_token=bearer_token)


if stream.get_rules()[3]['result_count'] != 0:
        n_rules = stream.get_rules()[0]
        ids = [n_rules[i_tuple[0]][2] for i_tuple in enumerate(n_rules)]
        print('Deleting old rules...')
        stream.delete_rules(ids)

stream.add_rules(rule)

stream.filter()