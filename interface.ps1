param([switch]$Installation,[switch]$SmokeTest)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Net.Http
[Windows.Forms.Application]::EnableVisualStyles()
. "$PSScriptRoot/agent.ps1"
Ensure-Layout
foreach($directory in @('vault/ui','vault/descriptions')) { [IO.Directory]::CreateDirectory((Safe $directory)) | Out-Null }
$script:busy=$false; $script:job=$null; $script:cases=@(); $script:drafts=@(); $script:reports=@()
function Message([string]$Text) { [Windows.Forms.MessageBox]::Show($Text,'Assistant juridique local',[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Information) | Out-Null }
function Guard([scriptblock]$Action) { try { & $Action } catch { Message $_.Exception.Message } }
function Button($Parent,$Text,$X,$Y,$Width=180) {
    $b=[Windows.Forms.Button]::new(); $b.Text=$Text; $b.SetBounds($X,$Y,$Width,34); $Parent.Controls.Add($b); return $b
}
function Label($Parent,$Text,$X,$Y,$Width=850,$Height=40) {
    $l=[Windows.Forms.Label]::new(); $l.Text=$Text; $l.SetBounds($X,$Y,$Width,$Height); $Parent.Controls.Add($l); return $l
}
function Box($Parent,$X,$Y,$Width,$Height,[bool]$ReadOnly=$false) {
    $t=[Windows.Forms.TextBox]::new(); $t.Multiline=$true; $t.ScrollBars='Vertical'; $t.ReadOnly=$ReadOnly; $t.SetBounds($X,$Y,$Width,$Height); $Parent.Controls.Add($t); return $t
}
function List($Parent,$X,$Y,$Width=850) {
    $c=[Windows.Forms.ComboBox]::new(); $c.DropDownStyle='DropDownList'; $c.SetBounds($X,$Y,$Width,30); $Parent.Controls.Add($c); return $c
}
$form=[Windows.Forms.Form]::new(); $form.Text='Cabinet — Assistant juridique confidentiel'; $form.ClientSize=[Drawing.Size]::new(1020,790)
$form.MinimumSize=[Drawing.Size]::new(1040,830); $form.StartPosition='CenterScreen'; $form.Font=[Drawing.Font]::new('Segoe UI',10)
$form.BackColor=[Drawing.Color]::FromArgb(245,247,250)
$null=Label $form 'ASSISTANT JURIDIQUE LOCAL' 24 15 950 30
$null=Label $form 'Droit français • Documents sur ce poste • Validation par un avocat avant utilisation' 24 48 960 25
$tabs=[Windows.Forms.TabControl]::new(); $tabs.SetBounds(20,90,980,640); $tabs.Anchor='Top,Bottom,Left,Right'; $form.Controls.Add($tabs)
$pages=@{}
foreach($name in @('Mes dossiers','Rapports','Directives du cabinet','Sources juridiques','Installation et aide')) {
    $p=[Windows.Forms.TabPage]::new(); $p.Text=$name; $p.BackColor=[Drawing.Color]::White; $tabs.TabPages.Add($p); $pages[$name]=$p
}
$status=Label $form 'Prêt. Commencez par Installation et aide lors de la première utilisation.' 24 741 960 40
$status.Anchor='Bottom,Left,Right'
$page=$pages['Mes dossiers']
$null=Label $page '1. Choisir ou créer un dossier' 20 15 900 25
$caseList=List $page 20 45 630
$newCase=Button $page 'Nouveau dossier' 670 42 240
$null=Label $page '2. Ajouter les pièces ou décrire les faits (vous pouvez faire les deux)' 20 88 900 25
$import=Button $page 'Ajouter des documents…' 20 120 260
$pieceCount=Label $page 'Formats acceptés : .txt et .md. Convertir les PDF/Word localement.' 300 126 620 40
$description=Box $page 20 172 890 140
$null=Label $page '3. Que souhaitez-vous examiner ?' 20 325 900 25
$questionInput=Box $page 20 355 890 65
$questionInput.Text='Identifier les moyens licites de défense, les faiblesses de la demande adverse et les preuves manquantes.'
$null=Label $page 'Modèle local' 20 435 150 25
$models=List $page 170 432 440
$refresh=Button $page 'Actualiser' 630 428 130
$analyze=Button $page 'Première lecture rapide' 20 485 260
$deepen=Button $page 'Analyser les arguments' 300 485 280
$null=Label $page 'Première lecture immédiate. Analyser les arguments confronte les pièces aux fiches avec Ollama : plusieurs minutes possibles.' 20 535 880 55
$page=$pages['Rapports']
$reportList=List $page 20 20 890
$reportText=Box $page 20 65 890 465 $true
$reportText.Font=[Drawing.Font]::new('Segoe UI',10)
$export=Button $page 'Enregistrer une copie…' 20 548 250
$null=Label $page 'Brouillons non vérifiés : confronter les faits aux pièces originales et les fondements aux sources officielles.' 290 550 620 50
$page=$pages['Directives du cabinet']
$null=Label $page 'Préparer une consigne commune au cabinet (aucun dossier client nʼest chargé)' 20 15 900 35
$directiveQuestion=Box $page 20 55 890 60
$directiveQuestion.Text='Préparer les directives communes sur la conservation des preuves et la revue des dossiers.'
$draftButton=Button $page 'Préparer un projet' 20 128 240
$currentButton=Button $page 'Voir la version en vigueur' 280 128 280
$draftList=List $page 20 177 890
$directiveText=Box $page 20 215 890 270 $true
$null=Label $page 'Nom de lʼavocat qui valide' 20 500 300 25
$reviewerInput=[Windows.Forms.TextBox]::new(); $reviewerInput.SetBounds(320,498,340,30); $page.Controls.Add($reviewerInput)
$approve=[Windows.Forms.CheckBox]::new(); $approve.Text='Jʼai relu ce texte et vérifié ses fondements. Publication locale uniquement.'; $approve.SetBounds(20,535,890,28); $page.Controls.Add($approve)
$publish=Button $page 'Valider et publier' 20 570 240
$page=$pages['Sources juridiques']
$null=Label $page 'Six fiches de départ sont déjà fournies. Ajouter des textes est facultatif pour la première lecture.' 20 15 590 50
$showReferences=Button $page 'Voir les fiches fournies' 630 15 280
$sourceTitle=[Windows.Forms.TextBox]::new(); $sourceTitle.SetBounds(180,80,730,28); $page.Controls.Add($sourceTitle); $null=Label $page 'Titre / article' 20 83 150 25
$sourceUrl=[Windows.Forms.TextBox]::new(); $sourceUrl.SetBounds(180,120,730,28); $page.Controls.Add($sourceUrl); $null=Label $page 'Lien officiel HTTPS' 20 123 160 25
$null=Label $page 'Applicable du' 20 165 130 25
$from=[Windows.Forms.DateTimePicker]::new(); $from.Format='Short'; $from.SetBounds(180,160,180,30); $page.Controls.Add($from)
$null=Label $page 'au (facultatif)' 400 165 160 25
$until=[Windows.Forms.DateTimePicker]::new(); $until.Format='Short'; $until.ShowCheckBox=$true; $until.Checked=$false; $until.SetBounds(580,160,210,30); $page.Controls.Add($until)
$null=Label $page 'Coller le texte officiel intégral vérifié par le cabinet' 20 205 890 30
$sourceText=Box $page 20 240 890 125
$null=Label $page 'Code / juridiction' 20 382 160 25
$sourceCode=[Windows.Forms.TextBox]::new();$sourceCode.SetBounds(180,377,330,28);$page.Controls.Add($sourceCode)
$null=Label $page 'Article / référence' 530 382 170 25
$sourceArticle=[Windows.Forms.TextBox]::new();$sourceArticle.SetBounds(710,377,200,28);$page.Controls.Add($sourceArticle)
$null=Label $page 'Questions effectivement couvertes par ce texte (à vérifier, sans cocher par défaut)' 20 412 890 25
$sourceTopics=[Windows.Forms.CheckedListBox]::new();$sourceTopics.SetBounds(20,440,890,64);$sourceTopics.MultiColumn=$true;$sourceTopics.ColumnWidth=285;$sourceTopics.CheckOnClick=$true;$page.Controls.Add($sourceTopics)
$script:topicKeys=@($script:LegalTopics.Keys)
foreach($key in $script:topicKeys){$sourceTopics.Items.Add($script:LegalTopicTitles[$key]) | Out-Null}
$null=Label $page 'Avocat relecteur' 20 515 180 25
$sourceReviewer=[Windows.Forms.TextBox]::new();$sourceReviewer.SetBounds(210,510,390,28);$page.Controls.Add($sourceReviewer)
$sourceReviewed=[Windows.Forms.CheckBox]::new();$sourceReviewed.Text='Jʼai comparé le texte, le code, la référence, les dates et les thèmes avec la source officielle.';$sourceReviewed.SetBounds(20,540,890,28);$page.Controls.Add($sourceReviewed)
$saveSource=Button $page 'Vérifier et enregistrer' 20 575 260
$sourceSummary=Label $page '' 300 577 610 28
$page=$pages['Installation et aide']
$null=Label $page 'Première utilisation : cliquez sur Préparer ce poste, puis attendez le message de confirmation.' 20 20 890 55
$setup=Button $page 'Préparer ce poste' 20 82 260
$check=Button $page 'Vérifier ce poste' 300 82 230
$diagnostic=Box $page 20 135 890 160 $true
$helpText=Box $page 20 315 890 270 $true
$helpText.Text=@'
AU QUOTIDIEN
1. Ouvrir Mes dossiers et créer un dossier.
2. Ajouter les documents TXT/MD, ou écrire les faits dans la grande zone.
3. Cliquer sur Analyser les arguments et patienter ; lire le résultat dans Rapports.
4. Pour un aperçu immédiat sans modèle : Première lecture rapide (extraits et questions seulement).
5. Faire vérifier les conclusions juridiques par un avocat avant toute décision.

La première lecture fonctionne sans modèle et sans ajouter de textes de loi. Six fiches publiques de référence sont incluses. Les doublons sont regroupés sans supprimer vos fichiers.

INSTALLATION
La préparation réutilise Ollama et les modèles déjà présents. Si nécessaire, elle installe Ollama avec le gestionnaire Windows et télécharge un modèle public (plusieurs Go). Internet est nécessaire pour cette étape, jamais pour envoyer les pièces.

CONFIDENTIALITÉ
Les données restent dans le sous-dossier vault de cette application. Ne pas placer ce dossier sur OneDrive ou un autre service de synchronisation. Cette interface utilise les droits de votre session Windows : elle nʼest pas un bac à sable du système. Pour le cloisonnement renforcé, faire configurer le déploiement isolé par le responsable informatique.

ARRÊT
Fermer cette fenêtre après la fin du traitement. Aucun rapport ne devient automatiquement une directive du cabinet.
'@
function Refresh-Cases {
    $caseList.Items.Clear(); $script:cases=@(Get-ChildItem -LiteralPath (Safe 'vault/cases') -Directory)
    foreach($c in $script:cases) { $null=Assert-SafePath $c.FullName; $label=$c.Name; $meta=Safe ('vault/ui/case-'+$c.Name+'.json'); if(Test-Path -LiteralPath $meta) {$label=(Read-Text $meta | ConvertFrom-Json).name}; $caseList.Items.Add($label) | Out-Null }
    if($caseList.Items.Count) {$caseList.SelectedIndex=0}
}
function Selected-Case {
    if($caseList.SelectedIndex -lt 0) {throw 'Créer ou sélectionner un dossier pour continuer.'}
    return $script:cases[$caseList.SelectedIndex].Name
}
function Refresh-Models {
    $handler=[Net.Http.HttpClientHandler]::new(); $handler.UseProxy=$false; $handler.AllowAutoRedirect=$false
    $client=[Net.Http.HttpClient]::new($handler); $client.Timeout=[TimeSpan]::FromSeconds(15)
    try {
        $r=$client.GetAsync('http://127.0.0.1:11434/api/tags').GetAwaiter().GetResult(); $r.EnsureSuccessStatusCode() | Out-Null
        $tags=$r.Content.ReadAsStringAsync().GetAwaiter().GetResult() | ConvertFrom-Json
        $models.Items.Clear()
        foreach($m in $tags.models) {if($m.name -notmatch '(?i)cloud|https?') {$models.Items.Add($m.name) | Out-Null}}
        if($models.Items.Count) {$models.SelectedIndex=0; for($i=0;$i -lt $models.Items.Count;$i++){if($models.Items[$i] -eq 'qwen3.5:4b'){$models.SelectedIndex=$i}}}
        $diagnostic.Text="Ollama : disponible sur ce poste.`r`nModèles locaux : $($models.Items.Count).`r`nSix fiches de référence fournies ; première lecture disponible sans modèle.`r`nDonnées : $Root\vault`r`nInterface native : contrôles applicatifs, sans isolation système."
        if(-not $models.Items.Count){$diagnostic.AppendText("`r`nCliquer sur Préparer ce poste pour télécharger le modèle.")}
    } catch {$diagnostic.Text='Ollama ne répond pas pour le moment. Attendre la fin du traitement en cours, puis cliquer sur Vérifier ce poste. Si le problème persiste, contacter le responsable informatique.'}
    finally {$client.Dispose();$handler.Dispose()}
    try{$laws=@(Load-Laws);$reviewed=@($laws | Where-Object {Test-ReviewedLaw $_});$sourceSummary.Text="$($reviewed.Count) source(s) complémentaire(s) relue(s)."}
    catch{$sourceSummary.Text='Une source complémentaire est invalide. La première lecture reste disponible.'}
}
function Refresh-Results {
    $reportList.Items.Clear(); $script:reports=@(Get-ChildItem -LiteralPath (Safe 'vault/reports') -Filter '*.json' -File | Sort-Object LastWriteTime -Descending)
    foreach($r in $script:reports){
        $data=Read-Text $r.FullName | ConvertFrom-Json
        $kind='Première lecture'
        if((Has-Field $data 'strategy') -and $null -ne $data.strategy){$kind="Arguments : $($data.strategy.arguments.Count) moyen(s)"}
        elseif((Has-Field $data 'model_called') -and $data.model_called){$kind='Première lecture — sans raisonnement retenu'}
        $reportList.Items.Add("$($r.LastWriteTime.ToString('dd/MM/yyyy HH:mm')) — $($data.case_id) — $kind") | Out-Null
    }
    if($reportList.Items.Count){$reportList.SelectedIndex=0}
    $draftList.Items.Clear(); $script:drafts=@(Get-ChildItem -LiteralPath (Safe 'vault/drafts') -Filter '*.json' -File | Sort-Object LastWriteTime -Descending)
    foreach($d in $script:drafts){$draftList.Items.Add("Projet du $($d.LastWriteTime.ToString('dd/MM/yyyy HH:mm')) — $($d.BaseName.Substring(0,8))") | Out-Null}
    if($draftList.Items.Count){$draftList.SelectedIndex=0}
}
function Start-Work([string]$Operation,[hashtable]$Extra=@{}) {
    if($script:busy){throw 'Un traitement est déjà en cours. Attendre sa fin.'}
    if($Operation -eq 'deepen' -and $models.SelectedIndex -lt 0){throw 'Aucun modèle local disponible. La première lecture reste accessible ; préparer Ollama dans Installation et aide pour le complément.'}
    $uid=[guid]::NewGuid().ToString('N')
    $req=@{command=$Operation;question='';case_description='';case_id='';model=[string]$models.SelectedItem;draft_id='';reviewer='';expected_hash='';as_of=(Get-Date -Format 'yyyy-MM-dd')}
    foreach($key in $Extra.Keys){$req[$key]=$Extra[$key]}
    Write-Json (Safe ('vault/ui/'+$uid+'.request.json')) $req
    $scriptFile=if($Operation -eq 'install'){'installation.ps1'}else{'travail.ps1'}
    $args=@('-NoProfile','-ExecutionPolicy','Bypass','-File',('"'+(Join-Path $PSScriptRoot $scriptFile)+'"'),'-RequestId',$uid)
    $p=Start-Process -FilePath 'powershell.exe' -ArgumentList $args -WindowStyle Hidden -PassThru
    $script:job=@{id=$uid;process=$p;operation=$Operation;started=(Get-Date)}; $script:busy=$true
    $status.Text='Traitement local en cours… Merci de patienter sans fermer la fenêtre.'
    foreach($button in @($analyze,$deepen,$draftButton,$publish,$saveSource,$setup,$newCase,$import)){$button.Enabled=$false}
}
$newCase.Add_Click({Guard {
    $dialog=[Windows.Forms.Form]::new(); $dialog.Text='Nouveau dossier'; $dialog.ClientSize=[Drawing.Size]::new(440,145); $dialog.StartPosition='CenterParent'
    $null=Label $dialog 'Nom du dossier (sans nom complet de client si possible)' 12 12 410 35
    $name=[Windows.Forms.TextBox]::new(); $name.SetBounds(12,48,410,28); $dialog.Controls.Add($name)
    $ok=Button $dialog 'Créer' 260 92 160; $ok.DialogResult='OK'; $dialog.AcceptButton=$ok
    if($dialog.ShowDialog($form) -eq 'OK') {
        if([string]::IsNullOrWhiteSpace($name.Text) -or $name.Text.Length -gt 120){throw 'Saisir un nom de 1 à 120 caractères.'}
        $cid='dossier-'+[guid]::NewGuid().ToString('N').Substring(0,12)
        [IO.Directory]::CreateDirectory((Safe ('vault/cases/'+$cid))) | Out-Null
        Write-Json (Safe ('vault/ui/case-'+$cid+'.json')) @{name=$name.Text}
        Refresh-Cases; for($i=0;$i -lt $script:cases.Count;$i++){if($script:cases[$i].Name -eq $cid){$caseList.SelectedIndex=$i}}
    }; $dialog.Dispose()
}})
$caseList.Add_SelectedIndexChanged({Guard {
    $cid=Selected-Case; $saved=Safe ('vault/descriptions/'+$cid+'.txt')
    $description.Text=if(Test-Path -LiteralPath $saved){Read-Text $saved}else{''}
    $count=@(Get-ChildItem -LiteralPath (Safe ('vault/cases/'+$cid)) -File).Count
    $pieceCount.Text="$count pièce(s) locale(s). Formats : TXT et MD."
}})
$import.Add_Click({Guard {
    $cid=Selected-Case; $d=[Windows.Forms.OpenFileDialog]::new(); $d.Multiselect=$true; $d.Filter='Documents texte (*.txt;*.md)|*.txt;*.md'
    if($d.ShowDialog() -eq 'OK') {
        $added=0;$already=0
        foreach($source in $d.FileNames){
            $result=Import-CaseDocument $cid $source
            if($result.added){$added++}else{$already++}
        }
        $pieceCount.Text="$added document(s) ajouté(s), $already déjà présent(s). Aucun doublon créé."
    };$d.Dispose()
}})
function Start-CaseWork([string]$Operation) {
    $cid=Selected-Case
    if($description.Text.Length -gt 20000){throw 'Description trop longue : 20 000 caractères maximum.'}
    [IO.File]::WriteAllText((Safe ('vault/descriptions/'+$cid+'.txt')),$description.Text,[Text.UTF8Encoding]::new($false))
    Start-Work $Operation @{case_id=$cid;question=$questionInput.Text;case_description=$description.Text}
}
$analyze.Add_Click({Guard {Start-CaseWork 'analyze'}})
$deepen.Add_Click({Guard {Start-CaseWork 'deepen'}})
$reportList.Add_SelectedIndexChanged({Guard {if($reportList.SelectedIndex -ge 0){$r=Read-Text $script:reports[$reportList.SelectedIndex].FullName | ConvertFrom-Json; $reportText.Text=Get-ReportDisplay $r}}})
$draftList.Add_SelectedIndexChanged({Guard {$approve.Checked=$false;if($draftList.SelectedIndex -ge 0){$r=Read-Text $script:drafts[$draftList.SelectedIndex].FullName | ConvertFrom-Json;$directiveText.Text=Get-ReportDisplay $r}}})
$draftButton.Add_Click({Guard {Start-Work 'draft' @{question=$directiveQuestion.Text}}})
$currentButton.Add_Click({Guard {$c=Current-Guidelines; $directiveText.Text=if($null -eq $c){'Aucune directive en vigueur.'}else{Get-ReportDisplay $c};$approve.Checked=$false;$draftList.SelectedIndex=-1}})
$publish.Add_Click({Guard {
    if($draftList.SelectedIndex -lt 0 -or -not $approve.Checked -or [string]::IsNullOrWhiteSpace($reviewerInput.Text)){throw 'Sélectionner un projet, saisir le nom du relecteur et cocher la confirmation de relecture.'}
    $d=Read-Text $script:drafts[$draftList.SelectedIndex].FullName | ConvertFrom-Json
    if($directiveText.Text -cne $d.text){throw 'Le texte affiché ne correspond plus au projet. Le sélectionner à nouveau.'}
    Start-Work 'publish' @{draft_id=$d.id;reviewer=$reviewerInput.Text;expected_hash=(Hash $d.text)}
}})
$export.Add_Click({Guard {
    if($reportList.SelectedIndex -lt 0){throw 'Sélectionner un rapport.'}
    $d=[Windows.Forms.SaveFileDialog]::new();$d.Filter='Texte UTF-8 (*.txt)|*.txt';$d.FileName='rapport-a-verifier.txt'
    if($d.ShowDialog() -eq 'OK'){[IO.File]::WriteAllText($d.FileName,$reportText.Text,[Text.UTF8Encoding]::new($true))};$d.Dispose()
}})
$saveSource.Add_Click({Guard {
    if([string]::IsNullOrWhiteSpace($sourceTitle.Text) -or [string]::IsNullOrWhiteSpace($sourceText.Text) -or [string]::IsNullOrWhiteSpace($sourceCode.Text) -or [string]::IsNullOrWhiteSpace($sourceArticle.Text)){throw 'Renseigner le titre, le code, la référence et le texte officiel.'}
    if(-not $sourceReviewed.Checked -or [string]::IsNullOrWhiteSpace($sourceReviewer.Text) -or $sourceTopics.CheckedIndices.Count -eq 0){throw 'Vérifier la source, choisir ses thèmes et indiquer lʼavocat relecteur avant de confirmer.'}
    if(-not (Official $sourceUrl.Text)){throw 'Utiliser un lien HTTPS officiel autorisé (par exemple www.legifrance.gouv.fr).'}
    if($until.Checked -and $until.Value.Date -lt $from.Value.Date){throw 'La fin de validité précède son début.'}
    $sid='source-'+[guid]::NewGuid().ToString('N')
    $source=[pscustomobject]@{id=$sid;title=$sourceTitle.Text;url=$sourceUrl.Text;retrieved_at=(Get-Date -Format 'yyyy-MM-dd');valid_from=$from.Value.ToString('yyyy-MM-dd');valid_to=$(if($until.Checked){$until.Value.ToString('yyyy-MM-dd')}else{$null});text=$sourceText.Text;code=$sourceCode.Text;article=$sourceArticle.Text;topics=@($sourceTopics.CheckedIndices | ForEach-Object {$script:topicKeys[$_]});reviewed_by=$sourceReviewer.Text;reviewed_at=(Get-Date -Format 'yyyy-MM-dd')}
    $source | Add-Member -NotePropertyName reviewed_hash -NotePropertyValue (Get-SourceFingerprint $source)
    Write-Json (Safe ('vault/law/'+$sid+'.json')) $source
    $sourceReviewed.Checked=$false;Refresh-Models;Message 'Source enregistrée avec son empreinte de relecture. Cette déclaration locale nʼest pas une authentification indépendante.'
}})
$setup.Add_Click({Guard {Start-Work 'install'}})
$showReferences.Add_Click({Guard {
    $dialog=[Windows.Forms.Form]::new();$dialog.Text='Fiches de référence fournies';$dialog.ClientSize=[Drawing.Size]::new(850,630);$dialog.StartPosition='CenterParent'
    $text=Box $dialog 15 15 820 600 $true
    $corpus=[IO.File]::ReadAllText($script:ReferencePath,[Text.Encoding]::UTF8) | ConvertFrom-Json
    $lines=@("Fiches préparées le $($corpus.prepared_at). Reformulations documentaires, sans validation avocat automatique.",'')
    foreach($r in $corpus.references){$lines+=@($r.title,$r.note,$r.url,'')}
    $text.Text=$lines -join "`r`n";$dialog.ShowDialog($form) | Out-Null;$dialog.Dispose()
}})
$check.Add_Click({Guard {Refresh-Models}});$refresh.Add_Click({Guard {Refresh-Models}})
$timer=[Windows.Forms.Timer]::new();$timer.Interval=1000
$timer.Add_Tick({Guard {
    if(-not $script:busy){return}
    $elapsed=[int]((Get-Date)-$script:job.started).TotalSeconds
    $status.Text="Traitement local en cours — $elapsed secondes. Merci de patienter."
    $result=Safe ('vault/ui/'+$script:job.id+'.result.json')
    if(Test-Path -LiteralPath $result){
        $r=Read-Text $result | ConvertFrom-Json; $operation=$script:job.operation
        $script:busy=$false;foreach($button in @($analyze,$deepen,$draftButton,$publish,$saveSource,$setup,$newCase,$import)){$button.Enabled=$true};$status.Text=if($r.ok){'Traitement terminé.'}else{'Le traitement a échoué. Consulter le message.'}
        Refresh-Results
        if($r.ok -and $operation -in @('analyze','deepen')){$tabs.SelectedTab=$pages['Rapports']}
        elseif($r.ok -and $operation -eq 'draft'){$tabs.SelectedTab=$pages['Directives du cabinet']}
        elseif($operation -eq 'install'){Refresh-Models;Message $r.message}
        else{Message $r.message}
    }elseif($script:job.process.HasExited){$script:busy=$false;foreach($button in @($analyze,$deepen,$draftButton,$publish,$saveSource,$setup,$newCase,$import)){$button.Enabled=$true};$status.Text='Traitement interrompu.';Message 'Le processus a été interrompu sans résultat. La première lecture reste accessible dans Rapports.'}
}})
$form.Add_FormClosing({param($sender,$eventArgs) if($script:busy){$eventArgs.Cancel=$true;Message 'Attendre la fin du traitement avant de fermer.'}})
Guard {Refresh-Cases;Refresh-Results;Refresh-Models}
if($Installation -or $models.Items.Count -eq 0){$tabs.SelectedTab=$pages['Installation et aide']}
if($SmokeTest){Write-Output "Interface française créée : $($tabs.TabPages.Count) onglets, $($models.Items.Count) modèle(s) local(aux).";$form.Dispose();exit 0}
if($Installation){$form.Add_Shown({Guard {Start-Work 'install'}})}
$timer.Start()
[Windows.Forms.Application]::Run($form)
$timer.Dispose();$form.Dispose()
