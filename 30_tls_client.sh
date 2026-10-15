#!/usr/bin/env bash
set -euo pipefail
WAS_HOME=${WAS_HOME:-/opt/IBM/WebSphere/AppServer_2}
PROFILE_NAME=${PROFILE_NAME:-Custom01}
FILE="$WAS_HOME/profiles/$PROFILE_NAME/properties/ssl.client.props"
[[ -f "$FILE" ]] || { echo "Absent : $FILE"; exit 1; }
grep '^com.ibm.ssl.protocol=' "$FILE" || true
read -r -p 'Remplacer SSL_TLS par TLSv1.2 pour ce client ? saisir OUI : ' confirm
[[ "$confirm" == OUI ]] || exit 1
cp -p "$FILE" "$FILE.bak.$(date +%Y%m%d%H%M%S)"
sed -i 's/^com\.ibm\.ssl\.protocol=SSL_TLS$/com.ibm.ssl.protocol=TLSv1.2/' "$FILE"
grep '^com.ibm.ssl.protocol=' "$FILE"
echo 'Attention : les configurations SSL du Node Agent se règlent séparément via le DMGR.'
