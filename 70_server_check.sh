#!/usr/bin/env bash
set -euo pipefail
SERVER_NAME=${1:?Usage: 70_server_check.sh NOM_SERVEUR}
WAS_HOME=${WAS_HOME:-/opt/IBM/WebSphere/AppServer_2}
PROFILE_NAME=${PROFILE_NAME:-Custom01}
CELL_NAME=${CELL_NAME:-vm-was-efiCell02}
NODE_NAME=${NODE_NAME:-nodesa1Node01}
PROFILE="$WAS_HOME/profiles/$PROFILE_NAME"
XML="$PROFILE/config/cells/$CELL_NAME/nodes/$NODE_NAME/servers/$SERVER_NAME/server.xml"
[[ -f "$XML" ]] || { echo "ERREUR : $XML absent. Synchroniser avant démarrage."; exit 1; }
echo "OK : $XML"; echo '=== Journaux ==='
for file in startServer.log SystemOut.log SystemErr.log; do [[ ! -f "$PROFILE/logs/$SERVER_NAME/$file" ]] || tail -n 35 "$PROFILE/logs/$SERVER_NAME/$file"; done
read -r -p "Démarrer $SERVER_NAME ? saisir OUI : " confirm
[[ "$confirm" == OUI ]] || exit 0
"$PROFILE/bin/startServer.sh" "$SERVER_NAME"
