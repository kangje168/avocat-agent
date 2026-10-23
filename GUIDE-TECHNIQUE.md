# Assistant juridique local pour cabinet d’avocats

Agent en français utilisant Ollama localement pour analyser les dossiers, rechercher dans un corpus de droit français et rédiger les directives communes du cabinet. Aucune télémétrie ni transmission automatique vers Internet. Les documents ne sont jamais envoyés à un moteur de recherche.

Version d’usage : `analyze` produit une première lecture immédiatement ; `deepen` combine une qualification factuelle par Ollama et un cadre conditionnel dans `strategie.ps1`. Pour les services, les moyens portent sur accord, exécution et prix. Chaque moyen relie des extraits exacts, une fiche documentaire, les conditions de son application, une objection, une réplique, une action et un élément susceptible de changer son évaluation. Les deux modes fonctionnent sans sources personnelles relues. `corpus-reference.json` contient six fiches de recherche publiques, distinctes des textes légaux intégraux et des sources relues par le cabinet. `legal` conserve le mode juridique avancé avec contrôles stricts.

## Installation et utilisation

Le cadre des moyens est limité aux prestations de services reconnues par le classement actuel. `scope_status` vaut `service`, `mixed_demo` ou `outside_service_scope`. Dans les deux derniers cas, aucun modèle de prestations n’est appelé : une préparation et un inventaire remplacent les moyens, sans fiches contractuelles imposées. La détection par mots-clés reste limitée, notamment pour les autres langues et les formulations ambiguës ; elle ne constitue pas une qualification juridique.

Une proposition du modèle sans indice propre à son axe reste indéterminée. Les seuls passages corroborant cet axe sont affichés comme appuis ; `model_constat`, `model_piece_ids` et `model_pieces` conservent la proposition initiale pour contrôle. Les anciennes versions du cadre sont signalées dans l’affichage des rapports historiques.

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

Les rapports dans `vault/reports/` contiennent un inventaire non authentifié et, pour `deepen`, les moyens ayant passé les contrôles de provenance. Un moyen invalide est écarté séparément ; une couverture incomplète est affichée. Si aucun moyen ne passe, la première lecture est conservée avec le motif. Les sorties rejetées restent dans `vault/rejected/`, sans affichage normal. Le mode avancé `legal` bloque avant tout appel si les thèmes obligatoires ne sont pas couverts par des sources relues. Voir [les contrôles de qualité](CONTROLES-QUALITE.md).

`deepen` transmet au modèle le dossier choisi et les fiches, sans tronquer les pièces (limite de 24 000 caractères de pièces), avec un contexte de 8 192, 16 384 ou 32 768 jetons selon une borne conservatrice en octets UTF-8, et une limite de génération de 900 jetons. Au-delà du budget, la première lecture est conservée sans tronquer les pièces. Une sortie tronquée n’est pas acceptée. Les rapports enregistrent les ancrages, l’empreinte des références et les métriques renvoyées par Ollama. Le schéma ne permet aucune prose juridique libre : seulement trois axes, cinq états factuels et des identifiants de passages. Le programme reprend les citations et assemble les applications, objections et actions du cadre. La justesse de la qualification factuelle reste à vérifier. Les indices textuels explicites peuvent corriger la proposition du modèle ; `model_constat` et `controle` conservent cette distinction. Une intention argumentative ne devient pas une preuve de non-exécution. Les repères lexicaux ne sont pas un analyseur sémantique exhaustif. Le modèle sélectionne des identifiants de passages ; le programme remplit les citations originales, sans demander au modèle de les recopier. Les règles documentaires et les branches conditionnelles ne sont pas produites par le modèle. Le modèle reçoit les rôles explicitement déclarés dans les textes ; un rôle absent ou contradictoire reste à confirmer.

## Sources et veille juridique

Importer les textes officiels dans `vault/law/*.json` selon `examples/law.template.json`. Le modèle de fichier ne contient aucune règle de droit réelle. Sources autorisées : Légifrance, Cour de cassation, Conseil d’État, Conseil constitutionnel et sites européens indiqués dans le code.

Chaque source comporte un identifiant unique, un titre, une URL officielle HTTPS, une date de consultation, un début et une fin de validité (`null` si inconnue), et le texte. Dates : `AAAA-MM-JJ`. La fin de validité est inclusive. L’URL ne certifie pas le contenu importé ; un avocat doit vérifier son authenticité et son actualité.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\agent.ps1 sources
```

Dans le mode avancé `legal` et les directives juridiques générées, les sources utilisables nécessitent aussi `code`, `article`, `topics`, `reviewed_by`, `reviewed_at` et `reviewed_hash`. L’empreinte lie la relecture au contenu, aux références, aux dates et aux thèmes. Les anciennes sources restent lisibles mais sont exclues tant qu’elles ne sont pas relues via l’interface. Le mode `deepen` utilise les fiches documentaires livrées ; il ne prétend pas que ces fiches sont des sources relues par un avocat.

La recherche retient les sources relues dont la période inclut `-AsOf`. Les thèmes obligatoires passent avant le classement lexical ; ils ne sont pas éliminés par la limite des six résultats lexicaux complémentaires. Une couverture incomplète bloque l’appel au modèle. Le budget de contexte reste strict : les sources obligatoires ne sont pas tronquées. Les extraits sont comparés mot pour mot ; ces contrôles ne valident pas leur interprétation.

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

L’empreinte porte sur le texte UTF-8 sans BOM. Le texte doit être identique au rendu des données contrôlées. Modifier manuellement le seul texte et son empreinte ne suffit plus : régénérer le projet. La publication revérifie aussi les sources et la version de la politique de qualité.

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

Les tests vérifient aussi le blocage sans sources, les citations inventées, les pièces jamais chargées, les faits présentés comme prouvés, les chiffres hors citation, les demandes hors sujet, les thèmes omis et les sources modifiées avant publication. Ils utilisent des réponses simulées et des sources synthétiques, sans Ollama. Ils ne constituent pas une évaluation juridique du modèle. La qualité des réponses, le conteneur et l’approbation organisationnelle doivent être réceptionnés avant l’utilisation de vrais dossiers.

Pour une évaluation réelle de sensibilité aux faits, exécuter `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\evaluer-strategie.ps1 -LocalModel qwen3.5:4b`. Le script appelle le modèle sur deux exposés fictifs opposés, exige trois moyens contrôlés par dossier et vérifie que la commande acceptée et la réception conforme affaiblissent les contestations correspondantes. Les résultats restent sous `.test-runs/`, exclus de Git. Ce test peut durer plusieurs minutes et ne constitue pas une validation juridique indépendante. Lire les applications, objections et actions dans les rapports, au-delà des étiquettes contrôlées automatiquement.

Références : [API officielle Ollama](https://github.com/ollama/ollama/blob/main/docs/api.md), [Légifrance](https://www.legifrance.gouv.fr/).
