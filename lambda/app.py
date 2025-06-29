import json
import boto3
import botocore.config

from datetime import datetime

def generate_dockerfile(language: str) -> str:
  formatted_prompt = f"""<|begin_of_text|><|start_header_id|>user<|end_header_id|>
  ONLY generate an ideal Dockerfile for {language} with best practices. Do not provide any explanation.
  Include:
  - Base image
  - Installing dependencies
  - Setting working directory
  - Adding source code
  - Running the application
  <|eot_id|>
  <|start_header_id|>assistant<|end_header_id|>
  """

  body = {
    "prompt": formatted_prompt,
    "max_gen_len": 1024,
    "temperature": 0.5,
  }

  try:
    bedrock = boto3.client("bedrock-runtime", region_name="ap-south-1",
                            config=botocore.config.Config(read_timeout=300, retries={"max_attempts": 3}))
    response = bedrock.invoke_model(body=json.dumps(body), modelId="meta.llama3-8b-instruct-v1:0")

    response_content = response.get("body").read().decode("utf-8")
    response_data = json.loads(response_content)
    print(response_data)

    dockerfile = response_data["generation"]
    return dockerfile

  except Exception as e:
    print("Error generating Dockerfile:", e)
    return ""

def save_dockerfile(s3_key: str, s3_bucket: str, dockerfile: str) -> str:
  s3 = boto3.client("s3")

  try:
    s3.put_object(
      Body=dockerfile,
      Bucket=s3_bucket,
      Key=s3_key,
      ContentType="text/plain"
    )

    print("Dockerfile saved to S3")
    return f"https://{s3_bucket}.s3.amazonaws.com/{s3_key}"

  except Exception as e:
    print("Error saving Dockerfile to S3:", e)
    return ""

def handler(event, context):
  event = json.loads(event["body"])
  language = event["language"]

  dockerfile = generate_dockerfile(language)
  current_time = datetime.now().strftime("%H-%M-%S")
  s3_bucket = "zlash65-aws-bedrock-example"

  if dockerfile:
    s3_key = f"dockerfiles/{language}-{current_time}.Dockerfile"
    dockerfile_url = save_dockerfile(s3_key, s3_bucket, dockerfile)
    return {
      "statusCode": 200,
      "body": json.dumps({
        "message": "Dockerfile generated",
        "url": dockerfile_url
      })
    }
  else:
    return {
      "statusCode": 500,
      "body": json.dumps({"message": "Failed to generate Dockerfile"})
    }
