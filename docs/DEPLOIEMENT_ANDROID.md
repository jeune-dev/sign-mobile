# 🚀 Déploiement Android automatique (Google Play) — Sign

> **En une phrase :** vous écrivez les nouveautés, vous poussez sur `release`,
> la chaîne vérifie tout, vous approuvez d'un clic, et l'app arrive chez vos
> testeurs — sans ouvrir Play Console.

Même chaîne que l'application Widjila, adaptée à Sign (pas de fichiers de
traduction, signature par `android/key.properties`, obfuscation Dart,
`google-services.json` versionné dans le dépôt).

## ⚡ Publier une nouvelle version

1. Écrire les nouveautés dans **`fastlane/notes/fr-FR.txt`** (500 caractères
   maximum). Elles doivent **changer** à chaque déploiement.
2. *Seulement pour une nouvelle version visible :* modifier `version:` dans
   `pubspec.yaml` (ex. `1.0.3` → `1.0.4`). Le numéro après le `+` est ignoré :
   le numéro de build est calculé à partir de Google Play.
3. Committer sur `main`, puis publier :

   ```bash
   git push origin main
   git push origin main:release
   ```

4. Attendre l'e-mail de GitHub (≈ 20 min), relire le résumé, puis
   **Review deployments › google-play › Approve and deploy**.
5. Google vérifie la version (quelques heures), puis les testeurs la reçoivent.

Un push sur `main` seul ne publie **rien**.

### 🧪 Essai à blanc

Onglet **Actions** › « Android — Google Play » › **Run workflow** (case cochée) :
tout est vérifié, Google Play valide l'envoi, mais rien n'est publié et aucun
numéro de build n'est consommé.

## 🛤️ Les 7 étapes

```
 1 · Contrôles d'entrée
        ├── 2a · Analyse du code ───┐
        ├── 2b · Tests & couverture ┤   (en parallèle)
        └── 2c · Sécurité ──────────┘
 3 · Compilation & contrôle de l'AAB
 4 · Test de démarrage sur émulateur Android
 5 · ✋ VOTRE APPROBATION
 6 · Publication Google Play + vérification + trace
 7 · Bilan
```

| Étape | Ce qui est vérifié | Si ça échoue |
|---|---|---|
| **1 · Contrôles d'entrée** | le commit est sur `main` · notes présentes, ≤ 500 caractères, **nouvelles** · version lisible | ❌ bloque |
| **2a · Analyse** | `flutter analyze` : aucune erreur ni avertissement (les remarques de style sont affichées, pas bloquantes) | ❌ bloque |
| **2b · Tests** | tous les tests passent · couverture mesurée | ❌ bloque |
| **2c · Secrets** | aucun mot de passe ni clé oublié dans le code (Gitleaks) | ❌ bloque |
| **2c · Dépendances** | failles connues des bibliothèques (OSV-Scanner) | ⚠️ signale |
| **3 · Numéro de build** | lu sur Google Play · version visible pas plus ancienne que celle en ligne | ❌ bloque |
| **3 · Signature** | empreinte SHA-256 **identique** à la clé d'importation | ❌ bloque |
| **3 · Identité** | package `com.signapp.sign_application`, numéro de build, version | ❌ bloque |
| **3 · Android ciblé** | targetSdk ≥ minimum exigé par Google Play | ❌ bloque |
| **3 · Permissions** | nouvelle permission par rapport à la référence | ⚠️ signale |
| **3 · Taille** | hausse de plus de 20 % | ⚠️ signale |
| **3 · Configuration** | adresse de l'API et Firebase présents dans l'AAB | ⚠️ signale |
| **4 · Émulateur** | l'app de release s'installe et démarre sans planter (capture d'écran) | ❌ bloque |
| **5 · Approbation** | vous relisez le résumé et approuvez | ✋ vous décidez |
| **6 · Publication** | intégrité des fichiers · numéro toujours libre · envoi (3 essais) · **présence vérifiée** sur Google Play | ❌ bloque |
| **6 · Trace** | tag `android-v1.0.3-build16` + Release GitHub (AAB, mapping, **symboles Dart**) | — |

### 📦 Ce qui est conservé

| Artefact | Contenu | Durée |
|---|---|---|
| `aab` | AAB envoyé, mapping, **symboles Dart** (`*-symbols.tar.gz`), manifeste, permissions, empreintes | 90 jours |
| `test-demarrage` | capture d'écran + journal Android | 30 jours |
| `couverture` | `lcov.info` | 30 jours |
| Release GitHub | la même chose, pour chaque vraie publication | permanent |

> **Les symboles Dart sont indispensables** : l'app est compilée avec
> `--obfuscate`. Sans eux, une pile d'appels Crashlytics est illisible
> (`flutter symbolize`).

## 🔧 Configuration initiale (une seule fois)

### 1️⃣ Play Console — autoriser le compte de service

Le compte de service de Widjila est réutilisé (même compte développeur) :
`fastlane-deploy@widjila-deploy.iam.gserviceaccount.com`.

1. **play.google.com/console** › page d'accueil du **compte** › **Utilisateurs
   et autorisations**.
2. Cliquer sur le compte de service (déjà présent) › **Autorisations de
   l'application** › **Ajouter une application** › cocher **Sign** › Appliquer.
3. Cocher pour cette app, comme pour Widjila :
   - Afficher les informations sur l'application (lecture seule) ;
   - Mettre les applications à disposition de tous les utilisateurs… ;
   - Déployer les applications sur des canaux de test ;
   - Gérer les canaux de test et modifier les listes de testeurs.
4. **Appliquer** › **Enregistrer**. L'activation peut prendre jusqu'à 24 à 36 h.

### 2️⃣ Secrets GitHub (dépôt `jeune-dev/sign-mobile`)

**Settings** › **Secrets and variables** › **Actions** › onglet **Secrets** :

| Nom | Contenu |
|---|---|
| `PLAY_SERVICE_ACCOUNT_JSON` | la clé JSON du compte de service (la même que pour Widjila) |
| `ANDROID_KEYSTORE_PROPERTIES` | le contenu de `android/key.properties` |
| `ANDROID_KEYSTORE_BASE64` | `android/app/sign-release.jks`, converti en texte |

Conversion, dans **Git Bash**, à la racine du projet :

```bash
base64 -w0 android/app/sign-release.jks > keystore.b64.txt
```

Coller le contenu du fichier dans le secret, puis **supprimer** `keystore.b64.txt`.

`android/app/google-services.json` est versionné dans ce dépôt : aucun secret
n'est nécessaire pour Firebase.

### 3️⃣ Variable GitHub de l'empreinte

Onglet **Variables** › **New repository variable** :

- **Name :** `ANDROID_UPLOAD_CERT_SHA256`
- **Value :** l'empreinte **SHA-256** du « Certificat de la clé d'importation »
  (Play Console › Sign › Tester et publier › **Intégrité de l'application**).

L'empreinte du keystore local `android/app/sign-release.jks` (alias `sign_key`)
est :

```
4C:BE:67:6A:7F:C3:D4:DF:FE:8C:F5:7E:3B:6A:BF:22:D3:E4:39:77:E3:DE:10:72:79:40:E7:EC:74:04:98:AE
```

⚠️ **Vérifier qu'elle correspond à celle affichée par Play Console.** Si elles
diffèrent, ce n'est pas le bon keystore : ne rien publier avant d'avoir tiré ça
au clair. (`android/upload-keystore.jks`, à la racine de `android/`, n'est
**pas** utilisé — mot de passe différent, vestige d'une ancienne configuration.)

### 4️⃣ Environnement d'approbation `google-play`

**Settings** › **Environments** › **New environment** › nom **`google-play`** :

- ✅ **Required reviewers** : votre compte.
- ⬜ Prevent self-review · ⬜ Wait timer · ⬜ Custom rules.
- ⬜ **Allow administrators to bypass configured protection rules** (à décocher).
- **Save protection rules**, puis **Deployment branches and tags** › *Selected
  branches and tags* › ajouter **`release`** et **`main`**.

> Sans cet environnement, GitHub le crée tout seul **sans approbation** : la
> publication partirait sans votre clic.

### 5️⃣ Protéger la branche `release`

**Settings** › **Rules** › **Rulesets** › **New branch ruleset** : nom
`release protégée`, *Active*, cible `release`, cocher **Restrict deletions** et
**Block force pushes** (surtout pas « Require a pull request »).

## 🛠️ Dépannage

| Message | Cause | Solution |
|---|---|---|
| `Seul du code présent sur main peut être publié` | `release` poussé depuis une autre branche | `git push origin main` puis `git push origin main:release` |
| `Les notes n'ont pas changé depuis …` | notes identiques au déploiement précédent | écrire les nouveautés |
| `L'analyse a trouvé des erreurs ou des avertissements` | problème dans le code | `flutter analyze` en local |
| `Un possible secret a été trouvé` | secret committé ou faux positif | vrai secret : le retirer **et le changer** ; faux positif : exception justifiée dans `.gitleaks.toml` |
| `Secret / Variable GitHub manquant(e)` | configuration incomplète | parties 2 et 3 |
| `The caller does not have permission` | droits Play Console pas encore actifs | attendre 24 à 36 h après l'ajout de l'app |
| Signature : `empreinte ≠ attendue` | mauvais keystore ou mauvaise variable | vérifier `ANDROID_KEYSTORE_BASE64` et `ANDROID_UPLOAD_CERT_SHA256` |
| `Keystore was tampered with, or password was incorrect` | mot de passe erroné | corriger `ANDROID_KEYSTORE_PROPERTIES` |
| `pubspec.yaml annonce … plus ancienne que …` | version visible inférieure à celle en ligne | augmenter `version:` |
| `Le build N n'est plus libre` | envoi manuel pendant l'approbation | relancer le déploiement |
| Émulateur : « l'app s'est arrêtée » | plantage au démarrage en release | artefact `test-demarrage` (`logcat.txt`, capture) |

## ↩️ Revenir à une version précédente

Google Play n'accepte que des numéros croissants : on annule le changement
fautif sur `main`, puis on publie normalement.

```bash
git revert <commit-fautif>
git push origin main
git push origin main:release
```

## 🗂️ Fichiers

| Fichier | Rôle |
|---|---|
| `.github/workflows/android-release.yml` | la chaîne (7 étapes) |
| `android/fastlane/Fastfile` | numéro de build, compilation obfusquée, envoi, vérification |
| `android/fastlane/Appfile` | package et clé du compte de service |
| `fastlane/notes/fr-FR.txt` | **vos notes de version** |
| `tool/ci/controle_aab.py` | contrôle de l'AAB |
| `tool/ci/android_reference.json` | valeurs de référence (package, targetSdk, permissions, API) |
| `tool/ci/test_demarrage.sh` | test de démarrage sur émulateur |
| `.gitleaks.toml` | règles de la recherche de secrets |
| `.github/dependabot.yml` | mises à jour de sécurité des outils de la chaîne |
