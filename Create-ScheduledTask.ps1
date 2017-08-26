Param (
    [Parameter(Mandatory=$true)]
    [string]$ScriptPath
)

$ScriptPath = Resolve-Path $ScriptPath
$CurrentPath = Resolve-Path '.\SchedTask.xml'

[xml]$xml = Get-Content '.\SchedTask.xml'
$xml.Task.RegistrationInfo.Author = $env:USERNAME
$xml.Task.Actions.Exec.Arguments = '-ExecutionPolicy Bypass -File "' + $ScriptPath + '"'
$xml.Save($CurrentPath.Path.Replace('SchedTask.xml', 'temp.xml'))
schtasks.exe /Create /XML temp.xml /TN "Time Resync"
Remove-Item temp.xml