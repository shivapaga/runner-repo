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
  echo "Usage: $0 --url https://github.com/shivapaga/runner-repo.git --token ${{ secrets.RUNNER_TOKEN }} --name self-hosted [--labels self1]"
  exit 1
fi

# Ensure the URL is in the correct format
REPO_URL=$(echo "$URL" | sed 's#https://github.com/##')

# Generate registration token
REGISTRATION_TOKEN=$(curl -s -X POST -H "Authorization: token $TOKEN" -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/$REPO_URL/actions/runners/registration-token" | jq -r .token)

if [[ -z $REGISTRATION_TOKEN || $REGISTRATION_TOKEN == "null" ]]; then
  echo "Error: Unable to fetch the registration token."
  exit 1
fi

# Prepare labels if provided
if [[ -n $LABELS ]]; then
  LABELS_JSON=$(echo $LABELS | jq -R 'split(",")')
else
  LABELS_JSON="[]"
fi

# Download and configure the runner
RUNNER_DIR="actions-runner"
RUNNER_URL="https://github.com/actions/runner/releases/latest/download/actions-runner-linux-x64-2.285.1.tar.gz"

mkdir -p $RUNNER_DIR
cd $RUNNER_DIR

curl -o actions-runner-linux-x64.tar.gz -L $RUNNER_URL
tar xzf ./actions-runner-linux-x64.tar.gz

# Configure the runner
RUNNER_ALLOW_RUNASROOT="1" ./config.sh --url "https://github.com/$REPO_URL" --token "$REGISTRATION_TOKEN" --name "$NAME" --labels "$LABELS"

# Register runner
RESPONSE=$(curl -s -X POST \
     -H "Authorization: token $RUNNER_TOKEN" \
     -H "Accept: application/vnd.github.v3+json" \
     "https://api.github.com/repos/$REPO_URL/actions/runners" \
     -d "{\"name\": \"$NAME\", \"labels\": $LABELS_JSON}")

# Check if registration was successful
if echo "$RESPONSE" | grep -q "id"; then
  echo "Runner registered successfully."
else
  echo "Error: Runner registration failed."
  echo "Response: $RESPONSE"
  exit 1
fi
