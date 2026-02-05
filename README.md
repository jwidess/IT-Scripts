# IT-Scripts
IT Related PowerShell and cmd Scripts.

## Table of Contents
- [Active Directory](#active-directory)
- [AHK (AutoHotKey)](#ahk-autohotkey)
- [Entra](#entra)
- [Other](#other)
- [Windows](#windows)

---

## Active Directory

### Check_AD_Default_Location.ps1
Checks and displays the default Active Directory containers for new users and computers in the current domain.

### Check_Domain_Response.ps1
Troubleshoots Active Directory domain connectivity and DNS issues by displaying network DNS suffixes and running nslookup/nltest commands for AD SRV records and domain controller details.

### Get_AD_User&Computers.ps1
Retrieves and displays all enabled and disabled users and computers in Active Directory along with their Organizational Units (OUs).

### Update_ADMX_Files.ps1
Prompts for a folder containing extracted ADMX files and the Central Store path (e.g. \\domain.com\SYSVOL\domain.com\Policies\PolicyDefinitions), verifies changes, backs up the existing PolicyDefinitions to the user's Documents folder, and copies .admx and en-US .adml files.

---

## AHK (AutoHotKey)

### TypeClipboard.ahk
AutoHotKey script that types clipboard contents as keystrokes when Ctrl+Shift+V is pressed. Useful for pasting into applications that don't support traditional paste operations.

---

## Entra

### Get_MFA_User_Status.ps1
Retrieves the MFA (Multi-Factor Authentication) status of users in Microsoft Entra ID and exports results to a CSV file. Shows which users have MFA registered and what authentication methods they use.

---

## Other

### CVE
#### GatherCVEInfoV2.ps1
Queries the NIST CVE API to gather information about specified CVE vulnerabilities including severity, CVSS scores, and descriptions. Exports results to CSV format.

### WinSCP
#### GenerateHTTPS-URL-HTML.WinSCPextension.ps1
WinSCP extension that generates HTTPS URLs for selected files with the /html/ root path removed.

---

## Windows

### Backup Scripts

#### Prior to Reinstall Backup
##### BackupToDrive.ps1
Recursively backs up specified directories to a location with exclusion rules, removes NTFS permissions from copied files, and logs errors to CSV. Designed for pre-reinstall system backups.

#### Win 11 Start Menu Pinned Items Backup
##### Backup_StartMenuItems.ps1
Backs up Windows 11 Start Menu pinned items (start.bin and start2.bin files) to preserve Start Menu customizations.

#### Windows Users Folder Backup
##### Users_Folder_Backup.ps1
Copies Windows Users folder without file permission structures, excluding AppData folders to make user data migration easier.

### File Permissions

#### Get_Access_Folder_Recurse.ps1
Takes ownership and resets permissions recursively on a specified folder, granting full control to the current user and removing all other permissions.

#### Personal Folders
##### PersonalFolderPermissions.ps1
Grants a specified user full control permissions to their personal folder on a file server. Creates the folder if it doesn't exist.

##### CSVListPersonalFolderPermissions.ps1
Reads a CSV file containing usernames and grants each user full control permissions to their personal folder on a file server. Batch version of PersonalFolderPermissions.ps1.

### Firewall

#### Firewall_Block_All_EXE_in_Folder_Mk2.ps1
Recursively finds all .exe files in the current directory and subdirectories, then adds Windows Firewall rules to block each executable (both inbound and outbound).

#### Firewall_UNBlock_All_EXE_in_Folder_Mk2.ps1
Removes Windows Firewall blocking rules for all .exe files in the current directory and subdirectories.

#### OLD-Block Firewall All In Folder.bat
Legacy batch script version that recursively blocks all .exe files in a folder using netsh commands.

### Get Computer Info

#### Get_Device_Info_V2.ps1
Comprehensive system information gathering script that collects hardware info (CPU, RAM, BIOS, disks, GPU), network configuration, OS details, licensing information, and group policy results. Outputs to a compressed .zip file.

#### Get_Disk_Info.ps1
Gathers information about physical disks, partitions, and volumes, including SMART status via smartmontools if installed.

#### Get_WSL_info.ps1
Gathers information about the Windows Subsystem for Linux (WSL) installation, including the status of WSL features and installed distributions.

### Licensing Info

#### Get_License_Info.ps1
Retrieves detailed Windows license and activation information including product key, license status, activation status, and volume licensing details.

### List Installed Software

#### List_Installed_Software_CSV.ps1
Collects a list of installed software from both 32-bit and 64-bit registry locations, including user-specific installs. Exports to CSV with details like version, publisher, install date, and size.

### Other Utilities

#### Fix Internet after VPN.bat
Deletes the 0.0.0.0 route and renews IP configuration to fix internet connectivity issues after disconnecting from VPN.

#### Next Background.vbs
VBScript to cycle to the next desktop background image in Windows slideshow.

#### Real Time.bat
Displays a continuously updating real-time clock in the command prompt window.

#### Restart Explorer.bat
Terminates and restarts Windows Explorer to fix shell-related issues.

### Registry

#### Find_Registry_Keys.ps1
Searches Windows registry (HKLM and HKCU) for registry key names containing a specified search term. Exports results to CSV with hive and key path information.

### Uninstall Scripts

#### Windows Updates
##### Remove_KB5063878.ps1
Removes KB5063878 update (known to cause drive issues) and blocks it from reinstalling via Windows Update. Checks for Windows Sandbox conflicts before uninstalling.

#### Xbox Removal
##### RemoveXbox_Logon.ps1
Logon script that removes Xbox-related packages for the current user when they log in.

##### RemoveXboxV2.ps1
Removes provisioned Xbox packages to prevent installation for new users, and removes installed packages for all existing users.

### WinFix

#### WinFix JDW #1.bat
Batch script version of WinFix that runs CHKDSK, DISM component cleanup, DISM image repair, and SFC system file check. Requires administrator privileges.

#### WinFix JDW #1 - NON ADMIN.bat
Non-administrator version of WinFix

#### WinFix-Original.bat
Original WinFix script for LinusTechTips forum by 191x7. Performs 4 repair procedures for Windows maintenance.

### WinRE Fix (0x80070643)

#### Resize_script.ps1
Microsoft-provided script to extend the Windows Recovery Environment (WinRE) partition when there's insufficient space for updates. Handles partition resizing, backup, and recreation of WinRE partition.

---

## Usage Notes

- Most PowerShell scripts require administrator privileges
- Some scripts are designed for specific scenarios (domain environments, pre-reinstall, etc.)
- Always review script parameters and modify file paths as needed for your environment
- Check script headers for detailed usage instructions and requirements

## Credits

- Various scripts adapted from community sources
- WinFix scripts originally by 191x7 for LinusTechTips forum
- WinRE resize script provided by Microsoft

## License

GNU Affero General Public License v3
> These scripts are provided as-is for IT administration purposes. Use at your own risk and always test in a non-production environment first.
