import tweepy
from dotenv import load_dotenv
import os
from kinesis_helper import KinesisStream

# Loading environment variables
load_dotenv()
api_key = os.getenv('api_key')
api_secret = os.getenv('api_secret')
access_token = os.getenv('access_token')
access_secret = os.getenv('access_secret')
bearer_token= os.getenv('bearer_token')

client = tweepy.Client(bearer_token, api_key, api_secret, access_token, access_secret)

auth = tweepy.OAuth1UserHandler(api_key, api_secret, access_token, access_secret)
api = tweepy.API(auth)
# Name of the AWS Kinesis stream
# streamName = "twitter-stream"

class MyStream(tweepy.StreamingClient):
    # NOT CORRECT

    def on_connect(self):
        print("Connected to Twitter API.")

    def on_tweet(self, tweet):
        print(tweet.text)
        return True

    def on_error(self, status):
        print(status)
        # Stops stream if rate limit is reached (status code 420)
        if status == 420:
            return False
        if status == 401:
            print("Authentication Error")
            return False

# Placeholder tracking keyword
searchTerm = ""

rule = tweepy.StreamRule((f"{searchTerm} lang:en"))

stream = MyStream(bearer_token=bearer_token)
print(stream.get_rules())

if stream.get_rules()[3]['result_count'] != 0:
        n_rules = stream.get_rules()[0]
        ids = [n_rules[i_tuple[0]][2] for i_tuple in enumerate(n_rules)]
        stream.delete_rules(ids)
        stream.add_rules(rule)

stream.filter()