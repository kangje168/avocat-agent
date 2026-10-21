$ErrorActionPreference='Stop'
. "$PSScriptRoot/agent.ps1"
$passed=0
function Reject($Label,[scriptblock]$Action) {
    $rejected=$false
    try { & $Action | Out-Null } catch { $rejected=$true }
    if (-not $rejected) { throw "ECHEC : $Label" }
    $script:passed++; Write-Output "OK $Label"
}
Reject 'traversee du repertoire parent' { Safe '../secret.txt' }
Reject 'chemin absolu externe' { Assert-SafePath 'C:\Windows\win.ini' }
Reject 'identifiant avec traversee' { Id '../other-client' }
Reject 'identifiant avec flux alternatif' { Id 'case:secret' }
if (Official 'https://www.legifrance.gouv.fr.attacker.example/foo') { throw 'Echec du controle du domaine' }; $passed++
if (Official 'http://www.legifrance.gouv.fr/foo') { throw 'Echec du controle HTTPS' }; $passed++
if (-not (Official 'https://www.legifrance.gouv.fr/codes/')) { throw 'URL officielle refusee' }; $passed++
$AsOf='2026-10-21'
$laws=@([pscustomobject]@{id='old';title='contrat';text='contrat';valid_from='2020-01-01';valid_to='2025-01-01'},[pscustomobject]@{id='new';title='contrat';text='contrat';valid_from='2026-01-01';valid_to=$null})
$selected=@(Select-Laws $laws 'contrat')
if ($selected.Count -ne 1 -or $selected[0].id -ne 'new') { throw 'Echec du filtre de validite' }; $passed++
if (@(Select-Laws $laws 'absent').Count -ne 0) { throw 'Source sans correspondance selectionnee' }; $passed++
if ((Hash 'abc') -ne 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad') { throw 'Empreinte incorrecte' }; $passed++
Reject 'modele distant' { $script:Model='x-cloud'; Ask-Local 'private' }
. "$PSScriptRoot/tests-qualite.ps1"
