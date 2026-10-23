param([string]$LocalModel='qwen3.5:4b')
# Evaluation reelle et reproductible : uniquement deux dossiers entierement fictifs.
$ErrorActionPreference='Stop'
. "$PSScriptRoot/agent.ps1"
$Root=Join-Path $PSScriptRoot ('.test-runs/evaluation-'+[guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($Root) | Out-Null
Ensure-Layout
$common=@'
DOSSIER ENTIEREMENT FICTIF POUR EVALUATION, sans donnees de client reel.
Client : Societe Alpha, qui conteste la demande de paiement.
Adversaire : Societe Beta, qui demande le paiement d une prestation de conseil.
Beta reclame 18 000 EUR. Sa facture est datee du 10 septembre 2026.
Les deux societes sont presentees comme commercantes ; qualification et nature commerciale a verifier.
'@
$variants=[ordered]@{
    reserves=@'
Alpha conteste avoir commande la mission ou accepte son prix.
Le courriel du 2 septembre 2026 dit : Envoyez-nous une proposition detaillee avant tout commencement.
Aucun devis signe, bon de commande ni livrable n est disponible dans ce dossier.
Seul cet expose est fourni ; les originaux des courriels et de la facture ne sont pas charges.
'@
    acceptation=@'
L expose rapporte qu Alpha a signe le bon de commande de la mission et accepte le prix de 18 000 EUR.
Le courriel du 2 septembre 2026 est suivi d une acceptation explicite de la proposition detaillee.
L expose rapporte qu Alpha a confirme par courriel la reception conforme de tous les livrables, sans reserve.
Alpha veut malgre tout soutenir qu elle n a jamais commande et qu aucun travail n a ete livre.
Seul cet expose est fourni ; les originaux du bon et des courriels ne sont pas charges. Leur autenticite reste a verifier.
'@
}
$Model=$LocalModel;$Command='deepen';$CaseDescription='';$Question='Identifier les moyens licites de defense d Alpha et les faiblesses de sa position, avec reponses adverses et actions precises.'
$results=@()
foreach($key in $variants.Keys){
    $CaseId=$key;[IO.Directory]::CreateDirectory((Safe ('vault/cases/'+$key))) | Out-Null
    [IO.File]::WriteAllText((Safe ('vault/cases/'+$key+'/expose.txt')),($common+"`n"+$variants[$key]),[Text.UTF8Encoding]::new($false))
    Write-Output "Appel reel Ollama : $key ($Model)"
    $out=Main | Out-String
    $match=[regex]::Match($out,'vault/reports/[a-f0-9]{32}\.json')
    if(-not $match.Success){throw 'Rapport absent'}
    $record=Read-Text (Safe $match.Value) | ConvertFrom-Json
    $arguments=@();$valid=$false
    if($null -ne $record.strategy){$arguments=@($record.strategy.arguments);$valid=($arguments.Count -eq 3 -and $record.strategy.rejected.Count -eq 0)}
    if(-not $valid){Write-Warning "Evaluation $key incomplete : $($record.model_note)"}
    $results+=@{cas=$key;path=(Safe $match.Value);arguments=$arguments;complete=$valid;inference=$record.inference}
    $arguments | Select-Object axe,evaluation,titre | Format-Table | Out-String | Write-Output
}
$a=$results[0];$b=$results[1]
Write-Json (Safe 'evaluation.json') @{model=$Model;results=$results}
if(-not $a.complete -or -not $b.complete){throw ('Evaluation incomplete ; rapports locaux : '+$Root)}
foreach($axis in @('accord','execution','prix')){if(@($a.arguments | Where-Object {$_.axe -eq $axis}).Count -ne 1 -or @($b.arguments | Where-Object {$_.axe -eq $axis}).Count -ne 1){throw "Axe absent : $axis"}}
$accordA=@($a.arguments | Where-Object {$_.axe -eq 'accord'})[0]
$accordB=@($b.arguments | Where-Object {$_.axe -eq 'accord'})[0]
$executionB=@($b.arguments | Where-Object {$_.axe -eq 'execution'})[0]
$checks=[ordered]@{
    reserve_met_la_commande_en_discussion=($accordA.evaluation -eq 'a_instruire')
    commande_acceptee_affaiblit_la_contestation=($accordB.evaluation -eq 'affaibli')
    reception_conforme_affaiblit_la_contestation=($executionB.evaluation -eq 'affaibli')
    analyse_accord_change=($accordA.application -cne $accordB.application -and $accordA.evaluation -ne $accordB.evaluation)
}
$summary=@{model=$Model;created_at=[datetime]::UtcNow.ToString('o');checks=$checks;results=$results;limite='Evaluation de sensibilite aux faits sur deux exposes fictifs, pas validation juridique independante.'}
Write-Json (Safe 'evaluation.json') $summary
Write-Output ($checks | ConvertTo-Json)
Write-Output ('Resultats locaux : '+(Safe 'evaluation.json'))
if(@($checks.Values | Where-Object {-not $_}).Count){throw 'Evaluation semantique echouee : examiner les rapports locaux avant utilisation.'}
