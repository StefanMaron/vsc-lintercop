param (
    $TargetPath,
    $prerelease
)
$ErrorActionPreference = 'Stop'

# Make sure that the current session supports TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$latestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/StefanMaron/BusinessCentral.LinterCop/releases"

if ($prerelease -eq "false") {
    $prerelease = $false
}
else {
    $prerelease = $true
}

if ($prerelease) {
    $latestRelease = $latestRelease[0]    
}
else {
    $latestRelease = ($latestRelease | Where-Object { $_.prerelease -eq $false })[0]        
}

$latestRelease.assets[0].browser_download_url
$lastVersionTimeStamp = Get-Content -Path (Join-Path $PSScriptRoot 'lastversion.txt') -ErrorAction SilentlyContinue

if ([string]::IsNullOrEmpty($lastVersionTimeStamp)) {
    $lastVersionTimeStamp = '0001-01-01T00:00:00Z'
}

$latestRelease.assets | ForEach-Object  {
    $asset = $_
    Join-Path $TargetPath $asset.name
    if (((Get-Date $lastVersionTimeStamp) -lt (Get-Date $latestRelease.assets[0].updated_at )) -or (-not (Test-Path (Join-Path $TargetPath $asset.name) -PathType leaf))) {
        Write-Host $asset.name

        if (Test-Path (Join-Path $TargetPath $asset.name) -PathType leaf) {
            Remove-Item -Path (Join-Path $TargetPath $asset.name) -Force
        }
        
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile (Join-Path $TargetPath $asset.name)
        
        if ($asset.name.EndsWith('current.dll')) {
            Move-Item (Join-Path $TargetPath $asset.name) (Join-Path $TargetPath 'BusinessCentral.LinterCop.dll') -force
        }
        Set-Content -Value $latestRelease.assets[0].updated_at -Path (Join-Path $PSScriptRoot 'lastversion.txt')
        return 1
    }
}
return 0

# SIG # Begin signature block
# MIIV/AYJKoZIhvcNAQcCoIIV7TCCFekCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUO2zDwR2AprD3xbj/1vLfswGu
# q8+gghK4MIIF2DCCBMCgAwIBAgIRAOQnBJX2jJHW0Ox7SU6k3xwwDQYJKoZIhvcN
# AQELBQAwfjELMAkGA1UEBhMCUEwxIjAgBgNVBAoTGVVuaXpldG8gVGVjaG5vbG9n
# aWVzIFMuQS4xJzAlBgNVBAsTHkNlcnR1bSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0
# eTEiMCAGA1UEAxMZQ2VydHVtIFRydXN0ZWQgTmV0d29yayBDQTAeFw0xODA5MTEw
# OTI2NDdaFw0yMzA5MTEwOTI2NDdaMHwxCzAJBgNVBAYTAlVTMQ4wDAYDVQQIDAVU
# ZXhhczEQMA4GA1UEBwwHSG91c3RvbjEYMBYGA1UECgwPU1NMIENvcnBvcmF0aW9u
# MTEwLwYDVQQDDChTU0wuY29tIFJvb3QgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkg
# UlNBMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA+Q/doyt9y9Aq/uxn
# habnLhu6d+Hj9a+k7PpKXZHEV0drGHdrdvL9k+Q9D8IWngtmw1aUnheDhc5W7/IW
# /QBi9SIJVOhlF05BueBPRpeqG8i4bmJeabFf2yoCfvxsyvNB2O3Q6Pw/YUjtsAMU
# HRAOSxngu07shmX/NvNeZwILnYZVYf16OO3+4hkAt2+hUGJ1dDyg+sglkrRueiLH
# +B6h47LdkTGrKx0E/6VKBDfphaQzK/3i1lU0fBmkSmjHsqjTt8qhk4jrwZe8jPkd
# 2SKEJHTHBD1qqSmTzOu4W+H+XyWqNFjIwSNUnRuYEcM4nH49hmylD0CGfAL0XAJP
# KMuucZ8POsgz/hElNer8usVgPdl8GNWyqdN1eANyIso6wx/vLOUuqfqeLLZRRv2v
# A9bqYGjqhRY2a4XpHsCz3cQk3IAqgUFtlD7I4MmBQQCeXr9/xQiYohgsQkCz+W84
# J0tOgPQ9gUfgiHzqHM61dVxRLhwrfxpyKOcAtdF0xtfkn60Hk7ZTNTX8N+TD9l0W
# viFz3pIK+KBjaryWkmo++LxlVZve9Q2JJgT8JRqmJWnLwm3KfOJZX5es6+8uyLzX
# G1k8K8zyGciTaydjGc/86Sb4ynGbf5P+NGeETpnr/LN4CTNwumamdu0bc+sapQ3E
# IhMglFYKTixsTrH9z5wJuqIz7YcCAwEAAaOCAVEwggFNMBIGA1UdEwEB/wQIMAYB
# Af8CAQIwHQYDVR0OBBYEFN0ECQei9Xp9UlMSkpXuOIAlDaZZMB8GA1UdIwQYMBaA
# FAh2zcsH/yT2xc3tu5C84oQ3RnX3MA4GA1UdDwEB/wQEAwIBBjA2BgNVHR8ELzAt
# MCugKaAnhiVodHRwOi8vc3NsY29tLmNybC5jZXJ0dW0ucGwvY3RuY2EuY3JsMHMG
# CCsGAQUFBwEBBGcwZTApBggrBgEFBQcwAYYdaHR0cDovL3NzbGNvbS5vY3NwLWNl
# cnR1bS5jb20wOAYIKwYBBQUHMAKGLGh0dHA6Ly9zc2xjb20ucmVwb3NpdG9yeS5j
# ZXJ0dW0ucGwvY3RuY2EuY2VyMDoGA1UdIAQzMDEwLwYEVR0gADAnMCUGCCsGAQUF
# BwIBFhlodHRwczovL3d3dy5jZXJ0dW0ucGwvQ1BTMA0GCSqGSIb3DQEBCwUAA4IB
# AQAflZojVO6FwvPUb7npBI9Gfyz3MsCnQ6wHAO3gqUUt/Rfh7QBAyK+YrPXAGa0b
# oJcwQGzsW/ujk06MiWIbfPA6X6dCz1jKdWWcIky/dnuYk5wVgzOxDtxROId8lZwS
# aZQeAHh0ftzABne6cC2HLNdoneO6ha1J849ktBUGg5LGl6RAk4ut8WeUtLlaZ1Q8
# qBvZBc/kpPmIEgAGiCWF1F7u85NX1oH4LK739VFIq7ZiOnnb7C7yPxRWOsjZy6Si
# TyWo0ZurLTAgUAcab/HxlB05g2PoH/1J0OgdRrJGgia9nJ3homhBSFFuevw1lvRU
# 0rwrROVH13eCpUqrX5czqyQRMIIGYjCCBEqgAwIBAgIQNwepqyR8kAKtxpkYAXsX
# zjANBgkqhkiG9w0BAQsFADB4MQswCQYDVQQGEwJVUzEOMAwGA1UECAwFVGV4YXMx
# EDAOBgNVBAcMB0hvdXN0b24xETAPBgNVBAoMCFNTTCBDb3JwMTQwMgYDVQQDDCtT
# U0wuY29tIENvZGUgU2lnbmluZyBJbnRlcm1lZGlhdGUgQ0EgUlNBIFIxMB4XDTIy
# MDYwMTE1MTQ0MloXDTIzMDUzMTE1MTQ0MlowazELMAkGA1UEBhMCREUxHzAdBgNV
# BAgMFk5vcnRoIFJoaW5lLVdlc3RwaGFsaWExDTALBgNVBAcMBEJvbm4xFTATBgNV
# BAoMDFN0ZWZhbiBNYXJvbjEVMBMGA1UEAwwMU3RlZmFuIE1hcm9uMIIBojANBgkq
# hkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAu7JgAclZo2b/UMlIyNet3LzWOC4+p4jl
# OoZRB8nfGIWQ2zz+gaYgdtl3K4eiZVJj6yGU3R2J6IdBj8za1+izj6iLC98GXYqV
# Mj9t8mupTxQD7xjxOvzpAVJASNAJUBNXvTmlaJxor9WdEoIZ0+gH1SoBpJnQChwu
# 6Ur3ESOdvYHjO7NKf4XFxxPjX3jf+zKihkPj0bujTGO/rJY57/NQnzP0Z6q7WI8X
# OyzCaPPvU1An9L9omFohmQVGpRzfNQcpYK0xPJ8LnxNEa0DV2iUD0O2U2yVQnLe2
# M1w/y/kOeWieauMIgy6evCaMafrDfDSkh/UylGlboYMBHiL33tzuvOpEquS9MByP
# ozt7WYe/v/5gb2eYE/aAAGLfUKpYPA9D2kZPj3l8827dQFTwHV5Hgdivjkfmd4+M
# IFX47pPfX8ZDKsTHPs3jjPWKNOKAcbCrC4wEPubksJcAmo0I0e7W98BA6jSCURoj
# LZHfHq7Hj2ZCAAavnSDaH1I5hC2gGL2VAgMBAAGjggFzMIIBbzAMBgNVHRMBAf8E
# AjAAMB8GA1UdIwQYMBaAFFTC/hCVAJPNavXnwNfZsku4jwzjMFgGCCsGAQUFBwEB
# BEwwSjBIBggrBgEFBQcwAoY8aHR0cDovL2NlcnQuc3NsLmNvbS9TU0xjb20tU3Vi
# Q0EtQ29kZVNpZ25pbmctUlNBLTQwOTYtUjEuY2VyMFEGA1UdIARKMEgwCAYGZ4EM
# AQQBMDwGDCsGAQQBgqkwAQMDATAsMCoGCCsGAQUFBwIBFh5odHRwczovL3d3dy5z
# c2wuY29tL3JlcG9zaXRvcnkwEwYDVR0lBAwwCgYIKwYBBQUHAwMwTQYDVR0fBEYw
# RDBCoECgPoY8aHR0cDovL2NybHMuc3NsLmNvbS9TU0xjb20tU3ViQ0EtQ29kZVNp
# Z25pbmctUlNBLTQwOTYtUjEuY3JsMB0GA1UdDgQWBBT0hUx9R0w7jgXhjwbX+ia3
# COIFbTAOBgNVHQ8BAf8EBAMCB4AwDQYJKoZIhvcNAQELBQADggIBAGcQ+sARXNWK
# eHY0/0vv/nb1W1vYEmztfdNav7kcSOdkNEajQXf7AB95bABWEV758td1X25I7IRK
# vQLlL2Dt6Ka3b9QuP4TFLWvCTEfRMkox3veK4I4RI3sHE+DHMUfYwNyz5uISfM3n
# K775UzGpBm9TWzERuWamRxk4WUD7EG4DXjPpwLBH3wb1IgcEjJ/K1O7OUOtOOI4k
# ZrqrAg2pom+BKoL/fZqwDaNeURw+PiuGGVk9raMe5bqoPqNh+1vfHu/AY1fcG6U5
# gTsN/YiFigHQWVaC5lm+U/jeeNblZ6Va4MOEICvTCZLKkP9/3/st+9rknMvmj2+B
# EwDD2zeVEoF4e8YKpolb/LTFG768SWDMY61AdYb3qidy4Nsvse8aBvC9gwXXK+mK
# dumB2tl2XNVeJ2TuhaLEiZc8FZSGa8dOPhTvbWrvrgFxtzXiOe0MjXFNwj9HnJQX
# c1LVFUYb0gG6nhd7U78cZ2o+HvqhkzsXieaxyJXIYPuLgXYypQ1PcrvZH5MNlNWM
# 4MbSr9hOjWGLrayQ4jVrlqkEGxfIScwm7Vkfc6Oz882Allo0i7Vvo4agustGqS1D
# /OxWqsjRSuxSzR7ajb7Fpp42xMZBhXtYbKntNu6W2rguae7ATdqrhCrTlXFNNC3I
# xTfHUumPMuiwYF3DrYzYzNBVnbVTj+j7MIIGcjCCBFqgAwIBAgIIZDNR08c4nwgw
# DQYJKoZIhvcNAQELBQAwfDELMAkGA1UEBhMCVVMxDjAMBgNVBAgMBVRleGFzMRAw
# DgYDVQQHDAdIb3VzdG9uMRgwFgYDVQQKDA9TU0wgQ29ycG9yYXRpb24xMTAvBgNV
# BAMMKFNTTC5jb20gUm9vdCBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eSBSU0EwHhcN
# MTYwNjI0MjA0NDMwWhcNMzEwNjI0MjA0NDMwWjB4MQswCQYDVQQGEwJVUzEOMAwG
# A1UECAwFVGV4YXMxEDAOBgNVBAcMB0hvdXN0b24xETAPBgNVBAoMCFNTTCBDb3Jw
# MTQwMgYDVQQDDCtTU0wuY29tIENvZGUgU2lnbmluZyBJbnRlcm1lZGlhdGUgQ0Eg
# UlNBIFIxMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAn4MTc6qwxm0h
# y9uLeod00HHcjpdymuS7iDS03YADxi9FpHSavx4PUOqebXjzn/pRJqk9ndGylFc+
# +zmJG5ErVu9ny+YL4w45jMY19Iw93SXpAawXQn1YFkDc+dUoRB2VZDBhOmTyl9dz
# TH17IwJt83XrVT1vqi3Er750rF3+arb86lx56Q9DnLVSBQ/vPrGxj9BJrabjQhlU
# P/MvDqHLfP4T+SM52iUcuD4ASjpvMjA3ZB7HrnUH2FXSGMkOiryjXPB8CqeFgcIO
# r4+ZXNNgJbyDWmkcJRPNcvXrnICb3CxnxN3JCZjVc+vEIaPlMo4+L1KYxmA3ZIyy
# b0pUchjMJ4f6zXWiYyFMtT1k/Summ1WvJkxgtLlc/qtDva3QE2ZQHwvSiab/14AG
# 8cMRAjMzYRf3Vh+OLzto5xXxd1ZKKZ4D2sIrJmEyW6BW5UkpjTan9cdSolYDIC84
# eIC99gauQTTLlEW9m8eJGB8Luv+prmpAmRPd71DfAbryBNbQMd80OF5XW8g4HlbU
# rEim7f/5uME77cIkvkRgp3fN1T2YWbRD6qpgfc3C5S/x6/XUINWXNG5dBGsFEdLT
# kowJJ0TtTzUxRn50GQVi7Inj6iNwmOTRL9SKExhGk2XlWHPTTD0neiI/w/ijVbf5
# 5oeC7EUexW46fLFOuato95tj1ZFBvKkCAwEAAaOB+zCB+DAPBgNVHRMBAf8EBTAD
# AQH/MB8GA1UdIwQYMBaAFN0ECQei9Xp9UlMSkpXuOIAlDaZZMDAGCCsGAQUFBwEB
# BCQwIjAgBggrBgEFBQcwAYYUaHR0cDovL29jc3BzLnNzbC5jb20wEQYDVR0gBAow
# CDAGBgRVHSAAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMDsGA1UdHwQ0MDIwMKAuoCyG
# Kmh0dHA6Ly9jcmxzLnNzbC5jb20vc3NsLmNvbS1yc2EtUm9vdENBLmNybDAdBgNV
# HQ4EFgQUVML+EJUAk81q9efA19myS7iPDOMwDgYDVR0PAQH/BAQDAgGGMA0GCSqG
# SIb3DQEBCwUAA4ICAQD1DyaHcK+Zosr11snwjWY9OYLTiCPYgr+PVIQnttODB9ee
# J4lNhI5U0SDuYEPbV0I8x7CV9r7M6qM9jk8GxitZhn/rcxvK5UAm4D1vzPa9ccbN
# fQ4gQDnWBdKvlAi/f8JRtyu1e4Mh8GPa5ZzhaS51HU7LYR71pTPfAp0V2e1pk1e6
# RkUugLxlvucSPt5H/5CcEK32VrKk1PrW/C68lyGzdoPSkfoGUNGxgCiA/tutD2ft
# +H3c2XBberpotbNKZheP5/DnV91p/rxe4dWMnxO7lZoV+3krhdVtPmdHbhsHXPtU
# RQ8WES4Rw7C8tW4cM1eUHv5CNEaOMVBO2zNXlfo45OYS26tYLkW32SLK9FpHSSwo
# 6E+MQjxkaOnmQ6wZkanHE4Jf/HEKN7edUHs8XfeiUoI15LXn0wpva/6N+aTX1R1L
# 531iCPjZ16yZSdu1hEEULvYuYJdTS5r+8Yh6dLqedeng2qfJzCw7e0wKeM+U9zZg
# toM8ilTLTg1oKpQRdSYU6iA3zOt5F3ZVeHFt4kk4Mzfb5GxZxyNi5rzOLlRL/V4D
# KsjdHktxRNB1PjFiZYsppu0k4XodhDR/pBd8tKx9PzVYy8O/Gt2fVFZtReVT84iK
# KzGjyj5Q0QA07CcIw2fGXOhov88uFmW4PGb/O7KVq5qNncyU8O14UH/sZEejnTGC
# Aq4wggKqAgEBMIGMMHgxCzAJBgNVBAYTAlVTMQ4wDAYDVQQIDAVUZXhhczEQMA4G
# A1UEBwwHSG91c3RvbjERMA8GA1UECgwIU1NMIENvcnAxNDAyBgNVBAMMK1NTTC5j
# b20gQ29kZSBTaWduaW5nIEludGVybWVkaWF0ZSBDQSBSU0EgUjECEDcHqaskfJAC
# rcaZGAF7F84wCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAw
# GQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisG
# AQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFGG2Ip5zp1pC48o0DtcfWZL50kcjMA0G
# CSqGSIb3DQEBAQUABIIBgAcnkZz5mzwbYNvdD4mSjw1uaIUnYRNBgAP9ORoNB7dk
# 6SBv6CoqZJ7+7JGhFZY/Roj+WXJiXaGwPhrGkb0i68E4xtXVtr+4UtjV7JIMnRxV
# CRzmYTmCcms0AtmBcUf1l6CUxXdgAtiwPv0/8GWF9cue37xzAipqxODr8kWLRdV7
# Ws5b1MLTlWNv6ZPHMNIJ/EX/llHwKf0Z6L3dQW5m65OUWhDhbmnm54yqcba5rWLE
# wWsoxwUR5QxQk3UHEOHuGwzXG3qSOWSO2arL/4NAFYZSsbVaZDZj6AH+YWAw0Gpi
# taHIWrflDYc8cxMDMUZNPDCpgv1eRhkW0uOOzNr0E63MhZtI3BkSInnQifx36agm
# yW+slCmHkvjkZk4PwQ6NudyrfoysG+fZzlAylVQxt6ab1vRVvkU9HxjU5soFoH1p
# ScTGQhWqwDRrUUvUELEdC316ZfciuVlUymzyMdsEQjp/zQgo9v/6TpZrx0C517oc
# af64D0E6EIKPFNY6hSBbjw==
# SIG # End signature block
