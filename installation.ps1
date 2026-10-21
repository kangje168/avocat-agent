param([Parameter(Mandatory=$true)][string]$RequestId)
$ErrorActionPreference='Stop'
. "$PSScriptRoot/agent.ps1"
$null=Id $RequestId
$resultPath=Safe ('vault/ui/'+$RequestId+'.result.json')
function Find-Ollama {
    $cmd=Get-Command ollama -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    foreach($path in @("$env:LOCALAPPDATA/Programs/Ollama/ollama.exe","$env:LOCALAPPDATA/Ollama/ollama.exe")) {
        if (Test-Path -LiteralPath $path) { return $path }
    }
    return $null
}
try {
    # Reutiliser le serveur et le modele presents sans reinstallation.
    Add-Type -AssemblyName System.Net.Http
    $probeHandler=[Net.Http.HttpClientHandler]::new();$probeHandler.UseProxy=$false;$probeHandler.AllowAutoRedirect=$false
    $probe=[Net.Http.HttpClient]::new($probeHandler);$probe.Timeout=[TimeSpan]::FromSeconds(3)
    $ready=$false
    try {
        $response=$probe.GetAsync('http://127.0.0.1:11434/api/tags').GetAwaiter().GetResult()
        if($response.IsSuccessStatusCode){
            $existing=$response.Content.ReadAsStringAsync().GetAwaiter().GetResult() | ConvertFrom-Json
            $ready=@($existing.models | Where-Object {$_.name -notmatch '(?i)cloud|https?'}).Count -gt 0
        }
    } catch {} finally {$probe.Dispose();$probeHandler.Dispose()}
    if($ready){Write-Json $resultPath @{ok=$true;message='Ce poste est deja pret : Ollama et un modele local sont disponibles. Aucun telechargement necessaire.'};exit 0}
    $exe=Find-Ollama
    if (-not $exe) {
        $winget=Get-Command winget -ErrorAction SilentlyContinue
        if (-not $winget) { throw 'Installation automatique indisponible : installer App Installer depuis le Microsoft Store, puis recommencer. Ou installer Ollama depuis https://ollama.com/download/windows.' }
        $p=Start-Process -FilePath $winget.Source -ArgumentList @('install','--id','Ollama.Ollama','--exact','--silent','--accept-package-agreements','--accept-source-agreements') -WindowStyle Hidden -Wait -PassThru
        if ($p.ExitCode -ne 0) { throw "Installation Ollama interrompue (code $($p.ExitCode)). Contacter le responsable informatique." }
        $exe=Find-Ollama
        if (-not $exe) { throw 'Ollama installe mais introuvable. Relancer Windows puis INSTALLER.cmd.' }
    }
    Add-Type -AssemblyName System.Net.Http
    $handler=[Net.Http.HttpClientHandler]::new(); $handler.UseProxy=$false; $handler.AllowAutoRedirect=$false
    $client=[Net.Http.HttpClient]::new($handler); $client.Timeout=[TimeSpan]::FromSeconds(3)
    function Tags {
        $r=$client.GetAsync('http://127.0.0.1:11434/api/tags').GetAwaiter().GetResult()
        $r.EnsureSuccessStatusCode() | Out-Null
        return ($r.Content.ReadAsStringAsync().GetAwaiter().GetResult() | ConvertFrom-Json)
    }
    try { $tags=Tags } catch {
        $env:OLLAMA_NO_CLOUD='1'
        Start-Process -FilePath $exe -ArgumentList 'serve' -WindowStyle Hidden | Out-Null
        $tags=$null
        for($i=0;$i -lt 20;$i++) { Start-Sleep -Seconds 1; try { $tags=Tags; break } catch {} }
        if ($null -eq $tags) { throw 'Ollama ne demarre pas. Redemarrer Windows puis reessayer.' }
    }
    $local=@($tags.models | Where-Object {$_.name -notmatch '(?i)cloud|https?'})
    if ($local.Count -eq 0) {
        # Telechargement du modele public uniquement, jamais de document du cabinet.
        $p=Start-Process -FilePath $exe -ArgumentList @('pull','qwen3.5:4b') -WindowStyle Hidden -Wait -PassThru
        if ($p.ExitCode -ne 0) { throw 'Telechargement du modele interrompu. Verifier Internet puis relancer la preparation.' }
    }
    Write-Json $resultPath @{ok=$true;message='Preparation terminee. Le modele local est disponible. Ouvrir Mes dossiers pour commencer.'}
} catch { Write-Json $resultPath @{ok=$false;message=$_.Exception.Message} }
finally { if (Get-Variable client -ErrorAction SilentlyContinue) {$client.Dispose();$handler.Dispose()} }
