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
         
            if (Test-Path (Join-Path $TargetPath 'BusinessCentral.LinterCop.dll') -PathType leaf) {
                Remove-Item -Path (Join-Path $TargetPath 'BusinessCentral.LinterCop.dll') -Force
            }
            Move-Item (Join-Path $TargetPath $asset.name) (Join-Path $TargetPath 'BusinessCentral.LinterCop.dll')
        }
        Set-Content -Value $latestRelease.assets[0].updated_at -Path (Join-Path $PSScriptRoot 'lastversion.txt')
        return 1
    }
}
return 0
# SIG # Begin signature block
# MIISTgYJKoZIhvcNAQcCoIISPzCCEjsCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUTo3ZPBcBmkTz4YaX3tIA4KYj
# jByggg6rMIIG6DCCBNCgAwIBAgIQd70OBbdZC7YdR2FTHj917TANBgkqhkiG9w0B
# AQsFADBTMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1zYTEp
# MCcGA1UEAxMgR2xvYmFsU2lnbiBDb2RlIFNpZ25pbmcgUm9vdCBSNDUwHhcNMjAw
# NzI4MDAwMDAwWhcNMzAwNzI4MDAwMDAwWjBcMQswCQYDVQQGEwJCRTEZMBcGA1UE
# ChMQR2xvYmFsU2lnbiBudi1zYTEyMDAGA1UEAxMpR2xvYmFsU2lnbiBHQ0MgUjQ1
# IEVWIENvZGVTaWduaW5nIENBIDIwMjAwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAw
# ggIKAoICAQDLIO+XHrkBMkOgW6mKI/0gXq44EovKLNT/QdgaVdQZU7f9oxfnejlc
# wPfOEaP5pe0B+rW6k++vk9z44rMZTIOwSkRQBHiEEGqk1paQjoH4fKsvtaNXM9JY
# e5QObQ+lkSYqs4NPcrGKe2SS0PC0VV+WCxHlmrUsshHPJRt9USuYH0mjX/gTnjW4
# AwLapBMvhUrvxC9wDsHUzDMS7L1AldMRyubNswWcyFPrUtd4TFEBkoLeE/MHjnS6
# hICf0qQVDuiv6/eJ9t9x8NG+p7JBMyB1zLHV7R0HGcTrJnfyq20Xk0mpt+bDkJzG
# uOzMyXuaXsXFJJNjb34Qi2HPmFWjJKKINvL5n76TLrIGnybADAFWEuGyip8OHtyY
# iy7P2uKJNKYfJqCornht7KGIFTzC6u632K1hpa9wNqJ5jtwNc8Dx5CyrlOxYBjk2
# SNY7WugiznQOryzxFdrRtJXorNVJbeWv3ZtrYyBdjn47skPYYjqU5c20mLM3GSQS
# cnOrBLAJ3IXm1CIE70AqHS5tx2nTbrcBbA3gl6cW5iaLiPcDRIZfYmdMtac3qFXc
# AzaMbs9tNibxDo+wPXHA4TKnguS2MgIyMHy1k8gh/TyI5mlj+O51yYvCq++6Ov3p
# Xr+2EfG+8D3KMj5ufd4PfpuVxBKH5xq4Tu4swd+hZegkg8kqwv25UwIDAQABo4IB
# rTCCAakwDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMDMBIGA1Ud
# EwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYEFCWd0PxZCYZjxezzsRM7VxwDkjYRMB8G
# A1UdIwQYMBaAFB8Av0aACvx4ObeltEPZVlC7zpY7MIGTBggrBgEFBQcBAQSBhjCB
# gzA5BggrBgEFBQcwAYYtaHR0cDovL29jc3AuZ2xvYmFsc2lnbi5jb20vY29kZXNp
# Z25pbmdyb290cjQ1MEYGCCsGAQUFBzAChjpodHRwOi8vc2VjdXJlLmdsb2JhbHNp
# Z24uY29tL2NhY2VydC9jb2Rlc2lnbmluZ3Jvb3RyNDUuY3J0MEEGA1UdHwQ6MDgw
# NqA0oDKGMGh0dHA6Ly9jcmwuZ2xvYmFsc2lnbi5jb20vY29kZXNpZ25pbmdyb290
# cjQ1LmNybDBVBgNVHSAETjBMMEEGCSsGAQQBoDIBAjA0MDIGCCsGAQUFBwIBFiZo
# dHRwczovL3d3dy5nbG9iYWxzaWduLmNvbS9yZXBvc2l0b3J5LzAHBgVngQwBAzAN
# BgkqhkiG9w0BAQsFAAOCAgEAJXWgCck5urehOYkvGJ+r1usdS+iUfA0HaJscne9x
# thdqawJPsz+GRYfMZZtM41gGAiJm1WECxWOP1KLxtl4lC3eW6c1xQDOIKezu86Jt
# vE21PgZLyXMzyggULT1M6LC6daZ0LaRYOmwTSfilFQoUloWxamg0JUKvllb0EPok
# ffErcsEW4Wvr5qmYxz5a9NAYnf10l4Z3Rio9I30oc4qu7ysbmr9sU6cUnjyHccBe
# jsj70yqSM+pXTV4HXsrBGKyBLRoh+m7Pl2F733F6Ospj99UwRDcy/rtDhdy6/KbK
# Mxkrd23bywXwfl91LqK2vzWqNmPJzmTZvfy8LPNJVgDIEivGJ7s3r1fvxM8eKcT0
# 4i3OKmHPV+31CkDi9RjWHumQL8rTh1+TikgaER3lN4WfLmZiml6BTpWsVVdD3FOL
# JX48YQ+KC7r1P6bXjvcEVl4hu5/XanGAv5becgPY2CIr8ycWTzjoUUAMrpLvvj19
# 94DGTDZXhJWnhBVIMA5SJwiNjqK9IscZyabKDqh6NttqumFfESSVpOKOaO4ZqUmZ
# XtC0NL3W+UDHEJcxUjk1KRGHJNPE+6ljy3dI1fpi/CTgBHpO0ORu3s6eOFAm9CFx
# ZdcJJdTJBwB6uMfzd+jF1OJV0NMe9n9S4kmNuRFyDIhEJjNmAUTf5DMOId5iiUgH
# 2vUwgge7MIIFo6ADAgECAgxGY8V0hPxkvi0LaeMwDQYJKoZIhvcNAQELBQAwXDEL
# MAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExMjAwBgNVBAMT
# KUdsb2JhbFNpZ24gR0NDIFI0NSBFViBDb2RlU2lnbmluZyBDQSAyMDIwMB4XDTIz
# MDYwMTExMzE1M1oXDTI1MDYwMTExMzE1M1owgfkxHTAbBgNVBA8MFFByaXZhdGUg
# T3JnYW5pemF0aW9uMRUwEwYDVQQFEwwwNDU3LjU1My42NTExEzARBgsrBgEEAYI3
# PAIBAxMCQkUxCzAJBgNVBAYTAkJFMRIwEAYDVQQIEwlBbnR3ZXJwZW4xETAPBgNV
# BAcTCFR1cm5ob3V0MR8wHQYDVQQKExZWQU4gUk9FWSBBVVRPTUFUSU9OIE5WMQsw
# CQYDVQQLEwJJVDEfMB0GA1UEAxMWVkFOIFJPRVkgQVVUT01BVElPTiBOVjEpMCcG
# CSqGSIb3DQEJARYaaW50ZXJuYWxzdXBwb3J0QHZhbnJvZXkuYmUwggIiMA0GCSqG
# SIb3DQEBAQUAA4ICDwAwggIKAoICAQC23jNo7xzLONUEV/YHafjX6AvdBolNdeOp
# TakNaF7oUv/CTlBwfp5G3sWtp4TL2KbiJ4P/CRQfZhRkHwTq6LnQv7WK1Gwi5Whf
# EqjkCoTRR3+LrDnjmKTljWzI01OcdUvByYwN7MeqlIcYo/z6MV3sB4+uVueeS1U8
# /zmCB2k/B/m8ba/970UvBx/3onKp2H50AlZHleAk9sVgmlk8xFNauuf638zUNb/W
# DpiRNYqgvNw0cIL2SKe/RkVuZbSb4nKIziM5aFKkdSpQ/BAX/bgKFFbT+IGKmUdz
# tEtDkl8m3dBi1eSZMN/T00uZHiLuBim9lfblE+80WkIEXX6JGuOvdF6IaWyV935C
# BRR57TUgzZaehOL1QRuu1oQpKvmt9fWIsroGoz/HxKyD2f5Ze8hsUgl2ulkw+JC8
# y0NPd73ksLYnaE8BkO7XIfOsBtQXjP1PJpoFCPxmxexB5qLGCNyRvC9ZUyTxRm7r
# Aq8IjZeeiqLRwWuLMaUIUoPP8y9bnZK3OFmdbvUOwr/3kDff3ub9BsGiE1RuF/V1
# zLUNkAqb9lrEl+RFRktibE/NMWqkAyM/KI7xfJGTMO3j0y/XS6UxGj2/Xvchy5mB
# Fm2MsNq/RhOa+uW2TMMTxc9qJ+YBfpu7eeu3L59Gui3SbItG7lf0n9TRMgeLp2f2
# znqyj6JwoQIDAQABo4IB3TCCAdkwDgYDVR0PAQH/BAQDAgeAMIGfBggrBgEFBQcB
# AQSBkjCBjzBMBggrBgEFBQcwAoZAaHR0cDovL3NlY3VyZS5nbG9iYWxzaWduLmNv
# bS9jYWNlcnQvZ3NnY2NyNDVldmNvZGVzaWduY2EyMDIwLmNydDA/BggrBgEFBQcw
# AYYzaHR0cDovL29jc3AuZ2xvYmFsc2lnbi5jb20vZ3NnY2NyNDVldmNvZGVzaWdu
# Y2EyMDIwMFUGA1UdIAROMEwwQQYJKwYBBAGgMgECMDQwMgYIKwYBBQUHAgEWJmh0
# dHBzOi8vd3d3Lmdsb2JhbHNpZ24uY29tL3JlcG9zaXRvcnkvMAcGBWeBDAEDMAkG
# A1UdEwQCMAAwRwYDVR0fBEAwPjA8oDqgOIY2aHR0cDovL2NybC5nbG9iYWxzaWdu
# LmNvbS9nc2djY3I0NWV2Y29kZXNpZ25jYTIwMjAuY3JsMCUGA1UdEQQeMByBGmlu
# dGVybmFsc3VwcG9ydEB2YW5yb2V5LmJlMBMGA1UdJQQMMAoGCCsGAQUFBwMDMB8G
# A1UdIwQYMBaAFCWd0PxZCYZjxezzsRM7VxwDkjYRMB0GA1UdDgQWBBTK0YAYgvF2
# QDvEIiJPbX+LSWjqyDANBgkqhkiG9w0BAQsFAAOCAgEAnLnYZyO6/6z/jv7I8qiA
# As2oDu204HBF0RSTFqF2+KXr6UE8rnEizj6HRg4yrbqf2OBGS5pF4z/of9BPH+my
# hfqZv586hpwc+ILlk0ACaS9gSmJE5LkW/NMBfOYvIgL+YIinj0nUBekaFGhwJBpr
# woORIZGLs56rekoEdpL94obRkWimQD3lizWXQ3MdChnmE8Hbe5GCDF9OaGwjj+Wk
# tijwyIg1Klluw5tMecaLZS3rQ7nkgV/iLxoAcZvi0dTzB2TzVHmxoqi4nbAFRFwy
# kdbqOZzr+NeRShTmIh4ztXaGrwOmY4fseicRoxbwMKR5wrNEFE4seMx9ZCpZ4QpC
# bdLq70Q0yG21ZlH2Gvk74RNeabdARFgLREYlhtF9IdJg7PiEIwYzDfrrCIxOaRnJ
# DuEQ3+GKCmTH6HgqrbJYUnLRDhAWKQhetIjPr4DY7WWygrCEX7TiPazLo4uBIHeQ
# VRaH0Vlt2GG+HsEf0jkyPBjBAFBOOjrIE0++rgabF5o9GgrhTJMqM5BPux0u0QTJ
# VhqvuqsTOFLdmlwDgW2jMPlFjybwOo2ihQh0pQQfZrlIy7JogfmBAc07cwfxh+F7
# a08YdmXxZJnSfTbfNjcvE0DRtkVMQXE8nNI4Qd9QHZPe3nx+LgBStieCfIfQEYLe
# 6/1MqEf8HRYlWcXYYhC0+NIxggMNMIIDCQIBATBsMFwxCzAJBgNVBAYTAkJFMRkw
# FwYDVQQKExBHbG9iYWxTaWduIG52LXNhMTIwMAYDVQQDEylHbG9iYWxTaWduIEdD
# QyBSNDUgRVYgQ29kZVNpZ25pbmcgQ0EgMjAyMAIMRmPFdIT8ZL4tC2njMAkGBSsO
# AwIaBQCgeDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEM
# BgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqG
# SIb3DQEJBDEWBBRXLhonnY4BLx2C3eVLNqepMbjvPDANBgkqhkiG9w0BAQEFAASC
# AgCEwkTTRChKOnnNCMlhNXUit82HFT7BxB6rUviNuFA/nu4ZN7UKEiK40cqMUt5S
# gooI04zKAabp4c2anlnlvScuT6i0IE6rOI2gs4E5vImo5eQcMdYy6eqiH88CbzTc
# Zr6d4ER81PlwZ/gjsJT8+MqYUqZkjVAifhb+7jPMc9vsm6lxpc/6GNE3AcVB0tXg
# dPgCoLKbfchsv1c4n2fZRqFIxverSpoPDcFg9SnpG92AyY/eH3MuuQpwsPGyVMfz
# DAk4pGfzym2wFF1JOOWid6fomAhJPP3BazmqtPB41/TNW0JtcFYBuCT4HDpQh/p1
# IO8BebpbXJCAk2+/ggQQylUbD85L2Z3fOIutGS29C1bjWtWai4Q/VzaXejFxWaNH
# 0jaa+blibnsA4V/v/UMwNH5JTFC0JgfBYNwhAq14wyFpiFjpvtIMh9eH5bEQBB3c
# CYrD6RMid+pMFakWWaRcNHQrKXi0spG2TWq/5P9Cb7Sj1qUYahuv1Lwo/O5H9Qo9
# v0w4KbSmhvx2bABEK7yHzIo9rDGmfkLBnu1pZXAuksukvYtXFjxC3QdTVhI2jTNn
# NyxBCDzlBsVmu0+ZI46tT9ykJw42yX5gTSJuNxglwYexeGLU6peqfYFfb5JaYjky
# O+RYhrumlxDl20+Xvwah2G5wB3aM8oiMA7Vo7TovULtQvQ==
# SIG # End signature block
