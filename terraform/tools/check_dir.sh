#!/bin/bash

# Note that terraform can only unmarshal a JSON object with string values
# https://github.com/hashicorp/terraform/issues/13991
if [ -d "$1" ]; then
  echo '{"exists": "true"}'
else
  echo '{"exists": "false"}'
fi
