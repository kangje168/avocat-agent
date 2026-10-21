# Assistant juridique du cabinet

**Tout se fait dans une fenêtre en français. Vous n’avez aucune commande à saisir.**

## Première utilisation

1. Ouvrez ce dossier dans l’Explorateur Windows.
2. Double-cliquez sur **INSTALLER.cmd**.
3. Patientez jusqu’au message « Préparation terminée ». La première installation peut prendre plusieurs minutes. Une connexion Internet est nécessaire pour installer Ollama et télécharger le modèle si ces éléments sont absents. Les éléments déjà installés sont réutilisés.

Si Windows demande une autorisation, vérifiez avec le responsable informatique qu’il s’agit bien de l’installation d’Ollama. Sur un ordinateur d’entreprise, l’installation peut nécessiter son intervention.

## Pour travailler chaque jour

Double-cliquez sur **DEMARRER.cmd**. La fenêtre du cabinet s’ouvre.

### Analyser un dossier

1. Dans **Mes dossiers**, cliquez sur **Nouveau dossier** et donnez-lui un nom.
2. Cliquez sur **Ajouter des documents…**, ou écrivez les faits dans la grande zone de texte.
3. Indiquez ce que vous souhaitez examiner. Une question de départ est déjà proposée.
4. Cliquez sur **Lancer l’analyse**. Attendez la fin du traitement : cela peut prendre plusieurs minutes.
5. Le résultat apparaît dans **Rapports**. Vous pouvez le relire et cliquer sur **Enregistrer une copie…**.

Si des sources vérifiées manquent, l’application affiche **EXAMEN JURIDIQUE BLOQUÉ** et prépare uniquement une liste des documents et vérifications nécessaires. Elle ne demande pas au modèle d’inventer une analyse. Ce comportement est normal : renseignez les sources demandées, puis relancez.

Si la réponse du modèle échoue aux contrôles, elle est également bloquée. L’ancienne réponse n’est pas affichée comme un résultat utilisable. Un ancien rapport doit être régénéré.

**Documents acceptés :** fichiers texte `.txt` et `.md`, 2 Mo maximum par fichier. Pour un PDF ou un document Word, copiez son texte dans la zone de description, ou faites-le convertir localement. Pour un scan, demandez une reconnaissance de texte locale. Ne transmettez pas les pièces à un site de conversion.

### Ajouter les textes de loi

Dans **Sources juridiques** :

1. Renseignez le titre, le lien officiel et les dates d’application, puis collez le texte officiel.
2. Indiquez le **code ou la juridiction** et l’**article ou la référence exacte**.
3. Cochez seulement les questions réellement couvertes par ce texte.
4. Après comparaison avec la source officielle, indiquez le nom de l’avocat relecteur et cochez sa confirmation.
5. Cliquez sur **Vérifier et enregistrer**.

Une simple URL officielle ne suffit pas. Une source sans relecture est exclue de l’analyse ; une modification du texte ou de ses références invalide sa relecture. Une source peut couvrir seulement une partie des questions : les textes manquants restent à compléter.

Pour une prestation de service, l’application impose de traiter la charge de la preuve, le régime applicable dont la preuve commerciale, la fixation du prix et la prescription. Elle demande de distinguer la mission consentie, son périmètre, l’exécution réelle et la justification du montant. Ces vérifications ne constituent pas un corpus exhaustif de droit français.

### Préparer les directives communes

Dans **Directives du cabinet**, décrivez la consigne souhaitée et cliquez sur **Préparer un projet**. Après vérification, l’avocat indique son nom, coche la confirmation de relecture puis clique sur **Valider et publier**.

Un projet bloqué ou ancien ne peut pas être publié. Si une source a changé depuis sa rédaction, il faut refaire le projet. Les contrôles de citations ne valident pas automatiquement le sens juridique de l’application proposée : l’avocat doit comparer chaque extrait et chaque raisonnement.

« Publier » signifie rendre la version applicable dans cette application locale. Rien n’est envoyé par courriel ni publié sur Internet. Le nom saisi n’est pas une signature électronique.

## Où sont mes données ?

Dans le sous-dossier **vault**, à côté de ces fichiers. Ne déplacez pas ce dossier pendant une analyse. Pour sauvegarder, fermez l’application puis utilisez la solution de sauvegarde chiffrée approuvée par le cabinet.

Installez l’application dans un dossier sans synchronisation OneDrive, Dropbox ou autre service externe. L’interface utilise les droits de votre session Windows ; pour une isolation renforcée, le responsable informatique doit configurer le déploiement prévu dans le guide technique.

## Si quelque chose ne fonctionne pas

- **L’application ne s’ouvre pas :** contactez le responsable informatique avec le nom `DEMARRER.cmd`. Ne désactivez pas les protections de Windows.
- **Ollama ou modèle indisponible :** ouvrez **Installation et aide**, puis cliquez sur **Préparer ce poste**.
- **Analyse lente :** laissez la fenêtre ouverte. Sur ce poste, une analyse peut prendre plusieurs minutes.
- **Document refusé :** utilisez du texte `.txt` ou `.md` et limitez sa taille à 2 Mo.
- **Texte trop long :** réduisez la description ou faites plusieurs analyses ciblées.

Les réponses sont des **brouillons à vérifier par un avocat**. Le modèle testé a déjà produit des erreurs de faits et de position des parties. Ne lui confiez pas seul une décision ou une échéance.

Pour le responsable informatique uniquement : [guide technique](GUIDE-TECHNIQUE.md).
