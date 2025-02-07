## [0.4.0] - 2025-02-04
### Added
    Added creation of desktop shortcut to SetupScript.ps1
    Added detection of scheduled task aleady existing to SetupScript.ps1
    Added creation of proper event trigger to SetupScript.ps1
    Added Data validation to Run-VLANChange.ps1 when pulling from JSON and ChangeVLAN.ps1 when writing to the JSON file.
    Created RUN_SETUP shortcut to make setup easier.
    Removed unnecessary output to end user that was used for debugging.
    Added general file path verification to SetupScript.ps1 to make sure the Change Vlan Tool is in the right directory.
### Fixed
    Fixed the desktop shortcut creation in SetupScript.ps1 to find the currently logged in user.

## [0.3.0] - 2025-01-29
### Added
    Modified script to trigger scheduled task from event viewer log message

## [0.2.0] - 2025-01-29
### Added    
    Changed to using a json file for variables between ChangeVLAN.ps1 and Run-VLANChange.ps1

## [0.1.0] - 2025-01-28
    Initial Draft