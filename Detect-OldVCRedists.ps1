<#
.SYNOPSIS
Detects pre-2012 Microsoft Visual C++ redistributables.

Usage: Use this script as the "Detection script" paired with Remediate-OldVCRedists.ps1 in Intune Remediations. Run in 64-bit PowerShell as SYSTEM.
Return: exits with code 0 when no pre-2012 redistributables are found and code 1 when any are found.
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
            if (-not $props) { return }

            $name = $props.DisplayName
            if (-not $name) { $name = $props.ProductName }
            if (-not $name) { return }

            if ($name -match 'Microsoft Visual C\+\+.*Redistributable') {
                $version = $props.DisplayVersion
                if (-not $version) { $version = $props.Version }

                $major = $null
                if ($version) {
                    if ($version -match '^(\d+)') { $major = [int]$matches[1] }
                }
                else {
                    if ($name -match '2005') { $major = 8 }
                    elseif ($name -match '2008') { $major = 9 }
                    elseif ($name -match '2010') { $major = 10 }
                    elseif ($name -match '2012') { $major = 11 }
                    elseif ($name -match '2013') { $major = 12 }
                }

                if ($major -and $major -lt 11) {
                    $results += [PSCustomObject]@{
                        DisplayName     = $name
                        DisplayVersion  = $version
                        UninstallString = $props.UninstallString
                        RegistryKey     = $_.PsPath
                    }
                }
            }
        }
    }
    return $results
}

$found = @(Get-InstalledVCRedists)
if ($found.Count -gt 0) {
    $versionSummary = ($found | ForEach-Object { $_.DisplayVersion } | Sort-Object -Unique | ForEach-Object { "VC++ $($_)" }) -join '; '
    Write-Output "Non-Compliant: $versionSummary"
    exit 1
}
else {
    Write-Output "Compliant: No pre-2012 Visual C++ redistributables found."
    exit 0
}
