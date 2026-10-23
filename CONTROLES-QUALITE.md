# Contrôles introduits après le rejet d’un rapport

Le rapport initial associait des numéros d’articles à des règles différentes, présentait un exposé comme une preuve et omettait des questions déterminantes. Il ne passe pas le contrôle juridique avancé. Le fichier historique reste local.

La version suivante avait étendu ce blocage à tout le travail sur un dossier, ce qui rendait l’application difficile à utiliser. Désormais, `analyze` prépare immédiatement un dossier de travail avec extraits, questions, actions et fiches documentaires fournies. Aucune bibliothèque personnelle ni modèle n’est nécessaire. Le bouton **Analyser les arguments** (`deepen`) produit désormais un raisonnement local, au lieu de sélectionner seulement des extraits. Le mode avancé `legal` conserve ses contrôles stricts. Sans sources relues, les projets de directives deviennent des consignes opérationnelles déterministes, publiables après relecture nommée et contrôle du texte exact, sans présenter de règle juridique générée.

## Raisonnement sur les pièces

Chaque moyen contient : évaluation de la contestation, extraits du dossier, passage exact d’une fiche documentaire, application conditionnelle, réponse adverse, réplique et limite, action et élément susceptible de changer l’évaluation. Une commande acceptée ou une réception conforme doit pouvoir affaiblir la position du client. Les rôles sont affichés avec les lignes qui les déclarent ; leur qualification reste à confirmer.

Après échec de la génération juridique libre sur le modèle local 4B, le schéma a été réduit aux états factuels et identifiants de passages. Le programme reprend les citations et assemble un cadre conditionnel par axe. Des indices lexicaux limités repèrent certaines acceptations et réserves explicites et peuvent corriger la proposition du modèle ; les négations et les simples souhaits de soutenir un argument sont traités séparément. Ces contrôles restent imparfaits, notamment en présence de formulations complexes ou de chronologies ambiguës. Il ne laisse plus ce modèle rédiger des règles, délais, remèdes ou répartitions de charge de la preuve. Il conserve les moyens valides si un autre échoue et annonce les axes manquants. Aucun moyen retenu : la première lecture reste accessible, avec un motif explicite. Les références sont affichées depuis les fiches, avec leur provenance de reformulation documentaire. Ce cadre vise les contestations générales de commande, de prestation et de prix ; une acceptation ne suffit pas à conclure que toute autre défense serait exclue. Leur date, leur pertinence et leur interprétation ne sont pas certifiées. Le rapport conserve les données structurées, les empreintes et les métriques Ollama.

`evaluer-strategie.ps1` appelle réellement Ollama sur deux cas fictifs opposés. Il exige une évolution de l’évaluation de la commande et un affaiblissement de la contestation d’exécution en présence d’une réception conforme. Les critères ne sont pas fournis comme réponses attendues au modèle. Ce test porte sur une paire de cas ; une réussite ne vaut pas validation juridique générale.

## Ce qui change réellement

| Défaut observé | Traitement dans le programme |
| --- | --- |
| Bibliothèque personnelle vide | La première lecture reste accessible et affiche les fiches documentaires fournies. Le mode juridique avancé et la publication nécessitent des sources relues. |
| URL officielle utilisée comme preuve de fiabilité | Source exclue sans code, référence, thèmes, relecteur, date et empreinte de relecture. Cette attestation reste déclarative. |
| Numéro d’article ou seuil inventé | Les références sont rendues depuis les sources. `legal` refuse les chiffres libres ; `deepen` ne permet aucune prose juridique libre du modèle et reprend les éléments documentaires depuis le cadre. La qualification factuelle peut néanmoins être erronée. |
| Citation inventée sous un identifiant valide | Comparaison exacte de l’extrait avec le texte local de la source. |
| Facture ou courriel mentionné mais jamais chargé | Référence limitée aux documents effectivement fournis et à des extraits présents mot pour mot. Aucune authentification d’original n’est présumée. |
| Exposé présenté comme faits prouvés | Affichage « texte fourni non authentifié » ; les observations sont des extraits, sans statut de fait établi. |
| Oubli des questions de preuve commerciale et de prix | Dans `legal`, leur absence bloque l’analyse. Dans `deepen`, accord, exécution et prix sont demandés et les axes manquants sont signalés ; les fiches et contrôles complémentaires restent visibles. |
| Dates de naissance ou qualifications hors sujet | Filtre des demandes sans correspondance dans les données fournies. |
| Texte rejeté néanmoins montré comme analyse | Réponse brute conservée dans `vault/rejected/`, hors de l’affichage normal. La première lecture reste disponible ; le mode juridique avancé signale son échec. |
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

## Réception du 23 octobre 2026

74 contrôles logiciels réussis ; interface créée avec cinq onglets et deux modèles locaux détectés. Le test réel sur deux exposés fictifs opposés passe ses quatre critères : la réserve ouvre une piste sur la commande ; la commande acceptée et la réception conforme affaiblissent les contestations générales correspondantes ; le raisonnement sur la commande change.

Cette réception concerne le pipeline Ollama + indices textuels + cadre conditionnel. Elle ne valide pas la capacité du modèle 4B à produire librement une analyse juridique. Elle ne couvre pas les autres branches du droit, toutes les formulations possibles ni tous les moyens de défense. Les résultats détaillés restent dans `.test-runs/`, hors de Git.
