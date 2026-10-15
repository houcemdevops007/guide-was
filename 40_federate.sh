#!/usr/bin/env bash
set -euo pipefail
WAS_HOME=${WAS_HOME:-/opt/IBM/WebSphere/AppServer_2}
PROFILE_NAME=${PROFILE_NAME:-Custom01}
DMGR_HOST=${DMGR_HOST:-vm-was-efi}
DMGR_PORT=${DMGR_PORT:-8880}
DMGR_USER=${DMGR_USER:-dmgr}
BIN="$WAS_HOME/profiles/$PROFILE_NAME/bin"
[[ -x "$BIN/addNode.sh" ]] || { echo 'Profil Custom absent'; exit 1; }
read -r -p "Fédérer ce nœud à $DMGR_HOST:$DMGR_PORT ? saisir OUI : " confirm
[[ "$confirm" == OUI ]] || exit 1
"$BIN/addNode.sh" "$DMGR_HOST" "$DMGR_PORT" -username "$DMGR_USER"
