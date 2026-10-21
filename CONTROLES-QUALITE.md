# Contrôles introduits après le rejet d’un rapport

Le rapport initial associait des numéros d’articles à des règles différentes, présentait un exposé comme une preuve et omettait des questions déterminantes. Il ne passe pas le nouveau contrôle. Le fichier historique reste local ; son texte n’est plus affiché comme rapport courant dans l’interface.

## Ce qui change réellement

| Défaut observé | Traitement dans le programme |
| --- | --- |
| Analyse juridique alors que le corpus est vide | Aucun appel à Ollama. Production d’un inventaire et d’une liste de collecte, sans consultation juridique générée. |
| URL officielle utilisée comme preuve de fiabilité | Source exclue sans code, référence, thèmes, relecteur, date et empreinte de relecture. Cette attestation reste déclarative. |
| Numéro d’article ou seuil inventé | Le modèle ne rédige pas les références. Le programme les affiche depuis la source relue ; les chiffres et références hors citations sont refusés dans le raisonnement libre. |
| Citation inventée sous un identifiant valide | Comparaison exacte de l’extrait avec le texte local de la source. |
| Facture ou courriel mentionné mais jamais chargé | Référence limitée aux documents effectivement fournis et à des extraits présents mot pour mot. Aucune authentification d’original n’est présumée. |
| Exposé présenté comme faits prouvés | Affichage « texte fourni non authentifié » ; les observations sont des extraits, sans statut de fait établi. |
| Oubli des questions de preuve commerciale et de prix | Ces thèmes deviennent obligatoires pour le profil détecté de prestations de services ; leur absence bloque l’analyse. |
| Dates de naissance ou qualifications hors sujet | Filtre des demandes sans correspondance dans les données fournies. |
| Texte rejeté néanmoins montré comme analyse | Réponse brute conservée seulement dans `vault/rejected/`, hors de l’affichage normal. Rapport de blocage à la place. |
| Publication d’un ancien projet ou d’un projet fondé sur une source modifiée | Refus de publication et nouvelle génération exigée. |

## Portée des contrôles

Une citation exacte ne démontre pas que son interprétation est correcte. Une source relue n’est pas automatiquement authentifiée ; la personne qui coche la relecture n’est pas identifiée par un système d’identité. Les filtres lexicaux peuvent manquer des formulations trompeuses ou refuser une formulation correcte. La détection de profil utilise des mots-clés et ne couvre pas toutes les branches du droit.

Le statut `technical_checks_passed` signifie seulement que la structure, les extraits, les références locales et les thèmes requis ont passé les vérifications programmées. Il ne signifie jamais « juridiquement exact ». L’avocat doit vérifier le champ d’application des textes, les règles spéciales, les dispositions transitoires et la logique de chaque proposition.

Les tests utilisent des textes synthétiques sans valeur juridique ; ils vérifient le blocage et l’intégrité du circuit. Ils ne constituent pas une évaluation juridique indépendante du modèle.

## Textes officiels à examiner pour le cas de prestations de services

Cette liste est une aide à la recherche, sans import automatique ni déclaration de relecture :

- [Code de commerce, L110-3 : régime de preuve commerciale](https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000006219127/2026-06-24).
- [Code civil, 1165 : prix des prestations de service](https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000036829839/2024-09-25).
- [Code civil, 1356 : contrats sur la preuve](https://www.legifrance.gouv.fr/loda/article_lc/LEGIARTI000032042326/2022-10-25).
- [Code civil, 2274 : présomption de bonne foi](https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000019017404/2026-03-15).
- [Code civil, 1302 : paiement de l’indu](https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000032041613).
- [Code civil, 2224 : délai de droit commun et point de départ](https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000019017112/2026-09-02).

Vérifier la version applicable aux faits. Ne pas traiter ces seuls liens comme un corpus suffisant ni appliquer une règle générale sans rechercher les règles spéciales pertinentes.
