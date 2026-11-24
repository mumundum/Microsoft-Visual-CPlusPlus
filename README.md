# Intune Remediation: End of Life Microsoft Visual C++ Redistributables

These Windows PowerShell 5.1 scripts detect and remove pre-2012 Microsoft Visual C++ redistributables. Deploy Detect-OldVCRedists.ps1 as the Intune detection script and Remediate-OldVCRedists.ps1 as its remediation script. Run both scripts in the 64-bit PowerShell host as SYSTEM.

## Detection

The detection script searches the 64-bit and 32-bit uninstall registry locations for Microsoft Visual C++ redistributables released before 2012.

- Exit code 0 indicates that no targeted redistributables were found.
- Exit code 1 indicates that one or more pre-2012 redistributables were found.

## Remediation

The remediation script reads the uninstall information for each detected redistributable and attempts a silent uninstall.

- Exit code 0 indicates that no targeted redistributables remain or that all uninstall attempts succeeded.
- Exit code 1 indicates that one or more uninstall attempts failed.

## Intune configuration

- Detection script: Detect-OldVCRedists.ps1
- Remediation script: Remediate-OldVCRedists.ps1
- Run scripts in 64-bit PowerShell: Enabled
- Run as: System
