#!/bin/bash

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --url)
      URL=$2
      shift 2
      ;;
    --token)
      TOKEN=$2
      shift 2
      ;;
    --name)
      NAME=$2
      shift 2
      ;;
    --labels)
      LABELS=$2
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

# Validate required parameters
if [[ -z $URL || -z $TOKEN || -z $NAME ]]; then
  echo "Usage: $0 --url <repository-url> --token <authentication-token> --name <runner-name> [--labels <runner-labels>]"
  exit 1
fi

# Generate registration token
REGISTRATION_TOKEN=$(curl -X POST -H "Authorization: token $TOKEN" -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/$URL/actions/runners/registration-token" | jq -r .token)

# Register runner
curl -X POST \
     -H "Authorization: token $REGISTRATION_TOKEN" \
     -H "Accept: application/vnd.github.v3+json" \
     "https://api.github.com/repos/$URL/actions/runners" \
     -d "{\"name\": \"$NAME\", \"labels\": [$LABELS]}"
