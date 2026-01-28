#!/bin/bash

export AGENT_SECRET=30bfb2fbb58f541b258dc8c9a10def5b7f4c4eaf67cf1890a16c8a9c60310e69

curl -sO http://localhost:8080/jnlpJars/agent.jar;java -jar agent.jar -url http://localhost:8080/ -secret $AGENT_SECRET -name nodocker -webSocket -workDir "/mnt/big_disk/workspace_agent_1"