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
                } else {
                    if ($name -match '2005') { $major = 8 }
                    elseif ($name -match '2008') { $major = 9 }
                    elseif ($name -match '2010') { $major = 10 }
                    elseif ($name -match '2012') { $major = 11 }
                    elseif ($name -match '2013') { $major = 12 }
                }

                if ($major -and $major -lt 11) {
                    $results += [PSCustomObject]@{
                        DisplayName = $name
                        DisplayVersion = $version
                        UninstallString = $props.UninstallString
                        RegistryKey = $_.PsPath
                    }
                }
            }
        }
    }
    return $results
}

$found = @(Get-InstalledVCRedists)
if ($found.Count -gt 0) {
    $versions = $found | ForEach-Object { $_.DisplayName + ' ' + $_.DisplayVersion }
    Write-Output "Non-Compliant: Pre-2012 Visual C++ redistributables detected."
    $versions | ForEach-Object { Write-Output $_ }
    exit 1
} else {
    Write-Output "Compliant: No pre-2012 Visual C++ redistributables found."
    exit 0
}
