# Fixtures fictives exclusivement, aucune loi ni donnee de client reelle.
function Check([string]$Label,[bool]$Condition){if(-not $Condition){throw "ECHEC : $Label"};$script:passed++;"OK $Label"}
$Root=Join-Path $PSScriptRoot ('.test-runs/'+[guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($Root) | Out-Null
Ensure-Layout
foreach($cid in @('a','b')){[IO.Directory]::CreateDirectory((Safe ('vault/cases/'+$cid))) | Out-Null}
[IO.File]::WriteAllText((Safe 'vault/cases/a/one.txt'),'DECLARATION CLIENT_A : prestation de conseil entre societes, facture contestee.')
[IO.File]::WriteAllText((Safe 'vault/cases/b/two.txt'),'CLIENT_B_SECRET')
$script:modelCalls=0;$script:fault='';$script:lastPrompt=''
function Ask-Local([string]$Prompt) {
    $script:modelCalls++;$script:lastPrompt=$Prompt
    $req=$Prompt.Substring($Prompt.IndexOf('{')) | ConvertFrom-Json
    $observations=@();$pistes=@()
    foreach($topic in $req.themes_obligatoires){
        $law=@($req.sources | Where-Object {$topic -in @($_.topics)})[0]
        $piece='';$extrait=''
        if($req.task -eq 'analyze'){$piece=$req.pieces[0].name;$extrait=$req.pieces[0].text}
        $pistes+=[pscustomobject]@{theme=$topic;source_id=$law.id;citation=$law.text;piece=$piece;extrait=$extrait;application_conditionnelle='Si les conditions du texte sont reunies, examiner les elements contradictoires.';contre_argument='Une communication ulterieure peut modifier la lecture proposee.';a_verifier='Retrouver les documents complets et verifier les conditions du texte.'}
    }
    if($req.task -eq 'analyze'){$observations+=@{piece=$req.pieces[0].name;extrait=$req.pieces[0].text}}
    switch($script:fault){
        'source' {$pistes[0].source_id='inconnue'}
        'citation' {$pistes[0].citation='La preuve doit etre ecrite au dela du seuil invente.'}
        'piece' {$pistes[0].piece='facture-originale-jamais-chargee.txt'}
        'extrait' {$pistes[0].extrait='DATE DE NOTIFICATION INVENTEE'}
        'seuil' {$pistes[0].application_conditionnelle='Si le montant depasse 1225 euros, le contrat est invalide.'}
        'faits' {$pistes[0].contre_argument='Les faits prouves etablissent une absence de prestation.'}
        'naissance' {$pistes[0].a_verifier='Demander la date de naissance des dirigeants.'}
        'omission' {$pistes=@($pistes | Where-Object {$_.theme -ne 'prix_service'})}
        'theme' {$pistes[0].theme='prix_service'}
    }
    return (@{observations=$observations;pistes=$pistes} | ConvertTo-Json -Depth 12 -Compress)
}
function Run-Report {
    $out=Main | Out-String
    $match=[regex]::Match($out,'vault/(reports|drafts)/([a-f0-9]{32})\.json')
    if(-not $match.Success){throw 'Rapport non enregistre'}
    return (Read-Text (Safe $match.Value) | ConvertFrom-Json)
}
$Model='mock';$Command='analyze';$CaseId='a';$Question='Analyser cette prestation de conseil entre societes';$AsOf='2026-10-21'
$report=Run-Report
Check 'corpus vide : aucun appel au modele' ($script:modelCalls -eq 0 -and $report.quality_status -eq 'sources_required')
Check 'collecte au lieu de conclusion' ($report.text.Contains('EXAMEN JURIDIQUE BLOQUE') -and $report.text.Contains('execution effective') -and -not $report.text.Contains('1356'))
$Command='draft';$blocked=Run-Report;$DraftId=$blocked.id;$Reviewer='Avocat test';$ExpectedHash=$blocked.content_hash;$Command='publish'
Reject 'projet sans sources non publiable' {Main}
foreach($topic in $script:LegalTopics.Keys){
    $law=[pscustomobject]@{id=('fixture-'+$topic);title=('TEST '+$topic);text=('SOURCE FICTIVE DE TEST UNIQUEMENT SANS VALEUR JURIDIQUE - '+$topic);url='https://www.legifrance.gouv.fr/';retrieved_at='2026-10-21';valid_from='2020-01-01';valid_to=$null;code='CODE FICTIF';article=('reference-'+$topic);topics=@($topic);reviewed_by='Relecteur fictif';reviewed_at='2026-10-21'}
    $law | Add-Member -NotePropertyName reviewed_hash -NotePropertyValue (Get-SourceFingerprint $law)
    Write-Json (Safe ('vault/law/'+$law.id+'.json')) $law
}
$loaded=@(Load-Laws);$one=$loaded[0]
Check 'source relue reconnue' (Test-ReviewedLaw $one)
$one.text+=' MODIFICATION'
Check 'modification invalide la relecture' (-not (Test-ReviewedLaw $one))
$plan=New-ReviewPlan 'Deux societes, conseil et facture sans devis signe'
Check 'commercial et prix obligatoires' ('preuve_commerciale' -in $plan.required -and 'prix_service' -in $plan.required)
$selected=@(Select-ReviewedLaws @(Load-Laws) $plan 'mot-sans-correspondance')
Check 'sources obligatoires hors mots cles retenues' (@(Missing-Topics $selected $plan).Count -eq 0)
$schema=New-AnswerSchema $selected @() $plan $true
Check 'schema de directives sans piece inventee' ($schema.properties.observations.maxItems -eq 0 -and $schema.properties.pistes.items.properties.piece.enum.Count -eq 1 -and $schema.properties.pistes.items.properties.piece.enum[0] -ceq '')
Reject 'ancien rapport libre non structure' {ConvertFrom-ModelReview 'Code civil art.1356 : preuve ecrite obligatoire au dela de 1225 euros.' $selected @() $plan 'contrat' $true}
$Command='analyze';$report=Run-Report
Check 'analyse structuree acceptee' ($report.quality_status -eq 'technical_checks_passed')
Check 'un seul dossier charge' ($lastPrompt.Contains('CLIENT_A') -and -not $lastPrompt.Contains('CLIENT_B_SECRET'))
Check 'expose non authentifie' ($report.text.Contains('Aucun fait n est declare prouve') -and $report.text.Contains('originaux mentionnes'))
foreach($fault in @('source','citation','piece','extrait','seuil','faits','naissance','omission','theme')){
    $script:fault=$fault;$report=Run-Report
    Check ("reponse bloquee : $fault") ($report.quality_status -eq 'blocked' -and $report.text.StartsWith('# EXAMEN JURIDIQUE BLOQUE'))
}
$script:fault='';$Command='draft';$draft=Run-Report
Check 'directives sans donnees de dossier' ($draft.quality_status -eq 'technical_checks_passed' -and -not $lastPrompt.Contains('CLIENT_A') -and -not $lastPrompt.Contains('CLIENT_B_SECRET'))
$DraftId=$draft.id;$Reviewer='Avocat test';$ExpectedHash='0'*64;$Command='publish'
Reject 'empreinte incorrecte' {Main}
$ExpectedHash=$draft.content_hash;$null=Main
Check 'publication controlee' ((Current-Guidelines).id -eq $DraftId)
Reject 'version non ecrasable' {Main}
$Command='draft';$newDraft=Run-Report
$DraftId=$newDraft.id;$ExpectedHash=$newDraft.content_hash;$Command='publish'
$changed=Read-Text (Safe 'vault/law/fixture-prix_service.json') | ConvertFrom-Json
$changed.text+=' CHANGEMENT';Write-Json (Safe 'vault/law/fixture-prix_service.json') $changed
Reject 'source modifiee bloque la publication' {Main}
Check 'directive aux sources modifiees exclue du contexte' (-not (Test-UsableGuidelines (Current-Guidelines) @(Load-Laws)))
Check 'ancien rapport masque' ((Get-ReportDisplay ([pscustomobject]@{text='CONTENU ANCIEN ERRONE'})) -notmatch 'CONTENU ANCIEN ERRONE')
Reject 'mauvais article de memoire' {Assert-FreeReasoning 'Si le Code civil article 2274 prevoit deux ans.' 'contrat'}
Reject 'collecte hors sujet' {Assert-FreeReasoning 'Verifier la convention collective applicable.' 'deux societes'}
"$passed controles reussis"
