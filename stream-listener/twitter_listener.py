#!/usr/bin/env python3
import tweepy
from dotenv import load_dotenv
import os
from text_transform import transform
import argparse
from s3_upload import s3_upload
import json

# parse keyword to search from command
def parse_arg():
    parser = argparse.ArgumentParser()
    parser.add_argument("--keyword", type=str, required=True)
    params = vars(parser.parse_args())
    return params


if __name__ == "__main__":
    params = parse_arg()
    global searchTerm
    searchTerm = params["keyword"]

load_dotenv()
# Set bearer token to env variable
bearer_token = os.getenv("bearer_token")

# Tweepy stream listener
class MyStream(tweepy.StreamingClient):
    def on_connect(self):
        print("Connected to Twitter API.")

    def on_data(self, raw_data):
        print("----------------------------------------")
        data = json.loads(raw_data)
        content = transform(data["data"]["text"])
        timestamp = data["data"]["created_at"]
        output = {
            "key": f"{searchTerm}",
            "content": f"{content}",
            "timestamp": f"{timestamp}",
        }
        print(output)
        s3_upload("sallen-sentiment-source-bucket", searchTerm, output)
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


# build filter rule
rule = tweepy.StreamRule((f"{searchTerm} lang:en -is:retweet -is:reply"))

stream = MyStream(bearer_token=bearer_token)

# Delete old rules if they exist
if stream.get_rules()[3]["result_count"] != 0:
    n_rules = stream.get_rules()[0]
    ids = [n_rules[i_tuple[0]][2] for i_tuple in enumerate(n_rules)]
    print("Deleting old rules...")
    stream.delete_rules(ids)

stream.add_rules(rule)

stream.filter(tweet_fields="created_at")
