# Assistant juridique local pour cabinet d’avocats

Agent en français utilisant Ollama localement pour analyser les dossiers, rechercher dans un corpus de droit français et rédiger les directives communes du cabinet. Aucune télémétrie ni transmission automatique vers Internet. Les documents ne sont jamais envoyés à un moteur de recherche.

## Installation et utilisation

Prérequis : Windows PowerShell 5.1 ou PowerShell 7 et Ollama. Préparer les modèles avant d’ajouter des données confidentielles. Le modèle par défaut `qwen2.5:14b` doit être installé séparément ; choisir un autre modèle local avec `-Model` selon le matériel et les résultats d’évaluation.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\agent.ps1 init
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\agent.ps1 status
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests.ps1
```

`Bypass` s’applique uniquement au processus lancé, sans modifier la stratégie système. Respecter la politique informatique du cabinet.

Créer `vault/cases/client-001/` et y placer les pièces en TXT ou Markdown UTF-8. Convertir les PDF, scans et documents Word avec un outil local au préalable. Les autres formats sont refusés, ainsi que les fichiers de plus de 2 Mo ou un contexte de plus de 32 000 caractères. Les sous-dossiers ne sont pas parcourus.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\agent.ps1 analyze -CaseId client-001 -Question 'Analyser la preuve du contrat et les moyens de defense' -AsOf 2026-10-21
```

Pour une description sans pièce, créer un dossier vide et fournir les faits dans `-Question`. Les arguments peuvent apparaître dans l’historique du terminal : préférer un fichier local pour les descriptions confidentielles.

Les rapports dans `vault/reports/` distinguent faits, allégations, hypothèses, moyens offensifs et défensifs licites, contre-arguments, preuves manquantes et actions proposées. Ils enregistrent le modèle, les empreintes des pièces, la date du droit et les sources. Une validation par un avocat reste nécessaire.

## Sources et veille juridique

Importer les textes officiels dans `vault/law/*.json` selon `examples/law.template.json`. Le modèle de fichier ne contient aucune règle de droit réelle. Sources autorisées : Légifrance, Cour de cassation, Conseil d’État, Conseil constitutionnel et sites européens indiqués dans le code.

Chaque source comporte un identifiant unique, un titre, une URL officielle HTTPS, une date de consultation, un début et une fin de validité (`null` si inconnue), et le texte. Dates : `AAAA-MM-JJ`. La fin de validité est inclusive. L’URL ne certifie pas le contenu importé ; un avocat doit vérifier son authenticité et son actualité.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\agent.ps1 sources
```

La recherche classe les sources par mots-clés français, filtre les périodes selon `-AsOf` et conserve au plus six résultats. Ce n’est pas une base exhaustive ou une recherche sémantique. Les citations `[LOI:id]` inexistantes sont rejetées ; cela ne valide pas leur interprétation ni les autres affirmations du modèle.

Le processus confidentiel n’effectue aucune recherche Internet. Actualisation : veille officielle dans un environnement distinct → vérification des versions → import des seuls textes publics → nouveau projet de directives → validation. Ne jamais communiquer de noms, faits clients ou requêtes dérivées des pièces à un service externe.

## Directives : rédaction, publication et mise à jour

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\agent.ps1 draft -Question 'Mettre a jour les directives sur la preuve des contrats'
```

Le projet dans `vault/drafts/<id>.json` utilise les sources publiques et les directives existantes, sans charger de dossier client. Après relecture du texte exact, fournir son SHA256 et le nom de l’avocat relecteur :

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\agent.ps1 publish -DraftId <id> -Reviewer 'Me Dupont' -ExpectedHash <empreinteSHA256>
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\agent.ps1 guidelines
```

L’empreinte porte sur le texte UTF-8 sans BOM. En cas de modification manuelle du texte, recalculer également `content_hash` avant validation. Les sauts de ligne influent sur le calcul.

La publication conserve la version historique et actualise `vault/published/current.json`, utilisé lors des analyses suivantes. Une modification des directives depuis la rédaction rend le projet obsolète et bloque sa publication. La publication est strictement locale, sans courriel ni site externe.

Le nom du relecteur est déclaratif, sans authentification ni signature électronique. Un seul opérateur à la fois ; pas de publication concurrente. Les archives ne constituent pas un journal d’audit inviolable.

## Confidentialité et isolation

L’application refuse les chemins hors du projet, les liens symboliques, les jonctions Windows et les identifiants invalides. Chaque analyse charge seulement le dossier choisi, les sources publiques et les directives. Le modèle n’a aucun outil d’exécution ou de lecture de fichiers.

**Ces contrôles ne constituent pas un bac à sable du système d’exploitation.** En mode natif, PowerShell possède les droits de l’utilisateur. Les contrôles ne protègent pas contre un administrateur, un processus malveillant sur l’hôte, des liens physiques, une modification simultanée des fichiers ou un Ollama compromis. Interdire les liens physiques et les modifications pendant une analyse.

### Conteneurs sans accès réseau externe

`compose.yaml` propose un déploiement Linux isolé : Ollama utilise `network_mode: none` ; l’agent partage cet espace réseau avec seulement la boucle locale et contacte `127.0.0.1:11434`. Aucun port hôte ou socket Docker n’est exposé. L’agent ne monte que le script et le coffre ; Ollama monte uniquement les modèles. Racines en lecture seule, capacités supprimées et élévation interdite.

1. Préparer Docker Desktop Linux et télécharger des images approuvées avant toute donnée confidentielle.
2. Définir dans `.env` les variables `OLLAMA_IMAGE` et `POWERSHELL_IMAGE` avec des références approuvées `image@sha256:...`. Aucun digest non vérifié n’est fourni.
3. Copier les modèles préchargés, avec `blobs/` et `manifests/`, dans `runtime/models/`.
4. Lancer `docker compose up -d ollama`, puis `docker compose run --rm agent init`.
5. Tester sur des données fictives avec `docker compose run --rm agent analyze -CaseId client-001 -Question 'Analyser les moyens de defense'`.
6. Vérifier le blocage des connexions externes avant exploitation. Arrêter avec `docker compose down`.

Ce déploiement reste à valider sur une machine équipée de Docker. Le coffre entier est visible par le conteneur de l’agent : l’isolation concerne le projet, pas les droits système entre dossiers. Pour des équipes ou intérêts distincts, utiliser des instances et coffres séparés avec contrôle d’accès organisationnel.

### Stockage

`vault/` et `runtime/` sont exclus de Git. Utiliser un répertoire sans synchronisation OneDrive/Dropbox, des droits NTFS restreints, un disque et des sauvegardes chiffrés. Examiner la journalisation d’Ollama. Les rapports sont en clair sur disque ; aucun chiffrement applicatif ou effacement sécurisé n’est intégré.

En mode natif, définir `OLLAMA_NO_CLOUD=1` et bloquer les connexions sortantes d’Ollama avec le pare-feu. Une URL locale seule ne garantit pas que le serveur n’utilise pas un service distant. L’espace réseau sans interface externe fournit une restriction plus forte.

## Validation

Les tests vérifient les chemins interdits, identifiants, domaines officiels, périodes de validité, résultats sans correspondance, SHA256 et noms de modèles cloud. Ils n’utilisent pas Ollama. La qualité des réponses, le conteneur et l’approbation organisationnelle doivent être réceptionnés avant l’utilisation de vrais dossiers.

Références : [API officielle Ollama](https://github.com/ollama/ollama/blob/main/docs/api.md), [Légifrance](https://www.legifrance.gouv.fr/).
