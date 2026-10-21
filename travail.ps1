param([Parameter(Mandatory=$true)][string]$RequestId)
$ErrorActionPreference='Stop'
. "$PSScriptRoot/agent.ps1"
$null=Id $RequestId
$requestPath=Safe ('vault/ui/'+$RequestId+'.request.json')
$resultPath=Safe ('vault/ui/'+$RequestId+'.result.json')
try {
    $req=Read-Text $requestPath | ConvertFrom-Json
    $Command=$req.command
    if ($Command -notin @('analyze','draft','publish')) { throw 'Operation non autorisee' }
    $Question=$req.question; $CaseId=$req.case_id; $Model=$req.model
    $DraftId=$req.draft_id; $Reviewer=$req.reviewer; $ExpectedHash=$req.expected_hash; $AsOf=$req.as_of
    $result=Main | Out-String
    Write-Json $resultPath @{ok=$true;message=$result}
} catch { Write-Json $resultPath @{ok=$false;message=$_.Exception.Message} }
