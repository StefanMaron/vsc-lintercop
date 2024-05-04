param (
    [Parameter(Mandatory = $true)]
    [string] $TargetPath,
    $prerelease,
    $alLanguageVersion
)

Set-Variable LinterCopFileName -Option ReadOnly -Value "BusinessCentral.LinterCop.dll" -Scope "Script"
$ErrorActionPreference = 'Stop'

# Parameter $prerelease can be a string (true/false) or a boolean ($true/$false)
if ($null -eq $prerelease) {
    $prerelease = $false
}
else {
    if ($prerelease.GetType().FullName -ne "System.Boolean") {
        switch ($prerelease.ToString().ToLower()) {
            "false" { 
                $prerelease = $false
            }
            "true" {
                $prerelease = $true
            }
            default {
                Write-Host "Invalid value for parameter prerelease. Please provide True or False."
                $prerelease = $false
            }
        }
    }
}

# Make sure that the current session supports TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
$releases = Invoke-RestMethod -Uri "https://api.github.com/repos/StefanMaron/BusinessCentral.LinterCop/releases?per_page=5"

# Determine artifact (Latest or Pre-release version of the LinterCop)
if ($prerelease) {
    $artifact = ($releases | Where-Object { $_.draft -eq $false })[0]
}
else {
    $artifact = ($releases | Where-Object { $_.prerelease -eq $false })[0]
}

# Populate expected name of artifact (defaults to "BusinessCentral.LinterCop.dll")
$artifactName = $LinterCopFileName
if ($null -ne $alLanguageVersion) {
    if ($null -ne $($alLanguageVersion -as [version])) {
        $artifactName = "BusinessCentral.LinterCop.AL-$($alLanguageVersion -as [version]).dll"
    }
    else {
        switch ($alLanguageVersion.ToString().ToLower()) {
            "prerelease" { 
                $artifactName = "BusinessCentral.LinterCop.AL-PreRelease.dll"
            }
            default {
                $artifactName = "BusinessCentral.LinterCop.$($alLanguageVersion).dll" 
            }
        }
    }
}

# Search for a matching asset
$asset = $artifact.assets | Where-Object { $_.name -eq $artifactName }
if ($null -ne $asset) {
    Write-Host "Artifact found: $($artifactName)"
}
else {
    Write-Host "No artifact available for $($artifactName)"
    exit 1
}

# Determine if the file needs to be updated
$downloadArtifact = $false
if (Test-Path(Join-Path $TargetPath $LinterCopFileName)) {
    $versionTimeStamp = Get-Content -Path (Join-Path $TargetPath "$($LinterCopFileName).txt") -ErrorAction SilentlyContinue
    if ([string]::IsNullOrEmpty($versionTimeStamp)) {
        $versionTimeStamp = '0001-01-01T00:00:00Z'
    }

    if ((Get-Date $versionTimeStamp) -ne (Get-Date $asset.updated_at)) {
        Write-Host "A newer version of the $($LinterCopFileName) is available"
        Remove-Item -Path (Join-Path $TargetPath $LinterCopFileName) -Force
        $downloadArtifact = $true;
    }
}
else {
    $downloadArtifact = $true;
}

if ($downloadArtifact) {
    Write-Host "Retrieving artifact $($asset.browser_download_url)"
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile (Join-Path $TargetPath $LinterCopFileName)
    Set-Content -Value $asset.updated_at -Path (Join-Path $TargetPath "$($LinterCopFileName).txt")
}
else {
    Write-Host "Current version of the $($LinterCopFileName) is up-to-date."
}

return 0
# SIG # Begin signature block
# MIIScwYJKoZIhvcNAQcCoIISZDCCEmACAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCL2e2braKqsF50
# FO4NJhcCUw5BbcabDC9GBEiq5CVfiqCCDqswggboMIIE0KADAgECAhB3vQ4Ft1kL
# th1HYVMeP3XtMA0GCSqGSIb3DQEBCwUAMFMxCzAJBgNVBAYTAkJFMRkwFwYDVQQK
# ExBHbG9iYWxTaWduIG52LXNhMSkwJwYDVQQDEyBHbG9iYWxTaWduIENvZGUgU2ln
# bmluZyBSb290IFI0NTAeFw0yMDA3MjgwMDAwMDBaFw0zMDA3MjgwMDAwMDBaMFwx
# CzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMTIwMAYDVQQD
# EylHbG9iYWxTaWduIEdDQyBSNDUgRVYgQ29kZVNpZ25pbmcgQ0EgMjAyMDCCAiIw
# DQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAMsg75ceuQEyQ6BbqYoj/SBerjgS
# i8os1P9B2BpV1BlTt/2jF+d6OVzA984Ro/ml7QH6tbqT76+T3PjisxlMg7BKRFAE
# eIQQaqTWlpCOgfh8qy+1o1cz0lh7lA5tD6WRJiqzg09ysYp7ZJLQ8LRVX5YLEeWa
# tSyyEc8lG31RK5gfSaNf+BOeNbgDAtqkEy+FSu/EL3AOwdTMMxLsvUCV0xHK5s2z
# BZzIU+tS13hMUQGSgt4T8weOdLqEgJ/SpBUO6K/r94n233Hw0b6nskEzIHXMsdXt
# HQcZxOsmd/KrbReTSam35sOQnMa47MzJe5pexcUkk2NvfhCLYc+YVaMkoog28vmf
# vpMusgafJsAMAVYS4bKKnw4e3JiLLs/a4ok0ph8moKiueG3soYgVPMLq7rfYrWGl
# r3A2onmO3A1zwPHkLKuU7FgGOTZI1jta6CLOdA6vLPEV2tG0leis1Ult5a/dm2tj
# IF2OfjuyQ9hiOpTlzbSYszcZJBJyc6sEsAnchebUIgTvQCodLm3HadNutwFsDeCX
# pxbmJouI9wNEhl9iZ0y1pzeoVdwDNoxuz202JvEOj7A9ccDhMqeC5LYyAjIwfLWT
# yCH9PIjmaWP47nXJi8Kr77o6/elev7YR8b7wPcoyPm593g9+m5XEEofnGrhO7izB
# 36Fl6CSDySrC/blTAgMBAAGjggGtMIIBqTAOBgNVHQ8BAf8EBAMCAYYwEwYDVR0l
# BAwwCgYIKwYBBQUHAwMwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQUJZ3Q
# /FkJhmPF7POxEztXHAOSNhEwHwYDVR0jBBgwFoAUHwC/RoAK/Hg5t6W0Q9lWULvO
# ljswgZMGCCsGAQUFBwEBBIGGMIGDMDkGCCsGAQUFBzABhi1odHRwOi8vb2NzcC5n
# bG9iYWxzaWduLmNvbS9jb2Rlc2lnbmluZ3Jvb3RyNDUwRgYIKwYBBQUHMAKGOmh0
# dHA6Ly9zZWN1cmUuZ2xvYmFsc2lnbi5jb20vY2FjZXJ0L2NvZGVzaWduaW5ncm9v
# dHI0NS5jcnQwQQYDVR0fBDowODA2oDSgMoYwaHR0cDovL2NybC5nbG9iYWxzaWdu
# LmNvbS9jb2Rlc2lnbmluZ3Jvb3RyNDUuY3JsMFUGA1UdIAROMEwwQQYJKwYBBAGg
# MgECMDQwMgYIKwYBBQUHAgEWJmh0dHBzOi8vd3d3Lmdsb2JhbHNpZ24uY29tL3Jl
# cG9zaXRvcnkvMAcGBWeBDAEDMA0GCSqGSIb3DQEBCwUAA4ICAQAldaAJyTm6t6E5
# iS8Yn6vW6x1L6JR8DQdomxyd73G2F2prAk+zP4ZFh8xlm0zjWAYCImbVYQLFY4/U
# ovG2XiULd5bpzXFAM4gp7O7zom28TbU+BkvJczPKCBQtPUzosLp1pnQtpFg6bBNJ
# +KUVChSWhbFqaDQlQq+WVvQQ+iR98StywRbha+vmqZjHPlr00Bid/XSXhndGKj0j
# fShziq7vKxuav2xTpxSePIdxwF6OyPvTKpIz6ldNXgdeysEYrIEtGiH6bs+XYXvf
# cXo6ymP31TBENzL+u0OF3Lr8psozGSt3bdvLBfB+X3Uuora/Nao2Y8nOZNm9/Lws
# 80lWAMgSK8YnuzevV+/Ezx4pxPTiLc4qYc9X7fUKQOL1GNYe6ZAvytOHX5OKSBoR
# HeU3hZ8uZmKaXoFOlaxVV0PcU4slfjxhD4oLuvU/pteO9wRWXiG7n9dqcYC/lt5y
# A9jYIivzJxZPOOhRQAyuku++PX33gMZMNleElaeEFUgwDlInCI2Oor0ixxnJpsoO
# qHo222q6YV8RJJWk4o5o7hmpSZle0LQ0vdb5QMcQlzFSOTUpEYck08T7qWPLd0jV
# +mL8JOAEek7Q5G7ezp44UCb0IXFl1wkl1MkHAHq4x/N36MXU4lXQ0x72f1LiSY25
# EXIMiEQmM2YBRN/kMw4h3mKJSAfa9TCCB7swggWjoAMCAQICDEZjxXSE/GS+LQtp
# 4zANBgkqhkiG9w0BAQsFADBcMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFs
# U2lnbiBudi1zYTEyMDAGA1UEAxMpR2xvYmFsU2lnbiBHQ0MgUjQ1IEVWIENvZGVT
# aWduaW5nIENBIDIwMjAwHhcNMjMwNjAxMTEzMTUzWhcNMjUwNjAxMTEzMTUzWjCB
# +TEdMBsGA1UEDwwUUHJpdmF0ZSBPcmdhbml6YXRpb24xFTATBgNVBAUTDDA0NTcu
# NTUzLjY1MTETMBEGCysGAQQBgjc8AgEDEwJCRTELMAkGA1UEBhMCQkUxEjAQBgNV
# BAgTCUFudHdlcnBlbjERMA8GA1UEBxMIVHVybmhvdXQxHzAdBgNVBAoTFlZBTiBS
# T0VZIEFVVE9NQVRJT04gTlYxCzAJBgNVBAsTAklUMR8wHQYDVQQDExZWQU4gUk9F
# WSBBVVRPTUFUSU9OIE5WMSkwJwYJKoZIhvcNAQkBFhppbnRlcm5hbHN1cHBvcnRA
# dmFucm9leS5iZTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBALbeM2jv
# HMs41QRX9gdp+NfoC90GiU1146lNqQ1oXuhS/8JOUHB+nkbexa2nhMvYpuIng/8J
# FB9mFGQfBOroudC/tYrUbCLlaF8SqOQKhNFHf4usOeOYpOWNbMjTU5x1S8HJjA3s
# x6qUhxij/PoxXewHj65W555LVTz/OYIHaT8H+bxtr/3vRS8HH/eicqnYfnQCVkeV
# 4CT2xWCaWTzEU1q65/rfzNQ1v9YOmJE1iqC83DRwgvZIp79GRW5ltJvicojOIzlo
# UqR1KlD8EBf9uAoUVtP4gYqZR3O0S0OSXybd0GLV5Jkw39PTS5keIu4GKb2V9uUT
# 7zRaQgRdfoka4690XohpbJX3fkIFFHntNSDNlp6E4vVBG67WhCkq+a319Yiyugaj
# P8fErIPZ/ll7yGxSCXa6WTD4kLzLQ093veSwtidoTwGQ7tch86wG1BeM/U8mmgUI
# /GbF7EHmosYI3JG8L1lTJPFGbusCrwiNl56KotHBa4sxpQhSg8/zL1udkrc4WZ1u
# 9Q7Cv/eQN9/e5v0GwaITVG4X9XXMtQ2QCpv2WsSX5EVGS2JsT80xaqQDIz8ojvF8
# kZMw7ePTL9dLpTEaPb9e9yHLmYEWbYyw2r9GE5r65bZMwxPFz2on5gF+m7t567cv
# n0a6LdJsi0buV/Sf1NEyB4unZ/bOerKPonChAgMBAAGjggHdMIIB2TAOBgNVHQ8B
# Af8EBAMCB4AwgZ8GCCsGAQUFBwEBBIGSMIGPMEwGCCsGAQUFBzAChkBodHRwOi8v
# c2VjdXJlLmdsb2JhbHNpZ24uY29tL2NhY2VydC9nc2djY3I0NWV2Y29kZXNpZ25j
# YTIwMjAuY3J0MD8GCCsGAQUFBzABhjNodHRwOi8vb2NzcC5nbG9iYWxzaWduLmNv
# bS9nc2djY3I0NWV2Y29kZXNpZ25jYTIwMjAwVQYDVR0gBE4wTDBBBgkrBgEEAaAy
# AQIwNDAyBggrBgEFBQcCARYmaHR0cHM6Ly93d3cuZ2xvYmFsc2lnbi5jb20vcmVw
# b3NpdG9yeS8wBwYFZ4EMAQMwCQYDVR0TBAIwADBHBgNVHR8EQDA+MDygOqA4hjZo
# dHRwOi8vY3JsLmdsb2JhbHNpZ24uY29tL2dzZ2NjcjQ1ZXZjb2Rlc2lnbmNhMjAy
# MC5jcmwwJQYDVR0RBB4wHIEaaW50ZXJuYWxzdXBwb3J0QHZhbnJvZXkuYmUwEwYD
# VR0lBAwwCgYIKwYBBQUHAwMwHwYDVR0jBBgwFoAUJZ3Q/FkJhmPF7POxEztXHAOS
# NhEwHQYDVR0OBBYEFMrRgBiC8XZAO8QiIk9tf4tJaOrIMA0GCSqGSIb3DQEBCwUA
# A4ICAQCcudhnI7r/rP+O/sjyqIACzagO7bTgcEXRFJMWoXb4pevpQTyucSLOPodG
# DjKtup/Y4EZLmkXjP+h/0E8f6bKF+pm/nzqGnBz4guWTQAJpL2BKYkTkuRb80wF8
# 5i8iAv5giKePSdQF6RoUaHAkGmvCg5EhkYuznqt6SgR2kv3ihtGRaKZAPeWLNZdD
# cx0KGeYTwdt7kYIMX05obCOP5aS2KPDIiDUqWW7Dm0x5xotlLetDueSBX+IvGgBx
# m+LR1PMHZPNUebGiqLidsAVEXDKR1uo5nOv415FKFOYiHjO1doavA6Zjh+x6JxGj
# FvAwpHnCs0QUTix4zH1kKlnhCkJt0urvRDTIbbVmUfYa+TvhE15pt0BEWAtERiWG
# 0X0h0mDs+IQjBjMN+usIjE5pGckO4RDf4YoKZMfoeCqtslhSctEOEBYpCF60iM+v
# gNjtZbKCsIRftOI9rMuji4Egd5BVFofRWW3YYb4ewR/SOTI8GMEAUE46OsgTT76u
# BpsXmj0aCuFMkyozkE+7HS7RBMlWGq+6qxM4Ut2aXAOBbaMw+UWPJvA6jaKFCHSl
# BB9muUjLsmiB+YEBzTtzB/GH4XtrTxh2ZfFkmdJ9Nt82Ny8TQNG2RUxBcTyc0jhB
# 31Adk97efH4uAFK2J4J8h9ARgt7r/UyoR/wdFiVZxdhiELT40jGCAx4wggMaAgEB
# MGwwXDELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExMjAw
# BgNVBAMTKUdsb2JhbFNpZ24gR0NDIFI0NSBFViBDb2RlU2lnbmluZyBDQSAyMDIw
# AgxGY8V0hPxkvi0LaeMwDQYJYIZIAWUDBAIBBQCggYQwGAYKKwYBBAGCNwIBDDEK
# MAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3
# AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgmJcwAkecvsnARbRz
# j/S8dx8JmaV7PPJAMBxZSncFKAUwDQYJKoZIhvcNAQEBBQAEggIAkD/j6kBZtCJH
# VdB6gvkVpPyPgwttNo3nC0xPdjWGrGbwp6OedUfXDHtHrN56KjO5EsoaCP+b47qe
# Z5xzo+OlVBu5+R3OahgDJrOdB8IxaQ0zjc4kk+d7Eo5RGfgsj2INWwvHl5OTkbWB
# x6phjpQndZMpCEp3W0MyEvsCConPk+OL7g2dC9DeUao3lImh4/QWIDO4AP8d5n7Y
# lbp/ohvb9yGYW50Xv3+wTJWMjy+R4mIutalkkRjJu+uCTwEC4d/+8fn6dF8M3haS
# W+5+FyEoHpbr8E6Wb56QArJluCiCuZrftv+NKtjn9SBY6K0H9iaREDqBSHFi+ym0
# N7132TQvOcwQIywbgB2jQutzJ8rsUuS+YhDBIMeqemkuHWb03aGtAhyNDFmBwQ3g
# 1q2ywv3Kb3wACPBu/RiOAruXFaZCHrI/4daD5s+HYzO1dqSTOUIR8MpjxNxNpxR7
# 4XO9OsHBgKMGsKbSKadBocPRPZ+e8HoCijStV+Zu6er+ftMpHFUz6/z0nJAsOcYh
# W363HZXC41QPyrVb6f19g5wGvW9PEd39DwemO5YHk4/jLWXhxz2FMv1Ucobtn6Hc
# LLj7CZR7YK97kXWPWh2rAG/W60lo64QRlpFdMnlKMA99LYmFots5mwowNOtQdTwX
# etBi7fWU4d5t12Pt2f+WrL9dcg20kfk=
# SIG # End signature block
