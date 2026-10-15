# Scripts WebSphere ND 8.5.5

Les scripts sont **indépendants** : lancer chaque étape sur le bon hôte, après lecture de `GUIDE_COMPLET.md`. Ils ne téléchargent pas les médias IBM et n'installent pas de certificat sans contrôle humain.

```bash
chmod +x scripts/*.sh
# sur DMGR NEUF UNIQUEMENT, après installation ND :
WAS_HOME=/opt/IBM/WebSphere/AppServer_2 ./scripts/10_create_dmgr.sh
# sur un NOUVEAU nœud uniquement, après installation ND :
NODE_HOST=nodesa3 NODE_NAME=nodesa3Node01 ./scripts/20_create_custom.sh
./scripts/30_tls_client.sh
./scripts/40_federate.sh
NODE_NAME=nodesa3Node01 ./scripts/50_diagnostics.sh
```

Ne jamais exécuter `10_create_dmgr.sh` sur `vm-was-efi` actuel ni `20_create_custom.sh` sur `nodesa1`/`nodesa2` actuels. Le script DMGR ne configure volontairement pas un mot de passe admin en argument ; l'activation de la sécurité et la configuration SSL se font via les outils IBM après création.

`60_sync_offline.sh` interrompt temporairement l'administration du nœud : utiliser uniquement si nécessaire et après autorisation. Il n'arrête pas le DMGR.
