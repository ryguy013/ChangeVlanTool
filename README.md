# ChangeVlanTool
A powershell tool that allows none admins to change the VLAN on ethernet interfaces.


Version 0.4.0-alpha

## What does this tool do?

The goal of this tool is to allow standard windows users the ability to change the vlan on an ethernet NIC without administrator intervention. The user would typically be a member of the local windows group Network Configuration Operators allowing them to change other NIC configuration items, but vlan configuration is under the NIC device properties which requires administrator privileges.

I made this for field technicians that may need to change their VLAN for troubleshooting/equipment setup but aren't administrators on their computers, or where they won't have network access to use JIT access to request permission.

## Tested Compatibility

This tool should work on most Windows 10/11 versions but have only been directly tested on the below and newer:

Windows 11 24H2 w/Powershell 5.1

## Setup Instructions

Download all files and place them in the directory: C:\ProgramData\AutoPilotConfig\ChangeVlanTool
This is the file path referenced by the scripts and is where all files should be located.

Log in as the user who needs Change VLAN capability. 
Run the RUN_SETUP as administrator

Add the user to the local group "Network Configuration Operators".

## How it works

The setup script registers a new Event Viewer Source, creates a scheduled task, and creates a 
desktop shortcut to the ChangeVLAN.ps1 script.

When the user executes the desktop shortcut it runs the ChangeVLAN.ps1 script with ExecutionPolicy bypass. 
It scans for available ethernet interfaces and prompts the user to input the name of the interface and vlan ID they want configured.

It then modifies the VLANConfig.json file to store that information and writes a message to 
event viewer using event ID 100 with the log source "VLAN Change Script".

The scheduled task is set to trigger for that specific event ID and source. Upon trigger it 
will execute the Run-VLANChange.ps1 script as the SYSTEM user.

The Run-VLANChange.ps1 file reads the JSON file for two variables, the NIC interface name and the 
vlan the user requests it to be changed to. It then executes the vlan change requested.

## Feature Idea's

Create a method to limit allowed vlans that can be entered into the tool.

Add error handling/logging to event viewer.

Would reseting the vlan property be better when entering 0?
Reset-NetAdapterAdvancedProperty -Name $adapterName -DisplayName "VLAN ID"

Test failure modes, bad input, etc.

Test how long the "VLAN configuration initiating" pause needs to be, or if we should just validate 
the change has happened and error if it doesn't work after x seconds.

SetupScript:

Automatically add user to Network Configuration Operators

Should I make a config file for the setup script to pull from so others can configure it easier for other environments?
This would include file paths, event log source, XML content, etc.

Could also just automate the directory placement and request for file path in the setup script.
        



