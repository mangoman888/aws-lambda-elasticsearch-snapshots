#!/usr/bin/python
# -*- coding: utf-8 -*-

from __future__ import print_function
from datetime import datetime
import requests
import json
import os
import boto3
from requests_aws4auth import AWS4Auth

# Use with a CloudWatch Rule to schedule backups to a S3 bucket
# This is in addition to the default cs-automated backups which keep 14 days worth of snapshots

def lambda_handler(event, context):

    session = boto3.session.Session()
    credentials = session.get_credentials()
    
    awsauth = AWS4Auth(credentials.access_key,
                       credentials.secret_key,
                       session.region_name, 'es',
                       session_token=credentials.token)

    datestamp = datetime.now().strftime('%Y-%m-%dt%H:%M:%S')
    
    print("Taking ES Snapshot:")
    rp = requests.put('https://' + os.environ.get("es_endpoint") + '/_snapshot/' + os.environ.get("es_bucket") + '/snapshot' + datestamp, auth=awsauth)
    rp.json()
    print(json.dumps(rp.json(), indent=2))

