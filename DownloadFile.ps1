param (
    $TargetPath
)

$WebClient = New-Object System.Net.WebClient
$latestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/StefanMaron/BusinessCentral.LinterCop/releases/latest"
$latestRelease.assets[0].browser_download_url
$lastVersionTimeStamp = Get-Content -Path (Join-Path $PSScriptRoot 'lastversion.txt')

if ((($lastVersionTimeStamp -ne '') -and ((Get-Date $lastVersionTimeStamp) -lt (Get-Date $latestRelease.published_at ))) -or (-not (Test-Path $TargetPath -PathType leaf))) {
    Set-Content -Value $latestRelease.published_at -Path (Join-Path $PSScriptRoot 'lastversion.txt')
    
    $WebClient.DownloadFile($latestRelease.assets[0].browser_download_url, $TargetPath)
    return 1
}

return 0