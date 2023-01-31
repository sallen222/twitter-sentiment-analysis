#! /bin/bash
sudo apt-get update
sudo apt-get install python3 -y
sudo apt-get install python3-pip -y
sudo apt-get install git -y
sudo pip3 install tweepy boto3 python-dotenv
git clone https://github.com/sallen222/twitter-sentiment-analysis /home/ubuntu/twitter-sentiment-analysis
cd /home/ubuntu/twitter-sentiment-analysis/stream-listener
chmod +x twitter_listener.py