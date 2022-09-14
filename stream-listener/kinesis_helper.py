import os
import boto3
import json
import uuid

kinesisRegion = "us-east-1"

awsAccessKey=os.getenv('awsAccessKey')
awsSecretKey=os.getenv('awsSecretKey')

class KinesisStream(object):
    
    def __init__(self, stream):
        self.stream = stream

    def _connected_client(self):
        """ Connect to Kinesis Streams """
        return boto3.client('kinesis',
                            region_name=kinesisRegion,
                            aws_access_key_id=awsAccessKey,
                            aws_secret_access_key=awsSecretKey)

    def send_stream(self, data, partition_key=None):
        """
        data: python dict containing your data.
        partition_key:  set it to some fixed value if you want processing order
                        to be preserved when writing successive records.
                        
                        If your kinesis stream has multiple shards, AWS hashes your
                        partition key to decide which shard to send this record to.
                        
                        Ignore if you don't care for processing order
                        or if this stream only has 1 shard.
                        
                        If your kinesis stream is small, it probably only has 1 shard anyway.
        """

        # If no partition key is given, assume random sharding for even shard write load
        if partition_key == None:
            partition_key = uuid.uuid4()

        client = self._connected_client()
        return client.put_record(
            StreamName=self.stream,
            Data=json.dumps(data),
            PartitionKey=partition_key
        )