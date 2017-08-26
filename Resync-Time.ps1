Function Get-NtpTime {
	# Adapted from https://chrisjwarwick.wordpress.com/2012/09/16/getting-sntp-network-time-with-powershell-improved/

    Param (
        [string]$Server = 'time.windows.com'
    )

    $StartOfEpoch=New-Object DateTime(1900,1,1,0,0,0,[DateTimeKind]::Utc)   

    [Byte[]]$NtpData = ,0 * 48
    $NtpData[0] = 0x1B    # NTP Request header in first byte

    $Socket = New-Object Net.Sockets.Socket([Net.Sockets.AddressFamily]::InterNetwork,
                                            [Net.Sockets.SocketType]::Dgram,
                                            [Net.Sockets.ProtocolType]::Udp)
    $Socket.Connect($Server,123)
    $t1 = Get-Date    # Start of transaction... the clock is ticking...
    [Void]$Socket.Send($NtpData)
    [Void]$Socket.Receive($NtpData)  
    $t4 = Get-Date    # End of transaction time
    $Socket.Close()

    $IntPart = [BitConverter]::ToUInt32($NtpData[43..40],0)   # t3
    $FracPart = [BitConverter]::ToUInt32($NtpData[47..44],0)
    $t3ms = $IntPart * 1000 + ($FracPart * 1000 / 0x100000000)

    $IntPart = [BitConverter]::ToUInt32($NtpData[35..32],0)   # t2
    $FracPart = [BitConverter]::ToUInt32($NtpData[39..36],0)
    $t2ms = $IntPart * 1000 + ($FracPart * 1000 / 0x100000000)

    $t1ms = ([TimeZoneInfo]::ConvertTimeToUtc($t1) - $StartOfEpoch).TotalMilliseconds
    $t4ms = ([TimeZoneInfo]::ConvertTimeToUtc($t4) - $StartOfEpoch).TotalMilliseconds
 
    $Offset = (($t2ms - $t1ms) + ($t3ms-$t4ms))/2

    # ToLocalTime() uses OS time zone configuration to correct UTC to proper time zone.
    return ($StartOfEpoch.AddMilliseconds($t4ms + $Offset).ToLocalTime())
}

# Wait for an internet connection.
While (!(Test-Connection -ComputerName www.google.com -Count 1 -Quiet)) {
    Start-Sleep -Seconds 2
}

# Get ntp server from w32time configuration.
$NtpServer = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\services\W32Time\Parameters' -Name NtpServer).NtpServer
$NtpServer = $NtpServer.Split(',')[0]

# Set new time.
Set-Date -Date (Get-NtpTime -Server $NtpServer)

# Save current w32time service status.
$ServiceStatus = (Get-Service -Name W32Time).Status

# Start/restart w32time service.
Restart-Service -Name W32Time

# Resync time just in case.
w32tm /resync

# Restore w32time service status.
Set-Service -Name W32Time -Status $ServiceStatus

#region Old approach
<#
# Widen resync window.
$ConfigRegistry = 'HKLM:\SYSTEM\CurrentControlSet\services\W32Time\Config'
$ConfigBackup = Get-ItemProperty $ConfigRegistry

Set-ItemProperty $ConfigRegistry -Name 'MaxNegPhaseCorrection' -Value 4294967295
Set-ItemProperty $ConfigRegistry -Name 'MaxPosPhaseCorrection' -Value 4294967295

# Start/restart w32time service.
Restart-Service -Name W32Time

# Resync time just in case.
w32tm /resync

# Restore original resync window.
Set-ItemProperty $ConfigRegistry -Name 'MaxNegPhaseCorrection' -Value $ConfigBackup.MaxNegPhaseCorrection
Set-ItemProperty $ConfigRegistry -Name 'MaxPosPhaseCorrection' -Value $ConfigBackup.MaxPosPhaseCorrection
#>
#endregion