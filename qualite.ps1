# Controles techniques locaux. Ils ne remplacent pas le controle juridique humain.
$script:QualityVersion='2026-10-21.3'
$script:LegalTopics=[ordered]@{
    charge_preuve='Charge de la preuve : qui affirme quoi, et quelles pieces etayent chaque affirmation ?'
    regime_preuve='Regime de preuve : domaine civil, commercial, actes mixtes, exceptions et droit dans le temps a verifier.'
    preuve_commerciale='Preuve commerciale : verifier la qualite des parties et la nature de l acte avant toute exigence d ecrit.'
    prix_service='Prix du service : separer accord sur la mission, execution effective, fixation du prix et justification du montant.'
    prescription='Prescription : qualifier la demande, rechercher la regle speciale, le point de depart, les interruptions et suspensions. Aucun calcul automatique.'
}
$script:LegalTopicTitles=@{charge_preuve='Charge de la preuve';regime_preuve='Regime civil et exceptions';preuve_commerciale='Preuve commerciale';prix_service='Prix des services';prescription='Prescription et point de depart'}
$script:AnswerSchema=@{
    type='object';additionalProperties=$false;required=@('observations','pistes')
    properties=@{
        observations=@{type='array';maxItems=12;items=@{type='object';additionalProperties=$false;required=@('piece','extrait');properties=@{piece=@{type='string'};extrait=@{type='string'}}}}
        pistes=@{type='array';minItems=1;maxItems=12;items=@{type='object';additionalProperties=$false;required=@('theme','source_id','citation','piece','extrait','application_conditionnelle','contre_argument','a_verifier');properties=@{
            theme=@{type='string';enum=@($script:LegalTopics.Keys)}
            source_id=@{type='string'};citation=@{type='string'};piece=@{type='string'};extrait=@{type='string'}
            application_conditionnelle=@{type='string';minLength=1;maxLength=1800};contre_argument=@{type='string';minLength=1;maxLength=1800};a_verifier=@{type='string';minLength=1;maxLength=1800}
        }}}
    }
}
function Has-Field($Object,[string]$Name) { return $null -ne $Object -and $Object.PSObject.Properties.Name -contains $Name }
function New-AnswerSchema($Laws,$Pieces,$Plan,[bool]$IsDraft) {
    $schema=$script:AnswerSchema | ConvertTo-Json -Depth 20 | ConvertFrom-Json
    $schema.properties.pistes.items.properties.source_id=@{type='string';enum=@($Laws | ForEach-Object {$_.id})}
    $schema.properties.pistes.items.properties.theme=@{type='string';enum=@($Plan.required)}
    if($IsDraft){
        $schema.properties.observations.maxItems=0
        $schema.properties.pistes.items.properties.piece=@{type='string';enum=@('')}
        $schema.properties.pistes.items.properties.extrait=@{type='string';enum=@('')}
    }else{
        $names=@($Pieces | ForEach-Object {$_.name})
        $schema.properties.observations.items.properties.piece=@{type='string';enum=$names}
        $schema.properties.pistes.items.properties.piece=@{type='string';enum=$names}
    }
    return $schema
}
function Normalize-ReviewText([string]$Text) {
    $builder=[Text.StringBuilder]::new()
    foreach($c in $Text.Normalize([Text.NormalizationForm]::FormD).ToCharArray()) {
        if([Globalization.CharUnicodeInfo]::GetUnicodeCategory($c) -ne [Globalization.UnicodeCategory]::NonSpacingMark){$null=$builder.Append($c)}
    }
    return $builder.ToString().ToLowerInvariant()
}
function Get-SourceFingerprint($Law) {
    $parts=@($Law.id,$Law.title,$Law.url,$Law.retrieved_at,$Law.valid_from,$Law.valid_to,$Law.text)
    foreach($key in @('code','article','reviewed_by','reviewed_at')) {$parts+=if(Has-Field $Law $key){[string]$Law.$key}else{''}}
    $topics=if(Has-Field $Law 'topics'){@($Law.topics | Sort-Object -Unique)}else{@()}
    $parts+=($topics -join '|')
    return Hash (ConvertTo-Json -InputObject $parts -Compress -Depth 4)
}
function Test-ReviewedLaw($Law) {
    foreach($key in @('code','article','topics','reviewed_by','reviewed_at','reviewed_hash')) {if(-not (Has-Field $Law $key)){return $false}}
    if([string]::IsNullOrWhiteSpace($Law.code) -or [string]::IsNullOrWhiteSpace($Law.article) -or [string]::IsNullOrWhiteSpace($Law.reviewed_by)){return $false}
    if(@($Law.topics).Count -eq 0){return $false}
    foreach($topic in $Law.topics){if($topic -notin @($script:LegalTopics.Keys)){return $false}}
    $date=[datetime]::MinValue
    if(-not [datetime]::TryParseExact($Law.reviewed_at,'yyyy-MM-dd',[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::None,[ref]$date)){return $false}
    if($date.Date -gt (Get-Date).Date -or $Law.reviewed_at -lt $Law.retrieved_at){return $false}
    return $Law.reviewed_hash -ceq (Get-SourceFingerprint $Law)
}
function New-ReviewPlan([string]$Text) {
    $normal=Normalize-ReviewText $Text
    $service=$normal -match 'prestation|consult|conseil|honorair|factur|service|devis'
    $business=$normal -match 'societe|entreprise|commerc|sarl|\bsas\b|\bb2b\b'
    $required=@('charge_preuve','regime_preuve','prescription')
    if($service -or $business){$required+='preuve_commerciale'}
    if($service){$required+='prix_service'}
    return [pscustomobject]@{service=$service;business=$business;required=$required}
}
function Select-ReviewedLaws($Laws,$Plan,[string]$Query) {
    $eligible=@($Laws | Where-Object {(Test-ReviewedLaw $_) -and $_.valid_from -le $AsOf -and (-not $_.valid_to -or $_.valid_to -ge $AsOf)})
    $selected=@()
    # Les themes obligatoires passent avant le classement lexical ; pas de top-6 aveugle.
    foreach($topic in $Plan.required){foreach($law in $eligible){if($topic -in @($law.topics) -and $law.id -notin @($selected | ForEach-Object {$_.id})){$selected+=$law}}}
    foreach($law in @(Select-Laws $eligible $Query)){if($law.id -notin @($selected | ForEach-Object {$_.id})){$selected+=$law}}
    return $selected
}
function Missing-Topics($Laws,$Plan) {
    return @($Plan.required | Where-Object {$topic=$_;@($Laws | Where-Object {$topic -in @($_.topics)}).Count -eq 0})
}
function Test-UsableGuidelines($Record,$CurrentLaws) {
    if($null -eq $Record -or -not (Has-Field $Record 'quality_version') -or $Record.quality_version -ne $script:QualityVersion){return $false}
    if(-not (Has-Field $Record 'quality_status') -or $Record.quality_status -notin @('technical_checks_passed','operational_ready') -or (Hash $Record.text) -cne $Record.content_hash){return $false}
    if($Record.quality_status -eq 'operational_ready'){return (Hash (New-OperationalDirective $Record.question (New-ReviewPlan $Record.question))) -ceq $Record.content_hash}
    foreach($source in $Record.sources){
        $now=@($CurrentLaws | Where-Object {$_.id -ceq $source.id -and (Test-ReviewedLaw $_) -and $_.valid_from -le $AsOf -and (-not $_.valid_to -or $_.valid_to -ge $AsOf)})
        if($now.Count -ne 1 -or (Get-SourceFingerprint $now[0]) -cne (Get-SourceFingerprint $source)){return $false}
    }
    return $true
}
function New-PreparationReport($Pieces,$Plan,$Missing,[string]$Reason) {
    $lines=@('# EXAMEN JURIDIQUE BLOQUE',"Motif : $Reason",'',"Date de reference fournie : $AsOf. Cette date ne prouve pas la date des evenements.",'',
        '## Documents effectivement charges')
    if(@($Pieces).Count -eq 0){$lines+='Aucun document charge.'}
    foreach($p in $Pieces){$lines+="- $($p.name) — texte fourni non authentifie ; SHA256 : $($p.sha256)."}
    $lines+=@('','La presence d une affirmation dans un expose ne constitue pas sa preuve. Les originaux des courriels, factures ou autres documents mentionnes ne sont pas reputes charges.',
        'L absence de document dans ce dossier ne demontre pas l absence de prestation, de contrat ou de piece chez l autre partie.','',
        '## Points a instruire avant toute conclusion')
    foreach($topic in $Plan.required){$label=if($topic -in @($Missing)){'SOURCE VERIFIEE MANQUANTE'}else{'Source disponible ; applicabilite a examiner'};$lines+="- $($script:LegalTopics[$topic]) [$label]"}
    if($Plan.service){$lines+=@('- Obtenir les echanges complets : proposition, reponses, communications ulterieures et comportement des parties.',
        '- Examiner separement le consentement a la mission, son perimetre, son execution et les elements de calcul du prix.',
        '- Ne pas deduire automatiquement de l absence de devis signe ou d accord prealable sur le prix que rien ne serait du.')}
    $lines+=@('- Identifier clairement le client, l adversaire, le demandeur et le defendeur avant de proposer un moyen.',
        '- Conserver les communications existantes et demander les originaux des documents simplement mentionnes.',
        '- Ne pas collecter de dates de naissance, de donnees de personnel ou de qualifications contractuelles sans lien explique avec le dossier.','',
        '## Conclusion suspendue','Les elements disponibles ne permettent pas de trancher le bien-fonde de la demande. Aucun seuil, delai, article ou strategie contentieuse n est genere de memoire. Completer les sources manquantes ou, en cas de rejet du modele, demander une revue manuelle.',
        'Ce document est une liste de collecte et de controle, pas une consultation juridique.')
    return $lines -join "`n"
}
function Check-Fields($Object,$Names,[string]$Label) {
    if($null -eq $Object -or $Object -is [array] -or $Object -is [string]){throw "Structure invalide : $Label"}
    foreach($name in $Names){if(-not (Has-Field $Object $name)){throw "Champ absent : $Label.$name"}}
    foreach($name in $Object.PSObject.Properties.Name){if($name -notin $Names){throw "Champ inattendu : $Label.$name"}}
}
function Check-Excerpt([string]$Piece,[string]$Excerpt,$Pieces) {
    $matches=@($Pieces | Where-Object {$_.name -ceq $Piece})
    if($matches.Count -ne 1 -or [string]::IsNullOrWhiteSpace($Excerpt) -or -not $matches[0].text.Contains($Excerpt)){throw 'Citation de piece absente ou non conforme au texte charge'}
}
function Assert-FreeReasoning([string]$Text,[string]$InputText) {
    if([string]::IsNullOrWhiteSpace($Text) -or $Text.Length -gt 1800){throw 'Raisonnement vide ou trop long'}
    $normal=Normalize-ReviewText $Text
    # Numeros, seuils et references ne sont autorises que dans les citations exactes.
    if($normal -match '\d|\barticles?\b|\bart\.|\bcodes?\s+(civil|de\s+commerce)|\[(loi|piece):|https?://|www\.|€|\beuros?\b|\b(deux|trois|cinq|dix|trente)\s+(ans?|annees?|mois|jours?)\b|\b(biennal|quinquennal)\w*'){throw 'Regle chiffree ou reference juridique hors citation : resultat bloque'}
    if($normal -match '\b(faits?|facts?)\s+(prouves?|etablis?)|prouve par|contrat (nul|invalide)|preuve (impossible|interdite)|ne doit rien|rien n.est du|creance (prescrite|etablie|certaine)'){throw 'Qualification definitive non autorisee'}
    $inputNormal=Normalize-ReviewText $InputText
    foreach($irrelevant in @('naissance','convention collective','mandat','commission')){if($normal.Contains($irrelevant) -and -not $inputNormal.Contains($irrelevant)){throw 'Demande ou qualification sans lien avec les donnees fournies'}}
}
function ConvertFrom-ModelReview([string]$Raw,$Laws,$Pieces,$Plan,[string]$InputText,[bool]$IsDraft) {
    try {$data=$Raw | ConvertFrom-Json} catch {throw 'Le modele n a pas fourni la structure JSON exigee'}
    Check-Fields $data @('observations','pistes') 'reponse'
    if($data.observations -isnot [array] -or $data.pistes -isnot [array] -or $data.observations.Count -gt 12 -or $data.pistes.Count -eq 0 -or $data.pistes.Count -gt 12){throw 'Listes de reponse invalides'}
    foreach($observation in $data.observations){Check-Fields $observation @('piece','extrait') 'observation';Check-Excerpt $observation.piece $observation.extrait $Pieces}
    foreach($piste in $data.pistes){
        Check-Fields $piste @('theme','source_id','citation','piece','extrait','application_conditionnelle','contre_argument','a_verifier') 'piste'
        $sources=@($Laws | Where-Object {$_.id -ceq $piste.source_id})
        if($sources.Count -ne 1){throw 'Source inconnue citee par le modele'}
        $law=$sources[0]
        if($piste.theme -notin @($script:LegalTopics.Keys) -or $piste.theme -notin @($law.topics)){throw 'Theme non couvert par la source citee'}
        if($piste.citation -isnot [string] -or $piste.citation.Length -lt [Math]::Min(40,$law.text.Length) -or -not $law.text.Contains($piste.citation)){throw 'Citation juridique absente, trop courte ou differente de la source'}
        if($IsDraft){if($piste.piece -or $piste.extrait){throw 'Une directive ne doit pas charger de dossier client'}}else{Check-Excerpt $piste.piece $piste.extrait $Pieces}
        if($piste.application_conditionnelle -notmatch '^Si\s'){throw 'L application doit exposer une hypothese conditionnelle commencant par Si'}
        foreach($field in @('application_conditionnelle','contre_argument','a_verifier')){Assert-FreeReasoning $piste.$field $InputText}
    }
    foreach($topic in $Plan.required){if($topic -notin @($data.pistes | ForEach-Object {$_.theme})){throw "Theme obligatoire omis : $topic"}}
    return $data
}
function Render-ModelReview($Data,$Laws,$Pieces,$Plan) {
    $lines=@('# PISTES CONDITIONNELLES — CONTROLE JURIDIQUE HUMAIN REQUIS',
        'Les controles automatises portent sur la structure, les citations exactes et la couverture des themes. Ils ne prouvent ni la pertinence juridique ni la justesse du raisonnement.',
        "Date de reference fournie : $AsOf. Aucune verification en ligne des dossiers.",'',
        '## Inventaire des documents effectivement charges')
    foreach($p in $Pieces){$lines+="- $($p.name) — texte fourni non authentifie ; SHA256 : $($p.sha256)."}
    if(@($Pieces).Count -eq 0){$lines+='Aucune piece de dossier chargee (projet commun au cabinet).'}
    $lines+=@('','Les originaux mentionnes dans un expose ne sont pas reputes consultes. Aucun fait n est declare prouve.','',
        '## Extraits fournis, sans authentification')
    foreach($o in $Data.observations){$lines+="- [PIECE:$($o.piece)] : « $($o.extrait) »"}
    $lines+=@('','## Controle obligatoire des questions de droit')
    foreach($topic in $Plan.required){$lines+="- $($script:LegalTopics[$topic])"}
    if($Plan.service){$lines+='Examiner separement mission consentie, perimetre, execution et justification du montant. Un devis absent ou un prix non convenu ne permet pas, a lui seul, de conclure a l absence de dette.'}
    foreach($p in $Data.pistes){
        $law=@($Laws | Where-Object {$_.id -ceq $p.source_id})[0]
        $lines+=@('',"## $($script:LegalTopics[$p.theme])", "Source : $($law.code), reference $($law.article) — $($law.url)",
            "Version renseignee : $($law.valid_from) a $($law.valid_to). Consultation : $($law.retrieved_at). Relecture declaree : $($law.reviewed_by), le $($law.reviewed_at).",
            "Extrait exact [LOI:$($law.id)] : « $($p.citation) »")
        if($p.piece){$lines+="Donnee fournie [PIECE:$($p.piece)] : « $($p.extrait) »"}
        $lines+=@("Application proposee par le modele : $($p.application_conditionnelle)","Contre-argument : $($p.contre_argument)","A verifier avant utilisation : $($p.a_verifier)")
    }
    $lines+=@('','## Decision reservee a l avocat','Aucune conclusion automatique sur la validite du contrat, le montant du, la prescription ou le succes d une procedure. Verifier aussi les regles speciales et sources absentes du corpus.')
    return $lines -join "`n"
}
function Get-ReportDisplay($Record) {
    if(-not (Has-Field $Record 'quality_version') -or $Record.quality_version -ne $script:QualityVersion){return 'Ancien format de rapport. Cliquer sur Premiere lecture rapide pour obtenir la nouvelle lecture du dossier, sans bibliotheque a remplir. Le fichier historique reste conserve localement.'}
    if((Has-Field $Record 'strategy_version') -and $Record.strategy_version -ne '2026-10-23.3' -and (Has-Field $Record 'strategy') -and $null -ne $Record.strategy){return "RAPPORT HISTORIQUE : regenerer apres verification du dossier choisi et des appuis propres a chaque axe. Les qualifications de cette version ne sont pas validees par les nouveaux controles.`r`n`r`n"+$Record.text}
    return $Record.text
}
