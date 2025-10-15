#!/usr/bin/env python3
import os
import openai

openai.api_key = os.environ.get("OPENAI_API_KEY")

dockerfile_content = os.environ.get("DOCKERFILE_CONTENT", "")
layers = os.environ.get("LAYERS", "")
binary_info = os.environ.get("BINARY_INFO", "")
ssl_info = os.environ.get("SSL_INFO", "")

prompt = (
    "Dockerfile:\n" + dockerfile_content +
    "\nLayers:\n" + layers +
    "\nBinary:\n" + binary_info +
    "\nSSL:\n" + ssl_info +
    "\nSuggest optimization tips."
)

resp = openai.ChatCompletion.create(
    model='gpt-4',
    messages=[{'role':'user','content':prompt}],
    temperature=0.2
)

with open("ai_suggestions.txt", "w") as f:
    f.write(resp.choices[0].message.content)
