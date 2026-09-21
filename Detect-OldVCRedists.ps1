<#
.SYNOPSIS
Detect installed Microsoft Visual C++ Redistributables with major version < 11 (pre-2012).

Usage: Use this script as the "Detection script" in Intune Proactive Remediations.
Return: exits with code 1 if any pre-2012 redistributables are found, otherwise exits 0.
#>

function Get-InstalledVCRedists {
    $paths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
    )
    $results = @()
    foreach ($p in $paths) {
        Get-ChildItem -Path $p -ErrorAction SilentlyContinue | ForEach-Object {
                $props = Get-ItemProperty -Path $_.PsPath -ErrorAction SilentlyContinue
            if (-not $props) { continue }
            $dn = $props.DisplayName
            if (-not $dn) { continue }
            if ($dn -match 'Microsoft Visual C\+\+.*Redistributable') {
                $ver = $props.DisplayVersion
                $major = $null
                if ($ver -and ($ver -match '^(\d+)')) {
                    $major = [int]$matches[1]
                } else {
                    if ($dn -match '2005') { $major = 8 }
                    elseif ($dn -match '2008') { $major = 9 }
                    elseif ($dn -match '2010') { $major = 10 }
                    elseif ($dn -match '2012') { $major = 11 }
                    elseif ($dn -match '2013') { $major = 12 }
                }
                if ($major -and $major -lt 11) {
                    $results += [PSCustomObject]@{
                        DisplayName = $dn
                        DisplayVersion = $props.DisplayVersion
                        UninstallString = $props.UninstallString
                        RegistryKey = $_.PsPath
                    }
                }
            }
        }
    }
    return $results
}

$found = Get-InstalledVCRedists
if (@($found).Count -gt 0) {
    $found | ConvertTo-Json -Depth 4
    exit 1
} else {
    Write-Output "No pre-2012 Visual C++ redistributables found."
    exit 0
}
