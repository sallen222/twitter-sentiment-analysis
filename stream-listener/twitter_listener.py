import tweepy
from dotenv import load_dotenv
import os
from kinesis_helper import KinesisStream

# Loading bearer token from .env file
load_dotenv()
bearer_token= os.getenv('bearer_token')

# Name of the AWS Kinesis stream
streamName = "twitter-stream"

class MyStream(tweepy.StreamingClient):
    # NOT CORRECT

    def on_connect(self):
        print("Connected to Twitter API.")

    def on_tweet(self, tweet):
        print(tweet.text)
        #outputData = {'': 'data'}
        #stream = KinesisStream(streamName)
        #stream.send_stream(data=outputData)
        return True

    def on_error(self, status):
        print(status)
        # Stops stream if rate limit is reached (status code 420)
        if status == 420:
            print("Rate limit reached. Stopping stream.")
            return False
        if status == 401:
            print("Authentication Error. Stopping stream.")
            return False

# Placeholder tracking keyword
searchTerm = ""

rule = tweepy.StreamRule((f"{searchTerm} lang:en -is:retweet -is:reply"))

stream = MyStream(bearer_token=bearer_token)


if stream.get_rules()[3]['result_count'] != 0:
        n_rules = stream.get_rules()[0]
        ids = [n_rules[i_tuple[0]][2] for i_tuple in enumerate(n_rules)]
        print("Deleting old rules...")
        stream.delete_rules(ids)

stream.add_rules(rule)

stream.filter()