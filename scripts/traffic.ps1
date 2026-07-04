# traffic.ps1 — called by the claude-traffic-light plugin hooks.
# Usage: traffic.ps1 R|Y|G|O
param([Parameter(Mandatory)][ValidateSet('R','G','Y','O')][string]$Color)

Import-Module "$PSScriptRoot/TrafficLight.psm1" -Force
$ok = Send-TrafficColor -Color $Color
# breadcrumb: proves the hook actually ran
"{0}  {1}  sent={2}" -f (Get-Date -Format 'HH:mm:ss'), $Color, $ok |
  Out-File -FilePath "$PSScriptRoot/traffic.log" -Append -Encoding utf8
exit 0   # never fail a hook, even if the light is unplugged
