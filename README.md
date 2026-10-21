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
4. Cliquez sur **Lancer l’analyse**. Une première lecture est préparée immédiatement, sans attendre Ollama.
5. Le résultat apparaît dans **Rapports**. Vous pouvez le relire et cliquer sur **Enregistrer une copie…**.

**Vous n’avez pas besoin de remplir une bibliothèque juridique pour commencer.** Le rapport contient des passages de vos documents, les questions à confronter, des demandes de pièces et six fiches de référence sur les contrats civils et commerciaux, avec leurs liens officiels. Ces fiches sont des reformulations préparées le 21 octobre 2026 ; leur version et leur applicabilité restent à vérifier pour votre dossier.

Pour un complément facultatif, cliquez sur **Approfondir avec Ollama**. Le modèle local sélectionne d’autres passages utiles dans vos textes ; les extraits doivent correspondre mot pour mot. Cette étape peut prendre plusieurs minutes. Si le modèle échoue, votre première lecture et les références restent disponibles. Vous pouvez lire les rapports pendant le traitement.

Les fichiers importés plusieurs fois sont reconnus comme doublons. Les anciennes copies restent sur le disque, mais ne comptent qu’une fois dans l’analyse. Aucun fichier n’est supprimé.

**Documents acceptés :** fichiers texte `.txt` et `.md`, 2 Mo maximum par fichier. Pour un PDF ou un document Word, copiez son texte dans la zone de description, ou faites-le convertir localement. Pour un scan, demandez une reconnaissance de texte locale. Ne transmettez pas les pièces à un site de conversion.

### Ajouter les textes de loi — facultatif pour la première lecture

Dans **Sources juridiques** :

1. Renseignez le titre, le lien officiel et les dates d’application, puis collez le texte officiel.
2. Indiquez le **code ou la juridiction** et l’**article ou la référence exacte**.
3. Cochez seulement les questions réellement couvertes par ce texte.
4. Après comparaison avec la source officielle, indiquez le nom de l’avocat relecteur et cochez sa confirmation.
5. Cliquez sur **Vérifier et enregistrer**.

Ces textes complémentaires servent à la rédaction juridique avancée et aux directives communes. Leur absence n’empêche pas la première lecture du dossier. Une modification du texte ou de ses références invalide sa relecture.

Pour une prestation de service, les fiches de départ abordent la charge de la preuve, la preuve civile et commerciale, le prix et la prescription. Le rapport sépare les questions de mission, périmètre, exécution et montant. Cette base n’est pas exhaustive et ne tranche pas la dette ou une échéance.

### Préparer les directives communes

Dans **Directives du cabinet**, décrivez la consigne souhaitée et cliquez sur **Préparer un projet**. Après vérification, l’avocat indique son nom, coche la confirmation de relecture puis clique sur **Valider et publier**.

Sans bibliothèque relue, le programme prépare des **consignes de travail** : conservation des pièces, contrôle contradictoire et étapes de vérification. Ce projet peut être relu et publié localement ; il ne devient pas une règle de droit. Les développements juridiques détaillés restent soumis à la disponibilité des textes et à leur vérification.

Un projet bloqué ou ancien ne peut pas être publié. Si une source a changé depuis sa rédaction, il faut refaire le projet. Les contrôles de citations ne valident pas automatiquement le sens juridique de l’application proposée : l’avocat doit comparer chaque extrait et chaque raisonnement.

« Publier » signifie rendre la version applicable dans cette application locale. Rien n’est envoyé par courriel ni publié sur Internet. Le nom saisi n’est pas une signature électronique.

## Où sont mes données ?

Dans le sous-dossier **vault**, à côté de ces fichiers. Ne déplacez pas ce dossier pendant une analyse. Pour sauvegarder, fermez l’application puis utilisez la solution de sauvegarde chiffrée approuvée par le cabinet.

Installez l’application dans un dossier sans synchronisation OneDrive, Dropbox ou autre service externe. L’interface utilise les droits de votre session Windows ; pour une isolation renforcée, le responsable informatique doit configurer le déploiement prévu dans le guide technique.

## Si quelque chose ne fonctionne pas

- **L’application ne s’ouvre pas :** contactez le responsable informatique avec le nom `DEMARRER.cmd`. Ne désactivez pas les protections de Windows.
- **Ollama ou modèle indisponible :** la première lecture fonctionne quand même. Pour le complément, ouvrez **Installation et aide**, puis cliquez sur **Préparer ce poste**.
- **Complément Ollama lent :** votre première lecture reste dans Rapports. Le traitement local peut prendre plusieurs minutes.
- **Document refusé :** utilisez du texte `.txt` ou `.md` et limitez sa taille à 2 Mo.
- **Texte trop long :** réduisez la description ou faites plusieurs analyses ciblées.

Les réponses sont des **brouillons à vérifier par un avocat**. Le modèle testé a déjà produit des erreurs de faits et de position des parties. Ne lui confiez pas seul une décision ou une échéance.

Pour le responsable informatique uniquement : [guide technique](GUIDE-TECHNIQUE.md).
