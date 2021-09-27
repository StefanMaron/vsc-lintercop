param (
    $TargetPath
)
$ErrorActionPreference = 'Stop'

$latestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/StefanMaron/BusinessCentral.LinterCop/releases/latest"
$latestRelease.assets[0].browser_download_url
$lastVersionTimeStamp = ''
$lastVersionTimeStamp = Get-Content -Path (Join-Path $PSScriptRoot 'lastversion.txt') -ErrorAction SilentlyContinue

if ($lastVersionTimeStamp -ne '') {
    $lastVersionTimeStamp = '0001-01-01T00:00:00Z'

}

if (((Get-Date $lastVersionTimeStamp) -lt (Get-Date $latestRelease.assets[0].updated_at )) -or (-not (Test-Path $TargetPath -PathType leaf))) {
    Remove-Item -Path $TargetPath -Force
    Invoke-WebRequest -Uri $latestRelease.assets[0].browser_download_url -OutFile $TargetPath
    Set-Content -Value $latestRelease.assets[0].updated_at -Path (Join-Path $PSScriptRoot 'lastversion.txt')
    return 1
}

return 0