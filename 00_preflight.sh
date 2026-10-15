#!/usr/bin/env bash
set -euo pipefail
WAS_HOME=${WAS_HOME:-/opt/IBM/WebSphere/AppServer_2}
DMGR_HOST=${DMGR_HOST:-vm-was-efi}
DMGR_PORT=${DMGR_PORT:-8880}
echo "=== Hôte ==="; hostname -f; id; uname -a
echo "=== Résolution ==="; getent hosts "$DMGR_HOST" || true
echo "=== Installation ==="; if [[ -x "$WAS_HOME/bin/versionInfo.sh" ]]; then "$WAS_HOME/bin/versionInfo.sh"; "$WAS_HOME/bin/manageprofiles.sh" -listProfiles; else echo 'WAS ND non installé ici'; fi
echo "=== Connectivité DMGR (si démarré) ==="; if command -v nc >/dev/null; then nc -zvw3 "$DMGR_HOST" "$DMGR_PORT" || true; fi
echo 'Précontrôle terminé. Aucune modification effectuée.'
