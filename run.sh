#!/usr/bin/env bash

#
# The following creates a lambda function that can be run via a Cloudwatch schedule rule
# It creates a IAM role (if it doesn't exist) and policies required to run
# It creates (or updates if exists) a lambda function called es-snapshots-lambda
# It assumes an S3 bucket $BUCKETNAME already exists for storing the ES snapshots
#

# Make build dir if not exist
if [[ ! -e build ]]; then
  mkdir build
fi

# Check role exists
if aws iam get-role --role-name es-snapshots-lambda --profile ${PROFILE} 2>/dev/null; then
  echo -e "\nes-snapshots-lambda role already exists\n"
else
  # Create the IAM Role
  aws iam create-role --role-name es-snapshots-lambda \
      --profile ${PROFILE} \
      --assume-role-policy-document file://json_file/trust_policy.json
fi
sleep 5

# Add or update inline policy for the IAM role
aws iam put-role-policy --role-name es-snapshots-lambda \
    --profile ${PROFILE} \
    --policy-name es_snapshots \
    --policy-document file://json_file/es_snapshotbucket.json

# Register the snapshot directory
python es-register-snapshot-directory.py

# Install requirements
pip install -r requirements.txt -t build

# Create your Lambda package
cp es-snapshots.py build
cd build && zip -r es-snapshots-lambda.zip *

# Check if function exists and update if it does
if aws lambda get-function --function-name es-snapshots-lambda --profile ${PROFILE} 2>/dev/null; then
  echo -e "\nUpdating es-snapshots-lambda function\n"
  aws lambda update-function-code \
      --profile ${PROFILE} \
      --function-name es-snapshots-lambda \
      --zip-file fileb://es-snapshots-lambda.zip
else
  # Lambda deployment
  echo -e "\nCreating es-snapshots-lambda function\n"
  aws lambda create-function \
      --profile ${PROFILE} \
      --function-name es-snapshots-lambda \
      --environment "Variables={es_endpoint=$ESENDPOINT,es_bucket=$BUCKETNAME}" \
      --zip-file fileb://es-snapshots-lambda.zip \
      --description "Elastichsearch backup snapshots to S3" \
      --role arn:aws:iam::$AWSACCOUNTID:role/es-snapshots-lambda \
      --handler es-snapshots.lambda_handler \
      --runtime python2.7 \
      --timeout 300
fi

