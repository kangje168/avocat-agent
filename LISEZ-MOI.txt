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

**Documents acceptés :** fichiers texte `.txt` et `.md`, 2 Mo maximum par fichier. Pour un PDF ou un document Word, copiez son texte dans la zone de description, ou faites-le convertir localement. Pour un scan, demandez une reconnaissance de texte locale. Ne transmettez pas les pièces à un site de conversion.

### Ajouter les textes de loi

Dans **Sources juridiques**, renseignez le titre, le lien officiel et les dates d’application, puis collez le texte officiel. Cliquez sur **Ajouter cette source**. Un avocat doit en vérifier le contenu et la version. Sans sources importées, les propositions juridiques restent non vérifiées.

### Préparer les directives communes

Dans **Directives du cabinet**, décrivez la consigne souhaitée et cliquez sur **Préparer un projet**. Après vérification, l’avocat indique son nom, coche la confirmation de relecture puis clique sur **Valider et publier**.

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
