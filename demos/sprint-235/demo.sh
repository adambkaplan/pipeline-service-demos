#!/usr/bin/env bash

# Copyright 2023 Adam B Kaplan
#
# SPDX-License-Identifier: Apache-2.0

set -e

# shellcheck source=./hack/demo-magic/demo-magic.sh
source ./hack/demo-magic/demo-magic.sh

clear

p "Pipeline Service Demo - Sprint 235"

clear

NAMESPACE="plnsvc-tests"

p "Tekton Results - REST + S3 + Logs!"
p "Results can be queried at a route endpoint, under a RESTful path"
p "Here are the pipelines that have been run:"
tkn pipelinerun list -o name -n $NAMESPACE
pipeline_name=$(tkn pipelineruns list -n $NAMESPACE -o name | head -1)
p "Let's query the result record for $pipeline_name!"

clear

RESULT_UID=$(kubectl get "$pipeline_name" -n "$NAMESPACE" -o yaml | yq .metadata.uid)
p "The UID for this PipelineRun is $RESULT_UID"
p "This UID is used to find the result record directly."

RESULT_ROUTE=$(kubectl get route tekton-results -n tekton-results --template='{{.spec.host}}')
ROOT_URL="https://$RESULT_ROUTE/apis/results.tekton.dev/v1alpha2/parents"
QUERY_URL="$ROOT_URL/$NAMESPACE/results/$RESULT_UID"

p "Let's look at the result summary:"
echo "curl -s --insecure $QUERY_URL | jq"

RESULTS_SA="tekton-results-tests"
token=$(kubectl create token "$RESULTS_SA" -n "$NAMESPACE")

curl -s --insecure \
  -H "Authorization: Bearer $token" \
  -H "Accept: application/json" \
  "$QUERY_URL" | jq

wait
clear

p "...and the records:"
echo "curl -s --insecure $QUERY_URL/records | jq '.records[] | {name: .name, type: .data.type}'"

curl -s --insecure \
  -H "Authorization: Bearer $token" \
  -H "Accept: application/json" \
  "$QUERY_URL/records" | \
  jq '.records[] | {name: .name, type: .data.type}'

wait
clear

p "...and the logs!"
echo "curl -s --insecure $QUERY_URL/logs | jq '.records[] | {name: .name, type: .data.type}'"

curl -s --insecure \
  -H "Authorization: Bearer $token" \
  -H "Accept: application/json" \
  "$QUERY_URL/logs" | \
  jq '.records[] | {name: .name, type: .data.type}'

wait
clear

p "We can try and get the first log..."
firstLog=$(curl -s --insecure -H "Authorization: Bearer $token" -H "Accept: application/json" "$QUERY_URL/logs" | jq -r '.records[0] | .name')
echo "curl -s --insecure $ROOT_URL/$firstLog | jq"

curl -s --insecure \
  -H "Authorization: Bearer $token" \
  -H "Accept: application/json" \
  "$ROOT_URL/$firstLog" | \
  jq

wait
p "Notice that we have data - which is base64 encoded."

clear
p "Decoding we get..."

curl -s --insecure \
  -H "Authorization: Bearer $token" \
  -H "Accept: application/json" \
  "$ROOT_URL/$firstLog" | \
  jq -r '.result.data' | \
  base64 -d

wait
clear

p "This concludes the demo. Enjoy!"

clear
