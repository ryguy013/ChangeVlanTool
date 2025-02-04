# Copyright (c) 2025, Ryan Rider
# All rights reserved.

# This source code is licensed under the GNU GPLv3 license found in the
# LICENSE file in the root directory of this source tree. 

# Change VLAN tool - Setup Script
# Version 0.4


# Define the path to the script that the scheduled task will execute
$taskScriptPath = "C:\ProgramData\AutoPilotConfig\ChangeVlanTool\Run-VLANChange.ps1"

# Test that all the files are in the correct directory and exist
$filePath = "C:\ProgramData\AutoPilotConfig\ChangeVlanTool"

if (Test-Path $filePath) {
    # just continue
} else {
    Write-Host "Error: Verify that scripts and JSON file are in the following directory: $filePath" -ForegroundColor Red
    exit 1
}

# Check if the event log source exists
$eventSource = "VLAN Change Script"
$logName = "Application"

if ([System.Diagnostics.EventLog]::SourceExists($eventSource)) {
    Write-Host "Event log source '$eventSource' already exists. Proceeding..." -ForegroundColor Green
} else {
    # Create the event log source
    Write-Host "Creating event log source '$eventSource' in log '$logName'..." -ForegroundColor Yellow
    New-EventLog -LogName $logName -Source $eventSource
    Write-Host "Event log source '$eventSource' created successfully." -ForegroundColor Green
}

# Check if the scheduled task already exists
$taskName = "DynamicVLANConfig"
$taskExists = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

# Register the scheduled task if it doesn't exist
if (-not $taskExists) {
    # Define the scheduled task variables
    $taskName = "DynamicVLANConfig"
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$taskScriptPath`""
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount

    # Define scheduled task trigger on event variables
    $CIMTriggerClass = Get-CimClass -ClassName MSFT_TaskEventTrigger -Namespace Root/Microsoft/Windows/TaskScheduler:MSFT_TaskEventTrigger
    $Trigger = New-CimInstance -CimClass $CIMTriggerClass -ClientOnly
    $Trigger.Subscription = @"
    <QueryList><Query Id="0" Path="Application"><Select Path="Application">*[System[Provider[@Name='VLAN Change Script'] and EventID=100]]</Select></Query></QueryList>
"@
    $Trigger.Enabled = $True
    try {
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $Trigger -Principal $principal -Description "Triggers VLAN change when Event ID 100 is logged in Application log."
        Write-Host "Scheduled task '$taskName' created successfully." -ForegroundColor Green
    } catch {
        Write-Host "Failed to create scheduled task. Error: $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "Scheduled task '$taskName' already exists. No action taken." -ForegroundColor Yellow
}

# Verify the task was created
Get-ScheduledTask -TaskName $taskName

# Create Desktop Shortcut for current user
Write-Host "Creating Desktop shortcut..." -ForegroundColor Cyan

# Define shortcut name
$ShortcutName = "Change VLAN Tool.lnk"

# Get the current user's desktop path explicitly. Have to do it a weird way since this script has to be run as admin, 
# default environment variables get overwritten to the user that elevated the powershell session.
$LoggedInUser = (Get-CimInstance -ClassName Win32_ComputerSystem).UserName -replace '^.*\\', ''
$UserProfilePath = "C:\Users\$LoggedInUser"
$DesktopPath = [System.IO.Path]::Combine($UserProfilePath, "Desktop")
$ShortcutPath = Join-Path -Path $DesktopPath -ChildPath $ShortcutName

# Check if shortcut exists, if so, skip creation
if (Test-Path $ShortcutPath) {
    Write-Host "Shortcut already exists. Skipping creation." -ForegroundColor Yellow
    exit 0
}

Write-Host "Shortcut does not exist. Creating now..."

# Create COM object
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutPath)

# Define shortcut properties
$Shortcut.TargetPath = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
$Shortcut.Arguments = '-ExecutionPolicy Bypass -File "C:\ProgramData\AutoPilotConfig\ChangeVlanTool\ChangeVLAN.ps1"'
$Shortcut.Description = "Shortcut to Change VLAN Tool"
$Shortcut.Save()

Write-Host "Shortcut created successfully at: $ShortcutPath" -ForegroundColor Green

# Prompt to exit so script doesn't auto close
Read-Host -Prompt "Setup Complete. Press any key to exit"