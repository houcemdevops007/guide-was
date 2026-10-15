#!/usr/bin/env bash
set -euo pipefail
WAS_HOME=${WAS_HOME:-/opt/IBM/WebSphere/AppServer_2}
PROFILE_NAME=${PROFILE_NAME:-Custom01}
NODE_NAME=${NODE_NAME:-nodesa1Node01}
CELL_NAME=${CELL_NAME:-vm-was-efiCell02}
PROFILE="$WAS_HOME/profiles/$PROFILE_NAME"
echo '=== Processus ==='; ps -ef | grep '[n]odeagent' || true
echo '=== Ports ==='; ss -lntp | grep ':8878' || true
echo '=== SSL client ==='; grep '^com.ibm.ssl.protocol=' "$PROFILE/properties/ssl.client.props" || true
echo '=== SSL nœud (lecture seule) ==='; grep -n -A 3 'alias="NodeDefaultSSLSettings"' "$PROFILE/config/cells/$CELL_NAME/security.xml" || true
echo '=== Fichiers serveurs ==='; ls -la "$PROFILE/config/cells/$CELL_NAME/nodes/$NODE_NAME/servers" || true
echo '=== Erreurs récentes ==='; grep -iE 'CWPKI|JSSL|ADMS|Exception|ERROR' "$PROFILE/logs/nodeagent/SystemOut.log" | tail -n 45 || true
