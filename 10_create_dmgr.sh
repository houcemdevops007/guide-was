#!/usr/bin/env bash
set -euo pipefail
WAS_HOME=${WAS_HOME:-/opt/IBM/WebSphere/AppServer_2}
PROFILE_NAME=${PROFILE_NAME:-Dmgr01}
PROFILE_PATH="$WAS_HOME/profiles/$PROFILE_NAME"
CELL_NAME=${CELL_NAME:-vm-was-efiCell02}
DMGR_NODE=${DMGR_NODE:-vm-was-efiCellManager02}
DMGR_HOST=${DMGR_HOST:-vm-was-efi}
[[ -x "$WAS_HOME/bin/manageprofiles.sh" ]] || { echo 'Installation WAS absente'; exit 1; }
[[ ! -e "$PROFILE_PATH" ]] || { echo "REFUS : profil existant $PROFILE_PATH"; exit 1; }
echo 'Ce script crée un DMGR neuf. Il n’active pas automatiquement la sécurité administrative.'
echo 'Configurer la sécurité administrative et les secrets dans la console avant la fédération.'
read -r -p "Créer $PROFILE_NAME sur $(hostname) ? saisir OUI : " confirm
[[ "$confirm" == OUI ]] || exit 1
"$WAS_HOME/bin/manageprofiles.sh" -create -profileName "$PROFILE_NAME" -profilePath "$PROFILE_PATH" -templatePath "$WAS_HOME/profileTemplates/management" -serverType DEPLOYMENT_MANAGER -nodeName "$DMGR_NODE" -cellName "$CELL_NAME" -hostName "$DMGR_HOST"
echo "Profil créé. Vérifier $PROFILE_PATH/logs/AboutThisProfile.txt ; configurer sécurité, SSL, ports et démarrer manuellement."
