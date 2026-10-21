$Command='analyze';$CaseId='a';$Question='Examiner la prestation de conseil et les pieces manquantes.';$CaseDescription=''
$before=$script:modelCalls
$report=Run-Report
Check 'premiere lecture sans precondition de corpus' ($report.quality_status -eq 'dossier_ready' -and $script:modelCalls -eq $before)
Check 'rapport utilisable au lieu du blocage' ($report.text.StartsWith('# DOSSIER') -and -not $report.text.Contains('EXAMEN JURIDIQUE BLOQUE'))
Check 'references de depart presentes' ($report.references.Count -ge 5 -and $report.text.Contains('article L110-3') -and $report.text.Contains('article 1165'))
Check 'documents ancres au dossier' ($report.text.Contains('CLIENT_A') -and -not $report.text.Contains('CLIENT_B_SECRET'))
Check 'aucune source presentee comme relecture avocat' ($report.text.Contains('Reformulations') -and -not $report.text.Contains('Relecture declaree'))
$source=Safe 'input.txt'
[IO.File]::WriteAllText($source,"Le montant est 18000 EUR.`nCourriel du 2 septembre 2026 : demander une proposition avant commencement.")
$first=Import-CaseDocument 'a' $source
$second=Import-CaseDocument 'a' $source
Check 'import identique sans creation de doublon' ($first.added -and -not $second.added -and $first.name -ceq $second.name)
[IO.File]::Copy((Safe ('vault/cases/a/'+$first.name)),(Safe 'vault/cases/a/ancienne-copie.txt'))
$bundle=Read-CaseBundle 'a' '' 'Demande de travail'
Check 'anciens doublons regroupes sans suppression' ($bundle.duplicates.Count -eq 1 -and $bundle.pieces.Count -eq 2 -and (Test-Path -LiteralPath (Safe 'vault/cases/a/ancienne-copie.txt')))
$points=@(Get-FactualPoints $bundle.pieces)
Check 'montant non traite comme date' (@($points | Where-Object {$_.axe -eq 'chronologie' -and $_.extrait -ceq 'Le montant est 18000 EUR.'}).Count -eq 0)
Check 'date de courriel reperee' (@($points | Where-Object {$_.axe -eq 'chronologie' -and $_.extrait.Contains('2 septembre')}).Count -gt 0)
Reject 'extrait fictif du complement refuse' {Read-FactualModel '{"points":[{"axe":"accord","piece":"facture-originale.txt","extrait":"FAUX"}]}' $bundle.pieces}
function Ask-Local([string]$Prompt,$Schema,[string]$Mode,[int]$MaxTokens){
    $script:modelCalls++;$script:capturedMode=$Mode
    return '{"points":[{"axe":"accord","piece":"facture-inventee.txt","extrait":"FAUX"}]}'
}
$Command='deepen';$report=Run-Report
Check 'echec du modele conserve la lecture' ($report.quality_status -eq 'dossier_ready' -and $report.text.Contains('pas ete retenu') -and $report.text.Contains('CLIENT_A'))
Check 'complement sans consigne de consultation juridique' ($script:capturedMode -eq 'factual')
Check 'sortie fautive non affichee' (-not $report.text.Contains('facture-inventee') -and -not $report.text.Contains('FAUX'))
function Ask-Local([string]$Prompt,$Schema,[string]$Mode,[int]$MaxTokens){
    $script:modelCalls++;$request=$Prompt | ConvertFrom-Json
    return (@{points=@(@{axe='accord';piece=$request.pieces[0].name;extrait=$request.pieces[0].text})} | ConvertTo-Json -Depth 6)
}
$report=Run-Report
Check 'complement exact accepte' ($report.model_note.Contains('controlee') -and $report.model_called)
$CaseDescription='Description supplementaire fournie par le client.';$Command='analyze';$report=Run-Report
Check 'description separee de la question' (@($report.pieces | Where-Object {$_.name -eq 'description-utilisateur'}).Count -eq 1 -and $report.question -ceq $Question)
$Command='draft';$Question='Preparer des consignes de travail pour les prestations de conseil.';$draft=Run-Report
Check 'consignes distinguent organisation et droit' ($draft.quality_status -eq 'operational_ready' -and $draft.text.Contains('ne fixe aucune regle de droit'))
$Command='publish';$DraftId=$draft.id;$Reviewer='Avocat relecteur';$ExpectedHash=$draft.content_hash;$null=Main
Check 'publication operationnelle avec relecture' ((Current-Guidelines).id -eq $draft.id)
