#Script to Enable VSS with Custom Schedule, Disabe Default VSS tasks if there are any, update ninja custom feilds.

#Setting Varibles
$date = Get-Date -Format yyyy-MM-dd

New-Item -ItemType Directory -Force -Path C:\DiscStuff\Logs

$ScheduledTasks = @()
$DisabledTasks = @()

#Enable VSS and Set tasks
$Disks = Get-Volume | Where-Object {$_.DriveType -eq "Fixed"} | Where-Object {$_.DriveLetter -ne $null} | Where-Object {$_.Size -gt 5GB}

$offset = New-TimeSpan
$offsetInterval = New-TimeSpan -Minutes 15

foreach ($Disk in $Disks) {
    # Enable Shadows
    vssadmin add shadowstorage /for=$($Disk.DriveLetter): /on=$($Disk.DriveLetter): /maxsize=10%
    # Set Shadow Copy Scheduled Task for C: 06:00, 12:00 and 17:00

    $time1 = New-TimeSpan -Hours 6
    $time2 = New-TimeSpan -Hours 12
    $time3 = New-TimeSpan -Hours 17

    $Argument = "-command ""C:\Windows\system32\vssadmin.exe create shadow /for=$($Disk.DriveLetter):"""
    $Action = new-scheduledtaskaction -execute "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument $Argument
    $Trigger1 = new-scheduledtasktrigger -daily -at ($time1 + $offset).ToString()
    $Trigger2 = new-scheduledtasktrigger -daily -at ($time2 + $offset).ToString()
    $Trigger3 = new-scheduledtasktrigger -daily -at ($time3 + $offset).ToString()
    Register-ScheduledTask -TaskName "ShadowCopy $($Disk.DriveLetter) drive" -Trigger $Trigger1,$Trigger2,$Trigger3 -Action $Action -Description "ShadowCopy for $($Disk.DriveLetter) drive" -user "NT AUTHORITY\SYSTEM" -RunLevel Highest -Force
    $offset = $offset + $offsetInterval
}

#Disable Default tasks
$ScheduledTasks = Get-ScheduledTask -TaskName "ShadowCopyVolume{*}"

$DisabledTasks = foreach ($Task in $ScheduledTasks){Disable-ScheduledTask -TaskName $Task.TaskName}

$DisabledTasks | ConvertTo-html -Property TaskName, State | Out-File C:\DiscStuff\Logs\$date-Shadows.html

if (!$DisabledTasks) {Write-Host "No Default VSS Tasks Disabled"}
else {Write-Host "Default VSS Tasks have been disabled. Please see log on Device to see details: C:\DiscStuff\Logs"}

#Update Custom feilds
$ScheduledTasks = Get-ScheduledTask -TaskName "ShadowCopy*"
$DefaultTasks = Get-ScheduledTask -TaskName "ShadowCopyVolume{*}"
$CustomTasks = Get-ScheduledTask -TaskName "ShadowCopy * drive"

$VSS = [PSCustomObject]@{
    enabled = $false
    type = $null
}
#No Tasks
if ($ScheduledTasks -eq $null)
    {Write-Host "No VSS Tasks"}
#Default Tasks
elseif ($DefaultTasks.State -ne "Disabled")
    {Write-Host "Default VSS Tasks Enabled"; $VSS.enabled = $true; $VSS.type = "Default"}
#Default Tasks Disabled and No Custom Tasks
if (($DefaultTasks.State -eq "Disabled") -and ($CustomTasks -eq $null))
    {Write-Host "Default VSS Tasks Disabled and NO Custom VSS Tasks"; $VSS.enabled = $false; $VSS.type = "Default"}
#Default Tasks Disabled and Custom Tasks Enabled
if ((($DefaultTasks.State -eq "Disabled") -or ($DefaultTasks -eq $null)) -and ($CustomTasks -ne $null))
    {Write-Host "Default VSS Tasks Disabled and Custom VSS Tasks Enabled"; $VSS.enabled = $true; $VSS.type = "Custom"}

if ($Host.Version.Major -gt 4){Write-Host $VSS}
elseif ($Host.Version.Major -lt 5){$VSS}

Ninja-Property-Set vssenabled $VSS.enabled
Ninja-Property-Set vsstype $VSS.type
