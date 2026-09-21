# Microsoft-Visual-CPlusPlus

This folder contains detection and remediation PowerShell scripts for use with Microsoft Intune Proactive Remediations.

Files:
- `Detect-OldVCRedists.ps1` : Detection script. Exits with code `1` when one or more pre-2012 (major &lt; 11) Visual C++ redistributables are found; exits `0` otherwise.
- `Remediate-OldVCRedists.ps1` : Remediation script. Silently uninstalls the found redistributables. Logs to `C:\Windows\Temp\Remediate-OldVCRedists.log`.

Intune guidance:
- Use `Detect-OldVCRedists.ps1` as the **Detection script** and `Remediate-OldVCRedists.ps1` as the **Remediation script** in a Proactive Remediations package.
- Run both scripts in the **system** context (default) and **64-bit PowerShell**.
- Test on a small pilot group first.

Notes & caveats:
- The scripts rely on the Uninstall registry keys and the presence of `UninstallString`. Some installers may not support silent switches; those entries may require manual handling.
- Always review the log file after remediation runs to confirm success.
