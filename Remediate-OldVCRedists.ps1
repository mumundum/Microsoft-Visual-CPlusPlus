<#
.SYNOPSIS
Silently uninstall Microsoft Visual C++ Redistributables with major version < 11 (pre-2012).

Usage: Use this script as the "Remediation script" in Intune Proactive Remediations.
Runs as System; logs to C:\Windows\Temp\Remediate-OldVCRedists.log
#>

$LogFile = 'C:\Windows\Temp\Remediate-OldVCRedists.log'
function Log {
    param([string]$Message)
    $t = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    "$t - $Message" | Out-File -FilePath $LogFile -Append -Encoding utf8
}

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
if ($found.Count -eq 0) {
    Log "Compliant: No pre-2012 Visual C++ redistributables found."
    exit 0
}

$allSuccess = $true
foreach ($item in $found) {
    Log "Attempting uninstall: $($item.DisplayName) - $($item.DisplayVersion)"
    $u = $item.UninstallString
    if (-not $u) {
        Log "No UninstallString found for $($item.DisplayName) (Registry: $($item.RegistryKey))"
        $allSuccess = $false
        continue
    }

    try {
        if ($u -match '\{[0-9A-Fa-f\-]+\}') {
            # MSI product code present
            $guidMatch = ([regex]::Match($u, '\{[0-9A-Fa-f\-]+\}')).Value
            if ($guidMatch) {
                Log "Uninstalling MSI product $guidMatch via msiexec"
                $msiArgs = "/x $guidMatch /qn /norestart"
                $p = Start-Process -FilePath msiexec.exe -ArgumentList $msiArgs -Wait -PassThru -NoNewWindow
                if ($p.ExitCode -eq 0) { Log "msiexec returned 0 for $guidMatch" } else { Log "msiexec returned $($p.ExitCode) for $guidMatch"; $allSuccess = $false }
                continue
            }
        }

        # Try to parse exe uninstallers
        if ($u -match '"?([^\"\s]+\.exe)"?\s*(.*)') {
            $exe = $matches[1]
            $uninstallArgs = $matches[2].Trim()
            $argList = @()
            if ($uninstallArgs) { $argList = $uninstallArgs -split '\s+' }
            # Ensure typical silent uninstall switches
            if (-not ($argList -match '/uninstall' -or $argList -match '-uninstall')) { $argList += '/uninstall' }
            if (-not ($argList -match '/quiet' -or $argList -match '/q' -or $argList -match '/passive')) { $argList += '/quiet' }
            if (-not ($argList -match '/norestart')) { $argList += '/norestart' }

            Log "Running: $exe $($argList -join ' ')"
            $p = Start-Process -FilePath $exe -ArgumentList $argList -Wait -PassThru -NoNewWindow
            if ($p.ExitCode -eq 0) { Log "Uninstall succeeded for $($item.DisplayName)" } else { Log "Uninstall returned $($p.ExitCode) for $($item.DisplayName)"; $allSuccess = $false }
            continue
        }

        # Fallback: try to run the uninstall string directly
        Log "Fallback: running raw uninstall string: $u"
        Start-Process -FilePath 'cmd.exe' -ArgumentList '/c', $u, '/quiet', '/norestart' -Wait -NoNewWindow
    }
    catch {
        Log "Error uninstalling $($item.DisplayName): $($_.Exception.Message)"
        $allSuccess = $false
    }
}

if ($allSuccess) { Log "All targeted redistributables removed or uninstalled successfully."; exit 0 }
else { Log "One or more uninstall attempts failed. Check log for details: $LogFile"; exit 1 }
