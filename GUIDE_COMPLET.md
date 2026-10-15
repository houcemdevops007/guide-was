# IBM WebSphere Network Deployment 8.5.5 — Installation complète DMGR + nœud géré

**Environnement de formation — 15 octobre 2026**  
**Topologie** : DMGR `vm-was-efi` (`172.16.3.20`) ; nœud géré `nodesa1` (`172.16.3.21`).  
**Cellule cible** : `vm-was-efiCell02` ; **DMGR** : `vm-was-efiCellManager02` ; **nœud** : `nodesa1Node01`.  
**Répertoire produit** : `/opt/IBM/WebSphere/AppServer_2` ; **profil DMGR** : `Dmgr01` ; **profil géré** : `Custom01` ; **SOAP DMGR observé** : `8880` ; **console HTTPS observée** : `9044` ; **SOAP Node Agent observé** : `8878`.

> Ce document fournit une **procédure de nouvelle installation** et un **diagnostic adapté à la cellule existante**. Les noms de cellule et les ports sont des valeurs propres à votre environnement ; une création neuve peut générer des noms/ports différents. Ne recréez jamais `Dmgr01` ou `Custom01` sur vos machines déjà fédérées. N'exécutez jamais les scripts d'installation sur le cluster en service sans validation préalable.

## 1. Architecture et prérequis

```
                    IBM WebSphere ND 8.5.5
           +----------------------------------+
           | vm-was-efi / 172.16.3.20         |
           | Profil Dmgr01                    |
           | Deployment Manager              |
           | SOAP 8880 / console HTTPS 9044  |
           +---------------+------------------+
                           | Fédération SOAP / SSL
           +---------------+------------------+
           | nodesa1 / 172.16.3.21            |
           | Profil Custom01                  |
           | Node Agent SOAP 8878             |
           | Serveur applicatif « test »       |
           +----------------------------------+
```

- Installer une version **Network Deployment** identique et des niveaux de correctifs compatibles sur les deux hôtes, avec IBM Installation Manager et les médias IBM sous licence. L'installateur et les identifiants de dépôt IBM ne sont pas inclus dans ce pack.
- Vérifier les ressources RAM/disque, la version Linux officiellement prise en charge et la compatibilité du SDK Java selon la matrice de support IBM. WAS 8.5.5.0 est ancien : appliquer les fix packs et correctifs de sécurité compatibles avant une exposition réseau.
- DNS direct et inverse cohérents entre les machines ; ports accessibles selon les besoins réels (SOAP 8880, HTTPS 9044 depuis l'administration, Node Agent SOAP 8878, ports ORB/DCS/IPC/transport WebSphere selon `serverindex.xml`). Éviter de supposer que seuls trois ports suffisent.
- Utiliser des comptes système dédiés en production, pas root ; ce guide emploie des commandes de diagnostic compatibles avec vos sessions root.

### 1.1 Préparer les noms d'hôtes

Sur le DMGR :
```bash
hostnamectl set-hostname vm-was-efi
```
Sur le nœud :
```bash
hostnamectl set-hostname nodesa1
```
Sur **les deux hôtes**, renseigner le DNS ou `/etc/hosts` :
```text
172.16.3.20 vm-was-efi
172.16.3.21 nodesa1
```
Contrôles :
```bash
hostname -f
getent hosts vm-was-efi nodesa1
getent ahostsv4 vm-was-efi
ping -c 2 vm-was-efi
```
Tester depuis le nœud après création du DMGR :
```bash
nc -zv vm-was-efi 8880
openssl s_client -connect vm-was-efi:11008 -tls1_2 </dev/null
```
Le port 11008 est un point SSL **observé dans vos logs**, pas un port universel WebSphere.

## 2. Installer IBM Installation Manager et WebSphere ND

Télécharger depuis votre portail IBM les médias **IBM Installation Manager**, **IBM WebSphere Application Server Network Deployment 8.5.5** et les fix packs appropriés. Décompresser les dépôts dans des répertoires locaux (ex. `/srv/ibm-repos/im` et `/srv/ibm-repos/was`). Les emplacements dépendent des médias réellement fournis.

Exemple *à adapter* pour Installation Manager (commande disponible seulement si le média contient `installc`) :
```bash
cd /srv/ibm-repos/im
./installc -acceptLicense -installationDirectory /opt/IBM/InstallationManager -dataLocation /var/ibm/InstallationManager -showProgress
```

Examiner les offres disponibles **avant toute installation** :
```bash
/opt/IBM/InstallationManager/eclipse/tools/imcl listAvailablePackages -repositories /srv/ibm-repos/was
```

L'identifiant d'offre standard de WAS ND est `com.ibm.websphere.ND.v85` ; vérifier qu'il figure dans les résultats. Exemple d'installation sur **chaque hôte**, seulement après validation des médias et de l'ID :
```bash
/opt/IBM/InstallationManager/eclipse/tools/imcl install com.ibm.websphere.ND.v85 \
  -repositories /srv/ibm-repos/was \
  -installationDirectory /opt/IBM/WebSphere/AppServer_2 \
  -sharedResourcesDirectory /opt/IBM/IMShared \
  -acceptLicense -showProgress
```

**Ne pas lancer cette installation sur une arborescence existante sans examiner l'inventaire Installation Manager.** Vérifier :
```bash
/opt/IBM/WebSphere/AppServer_2/bin/versionInfo.sh
/opt/IBM/WebSphere/AppServer_2/bin/manageprofiles.sh -listProfiles
/opt/IBM/InstallationManager/eclipse/tools/imcl listInstalledPackages -long
```

## 3. Créer et configurer le Deployment Manager (machine vm-was-efi)

### 3.1 Création d'un profil DMGR — uniquement installation neuve

Lister les modèles :
```bash
WAS_HOME=/opt/IBM/WebSphere/AppServer_2
ls "$WAS_HOME/profileTemplates/management"
"$WAS_HOME/bin/manageprofiles.sh" -listProfiles
```

Exemple :
```bash
"$WAS_HOME/bin/manageprofiles.sh" -create \
  -profileName Dmgr01 \
  -profilePath "$WAS_HOME/profiles/Dmgr01" \
  -templatePath "$WAS_HOME/profileTemplates/management" \
  -serverType DEPLOYMENT_MANAGER \
  -nodeName vm-was-efiCellManager02 \
  -cellName vm-was-efiCell02 \
  -hostName vm-was-efi \
  -enableAdminSecurity true \
  -adminUserName dmgr \
  -adminPassword 'REMPLACER_PAR_SECRET_FORT'
```

**Sécurité** : la ligne ci-dessus illustre les options de création, mais le mot de passe sur la ligne de commande peut apparaître dans l'historique et la liste des processus. En environnement réel, utiliser un fichier réponse protégé ou une méthode de provisioning de secrets ; ne pas copier littéralement le mot de passe d'exemple. Vérifier la syntaxe prise en charge par votre fix pack avec `manageprofiles.sh -help` avant exécution.

Vérifier la création :
```bash
cat "$WAS_HOME/profiles/Dmgr01/logs/AboutThisProfile.txt"
"$WAS_HOME/bin/manageprofiles.sh" -listProfiles
```

### 3.2 Démarrer le DMGR et identifier ses ports

```bash
cd /opt/IBM/WebSphere/AppServer_2/profiles/Dmgr01/bin
./startManager.sh
./serverStatus.sh dmgr -username dmgr
```

Contrôler les ports réellement attribués :
```bash
grep -n -A 4 -B 2 'SOAP_CONNECTOR_ADDRESS\|WC_adminhost_secure' \
 /opt/IBM/WebSphere/AppServer_2/profiles/Dmgr01/config/cells/vm-was-efiCell02/nodes/vm-was-efiCellManager02/serverindex.xml
ss -lntp | grep java
```

Dans **votre** environnement : console `https://172.16.3.20:9044/ibm/console`, SOAP `8880`. Une installation neuve peut utiliser d'autres ports ; les déterminer via `serverindex.xml`.

### 3.3 Administrer la sécurité SSL du DMGR

Console → **Sécurité → Certificat SSL et gestion des clés** → configurations SSL → `CellDefaultSSLSettings` → qualité de protection (QoP) → protocole `TLSv1.2`. Sauvegarder. Ne pas éditer `security.xml` directement.

Dans votre environnement, le certificat serveur personnalisé est nommé `websphere-ssl-2026`, présenté sur `vm-was-efi:11008`, avec sujet `CN=vm-was-efi, OU=FR, O=EFI`. Son empreinte SHA-256 observée était :
```text
1B:D2:D3:DA:FD:82:4A:70:CF:2D:1C:35:AA:9D:C5:DA:79:65:6E:E6:B5:C1:AB:D1:7E:D8:DD:08:4E:A0:33:C1
```
Ne pas présumer que cette empreinte restera identique après renouvellement. Toujours la vérifier depuis une source administrative de confiance.

## 4. Créer le profil Custom sur nodesa1

**Uniquement sur un nœud neuf, non fédéré** :
```bash
WAS_HOME=/opt/IBM/WebSphere/AppServer_2
"$WAS_HOME/bin/manageprofiles.sh" -listProfiles
"$WAS_HOME/bin/manageprofiles.sh" -create \
  -profileName Custom01 \
  -profilePath "$WAS_HOME/profiles/Custom01" \
  -templatePath "$WAS_HOME/profileTemplates/managed" \
  -nodeName nodesa1Node01 \
  -cellName nodesa1Cell01 \
  -hostName nodesa1 \
  -federateLater true
```

Vérifier les options réellement disponibles dans votre version de `manageprofiles.sh`. Ne pas recréer `Custom01` sur `nodesa1` actuel.

### 4.1 Client SOAP TLS 1.2

```bash
PROFILE=/opt/IBM/WebSphere/AppServer_2/profiles/Custom01
cp -p "$PROFILE/properties/ssl.client.props" "$PROFILE/properties/ssl.client.props.bak.$(date +%Y%m%d%H%M%S)"
sed -i 's/^com\.ibm\.ssl\.protocol=SSL_TLS$/com.ibm.ssl.protocol=TLSv1.2/' "$PROFILE/properties/ssl.client.props"
grep '^com.ibm.ssl.protocol=' "$PROFILE/properties/ssl.client.props"
```

Le client SOAP et le Node Agent utilisent aussi des configurations SSL de cellule/nœud ; ce seul réglage ne suffit pas toujours.

## 5. Fédérer le nœud

Sur le nœud :
```bash
cd /opt/IBM/WebSphere/AppServer_2/profiles/Custom01/bin
./addNode.sh vm-was-efi 8880 -username dmgr
```

Saisir le mot de passe à l'invite, vérifier tout certificat proposé avant acceptation. Succès observé : `ADMU0003I: Le noeud ... a été fédéré avec succès.` L'option `-includeapps` n'a pas été utilisée dans vos opérations ; les applications autonomes ne sont donc pas migrées automatiquement.

Vérifier le Node Agent :
```bash
./serverStatus.sh nodeagent -username dmgr
ps -ef | grep '[n]odeagent'
ss -lntp | grep ':8878'
```

`ADMU3028I` sur 8878 peut simplement signifier que le Node Agent est déjà en cours d'exécution ; **ne pas tuer le processus** sans diagnostic.

## 6. Configurer NodeDefaultSSLSettings dans le référentiel maître

Dans la console DMGR : **Sécurité → Certificat SSL et gestion des clés → Gérer les configurations de sécurité des nœuds finals**. Sélectionner la portée **du nœud concerné** `(cell):vm-was-efiCell02:(node):nodesa1Node01`, puis `NodeDefaultSSLSettings` → QoP → `TLSv1.2` → Sauvegarder.

Sur votre deuxième nœud, les investigations ont montré deux configurations de même alias mais de **portées distinctes** : `nodesa1Node01` était `TLSv1.2`, `nodesa2Node01` était initialement `SSL_TLS`. Ne pas modifier la configuration d'un autre nœud.

Depuis `wsadmin` connecté au DMGR :
```python
print AdminTask.listSSLConfigs('[-all true]')
```

Inspecter les portées et protocoles dans le référentiel maître, sans modifier les XML à la main :
```bash
grep -n -B 2 -A 4 'alias="NodeDefaultSSLSettings"' \
 /opt/IBM/WebSphere/AppServer_2/profiles/Dmgr01/config/cells/vm-was-efiCell02/security.xml
```

## 7. Gérer la confiance des certificats

Sur le nœud, examiner le certificat présenté :
```bash
openssl s_client -connect vm-was-efi:11008 -tls1_2 -showcerts </dev/null 2>/dev/null \
 | openssl x509 -noout -subject -issuer -fingerprint -sha256
```

Examiner le magasin local :
```bash
PROFILE=/opt/IBM/WebSphere/AppServer_2/profiles/Custom01
/opt/IBM/WebSphere/AppServer_2/java/bin/keytool -list -v \
 -keystore "$PROFILE/config/cells/vm-was-efiCell02/trust.p12" -storetype PKCS12
```

Sur votre premier nœud, ce magasin ne contenait initialement que le signataire `root` IBM ; le certificat personnalisé `CN=vm-was-efi, OU=FR, O=EFI` n'y figurait pas. Les journaux signalaient `CWPKI0022E` et `PKIX path building failed`.

**Procédure gérée, côté DMGR :** placer le PEM vérifié sur le DMGR (`/tmp/vm-was-efi-11008.pem`), puis :
```python
AdminTask.addSignerCertificate('[-keyStoreName CellDefaultTrustStore -keyStoreScope (cell):vm-was-efiCell02 -certificateFilePath /tmp/vm-was-efi-11008.pem -certificateAlias vm-was-efi-11008 -base64Encoded true]')
AdminConfig.save()
print AdminTask.listSignerCertificates('[-keyStoreName CellDefaultTrustStore -keyStoreScope (cell):vm-was-efiCell02]')
```

**Important** : cette commande agit sur le magasin géré par le DMGR ; si la synchronisation est rompue, elle ne met pas instantanément à jour le magasin local du nœud. Après correction du référentiel maître, effectuer une synchronisation hors ligne si nécessaire. Ne pas changer le mot de passe du magasin avec `keytool`. Le mot de passe historique `WebAS` fait 5 caractères et peut être refusé pour une opération d'écriture par `keytool` ; utiliser les outils administratifs IBM pour les modifications.

## 8. Synchroniser le nœud

**Méthode en ligne** : console DMGR → Administration du système → Nœuds → sélectionner le nœud → Synchroniser / Resynchronisation complète. Vérifier la fin effective, pas seulement « lancement de la synchronisation réussi ».

**Méthode hors ligne**, si l'agent n'arrive plus à joindre le DMGR :
```bash
cd /opt/IBM/WebSphere/AppServer_2/profiles/Custom01/bin
./stopNode.sh -username dmgr
ps -ef | grep '[n]odeagent'   # doit être vide
./syncNode.sh vm-was-efi 8880 -username dmgr
# seulement si syncNode.sh a réussi :
./startNode.sh
```

Un arrêt de Node Agent interrompt l'administration distante de ce nœud ; les serveurs d'applications existants ne sont pas nécessairement arrêtés. Ne pas arrêter le DMGR. Si `syncNode.sh` échoue, ne pas poursuivre automatiquement.

Vérifier la découverte du Node Agent depuis `wsadmin` DMGR :
```python
print AdminControl.queryNames('type=NodeAgent,node=nodesa1Node01,*')
```

## 9. Créer et démarrer un serveur d'applications

Console DMGR → **Serveurs → Types de serveurs → Serveurs d'applications WebSphere → Nouveau** → nœud `nodesa1Node01` → nom `test` → modèle `default` → terminer → sauvegarder → synchroniser.

Sur le nœud :
```bash
PROFILE=/opt/IBM/WebSphere/AppServer_2/profiles/Custom01
ls -l "$PROFILE/config/cells/vm-was-efiCell02/nodes/nodesa1Node01/servers/test/server.xml"
cd "$PROFILE/bin"
./startServer.sh test
./serverStatus.sh test -username dmgr
```

En cas d'échec :
```bash
tail -n 100 "$PROFILE/logs/test/startServer.log"
tail -n 100 "$PROFILE/logs/test/SystemOut.log"
tail -n 100 "$PROFILE/logs/test/SystemErr.log"
ss -lntp | grep java
```

**Historique de vos tests** : `nodesa1/test` a initialement échoué parce que `servers/test/server.xml` était absent localement alors que présent sur le DMGR. Sur `nodesa2/test2`, le fichier `server.xml` existait localement ; l'échec de démarrage avait donc une autre cause encore non établie dans les résultats transmis.

## 10. Diagnostic rapide — erreurs réellement rencontrées

| Code | Constat | Vérification / action |
|---|---|---|
| `ADMU0003I` | Fédération réussie | Contrôler le Node Agent et la synchronisation |
| `ADMU3028I`, `ADMU3027E` | Port SOAP 8878 occupé | `ss -lntp`, `ps -ef`, ne pas tuer le processus sans preuve |
| `JSSL0080E` | Échec de négociation SSL | Contrôler QoP TLS, suites cryptographiques, certificat et journaux |
| `CWPKI0022E` | Signataire non approuvé | Vérifier empreinte et magasin `CellDefaultTrustStore` |
| `ADMS0012E`, `ADMS0005E` | Agent ne découvre pas le DMGR | Réseau, SSL, service administratif, synchronisation hors ligne |
| `ADMS0212I` | Synchronisation automatique désactivée | Corriger la cause, resynchroniser et contrôler le mode automatique |
| `FileNotFoundException .../server.xml` | Configuration serveur absente localement | Comparer DMGR / nœud, synchroniser |
| `WSVR0001I` | Processus prêt | Vérifier ensuite découverte par le DMGR |

## 11. Exploitation et sécurité

- Sauvegarder `config`, les magasins PKCS12 et les fichiers de propriétés avant toute modification ; protéger les copies, qui contiennent des secrets.
- Restreindre l'accès à la console d'administration, aux ports SOAP et aux fichiers de configuration.
- Ne pas confondre « processus Java présent », « Node Agent démarré », « Node Agent découvert par le DMGR » et « synchronisation complète ».
- Pour un nouveau nœud, utiliser les scripts du pack dans cet ordre : `00_preflight.sh`, `10_create_dmgr.sh` **sur une machine DMGR neuve uniquement**, `20_create_custom.sh` **sur le nœud neuf uniquement**, `30_tls_client.sh`, `40_federate.sh`, `50_diagnostics.sh`, puis `60_sync_offline.sh` uniquement en cas de besoin et après confirmation.
- Les scripts ne redémarrent pas automatiquement le DMGR et n'importent pas de certificats sans contrôle humain.

## 12. Références à consulter

- Documentation IBM WebSphere Application Server Network Deployment 8.5.5 : `https://www.ibm.com/docs/en/was-nd/8.5.5`
- Aide embarquée : `manageprofiles.sh -help`, `addNode.sh -help`, `syncNode.sh -help`, `wsadmin> print AdminTask.help('addSignerCertificate')`.

**Limite de validation** : ces scripts sont préparés pour votre topologie mais ne sont pas exécutés contre vos serveurs ; valider la syntaxe des commandes de création avec le fix pack et les médias réellement installés avant usage.
