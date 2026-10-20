#!/usr/bin/env bash
# Smoke-test every resource created by the lab, through Topaz, with the Azure CLI.
set -euo pipefail

# Use the lab's az profile (logged in to Topaz), never your real one.
lab_dir="$(cd "$(dirname "$0")/.." && pwd)"
export AZURE_CONFIG_DIR="$lab_dir/.azure"
export AZURE_CORE_INSTANCE_DISCOVERY=false AZURE_CORE_COLLECT_TELEMETRY=false
export REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

rg=$(terraform output -raw resource_group)
st=$(terraform output -raw storage_account)
kv=$(terraform output -raw key_vault_name)
sb=$(terraform output -raw servicebus_namespace)
vnet=$(terraform output -raw vnet_name)
log=$(terraform output -raw log_analytics_workspace)

echo "== Azure CLI is talking to"
az cloud show --query '{cloud:name, arm:endpoints.resourceManager}' -o table

echo "== Resource group"
az group show -n "$rg" --query '{name:name, location:location, state:properties.provisioningState}' -o table

echo "== Storage: upload a blob, send a queue message"
conn=$(az storage account show-connection-string -n "$st" -g "$rg" -o tsv)
echo "hello from jaylabs" > /tmp/hello.txt
az storage blob upload --connection-string "$conn" -c uploads -f /tmp/hello.txt -n hello.txt --overwrite -o none --only-show-errors --no-progress
az storage blob list --connection-string "$conn" -c uploads --query '[].name' -o tsv
az storage message put --connection-string "$conn" -q orders --content order-001 -o none --only-show-errors
az storage message peek --connection-string "$conn" -q orders --query '[].content' -o tsv --only-show-errors

echo "== Key Vault: read the generated secret (length only)"
az keyvault secret show --vault-name "$kv" -n db-password --query '{name:name, length:length(value)}' -o table

echo "== Service Bus"
az servicebus queue show -g "$rg" --namespace-name "$sb" -n orders \
  --query '{queue:name, status:status, maxDelivery:maxDeliveryCount}' -o table

echo "== Network"
az network vnet subnet show -g "$rg" --vnet-name "$vnet" -n snet-app \
  --query '{subnet:name, prefix:addressPrefix, nsg:networkSecurityGroup.id}' -o tsv \
  | awk '{n = split($3, id, "/"); print "subnet " $1 "  " $2 "  nsg " id[n]}'
az network nsg rule list -g "$rg" --nsg-name "nsg-${rg#rg-}" \
  --query '[].{rule:name, priority:priority, port:destinationPortRange, access:access}' -o table

echo "== Log Analytics"
az monitor log-analytics workspace show -g "$rg" -n "$log" --query '{name:name, sku:sku.name, retention:retentionInDays}' -o table
