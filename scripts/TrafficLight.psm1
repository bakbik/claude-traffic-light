# TrafficLight.psm1 — COM port resolution + serial write for the Claude traffic light.

function Get-TrafficPort {
  param([object[]]$Devices)

  if ($env:TRAFFIC_COM) { return $env:TRAFFIC_COM }

  if (-not $PSBoundParameters.ContainsKey('Devices')) {
    $Devices = Get-CimInstance Win32_PnPEntity
  }

  foreach ($d in $Devices) {
    if ($d.DeviceID -match 'VID_303A' -and $d.Name -match '\((COM\d+)\)') {
      return $Matches[1]
    }
  }
  return $null
}

function Send-TrafficColor {
  param([Parameter(Mandatory)][ValidateSet('R','G','Y','O')][string]$Color)

  $port = Get-TrafficPort
  if (-not $port) { return $false }

  try {
    $sp = New-Object System.IO.Ports.SerialPort $port, 115200
    $sp.WriteTimeout = 500
    $sp.Open()
    $sp.Write($Color)
    $sp.Close()
    return $true
  } catch {
    return $false
  }
}

Export-ModuleMember -Function Get-TrafficPort, Send-TrafficColor
