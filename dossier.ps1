# Rapport utile sans exiger une bibliotheque juridique prealablement administree.
$script:ReferencePath=Join-Path $PSScriptRoot 'corpus-reference.json'
$script:FactAxes=[ordered]@{
    accord=@{title='Accord sur la mission';pattern='accord|accept|command|proposition|devis|commencement';question='Quels echanges montrent une acceptation, un refus ou une reserve sur la mission ?';action='Rassembler la proposition, les reponses et les echanges ulterieurs, avec leurs dates et destinataires.'}
    perimetre=@{title='Perimetre de la prestation';pattern='perimetre|mission|prestation|conseil|travaux';question='Quels travaux etaient demandes, et quels travaux sont reellement documentes ?';action='Comparer les prestations demandees, les comptes rendus et les livrables disponibles.'}
    execution=@{title='Execution et reception';pattern='livrable|execut|realis|reception|fourni|recu|preuve';question='Quelles traces attestent ou contestent les travaux et leur reception ?';action='Demander les livrables, comptes rendus, historiques de remise et observations du client ; une piece absente ici peut exister ailleurs.'}
    montant=@{title='Justification du montant';pattern='prix|montant|factur|\beur\b|euro|tarif|calcul';question='Quel document explique le montant reclame et son mode de calcul ?';action='Demander le detail des prestations, du temps, des tarifs, des frais et des paiements deja effectues.'}
    chronologie=@{title='Chronologie a reconstituer';pattern='\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b|\b\d{1,2}\s+(janvier|fevrier|mars|avril|mai|juin|juillet|aout|septembre|octobre|novembre|decembre)\b|date|apres|avant|ulterieur|notification';question='Dans quel ordre les echanges et les travaux se sont-ils produits ?';action='Distinguer date du document, date d envoi, reception et evenement relate. Ne pas inventer une date de notification.'}
}
function Import-CaseDocument([string]$Case,[string]$Source) {
    if((Id $Case) -eq 'demo-fictif'){throw 'Le dossier de demonstration est reserve a l exemple. Cliquer sur Nouveau dossier avant d ajouter vos documents.'}
    $folder=Safe ('vault/cases/'+(Id $Case))
    $file=Get-Item -LiteralPath $Source
    if($file.Extension -notin '.txt','.md' -or $file.Length -gt 2MB -or ($file.Attributes -band [IO.FileAttributes]::ReparsePoint)){throw 'Utiliser un fichier TXT/MD, 2 Mo maximum, sans lien.'}
    $digest=(Get-FileHash -LiteralPath $Source -Algorithm SHA256).Hash
    foreach($existing in Get-ChildItem -LiteralPath $folder -File){
        $p=Assert-SafePath $existing.FullName
        if((Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash -ceq $digest){return [pscustomobject]@{added=$false;name=$existing.Name}}
    }
    $target=Assert-SafePath (Join-Path $folder ([guid]::NewGuid().ToString('N').Substring(0,8)+'-'+$file.Name))
    [IO.File]::Copy($Source,$target,$false)
    return [pscustomobject]@{added=$true;name=[IO.Path]::GetFileName($target)}
}
function Read-CaseBundle([string]$Id,[string]$Description,[string]$Request='') {
    $cid=Id $Id;$folder=Safe ('vault/cases/'+$cid)
    if(-not (Test-Path -LiteralPath $folder -PathType Container)){throw 'Creer ou selectionner un dossier.'}
    $pieces=@();$seen=@{};$duplicates=@()
    foreach($file in Get-ChildItem -LiteralPath $folder -File | Sort-Object Name){
        $null=Assert-SafePath $file.FullName
        if($file.Extension -notin '.txt','.md'){throw 'Utiliser des documents TXT/MD UTF-8.'}
        $text=Read-Text $file.FullName;$digest=Hash $text
        if($seen.ContainsKey($digest)){$duplicates+=@{name=$file.Name;retained=$seen[$digest]};continue}
        $seen[$digest]=$file.Name
        $pieces+=@{name=$file.Name;text=$text;sha256=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash;nature='texte_fourni_non_authentifie'}
    }
    if(-not [string]::IsNullOrWhiteSpace($Description)){$pieces+=@{name='description-utilisateur';text=$Description;sha256=(Hash $Description);nature='declaration'}}
    if($pieces.Count -eq 0 -and $Request){$pieces+=@{name='demande-utilisateur';text=$Request;sha256=(Hash $Request);nature='declaration'}}
    return [pscustomobject]@{pieces=$pieces;duplicates=$duplicates}
}
function Load-ReferenceCards($Plan) {
    # Fichier public livre avec le code. Il ne contient jamais de donnees de dossier.
    $corpus=[IO.File]::ReadAllText($script:ReferencePath,[Text.Encoding]::UTF8) | ConvertFrom-Json
    $items=@()
    foreach($r in $corpus.references){
        if(-not (Official $r.url)){throw 'Lien non officiel dans les fiches de reference'}
        if(@($r.topics | Where-Object {$_ -in $Plan.required}).Count){$items+=$r}
    }
    return [pscustomobject]@{prepared_at=$corpus.prepared_at;scope=$corpus.scope;items=$items}
}
function Get-FactualPoints($Pieces) {
    $points=@()
    foreach($axis in $script:FactAxes.Keys){
        $candidates=@()
        foreach($piece in $Pieces){
            foreach($line in @($piece.text -split "`r?`n")){
                if($line.Length -gt 5 -and $line.Length -le 900 -and (Normalize-ReviewText $line) -match $script:FactAxes[$axis].pattern){
                    $score=1
                    if((Normalize-ReviewText $line) -match 'courriel|proposition|livrable|bon de commande|avant tout'){ $score+=2 }
                    $candidates+=@{score=$score;point=@{axe=$axis;piece=$piece.name;extrait=$line}}
                }
            }
        }
        # Conserver les dates et les montants meme si plusieurs autres lignes parlent de devis.
        foreach($c in $candidates){if($axis -in @('montant','chronologie') -and $c.point.extrait -match '\d'){$c.score+=4}}
        $points+=@($candidates | Sort-Object { $_.score } -Descending | Select-Object -First 8 | ForEach-Object {$_.point})
    }
    return $points
}
function New-FactualSchema($Pieces) {
    return @{type='object';additionalProperties=$false;required=@('points');properties=@{points=@{type='array';minItems=1;maxItems=5;items=@{type='object';additionalProperties=$false;required=@('axe','piece','extrait');properties=@{axe=@{type='string';enum=@($script:FactAxes.Keys)};piece=@{type='string';enum=@($Pieces | ForEach-Object {$_.name})};extrait=@{type='string';minLength=1;maxLength=900}}}}}}
}
function Read-FactualModel([string]$Raw,$Pieces) {
    $data=$Raw | ConvertFrom-Json
    Check-Fields $data @('points') 'reponse'
    if($data.points -isnot [array] -or $data.points.Count -lt 1 -or $data.points.Count -gt 5){throw 'Selection d extraits invalide'}
    foreach($p in $data.points){Check-Fields $p @('axe','piece','extrait') 'point';if($p.axe -notin @($script:FactAxes.Keys) -or $p.extrait.Length -gt 900){throw 'Axe ou extrait invalide'};Check-Excerpt $p.piece $p.extrait $Pieces}
    return @($data.points)
}
function Render-Dossier($Bundle,$Plan,$Cards,$Points,[string]$ModelNote,[bool]$HasStrategy=$false) {
    $lines=@('# DOSSIER — PREMIERE LECTURE',"Analyse demandee : $Question",'',
        '## Ce que le dossier permet deja de travailler',
        'Les passages ci-dessous proviennent des textes fournis. Ils servent a preparer les questions et les demandes de pieces ; ils ne prouvent pas, a eux seuls, les faits relates.')
    foreach($axis in $script:FactAxes.Keys){
        $items=@($Points | Where-Object {$_.axe -eq $axis})
        if($items.Count -eq 0 -and -not $Plan.service){continue}
        $info=$script:FactAxes[$axis];$lines+=@('',"### $($info.title)")
        foreach($p in $items){$lines+="- Selon [$($p.piece)] : « $($p.extrait) »"}
        if($items.Count -eq 0){$lines+='Aucun passage selectionne sur ce point ; cela ne signifie pas qu aucune preuve existe.'}
        $lines+=@("Question a examiner : $($info.question)","Prochaine action : $($info.action)")
    }
    if(-not $HasStrategy){
    $lines+=@('','## Questions generales de preparation (sans raisonnement du modele)')
    if($Plan.service){$lines+=@('- Pour contester la demande : chercher les reserves sur le lancement de la mission, les limites de son perimetre, les ecarts entre travaux annonces et traces disponibles, et le detail du montant.',
        '- Pour anticiper la reponse adverse : rechercher aussi les acceptations ulterieures, les usages des travaux et les traces de remise susceptibles de soutenir la demande.',
        '- Ces pistes ne permettent pas de dire automatiquement que le contrat est inexistant, que la prestation n a pas ete faite ou que le prix n est pas du.')}
    else{$lines+='Comparer les versions des parties, les documents contemporains et les pieces manquantes avant de retenir une interpretation.'}
    }
    $lines+=@('','## References officielles pour approfondir',
        "Fiches documentaires preparees le $($Cards.prepared_at). Reformulations, pas citations litterales des articles ; verifier la version et l applicabilite dans les liens officiels. Le lot fourni concerne les contrats civils/commerciaux et n est pas exhaustif.")
    foreach($r in $Cards.items){$lines+=@('',"### $($r.title)",$r.note,"A verifier dans le dossier : $($r.question)","Source officielle : $($r.url)")}
    $lines+=@('','## Pieces a reunir en priorite','- Les originaux des courriels et factures seulement evoques dans les descriptions, avec leurs pieces jointes et les echanges complets.',
        '- Les traces de commande, de travail, de remise et de contestation ; garder les documents utiles aux deux versions.',
        '- Les actes de procedure, echeances et paiements eventuels. Aucun delai n est calcule automatiquement.','',
        '## Documents pris en compte')
    foreach($p in $Bundle.pieces){$lines+="- $($p.name) — texte fourni, sans authentification de l original."}
    if($Bundle.duplicates.Count){$lines+="$($Bundle.duplicates.Count) copie(s) identique(s) ignoree(s) pour cette analyse. Les fichiers restent conserves."}
    $lines+=@('',"Modele : $ModelNote",'',
        '## Prochaine etape','Le bouton Analyser les arguments combine une lecture locale des passages et un cadre conditionnel : application, reponse adverse, replique et action. Chaque axe exige ses propres appuis ; une qualification non corroboree reste indeterminee. Faire verifier les originaux, le cadre applicable et les echeances par l avocat.')
    return $lines -join "`n"
}
function New-OperationalDirective([string]$Request,$Plan) {
    $cards=Load-ReferenceCards $Plan
    $lines=@('# PROJET — CONSIGNES DE TRAVAIL DU CABINET',"Objectif demande (a relire) : $Request",'',
        '## Portee','Consignes d organisation et de controle des dossiers. Ce projet ne fixe aucune regle de droit ni position contentieuse obligatoire. Il peut etre revu et publie localement sans attendre la constitution d une bibliotheque juridique.',
        '','## Procedure commune',
        '1. Identifier le client, la partie adverse, leurs demandes respectives et les personnes chargees du dossier.',
        '2. Conserver les fichiers originaux, les pieces jointes et les echanges complets ; garder un inventaire. Regrouper les copies identiques sans supprimer les originaux.',
        '3. Distinguer les declarations, les documents effectivement consultes et les hypotheses. Ne pas qualifier automatiquement un fait de prouve.',
        '4. Reconstituer la chronologie en distinguant la date du document, son envoi, sa reception et l evenement relate.',
        '5. Confronter les arguments utiles au client avec les elements qui pourraient soutenir la partie adverse. Demander les pieces manquantes avant de conclure.',
        '6. Faire verifier par l avocat responsable les fondements, le regime de preuve et les echeances avant tout acte ou conseil juridique.',
        '7. Noter les verifications effectuees, leurs sources, les points ouverts et le nom du relecteur dans le dossier.')
    if($Plan.service){$lines+=@('','## Controle particulier des prestations',
        '- Examiner separement la mission acceptee, son perimetre, les travaux realises, la remise des livrables et le calcul du montant.',
        '- Ne pas conclure automatiquement a une absence de dette parce qu un devis signe ou un accord prealable sur le prix manque.',
        '- Rassembler les reserves, les reponses ulterieures, les traces d usage et les justificatifs de prestation, y compris ceux utiles a l adversaire.')}
    $lines+=@('','## Recherches a faire selon le dossier')
    foreach($r in $cards.items){$lines+="- $($r.title) : $($r.question) — $($r.url)"}
    $lines+=@('',"Fiches documentaires preparees le $($cards.prepared_at). Verifier leur actualite et leur applicabilite ; elles ne remplacent pas les textes officiels.",'',
        '## Validation','Le relecteur confirme la pertinence de ces consignes avant publication. Toute conclusion juridique propre a un dossier reste soumise a une verification distincte.')
    return $lines -join "`n"
}
function Test-DemoMixture($Bundle) {
    $demo=@($Bundle.pieces | Where-Object {(Normalize-ReviewText $_.text) -match 'dossier entierement fictif\s*-\s*demonstration'})
    return $demo.Count -gt 0 -and $demo.Count -lt $Bundle.pieces.Count
}
function Render-UnscopedDossier($Bundle,[string]$Scope) {
    $lines=@('# DOSSIER — PREPARATION ET VERIFICATION DU PERIMETRE',"Demande : $Question",'')
    if($Scope -eq 'mixed_demo'){
        $lines+=@('## Sources a separer','Un exemple marque comme demonstration est melange a d autres textes. Aucune analyse des moyens n est produite sur ce melange. Les conclusions de l exemple ne doivent pas etre attribuees a votre dossier.',
            'Creer ou selectionner un dossier distinct et y ajouter seulement les documents de cette affaire. Les originaux du dossier actuel restent conserves.')
    }else{
        $lines+=@('## Cadre des prestations non applique','Le profil de prestation de services n est pas etabli par le classement actuel. Le cadre commande / execution / prix ne sera pas applique par defaut. Ce classement limite ne constitue pas une qualification juridique.',
            'Le dossier reste disponible pour instruction. La presente sortie ne constitue pas une analyse des responsabilites, des demandes ou des voies de recours.',
            '','## Textes fournis a examiner')
        foreach($p in $Bundle.pieces){
            $excerpt=$p.text.Substring(0,[Math]::Min(1200,$p.text.Length))
            $lines+=@('',"### $($p.name)",$excerpt)
            if($p.text.Length -gt 1200){$lines+='Extrait de lecture limite ; le fichier integral reste conserve dans ce dossier.'}
        }
        $lines+=@('','## Points a instruire',
            '- Identifier le client, les parties, leur qualite pour agir et les demandes exactes ; distinguer chaque personne lesee et chaque prejudice.',
            '- Reconstituer les faits et la chronologie a partir des pieces ; distinguer allegations, originaux consultes et hypotheses.',
            '- Obtenir les actes recus, les demandes adverses, les dates de notification et les pieces utiles a la defense comme a la position adverse.',
            '- Faire qualifier les fondements, les conditions des demandes reconventionnelles et les mesures envisagees par l avocat responsable, avec les textes officiels pertinents. Aucun delai ou droit a obtenir une mesure n est presume.')
    }
    $lines+=@('','## Inventaire local')
    foreach($p in $Bundle.pieces){$lines+="- $($p.name) — texte fourni, original non authentifie."}
    $lines+=@('','Aucun appel au modele de prestations ; aucune conclusion juridique tiree des fiches sur les contrats. Ajouter les sources et le cadre adaptes a cette affaire avant une analyse juridique.')
    return $lines -join "`n"
}
function Invoke-Dossier([bool]$Deepen) {
    if([string]::IsNullOrWhiteSpace($Question) -or $Question.Length -gt 8000){throw 'Indiquer une question (8000 caracteres maximum).'}
    if($CaseDescription.Length -gt 20000){throw 'Description : 20 000 caracteres maximum.'}
    $bundle=Read-CaseBundle $CaseId $CaseDescription $Question
    $inputText=($bundle.pieces | ForEach-Object {$_.text}) -join "`n"
    $plan=New-ReviewPlan $inputText
    $scope=if(Test-DemoMixture $bundle){'mixed_demo'}elseif(-not $plan.service){'outside_service_scope'}else{'service'}
    $cards=if($scope -eq 'service'){Load-ReferenceCards $plan}else{[pscustomobject]@{items=@();prepared_at='';scope=$scope}}
    $points=@(Get-FactualPoints $bundle.pieces);$modelUsed=$false;$modelNote='Lecture locale immediate, sans attente du modele.';$modelData=$null;$inference=$null
    $uid=[guid]::NewGuid().ToString('N')
    if($Deepen -and $scope -eq 'service'){
        try{
            if($inputText.Length -gt 24000){throw 'Documents trop longs pour l approfondissement ; la premiere lecture est conservee.'}
            $req=New-StrategyPrompt $bundle $cards $Question $plan
            $script:LastInference=$null
            $modelUsed=$true;$raw=Ask-Local $req (New-StrategySchema $bundle.pieces $cards) 'strategy' 900
            $inference=$script:LastInference
            $modelData=Read-StrategyModel $raw $bundle.pieces $cards
            if($modelData.arguments.Count -eq 0){throw ('Aucun moyen retenu : '+($modelData.rejected -join '; '))}
            $modelNote='Qualification locale et cadre conditionnel : '+$modelData.arguments.Count+' moyen(s) avec ancrages controles ; interpretation non certifiee.'
            if($modelData.rejected.Count){Write-Json (Safe ('vault/rejected/'+$uid+'.json')) @{reason=$modelData.rejected;raw=$raw;confidential=$true}}
        }catch{
            if($modelUsed){$inference=$script:LastInference}
            $modelData=$null
            $modelNote='Le raisonnement du modele n a pas ete retenu : '+$_.Exception.Message+'. La premiere lecture reste disponible ; aucune strategie validee ne peut en etre deduite.'
            if(Get-Variable raw -Scope Local -ErrorAction SilentlyContinue){Write-Json (Safe ('vault/rejected/'+$uid+'.json')) @{reason=$_.Exception.Message;raw=$raw;confidential=$true}}
        }
    }
    if($scope -eq 'service'){$answer=Render-Dossier $bundle $plan $cards $points $modelNote ($null -ne $modelData)}
    else{$answer=Render-UnscopedDossier $bundle $scope;$modelNote='Preparation uniquement ; cadre de prestations non applique.'}
    if($null -ne $modelData){$answer=(Render-Strategy $modelData $bundle $cards $plan)+"`n"+$answer}
    $record=@{id=$uid;status='draft';case_id=$CaseId;created_at=[datetime]::UtcNow.ToString('o');as_of=$AsOf;question=$Question;model=$Model;model_called=$modelUsed;model_note=$modelNote;inference=$inference;strategy=$modelData;strategy_version='2026-10-23.3';reference_hash=(Hash ($cards.items | ConvertTo-Json -Depth 8 -Compress));text=$answer;content_hash=(Hash $answer);quality_version=$script:QualityVersion;quality_status=$(if($scope -eq 'service'){'dossier_ready'}else{'preparation_only'});scope_status=$scope;pieces=@($bundle.pieces | ForEach-Object {@{name=$_.name;sha256=$_.sha256}});duplicates=$bundle.duplicates;references=$cards.items;points=$points;sources=@()}
    Write-Json (Safe ('vault/reports/'+$uid+'.json')) $record
    "Enregistre : vault/reports/$uid.json`n`n$answer"
}
