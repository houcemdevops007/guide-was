#!/usr/bin/env bash
set -euo pipefail
WAS_HOME=${WAS_HOME:-/opt/IBM/WebSphere/AppServer_2}
PROFILE_NAME=${PROFILE_NAME:-Custom01}
NODE_HOST=${NODE_HOST:-nodesa1}
NODE_NAME=${NODE_NAME:-${NODE_HOST}Node01}
PROFILE_PATH="$WAS_HOME/profiles/$PROFILE_NAME"
[[ -x "$WAS_HOME/bin/manageprofiles.sh" ]] || { echo 'Installation WAS absente'; exit 1; }
[[ ! -e "$PROFILE_PATH" ]] || { echo "REFUS : profil existant $PROFILE_PATH"; exit 1; }
read -r -p "Créer le profil géré $NODE_NAME sur $(hostname) ? saisir OUI : " confirm
[[ "$confirm" == OUI ]] || exit 1
"$WAS_HOME/bin/manageprofiles.sh" -create -profileName "$PROFILE_NAME" -profilePath "$PROFILE_PATH" -templatePath "$WAS_HOME/profileTemplates/managed" -nodeName "$NODE_NAME" -cellName "${NODE_HOST}Cell01" -hostName "$NODE_HOST" -federateLater true
