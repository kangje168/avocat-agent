# Le modele classe les passages ; le cadre d analyse ne genere aucune regle de droit libre.
function New-StrategyCatalog($Pieces) {
    $items=@();$index=0
    foreach($p in $Pieces){$index++;$part=0
        foreach($line in @($p.text -split "`r?`n")){
            for($offset=0;$offset -lt $line.Length;$offset+=700){
                $text=$line.Substring($offset,[Math]::Min(700,$line.Length-$offset))
                if([string]::IsNullOrWhiteSpace($text)){continue}
                $intent=(Normalize-ReviewText $text) -match '\b(souhaite|veut|envisage|entend)\b.{0,100}\b(contest|soutenir|nier|invoqu|argu)'
                $part++;$items+=@{id="p$index-$part";piece=$p.name;extrait=$text;intention_argumentative=$intent}
            }
        }
    }
    return @($items)
}
function Get-PartyContext($Pieces) {
    $roles=@()
    foreach($p in $Pieces){foreach($line in @($p.text -split "`r?`n")){
        if($line -match '^\s*(Client|Adversaire|Demandeur|D[eé]fendeur)\s*:'){$roles+=@{piece=$p.name;extrait=$line}}
    }}
    return @($roles)
}
function New-StrategySchema($Pieces,$Cards) {
    return @{type='object';additionalProperties=$false;required=@('arguments');properties=@{arguments=@{type='array';minItems=3;maxItems=3;items=@{type='object';additionalProperties=$false;required=@('axe','constat','pieces');properties=@{
        axe=@{type='string';enum=@('accord','execution','prix')}
        constat=@{type='string';enum=@('acceptation_declaree','contestation_declaree','absence_documentaire','contradiction','indetermine')}
        pieces=@{type='array';minItems=1;maxItems=4;items=@{type='string';enum=@(New-StrategyCatalog $Pieces | Where-Object {-not $_.intention_argumentative} | ForEach-Object {$_.id})}}
    }}}}}
}
function Get-ExplicitFinding([string]$Axis,$Catalog) {
    # Indices textuels limites, jamais authentification ni qualification juridique.
    $positive=@();$negative=@()
    foreach($p in $Catalog){
        if($p.intention_argumentative){continue}
        $text=(Normalize-ReviewText $p.extrait) -replace 'sans reserves?',''
        $negated=$text -match '\b(aucun|aucune|absence|non|pas|jamais|contest|refus)'
        $pos=$false;$neg=$false
        switch($Axis){
            'accord'{
                $pos=($text -match '(sign|accept|accord explicite).{0,90}(commande|mission|proposition)|(commande|mission|proposition).{0,90}(sign|accept|accord explicite)')
                $neg=($text -match '(contest|refus|reserve).{0,70}(command|mission|proposition)|proposition.{0,60}avant.{0,40}(commencement|debut)')
            }
            'execution'{
                $consentOnly=($text -match '\b(prix|tarif|montant|perimetre|devis|proposition)\b' -and $text -notmatch 'reception|remise|livraison|realisation|conformite|non conforme|malfacon|defaut|retard|inachev|incomplet|non.execut|non.realise')
                if(-not $consentOnly){
                    $pos=($text -match 'reception.{0,50}(conforme|accept)|confirm.{0,90}reception|accept.{0,70}(livrable|travaux)|(livrable|travaux).{0,70}(accept|valid)')
                    $neg=($text -match '(contest|refus|reserve|non conforme|malfacon).{0,60}(livrable|travaux|execution|prestation)|(livrable|travaux|prestation).{0,60}(contest|refus|non conforme|malfacon)')
                }
            }
            'prix'{
                $pos=($text -match '(prix|tarif|montant).{0,60}(accept|convenu)|(accept|convenu).{0,60}(prix|tarif|montant)')
                $neg=($text -match '(contest|refus|pas.{0,25}accept).{0,70}(prix|tarif|montant)|(prix|tarif|montant).{0,60}(contest|refus|pas.{0,25}accept)|conteste.{0,90}accepte.{0,25}prix')
            }
        }
        if($pos -and -not $negated){$positive+=$p}
        if($neg){$negative+=$p}
    }
    if($positive.Count -and $negative.Count){return @{constat='contradiction';passages=@($positive+$negative)}}
    if($positive.Count){return @{constat='acceptation_declaree';passages=$positive}}
    if($negative.Count){return @{constat='contestation_declaree';passages=$negative}}
    return $null
}
function New-StrategyPrompt($Bundle,$Cards,[string]$Request,$Plan) {
    return (@{demande=$Request;roles_declares=@(Get-PartyContext $Bundle.pieces);passages=@(New-StrategyCatalog $Bundle.pieces)} | ConvertTo-Json -Depth 10 -Compress)
}
function Get-DocumentaryGap([string]$Axis,$Catalog) {
    $topics=@{accord='devis|bon de commande|contrat|accord';execution='livrable|justificatif de reception|trace de remise|document de reception';prix='prix|tarif|calcul|facture|montant'}
    $items=@()
    foreach($p in $Catalog){
        if($p.intention_argumentative){continue}
        foreach($clause in @((Normalize-ReviewText $p.extrait) -split '[.;!?]')){
            # Une negation de reserve ou de defaut ne signifie pas qu une piece manque.
            if($clause -match '\b(mais|cependant|toutefois)\b'){continue}
            if($clause -match '\b(aucun[e]?|absence de|manque de|pas de|sans)\s+(devis|bon de commande|contrat|livrable|justificatif|document|piece)' -and $clause -match $topics[$Axis]){$items+=$p;break}
        }
    }
    return @($items)
}
function New-FramedArgument([string]$Axis,[string]$Finding,$Evidence,$Ids,$Cards) {
    $titles=@{accord='Contestation de la preuve de la commande';execution='Contestation de l execution et de la reception';prix='Contestation du prix et du montant facture'}
    $sourceId=if($Axis -eq 'prix'){'civil-1165'}else{'civil-1353'}
    $ref=@($Cards.items | Where-Object {$_.id -ceq $sourceId})
    if($ref.Count -ne 1){throw 'Fiche requise absente du cadre documentaire'}
    $evaluation='indetermine'
    if($Finding -eq 'acceptation_declaree'){$evaluation='affaibli'}
    elseif($Finding -eq 'contestation_declaree'){$evaluation='a_instruire'}
    $a=@{axe=$Axis;titre=$titles[$Axis];constat=$Finding;evaluation=$evaluation;pieces=@($Evidence);piece_ids=@($Ids);source_id=$sourceId;passage_source=$ref[0].note}
    switch($Axis){
        'accord'{
            $a.application='Si les reserves ou la contestation relatees sont confirmees, examiner le consentement et les limites de la mission. Elles ne suffisent pas a exclure une acceptation ulterieure ou tacite. Verifier la qualite des parties, la nature de l acte et les modes de preuve admis avant d exiger un ecrit.'
            $a.contre_argument='La partie demandant paiement peut invoquer une acceptation ulterieure, des echanges ou un comportement confirmant la commande, sous le regime de preuve applicable.'
            $a.reponse='Confronter les echanges complets et leur chronologie, le perimetre effectivement accepte et les pouvoirs de leur auteur. Ne pas exiger du client la preuve d une absence de commande du seul fait de sa contestation.'
            $a.action='Obtenir la proposition, les reponses, les pieces jointes et les echanges ulterieurs ; comparer les reserves initiales aux acceptations eventuelles.'
            $a.bascule='Une commande acceptee ou des echanges ulterieurs concordants affaibliraient la negation generale de la mission ; une reserve maintenue et circonstanciee pourrait au contraire la soutenir.'
            if($Finding -eq 'acceptation_declaree'){
                $a.application='Si l acceptation de commande relatee est confirmee, nier globalement la mission est un moyen affaibli. Il reste a verifier l auteur, ses pouvoirs, le perimetre et les conditions de l accord. La declaration fournie ne remplace pas les originaux.'
                $a.action='Rapprocher la commande acceptee et les originaux. Rechercher seulement des reserves ou divergences concretes ; ne pas maintenir une negation generale contraire aux echanges confirmes.'
                $a.bascule='Un ecart documente de perimetre, une reserve maintenue ou une contestation precise et etayee de l accord modifierait cette evaluation ; ne pas presumer de falsification.'
            }elseif($Finding -ne 'contestation_declaree'){
                $a.application='Les textes ne permettent pas de trancher le consentement. Une absence de devis signe dans le dossier ne prouve pas une absence de commande ; des elements contradictoires exigent les echanges complets. Verifier le regime de preuve, dont le regime commercial eventuel.'
            }
        }
        'execution'{
            $a.application='Si les griefs de prestation relates sont confirmes, comparer les travaux convenus, les travaux realises et leur reception. La personne qui demande l execution d une obligation doit en etablir le fondement ; ne pas confondre une contestation de prestation et une liberation par paiement.'
            $a.contre_argument='Des livrables, comptes rendus, traces de remise ou d utilisation peuvent soutenir la demande meme si ces elements ne figurent pas encore dans ce dossier.'
            $a.reponse='Rapprocher chaque travail reclame d une trace de realisation et des observations du client. Une piece absente ici peut exister chez l autre partie ; ne pas demander de prouver une absence generale de travail.'
            $a.action='Demander les livrables, historiques de remise, comptes rendus et reserves ; etablir une comparaison precise avec le perimetre convenu.'
            $a.bascule='Des traces concordantes de realisation et de reception affaibliraient une negation generale ; un ecart precis et documente ouvrirait une autre contestation a examiner.'
            if($Finding -eq 'acceptation_declaree'){
                $a.application='Si la reception conforme ou l acceptation des travaux relatee est confirmee, nier globalement leur execution est un moyen affaibli. Cela ne demontre pas le paiement ni une liberation du client. Un autre grief exige des faits precis et des pieces.'
                $a.contre_argument='La partie demandant paiement peut opposer la reception acceptee et l absence de reserves relatees pour soutenir que les travaux ont ete remis et acceptes.'
                $a.reponse='Examiner seulement des ecarts ou reserves documentes, leur contenu et leur chronologie. Ne pas inventer un defaut, une reserve ou une contestation d authenticite pour contourner la reception acceptee.'
                $a.action='Confronter le message de reception aux livrables et aux reserves existantes ; examiner les paiements et autres points reels du dossier avant de maintenir une contestation generale.'
            }elseif($Finding -ne 'contestation_declaree'){
                $a.application='Les textes ne permettent pas de qualifier suffisamment l execution. Une absence documentaire ou des indications contradictoires ne permettent pas de conclure a une absence de travail. La contestation reste indeterminee jusqu a confrontation des travaux, remises et observations.'
            }
        }
        'prix'{
            $a.application='Si aucun accord prealable sur le prix n est confirme, cela n exclut pas necessairement une fixation ulterieure du prix du service. Examiner separement la commande, l execution et la justification du montant ; verifier les conditions et le droit applicable dans le temps.'
            $a.contre_argument='La partie demandant paiement peut invoquer un prix accepte ou expliquer le prix du service en l absence d accord prealable. Une facture seule ne dispense pas d examiner la mission et son execution.'
            $a.reponse='Demander le detail du montant et le confronter au perimetre, aux tarifs et aux travaux documentes. Ne pas deduire automatiquement une absence de dette de l absence de prix prealable.'
            $a.action='Rapprocher commande, facture detaillee, tarifs, temps ou autres bases de calcul, frais et paiements deja effectues. Identifier chaque ecart concret.'
            $a.bascule='Un prix accepte et une facture concordante affaibliraient l argument tire d une absence d accord sur le prix ; un ecart de facturation ou de calcul documente ouvrirait une contestation distincte.'
            if($Finding -eq 'acceptation_declaree'){
                $a.application='Si le prix accepte relate est confirme, l absence d accord prealable sur le prix ne doit pas etre invoquee. La fiche sur une fixation ulterieure ne permet pas d effacer ce prix convenu. Verifier la concordance de la facture, les travaux et les paiements sans en deduire automatiquement une dette certaine.'
                $a.contre_argument='La partie demandant paiement peut opposer le prix convenu et la concordance de sa facture avec cet accord.'
                $a.reponse='Distinguer le prix convenu, les eventuels travaux hors perimetre, les erreurs de calcul et les paiements. Ne pas soutenir que le prix etait indetermine si l accord confirme le contraire.'
            }elseif($Finding -ne 'contestation_declaree'){
                $a.application='L etat des textes ne permet pas de fixer les conditions du prix. Obtenir les echanges sur le montant avant de retenir un moyen ; une absence de document disponible ne signifie pas qu aucun prix n a ete convenu.'
            }
        }
    }
    return [pscustomobject]$a
}
function Read-StrategyModel([string]$Raw,$Pieces,$Cards) {
    $data=$Raw | ConvertFrom-Json;Check-Fields $data @('arguments') 'qualification factuelle'
    if($data.arguments -isnot [array] -or $data.arguments.Count -lt 1 -or $data.arguments.Count -gt 3){throw 'Nombre de qualifications invalide'}
    $catalog=@(New-StrategyCatalog $Pieces);$accepted=@();$rejected=@();$seen=@{}
    foreach($a in $data.arguments){try{
        Check-Fields $a @('axe','constat','pieces') 'qualification'
        if($a.axe -notin @('accord','execution','prix') -or $seen.ContainsKey([string]$a.axe)){throw 'Axe inconnu ou repete'}
        if($a.constat -notin @('acceptation_declaree','contestation_declaree','absence_documentaire','contradiction','indetermine')){throw 'Qualification inconnue'}
        if($a.pieces -isnot [array] -or $a.pieces.Count -lt 1 -or $a.pieces.Count -gt 4){throw 'Passages invalides'}
        $evidence=@()
        foreach($key in $a.pieces){
            $selected=@($catalog | Where-Object {$_.id -ceq $key})
            if($key -isnot [string] -or $selected.Count -ne 1){throw 'Passage inconnu'}
            if($selected[0].intention_argumentative){throw 'Un argument souhaite ne constitue pas un constat factuel'}
            Check-Excerpt $selected[0].piece $selected[0].extrait $Pieces
            $evidence+=@{piece=$selected[0].piece;extrait=$selected[0].extrait}
        }
        $modelEvidence=@($evidence)
        $finding='indetermine';$basis=@();$control='qualification_modele_non_corroboree'
        $explicit=Get-ExplicitFinding $a.axe $catalog
        if($null -ne $explicit){
            $finding=$explicit.constat;$basis=@($explicit.passages);$control='indices_textuels_a_confirmer'
        }else{
            $gaps=@(Get-DocumentaryGap $a.axe $catalog)
            if($gaps.Count){$finding='absence_documentaire';$basis=$gaps;$control='absence_documentaire_relatee'}
        }
        # Les passages doivent soutenir le meme axe. Une qualification du modele seule
        # ne transforme pas une reserve de commande/prix en grief de prestation.
        $ids=@($basis | ForEach-Object {$_.id})
        $evidence=@($basis | ForEach-Object {@{piece=$_.piece;extrait=$_.extrait}})
        $argument=New-FramedArgument $a.axe $finding $evidence $ids $Cards
        $argument | Add-Member -NotePropertyName model_constat -NotePropertyValue $a.constat
        $argument | Add-Member -NotePropertyName model_piece_ids -NotePropertyValue @($a.pieces)
        $argument | Add-Member -NotePropertyName model_pieces -NotePropertyValue $modelEvidence
        $argument | Add-Member -NotePropertyName controle -NotePropertyValue $control
        $accepted+=$argument
        $seen[[string]$a.axe]=$true
    }catch{$rejected+=$_.Exception.Message}}
    return [pscustomobject]@{arguments=@($accepted);rejected=@($rejected);method='qualification_locale_et_cadre_conditionnel'}
}
function Render-Strategy($Strategy,$Bundle,$Cards,$Plan) {
    $lines=@('# ANALYSE DES ARGUMENTS — PROJET A RELIRE','',
        'Methode : Ollama propose une qualification des passages. Des controles textuels reperent certaines acceptations ou reserves explicites et ecartent les simples souhaits argumentatifs. Le programme assemble un cadre conditionnel correspondant. Le modele ne redige pas de regles de droit libres.',
        'Les citations sont reprises mot pour mot. Leur qualification par le modele reste a verifier ; la presence des textes ne certifie pas les faits relates. Les fiches sont des reformulations documentaires, pas le texte officiel verifie a ce jour. Ce cadre ne couvre pas tous les moyens ni toutes les branches du droit.')
    $roles=@(Get-PartyContext $Bundle.pieces)
    if($roles.Count){$lines+=@('','## Roles declares');foreach($r in $roles){$lines+="- [$($r.piece)] $($r.extrait)"}}
    else{$lines+=@('','Client et adversaire a confirmer avant utilisation.')}
    $labels=@{a_instruire='Piste a instruire';affaibli='Contestation generale affaiblie si le passage est confirme';indetermine='Indetermine avec ces textes'}
    $findings=@{acceptation_declaree='Acceptation relatee';contestation_declaree='Contestation ou reserve relatee';absence_documentaire='Absence documentaire relatee';contradiction='Indications contradictoires';indetermine='Information insuffisante'}
    foreach($a in $Strategy.arguments){
        $r=@($Cards.items | Where-Object {$_.id -ceq $a.source_id})[0]
        $control=switch($a.controle){
            'indices_textuels_a_confirmer' {'Indices explicites reperes pour cet axe'}
            'absence_documentaire_relatee' {'Manque de pieces relate, sans constat d absence de prestation'}
            default {'Qualification du modele non corroboree pour cet axe ; evaluation suspendue'}
        }
        $lines+=@('',"## $($a.titre)","Lecture conditionnelle : $($findings[$a.constat])","Controle : $control — a confirmer sur les passages et les originaux.","Evaluation : $($labels[$a.evaluation])",'')
        if(-not $a.pieces.Count){$lines+='Aucun passage suffisamment explicite retenu pour cet axe. Les extraits proposes par le modele restent dans les donnees de controle, sans etre presentes comme appuis de ce moyen.'}
        foreach($p in $a.pieces){$lines+="- [$($p.piece)] « $($p.extrait) »"}
        $lines+=@('',"Base documentaire : $($r.title)","Passage de la fiche (reformulation) : « $($a.passage_source) »","Texte officiel a consulter : $($r.url)",'',"Application conditionnelle : $($a.application)","Reponse adverse a anticiper : $($a.contre_argument)","Replique et limite : $($a.reponse)","Action proposee : $($a.action)","Element susceptible de changer cette evaluation : $($a.bascule)")
    }
    if(@($Strategy.arguments | Where-Object {$_.constat -eq 'acceptation_declaree'}).Count -eq 3){$lines+=@('','## Orientation a discuter avec le client','Si ces trois acceptations sont confirmees, ne pas fonder la defense sur une negation generale de la commande, de la remise et du prix. Verifier les paiements, ecarts et autres circonstances documentees, puis examiner avec l avocat une solution amiable adaptee au risque. Aucune dette certaine n est deduite automatiquement.')}
    $missing=@(@('accord','execution','prix') | Where-Object {$_ -notin @($Strategy.arguments | ForEach-Object {$_.axe})})
    if($missing.Count){$lines+=@('',"Couverture incomplete : $($missing -join ', '). Completer les qualifications et les pieces.")}
    if($Strategy.rejected.Count){$lines+=@('',"$($Strategy.rejected.Count) qualification(s) ecartee(s) : $($Strategy.rejected -join '; ').")}
    $lines+=@('','## Verification par l avocat','Confirmer les roles, la qualification des passages, la chronologie, le regime de preuve et les conditions des textes. Prescription, actes de procedure et echeances demandent une verification distincte ; aucun delai n est calcule. Le cadre est une aide a la preparation, pas une conclusion sur le bien-fonde de la creance.','','---','')
    return $lines -join "`n"
}
