#!/bin/bash

rm -rf lambda_build lambda.zip
mkdir -p lambda_build

pip3 install -r lambda/requirements.txt -t lambda_build

cp lambda/app.py lambda_build
cd lambda_build && zip -r ../lambda.zip .

cd ..
