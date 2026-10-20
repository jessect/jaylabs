#!/usr/bin/env bash
# Smoke-test every resource created by the lab against the local emulators.
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/emulators.env

project=$(terraform output -raw project_id)
bucket=$(terraform output -raw bucket_name)
object=$(terraform output -raw config_object)
topic=$(terraform output -raw topic_name)
sub=$(terraform output -raw subscription_name)
instance=$(terraform output -raw spanner_instance)
db=$(terraform output -raw spanner_database)
doc=$(terraform output -raw firestore_document)
bt_instance=$(terraform output -raw bigtable_instance)
bt_table=$(terraform output -raw bigtable_table)

echo "== Cloud Storage (fake-gcs-server)"
gcloud storage buckets describe "gs://${bucket}" --format="table(name,location,versioning_enabled)"
gcloud storage cat "gs://${bucket}/${object}"; echo

echo "== Pub/Sub"
gcloud pubsub subscriptions describe "$sub" --format="yaml(topic,ackDeadlineSeconds,deadLetterPolicy)"
gcloud pubsub topics publish "$topic" --message='{"order_id":"order-001"}'
gcloud pubsub subscriptions pull "$sub" --auto-ack --format="value(message.data)"

echo "== Spanner"
gcloud spanner instances list --format="table(name,config,state)"
gcloud spanner databases execute-sql "$db" --instance="$instance" \
  --sql="INSERT INTO Orders (OrderId, Item, Qty) VALUES ('order-001', 'keyboard', 2)" >/dev/null
gcloud spanner databases execute-sql "$db" --instance="$instance" --sql="SELECT * FROM Orders"

echo "== Firestore"
curl -s -H "Authorization: Bearer owner" \
  "http://localhost:8080/v1/projects/${project}/databases/(default)/documents/${doc}" | jq '.fields'

echo "== Bigtable"
cbt -project "$project" -instance "$bt_instance" ls "$bt_table" 2>/dev/null
cbt -project "$project" -instance "$bt_instance" set "$bt_table" order-001 order:item=keyboard 2>/dev/null
cbt -project "$project" -instance "$bt_instance" read "$bt_table" 2>/dev/null
