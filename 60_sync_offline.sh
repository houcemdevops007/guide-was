#!/usr/bin/env bash
set -euo pipefail
WAS_HOME=${WAS_HOME:-/opt/IBM/WebSphere/AppServer_2}
PROFILE_NAME=${PROFILE_NAME:-Custom01}
DMGR_HOST=${DMGR_HOST:-vm-was-efi}
DMGR_PORT=${DMGR_PORT:-8880}
DMGR_USER=${DMGR_USER:-dmgr}
BIN="$WAS_HOME/profiles/$PROFILE_NAME/bin"
echo 'ATTENTION : arrêt du Node Agent local, synchronisation, puis démarrage sous contrôle.'
read -r -p 'Confirmer arrêt du Node Agent local ? saisir OUI : ' confirm
[[ "$confirm" == OUI ]] || exit 1
"$BIN/stopNode.sh" -username "$DMGR_USER"
if ps -ef | grep -q '[n]odeagent'; then echo 'Node Agent encore présent ; arrêt de la procédure.'; exit 1; fi
read -r -p 'Lancer syncNode hors ligne ? saisir OUI : ' confirm
[[ "$confirm" == OUI ]] || exit 1
"$BIN/syncNode.sh" "$DMGR_HOST" "$DMGR_PORT" -username "$DMGR_USER"
read -r -p 'Synchronisation réussie. Démarrer Node Agent ? saisir OUI : ' confirm
[[ "$confirm" == OUI ]] || exit 0
"$BIN/startNode.sh"
