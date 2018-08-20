# PowershellTimeResync
A script for resyncing time on those computer where the BIOS battery is broken and system time is reset at every boot.

It reads the current ntp server from the w32time service, performs an ntp request to get the current time and sets it.
Upon completion it forces a time resync through w32tm.exe just to make sure the drift is minimal.

**Why not just a resync?**
Widening the acceptance window through registry for a resync with the W32Time service does not guarantee the time actually gets resynced if the drift is extremely large (it can happen with bad BIOS batteries).

## Registering a scheduled task:
In order to register a new scheduled task that performs the resync at boot time, execute the following command in an elevated Powershell (from the project folder):
`.\CreateScheduledTask.ps1 -ScriptPath .\Resync-Time.ps1`
The script uses schtasks.exe for compatibility with Windows 7.

## Warning:
Since changing the time is a sensitive operation, your antivirus may block the script. If this happens, please whitelist the script in order to let it perform as expected.

## Credits:
Get-NtpTime function is adapted from https://chrisjwarwick.wordpress.com/2012/09/16/getting-sntp-network-time-with-powershell-improved/
