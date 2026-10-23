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
    return '{"arguments":[{"axe":"accord","constat":"acceptation_declaree","pieces":["p99-999"]}]}'
}
$Command='deepen';$report=Run-Report
Check 'echec du modele conserve la lecture' ($report.quality_status -eq 'dossier_ready' -and $report.text.Contains('pas ete retenu') -and $report.text.Contains('CLIENT_A'))
Check 'mode de qualification sans doctrine libre' ($script:capturedMode -eq 'strategy')
Check 'passage fictif non affiche' (-not $report.text.Contains('p99-999'))
function Ask-Local([string]$Prompt,$Schema,[string]$Mode,[int]$MaxTokens){
    $script:modelCalls++;$request=$Prompt | ConvertFrom-Json
    $script:validRaw=@{axe='accord';constat='contestation_declaree';pieces=@($request.passages[0].id)}
    return (@{arguments=@($script:validRaw)} | ConvertTo-Json -Depth 8)
}
$report=Run-Report
Check 'chaine pieces regle application objection action' ($report.model_called -and $report.strategy.arguments.Count -eq 1 -and $report.text.Contains('Reponse adverse a anticiper') -and $report.text.Contains('Action proposee'))
Check 'methode annoncee sans fausse libre consultation' ($report.text.Contains('Le modele ne redige pas de regles de droit libres'))
Check 'couverture incomplete annoncee' ($report.text.Contains('Couverture incomplete : execution, prix'))
Check 'empreinte des references conservee' ($report.reference_hash -match '^[a-f0-9]{64}$')
$cards=Load-ReferenceCards (New-ReviewPlan 'prestation conseil entre societes')
$valid=$script:validRaw
$data=@{arguments=@($valid)} | ConvertTo-Json -Depth 10 | ConvertFrom-Json
$data.arguments[0] | Add-Member -NotePropertyName fondement -NotePropertyValue 'article-invente'
$checked=Read-StrategyModel ($data | ConvertTo-Json -Depth 10) $bundle.pieces $cards
Check 'regle libre ajoutee par le modele refusee' ($checked.arguments.Count -eq 0 -and $checked.rejected.Count -eq 1)
$data=@{arguments=@($valid)} | ConvertTo-Json -Depth 10 | ConvertFrom-Json
$data.arguments[0] | Add-Member -NotePropertyName application -NotePropertyValue 'La dette est certaine et la charge est renversee.'
$checked=Read-StrategyModel ($data | ConvertTo-Json -Depth 10) $bundle.pieces $cards
Check 'ancienne prose juridique non acceptee' ($checked.arguments.Count -eq 0)
$invalid=@{arguments=@($valid)} | ConvertTo-Json -Depth 10 | ConvertFrom-Json
$invalid.arguments[0].axe='execution';$invalid.arguments[0].pieces=@('p99-999')
$checked=Read-StrategyModel (@{arguments=@($valid,$invalid.arguments[0])} | ConvertTo-Json -Depth 10) $bundle.pieces $cards
Check 'qualification valide conservee si une autre echoue' ($checked.arguments.Count -eq 1 -and $checked.rejected.Count -eq 1)
$samplePieces=@(@{name='cas.txt';text="Client : Alpha`nAdversaire : Beta`nCommande signee et prix accepte de 18 000 EUR.`nReception conforme des livrables acceptee.`nFacture datee du 10 septembre 2026.`nCourriel du 2 septembre 2026."})
$states=@{arguments=@(@{axe='accord';constat='acceptation_declaree';pieces=@('p1-3')},@{axe='execution';constat='acceptation_declaree';pieces=@('p1-4')},@{axe='prix';constat='acceptation_declaree';pieces=@('p1-3')})}
$checked=Read-StrategyModel ($states | ConvertTo-Json -Depth 8) $samplePieces $cards
Check 'acceptations affaiblissent les trois contestations generales' ($checked.arguments.Count -eq 3 -and @($checked.arguments | Where-Object {$_.evaluation -ne 'affaibli'}).Count -eq 0)
Check 'reception acceptee ne devient pas liberation par paiement' ($checked.arguments[1].application.Contains('ne demontre pas le paiement') -and -not $checked.arguments[1].application.Contains('Alpha se dit liberee'))
Check 'prix accepte exclut moyen du prix non convenu' ($checked.arguments[2].application.Contains('ne doit pas etre invoquee'))
$absencePieces=@(@{name='cas.txt';text='Aucun livrable n est disponible dans ce dossier.'})
$absence=@{arguments=@(@{axe='execution';constat='absence_documentaire';pieces=@('p1-1')})}
$checked=Read-StrategyModel ($absence | ConvertTo-Json -Depth 8) $absencePieces $cards
Check 'absence documentaire ne prouve pas inexécution' ($checked.arguments[0].evaluation -eq 'indetermine')
$wrong=@{arguments=@(@{axe='execution';constat='contestation_declaree';pieces=@('p1-4')})}
$checked=Read-StrategyModel ($wrong | ConvertTo-Json -Depth 8) $samplePieces $cards
Check 'reception explicite corrige une qualification incoherente du modele' ($checked.arguments[0].evaluation -eq 'affaibli' -and $checked.arguments[0].model_constat -eq 'contestation_declaree')
$intentPieces=@(@{name='cas.txt';text="DOSSIER FICTIF`nAlpha souhaite soutenir qu aucun travail n a ete livre."})
$intent=@{arguments=@(@{axe='execution';constat='contestation_declaree';pieces=@('p1-2')})}
$checked=Read-StrategyModel ($intent | ConvertTo-Json -Depth 8) $intentPieces $cards
Check 'souhait de nier ne devient pas preuve de non execution' ($checked.arguments.Count -eq 0)
$negatives=@(New-StrategyCatalog @(@{name='n.txt';text="Aucun bon de commande signe.`nLe prix n est pas accepte.`nAucune reception conforme n est etablie."}))
Check 'negations ne deviennent pas acceptations' ($null -eq (Get-ExplicitFinding 'accord' $negatives) -and $null -eq (Get-ExplicitFinding 'execution' $negatives) -and (Get-ExplicitFinding 'prix' $negatives).constat -ne 'acceptation_declaree')
$crossAxis=@(@{name='expose-test.txt';text="Le client conteste avoir accepte le prix ou le perimetre de la mission.`nUn courriel dit : Envoyez une proposition detaillee avant tout commencement.`nAucun devis signe, bon de commande, livrable ni justificatif de reception n'est disponible dans ce dossier."})
$wrongExecution=@{arguments=@(@{axe='execution';constat='contestation_declaree';pieces=@('p1-1','p1-2')})}
$checked=Read-StrategyModel ($wrongExecution | ConvertTo-Json -Depth 8) $crossAxis $cards
Check 'reserve sur commande et prix ne devient pas grief execution' ($checked.arguments.Count -eq 1 -and $checked.arguments[0].evaluation -eq 'indetermine')
Check 'absence de livrable citee pour le constat documentaire' ($checked.arguments[0].constat -eq 'absence_documentaire' -and 'p1-3' -in $checked.arguments[0].piece_ids)
Check 'appuis utiles separes des propositions du modele' ($checked.arguments[0].pieces.Count -eq 1 -and $checked.arguments[0].model_pieces.Count -eq 2)
$rendered=Render-Strategy $checked ([pscustomobject]@{pieces=$crossAxis}) $cards (New-ReviewPlan 'prestation conseil')
Check 'rapport ne suggere plus de grief execution non decrit' ($rendered.Contains('Evaluation : Indetermine') -and -not $rendered.Contains('Si les griefs de prestation relates'))
$unrelated=@(@{name='prix.txt';text='Le prix de la mission a ete accepte.'})
foreach($unsupported in @('acceptation_declaree','contestation_declaree','contradiction')){
    $raw=@{arguments=@(@{axe='execution';constat=$unsupported;pieces=@('p1-1')})}
    $checked=Read-StrategyModel ($raw | ConvertTo-Json -Depth 8) $unrelated $cards
    Check ("qualification execution sans appui suspendue : $unsupported") ($checked.arguments[0].evaluation -eq 'indetermine' -and $checked.arguments[0].constat -eq 'indetermine' -and $checked.arguments[0].model_constat -eq $unsupported)
}
$realGrief=@(@{name='grief.txt';text='Le client conteste la conformite des livrables remis.'})
$checked=Read-StrategyModel ($wrong | ConvertTo-Json -Depth 8).Replace('p1-4','p1-1') $realGrief $cards
Check 'grief de livrables conserve sur son propre axe' ($checked.arguments.Count -eq 1 -and $checked.arguments[0].evaluation -eq 'a_instruire')
$priceOnly=@(@{name='prix.txt';text='Le client conteste le prix de la prestation.'})
$raw=@{arguments=@(@{axe='execution';constat='contestation_declaree';pieces=@('p1-1')})}
$checked=Read-StrategyModel ($raw | ConvertTo-Json -Depth 8) $priceOnly $cards
Check 'mot prestation ne transforme pas litige prix en grief execution' ($checked.arguments[0].evaluation -eq 'indetermine')
$priceAndDefect=@(@{name='grief.txt';text='Le client conteste la conformite des livrables et leur prix.'})
$checked=Read-StrategyModel ($raw | ConvertTo-Json -Depth 8) $priceAndDefect $cards
Check 'grief concret conserve meme si prix mentionne' ($checked.arguments[0].evaluation -eq 'a_instruire')
$samplePoints=@(Get-FactualPoints $samplePieces)
Check 'montant et date de facture conserves' (@($samplePoints | Where-Object {$_.axe -eq 'montant' -and $_.extrait.Contains('18 000')}).Count -eq 1 -and @($samplePoints | Where-Object {$_.axe -eq 'chronologie' -and $_.extrait.Contains('10 septembre')}).Count -eq 1)
Check 'roles ancres dans les textes' (@(Get-PartyContext $samplePieces).Count -eq 2)
$CaseDescription='Description supplementaire fournie par le client.';$Command='analyze';$report=Run-Report
Check 'description separee de la question' (@($report.pieces | Where-Object {$_.name -eq 'description-utilisateur'}).Count -eq 1 -and $report.question -ceq $Question)
$Command='draft';$Question='Preparer des consignes de travail pour les prestations de conseil.';$draft=Run-Report
Check 'consignes distinguent organisation et droit' ($draft.quality_status -eq 'operational_ready' -and $draft.text.Contains('ne fixe aucune regle de droit'))
$Command='publish';$DraftId=$draft.id;$Reviewer='Avocat relecteur';$ExpectedHash=$draft.content_hash;$null=Main
Check 'publication operationnelle avec relecture' ((Current-Guidelines).id -eq $draft.id)
Reject 'import dans le dossier de demonstration refuse' {Import-CaseDocument 'demo-fictif' $source}
$mixed=[pscustomobject]@{pieces=@(@{name='expose.txt';text='DOSSIER ENTIEREMENT FICTIF - DEMONSTRATION'},@{name='reel.txt';text='Texte d une autre affaire.'})}
Check 'melange demonstration et autre affaire detecte' (Test-DemoMixture $mixed)
[IO.Directory]::CreateDirectory((Safe 'vault/cases/melange')) | Out-Null
[IO.File]::WriteAllText((Safe 'vault/cases/melange/expose.txt'),'DOSSIER ENTIEREMENT FICTIF - DEMONSTRATION : prestation de conseil.')
[IO.File]::WriteAllText((Safe 'vault/cases/melange/reel.txt'),'Texte d une autre affaire.')
$Command='deepen';$CaseId='melange';$CaseDescription='';$Question='Identifier les points a examiner.';$before=$script:modelCalls
$report=Run-Report
Check 'melange non envoye au modele et sans analyse des moyens' ($report.scope_status -eq 'mixed_demo' -and $report.quality_status -eq 'preparation_only' -and $script:modelCalls -eq $before -and $null -eq $report.strategy -and $report.references.Count -eq 0)
[IO.Directory]::CreateDirectory((Safe 'vault/cases/autre')) | Out-Null
[IO.File]::WriteAllText((Safe 'vault/cases/autre/voisin.txt'),'Un voisin entre dans un jardin prive. La famille demande une mesure de protection.')
$CaseId='autre';$before=$script:modelCalls;$report=Run-Report
Check 'autre domaine ne devient pas une prestation de service' ($report.scope_status -eq 'outside_service_scope' -and $script:modelCalls -eq $before -and $null -eq $report.strategy -and -not $report.text.Contains('article 1165') -and $report.text.Contains('Un voisin entre'))
Check 'ancienne qualification signalee comme historique' ((Get-ReportDisplay ([pscustomobject]@{quality_version=$script:QualityVersion;strategy_version='2026-10-23.2';strategy=@{};text='ANCIEN TEXTE'})).StartsWith('RAPPORT HISTORIQUE'))
