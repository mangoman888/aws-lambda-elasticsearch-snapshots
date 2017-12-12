#!/usr/bin/python
# -*- coding: utf-8 -*-

from boto.connection import AWSAuthConnection
import os

class ESConnection(AWSAuthConnection):

    def __init__(self, region, **kwargs):
        super(ESConnection, self).__init__(**kwargs)
        self._set_auth_region_name(region)
        self._set_auth_service_name("es")

    def _required_auth_capability(self):
        return ['hmac-v4']

if __name__ == "__main__":

    client = ESConnection(
            region='eu-west-1',
            host=os.environ.get("ESENDPOINT", None),
            aws_access_key_id=os.environ.get("AWSKEY"),
            aws_secret_access_key=os.environ.get("AWSSECRET"), is_secure=True)

    print 'Registering Snapshot Repository'
    resp = client.make_request(method='POST',
            path='/_snapshot/' + os.environ.get("BUCKETNAME"),
            data='{"type": "s3","settings": { "bucket": "' + os.environ.get("BUCKETNAME") + '","region": "eu-west-1","role_arn": "arn:aws:iam::' + os.environ.get("AWSACCOUNTID") + ':role/es-snapshots-lambda"}}')
    body = resp.read()
    print body
