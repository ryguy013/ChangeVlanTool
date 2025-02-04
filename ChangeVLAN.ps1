# Copyright (c) 2025, Ryan Rider
# All rights reserved.

# This source code is licensed under the GNU GPLv3 license found in the
# LICENSE file in the root directory of this source tree. 

# Change VLAN tool - User side execution script.
# Version 0.4

# Define the path to the JSON configuration file
$configFilePath = "C:\ProgramData\AutoPilotConfig\ChangeVlanTool\VLANConfig.json"

# Verify the JSON file exits
#Write-Host "Verifying JSON file exists..." -ForegroundColor Cyan
if (Test-Path $configFilePath) {
    #Write-Host "Confirmed." -ForegroundColor Green
} else {
    Write-Host "Error: JSON File not found. Verify that scripts and JSON file are in the following directory: $configFilePath" -ForegroundColor Red
    Read-Host -Prompt "Press Enter to exit"
    exit 1
}

# Scan all Ethernet adapters and display details
Write-Host "Scanning network interfaces..." -ForegroundColor Cyan
$adapters = Get-NetAdapter | Where-Object { $_.InterfaceDescription -match "Ethernet" -or $_.Name -match "Ethernet" }

if (-not $adapters) {
    Write-Host "No Ethernet interfaces found on this machine." -ForegroundColor Red
    Read-Host -Prompt "Press Enter to exit"
    exit 1
}

Write-Host "`nAvailable Ethernet Interfaces:" -ForegroundColor Green
foreach ($adapter in $adapters) {
    $adapterName = $adapter.Name
    $adapterDescription = $adapter.InterfaceDescription
    $status = $adapter.Status
    $ipAddress = (Get-NetIPAddress -InterfaceAlias $adapterName -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress
    $ipAddress = $ipAddress -join ", " # Handle multiple IPs
    $vlan = try {
        Get-NetAdapterAdvancedProperty -Name $adapterName -DisplayName "VLAN ID" -ErrorAction Stop | Select-Object -ExpandProperty DisplayValue
    } catch {
        "No VLAN configured"
    }

    Write-Host "----------------------------------" -ForegroundColor Yellow
    Write-Host "Interface: $adapterName" -ForegroundColor White
    Write-host "Description: $adapterDescription" 
    Write-Host "Status:    $status"
    Write-Host "IP:        $ipAddress"
    Write-Host "VLAN:      $vlan"
}
Write-Host "----------------------------------" -ForegroundColor Yellow

# Prompt user to select an interface
do {
    # Get user input
    $selectedAdapter = Read-Host "Select an interface to change the VLAN (type the exact name)"

    # Check if the entered name exists in the list of adapters
    if ($adapters.Name -contains $selectedAdapter) {
        break  # Exit the loop if valid
    } else {
        Write-Host "Invalid interface name. Please try again." -ForegroundColor Red
    }
} while ($true)  # Loop until a valid name is entered

# Prompt user to input the VLAN ID
do {
    # Prompt user for VLAN ID
    $vlanID = Read-Host "What VLAN would you like to set the interface to? (Enter 0 to remove VLAN configuration)"

    # Check if the input is a valid VLAN ID (0-4095)
    if ($vlanID -match '^(?:[0-9]|[1-9][0-9]{1,2}|[1-3][0-9]{3}|40[0-8][0-9]|409[0-5])$') {
        break  # Exit the loop if valid
    } else {
        Write-Host "Invalid VLAN ID. Please enter a numeric VLAN ID between 0 and 4095." -ForegroundColor Red
    }
} while ($true)  # Keep prompting until a valid input is given


# Write the variables to the JSON file
$config = @{
    InterfaceName = $selectedAdapter
    VlanID        = [int]$vlanID
}
$config | ConvertTo-Json | Set-Content -Path $configFilePath -Encoding UTF8

# Validation: Read the file back and compare content
if (Test-Path $configFilePath) {
    $readData = Get-Content -Path $configFilePath -Raw | ConvertFrom-Json

    # Ensure the read data matches the expected values
    if ($readData.InterfaceName -eq $config.InterfaceName -and $readData.VlanID -eq $config.VlanID) {
        # Proceed if JSON file exists
    } else {
        Write-Host "Error: JSON file does not match expected values. Please try again." -ForegroundColor Red
        Read-Host -Prompt "Press Enter to exit"
        exit 1
    }
} else {
    Write-Host "Error: JSON file could not be created. Please check file permissions." -ForegroundColor Red
    Read-Host -Prompt "Press Enter to exit"
    exit 1
}

# Trigger the scheduled task via event viewer. This is due to the user running this not being a elevated user.
try {
    Write-EventLog -LogName Application -Source "VLAN Change Script" -EntryType Information -EventID 100 -Message "The VLAN Change Script has been run and is trying to change the VLAN."
    Write-Host "`nVLAN configuration initiated..." -ForegroundColor Green
    Start-Sleep -Seconds 5
} catch {
    Write-Host "Failed to trigger the scheduled task. Ensure the task is pre-configured correctly. Error: $_" -ForegroundColor Red
    Read-Host -Prompt "Press Enter to exit"
    exit 1
}

# Pull the status of the interfaces again for the user to review the change
Write-Host "`nVLAN Configuration complete. Refreshing interface information..." -ForegroundColor Cyan

foreach ($adapter in $adapters) {
    $adapterName = $adapter.Name
    $adapterDescription = $adapter.InterfaceDescription
    $status = $adapter.Status
    $ipAddress = (Get-NetIPAddress -InterfaceAlias $adapterName -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress
    $ipAddress = $ipAddress -join ", " # Handle multiple IPs
    $vlan = try {
        Get-NetAdapterAdvancedProperty -Name $adapterName -DisplayName "VLAN ID" -ErrorAction Stop | Select-Object -ExpandProperty DisplayValue
    } catch {
        "No VLAN configured"
    }

    Write-Host "----------------------------------" -ForegroundColor Yellow
    Write-Host "Interface: $adapterName" -ForegroundColor White
    Write-host "Description: $adapterDescription" 
    Write-Host "Status:    $status"
    Write-Host "IP:        $ipAddress"
    Write-Host "VLAN:      $vlan"
}
Write-Host "----------------------------------" -ForegroundColor Yellow

# Prompt to exit so script doesn't auto close
Read-Host -Prompt "Press Enter to exit"