# Usage: source env.sh
# Points the Azure CLI (and Terraform, which logs in through it) at Topaz.
# AZURE_CONFIG_DIR keeps a separate az profile inside this folder:
# your real ~/.azure login is never read or changed.
LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export AZURE_CONFIG_DIR="$LAB_DIR/.azure"
export AZURE_CORE_INSTANCE_DISCOVERY=false   # Topaz is not in Microsoft's list of login hosts
export AZURE_CORE_COLLECT_TELEMETRY=false
export REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt   # az ships its own CA bundle; use the OS one (has topaz.crt)
