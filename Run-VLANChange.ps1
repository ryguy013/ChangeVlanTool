# Copyright (c) 2025, Ryan Rider
# All rights reserved.

# This source code is licensed under the GNU GPLv3 license found in the
# LICENSE file in the root directory of this source tree. 

# Change VLAN tool - backend execution script.
# Version 0.4

# Define the path to the JSON configuration file
$configFilePath = "C:\ProgramData\AutoPilotConfig\ChangeVlanTool\VLANConfig.json"

# Verify that the JSON file exists
if (-not (Test-Path $configFilePath)) {
    Write-Output "Configuration file not found at $configFilePath. Ensure the file exists and is correctly configured."
    exit 1
}

# Read the JSON configuration file
try {
    $config = Get-Content -Path $configFilePath | ConvertFrom-Json
    $interfaceName = $config.InterfaceName
    $vlanID = $config.VlanID
} catch {
    Write-Output "Failed to read or parse the configuration file. Error: $_"
    exit 1
}

# Validate VLAN ID (must be 0-4095)
if (-not ($vlanID -match '^(?:[0-9]|[1-9][0-9]{1,2}|[1-3][0-9]{3}|40[0-8][0-9]|409[0-5])$')) {
    Write-Output "Error: VLAN ID '$vlanID' is invalid. Please ensure it is between 0 and 4095."
    exit 1
}

# Validate Interface Name (must be 15 characters or less)
if ($interfaceName.Length -gt 15) {
    Write-Output "Error: Interface name '$interfaceName' is too long. Maximum length is 15 characters."
    exit 1
}

# Apply VLAN Configuration
try {
    Set-NetAdapterAdvancedProperty -Name $interfaceName -DisplayName "VLAN ID" -DisplayValue $vlanID
    Restart-NetAdapter -Name $adapterName
    Write-Output "Successfully configured VLAN $vlanID for interface $interfaceName."
} catch {
    Write-Output "Failed to configure VLAN. Error: $_"
}

