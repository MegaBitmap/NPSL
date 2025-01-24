<#
.Synopsis
   Neutrino PowerShell Launcher (NPSL) Setup Script.
.DESCRIPTION
   NPSL uses third party apps to play ps2 games on real hardware while connected to a PC.
#>

$Error.Clear()
$InstallLog = $null
$UninstallLog = $null
$UninstallFiles = $null

$ScriptRepo         = Get-Location
$SetupFilesZip      = "$ScriptRepo/SetupFiles.zip"
$SetupLastUpdated   = "2025-01-23"
$InstallFilesZip    = "$ScriptRepo/InstallFiles.zip"
$InstallLastUpdated = "2025-01-21"
$License            = "$ScriptRepo/LICENSE.txt"
$3rdPartyLicense    = "$ScriptRepo/LICENSE-3RD-PARTY.txt"

$SetupDir     = "$env:TEMP\NPSL"
$BChunk       = "$SetupDir\bchunk.exe"
$BlankVMC8    = "$SetupDir\BlankVMC8.bin"
$BlankVMC32   = "$SetupDir\BlankVMC32.bin"
$ImageMagick  = "$SetupDir\magick.exe"
$VMCGroupFile = "$SetupDir\vmc_groups.list"

$DefaultPS2IP       = "192.168.0.10"
$DefaultShortcutDir = "$env:USERPROFILE\Desktop"
$DefaultInstallDir  = "$env:LOCALAPPDATA"
$BoxArtDatabase     = "https://raw.githubusercontent.com/xlenore/ps2-covers/main/covers/default/"

Add-Type -AssemblyName System.Windows.Forms

$FormObject = [System.Windows.Forms.Form]
$LabelObject = [System.Windows.Forms.Label]
$ButtonObject = [System.Windows.Forms.Button]
$TextBoxObject = [System.Windows.Forms.TextBox]
$CheckBoxObject = [System.Windows.Forms.CheckBox]
$ComboBoxObject = [System.Windows.Forms.ComboBox]
$FolderBrowserDialogObject = [System.Windows.Forms.FolderBrowserDialog]

function Find-Error {
    if ( $Error ) {
        Write-Form "`r`nAn error has occured:`r`n`r`n$( $Error -join "`r`n`r`n" )" "Error"
        exit
    }
}
function Set-Folder {
    param (
        $Default
    )
    $SetFolderDialog = New-Object $FolderBrowserDialogObject
    $SetFolderDialog.ShowDialog() | Out-Null
    if ( $SetFolderDialog.SelectedPath ) {
        return $SetFolderDialog.SelectedPath
    }
    else {
        return $Default
    }
}
function Write-Form {
    param (
        $WriteFormMessage,
        $WriteFormTitle
    )
    $WriteForm = New-Object $FormObject
    $WriteForm.Text = $WriteFormTitle
    $WriteForm.AutoSize = $true
    $WriteForm.FormBorderStyle = "FixedSingle"
    $WriteForm.Padding = New-Object System.Windows.Forms.Padding( 20 )
    $WriteForm.Font = New-Object System.Drawing.Font( "Segoe UI" , 12 )

    $WriteFormLabel = New-Object $TextBoxObject
    $WriteFormLabel.Text = $WriteFormMessage
    $WriteFormLabel.ReadOnly = $true
    $WriteFormLabel.Multiline = $true
    $WriteFormLabel.ScrollBars = "Vertical"
    $WriteFormLabel.ClientSize = "800 , 400"
    $WriteFormLabel.Location = New-Object System.Drawing.Point( 20 , 10 )

    $WriteFormButton = New-Object $ButtonObject
    $WriteFormButton.Text = "OK"
    $WriteFormButton.AutoSize = $true
    $WriteFormButton.Location = New-Object System.Drawing.Point( 720 , 430 )
    $WriteFormButton.DialogResult = "OK"
    $WriteForm.AcceptButton = $WriteFormButton

    $WriteForm.Controls.AddRange( @( $WriteFormButton , $WriteFormLabel ) )
    $WriteFormResult = $WriteForm.ShowDialog()
    if ( $WriteFormResult -match "Cancel" ) {
        exit
    }
}
function Search-BadChar {
    param (
        $FileArray
    )
    foreach ( $FileCBC in $FileArray ) {
        if ( $FileCBC -match "\$|{|}" ) {
            Write-Form "`r`nAn error has occured:`r`n`r`nPlease rename $FileCBC so that it does not contain these characters:`r`n $ or { or }" "Error"
            exit
        }
    }
}
function Get-VMCGroup {
    param (
        $TempSerialGameID
    )
    $GroupLineArray = Get-Content -Path $VMCGroupFile
    $CombinedLines = $GroupLineArray -join ""
    if ( $CombinedLines -match $TempSerialGameID ) {
        $VMCCurrentGroup = ""
        foreach ( $GroupLine in $GroupLineArray ) {
            if ( $GroupLine -match "XEBP" ) {
                $VMCCurrentGroup = $GroupLine
            }
            elseif ( $GroupLine -match $TempSerialGameID ) {
                return $VMCCurrentGroup
            }
        }
    }
    else { return $TempSerialGameID }
}
function Get-VMCGroupSize {
    param (
        $TempSerialGameID
    )
    $GroupLineArray = Get-Content -Path $VMCGroupFile
    $CombinedLines = $GroupLineArray -join ""
    if ( $CombinedLines -match $TempSerialGameID ) {
        $VMCCurrentSize = "8"
        $CheckNextLine = $false
        foreach ( $GroupLine in $GroupLineArray ) {
            if ( $CheckNextLine ) {
                if ( $GroupLine.Length -le 5 ) {
                    $VMCCurrentSize = $GroupLine
                }
                else {
                    $VMCCurrentSize = "8"
                }
                $CheckNextLine = $false
            }
            if ( $GroupLine -match "XEBP" ) {
                $CheckNextLine = $true
            }
            elseif ( $GroupLine -match $TempSerialGameID ) {
                return $VMCCurrentSize
            }
        }
    }
    else { return "8" }
}
function Uninstall-Form {
    
    $UninstallForm = New-Object $FormObject
    $UninstallForm.Text = "Neutrino PowerShell Launcher Uninstaller"
    $UninstallForm.AutoSize = $true
    $UninstallForm.FormBorderStyle = "FixedSingle"
    $UninstallForm.Padding = New-Object System.Windows.Forms.Padding( 20 )
    $UninstallForm.Font = New-Object System.Drawing.Font( "Segoe UI" , 12 )

    $LabelShortcutUninstall = New-Object $LabelObject
    $LabelShortcutUninstall.Text = "Please Choose where to Uninstall Shortcuts:"
    $LabelShortcutUninstall.AutoSize = $true
    $LabelShortcutUninstall.Location = New-Object System.Drawing.Point( 20 , 80 )
    $UninstallForm.Controls.Add( $LabelShortcutUninstall )

    $ButtonShortcutUninstall = New-Object $ButtonObject
    $ButtonShortcutUninstall.Text = "Choose Folder"
    $ButtonShortcutUninstall.AutoSize = $true
    $ButtonShortcutUninstall.Width = "154"
    $ButtonShortcutUninstall.Location = New-Object System.Drawing.Point( 475 , 85 )
    $ButtonShortcutUninstall.Add_Click( { $LabelShortcutUninstallPath.Text = Set-Folder $DefaultShortcutDir } )
    $UninstallForm.Controls.Add( $ButtonShortcutUninstall )

    $LabelShortcutUninstallPath = New-Object $LabelObject
    $LabelShortcutUninstallPath.Text = $DefaultShortcutDir
    $LabelShortcutUninstallPath.AutoSize = $true
    $LabelShortcutUninstallPath.Location = New-Object System.Drawing.Point( 20 , 102 )
    $UninstallForm.Controls.Add( $LabelShortcutUninstallPath )

    $LabelUninstall = New-Object $LabelObject
    $LabelUninstall.Text = "Please Choose where to Uninstall Program Files:"
    $LabelUninstall.AutoSize = $true
    $LabelUninstall.Location = New-Object System.Drawing.Point( 20 , 132 )
    $UninstallForm.Controls.Add( $LabelUninstall )

    $ButtonChooseUninstall = New-Object $ButtonObject
    $ButtonChooseUninstall.Text = "Choose Folder"
    $ButtonChooseUninstall.AutoSize = $true
    $ButtonChooseUninstall.Width = "154"
    $ButtonChooseUninstall.Location = New-Object System.Drawing.Point( 475 , 137 )
    $ButtonChooseUninstall.Add_Click( { $LabelUninstallPath.Text = Set-Folder "$DefaultInstallDir\NPSL" } )
    $UninstallForm.Controls.Add( $ButtonChooseUninstall )

    $LabelUninstallPath = New-Object $LabelObject
    $LabelUninstallPath.Text = "$DefaultInstallDir\NPSL"
    $LabelUninstallPath.AutoSize = $true
    $LabelUninstallPath.Location = New-Object System.Drawing.Point( 20 , 154 )
    $UninstallForm.Controls.Add( $LabelUninstallPath )

    $LabelRemoveFirewall = New-Object $LabelObject
    $LabelRemoveFirewall.Text = "(ADMIN) Remove firewall rules:"
    $LabelRemoveFirewall.AutoSize = $true
    $LabelRemoveFirewall.Location = New-Object System.Drawing.Point( 20 , 186 )
    $UninstallForm.Controls.Add( $LabelRemoveFirewall )

    $CheckBoxRemoveFirewall = New-Object $CheckBoxObject
    $CheckBoxRemoveFirewall.Width = "20"
    $CheckBoxRemoveFirewall.Checked = $true
    $CheckBoxRemoveFirewall.Location = New-Object System.Drawing.Point( 478 , 187 )
    $UninstallForm.Controls.Add( $CheckBoxRemoveFirewall )

    $ButtonCancelUninstall = New-Object $ButtonObject
    $ButtonCancelUninstall.Text = "Cancel"
    $ButtonCancelUninstall.AutoSize = $true
    $ButtonCancelUninstall.Location = New-Object System.Drawing.Point( 555 , 290 )
    $UninstallForm.CancelButton = $ButtonCancelUninstall
    $UninstallForm.Controls.Add( $ButtonCancelUninstall )

    $ButtonConfirmUninstall = New-Object $ButtonObject
    $ButtonConfirmUninstall.Text = "Uninstall"
    $ButtonConfirmUninstall.AutoSize = $true
    $ButtonConfirmUninstall.Location = New-Object System.Drawing.Point( 475 , 290 )
    $ButtonConfirmUninstall.DialogResult = "OK"
    $UninstallForm.AcceptButton = $ButtonConfirmUninstall
    $UninstallForm.Controls.Add( $ButtonConfirmUninstall )

    $UninstallFormResult = $UninstallForm.ShowDialog()
    if ( $UninstallFormResult -match "Cancel" ) {
        exit
    }
    $ShortcutUninstallPath = $LabelShortcutUninstallPath.Text
    $UninstallPath = $LabelUninstallPath.Text
    $RemoveFirewallRule = $CheckBoxRemoveFirewall.Checked
    
    if ( Test-Path -Path $SetupDir ) {
        
        Remove-Item -Path $SetupDir -Recurse -ErrorAction Ignore
        $UninstallLog += "`r`nRemoving setup files from $SetupDir`r`n"
    }
    if ( Test-Path -Path "$UninstallPath\ps2client.exe" -PathType Leaf ) {
        
        $FilesToRemove = Get-ChildItem -Path $UninstallPath -File -Recurse -ErrorAction Ignore
        foreach ( $File in $FilesToRemove ){
            
            $UninstallFiles += "`r`nRemoving $($File.FullName)"
        }
        Write-Form "`r`n`r`nThe following files will be deleted!`r`n$UninstallFiles" "WARNING THESE FILES WILL BE REMOVED!"

        Remove-Item -Path $UninstallPath -Recurse -ErrorAction Ignore
        $UninstallLog += "`r`nRemoving $UninstallPath`r`n"
    }
    else {
        Write-Form "`r`nWarning:`r`n`r`nThe uninstaller can not find the program files." "Warning"
        $UninstallLog += "`r`nUninstaller can not find the program files`r`n"
    }
    $WshShell = New-Object -ComObject WScript.Shell
    $NumberOfShortcuts = 0
    $AllShortcuts = Get-ChildItem -Path "$ShortcutUninstallPath\*" -Include *.lnk
    foreach ( $Shortcut in $AllShortcuts ){
        
        $TempShortcut = $WshShell.CreateShortcut( $Shortcut.FullName )
        if ( $TempShortcut.Arguments -match "udpbd" ){
            
            $NumberOfShortcuts++
            $UninstallLog += "`r`nRemoving $Shortcut"
        }
    }
    if ( $NumberOfShortcuts ){
        Write-Form "`r`n`r`nThe following files will be deleted!`r`n$UninstallLog" "WARNING THESE FILES WILL BE REMOVED!"

        foreach ( $Shortcut in $AllShortcuts ){
            $TempShortcut = $WshShell.CreateShortcut( $Shortcut.FullName )
            if ( $TempShortcut.Arguments -match "udpbd" ){
                Remove-Item -Path $Shortcut
            }
        }
    }
    else {
        Write-Form "`r`nWarning:`r`n`r`nThe uninstaller can not find any shortcut files." "Warning"
        $UninstallLog += "`r`nUninstaller can not find any shortcut files"
    }
    if ( $RemoveFirewallRule ) {
        Start-Process powershell.exe -WindowStyle Hidden -Verb RunAs -Wait -ArgumentList "Remove-NetFirewallRule -DisplayName ps2client*; Remove-NetFirewallRule -DisplayName udpbd-server*"
        $UninstallLog += "`r`n`r`nRemoving firewall rules for ps2client and udpbd-server"
    }
    Find-Error

    Write-Form "`r`nThe uninstallation has successfully completed without any errors.`r`n$UninstallLog" "Finished"
    exit
}
Write-Form ( Get-Content $License -Raw ) "Please Read the Software License"
Write-Form ( Get-Content $3rdPartyLicense -Raw ) "Please Read the 3rd Party Software Licenses"

Find-Error

if ( Get-Process -Name "udpbd-server" -ErrorAction Ignore ) {
    Write-Form "`r`nAn error has occured:`r`n`r`nudpbd-server is currently running, please close or end the task." "Error"
    exit
}

$MainForm = New-Object $FormObject
$MainForm.Text = "Neutrino PowerShell Launcher Installer"
$MainForm.AutoSize = $true
$MainForm.FormBorderStyle = "FixedSingle"
$MainForm.Padding = New-Object System.Windows.Forms.Padding( 20 )
$MainForm.Font = New-Object System.Drawing.Font( "Segoe UI" , 12 )

$LabelDrive = New-Object $LabelObject
$LabelDrive.Text = "Please Choose the PS2 Drive:"
$LabelDrive.AutoSize = $true
$LabelDrive.Location = New-Object System.Drawing.Point( 60 , 40 )
$MainForm.Controls.Add( $LabelDrive )

$ComboBoxDrive = New-Object $ComboBoxObject
$ComboBoxDrive.DropDownStyle = "DropDownList"
$ComboBoxDrive.Width = "154"
$ComboBoxDrive.Location = New-Object System.Drawing.Point( 400 , 40 )
$MainForm.Controls.Add( $ComboBoxDrive )

$LabelPS2IP = New-Object $LabelObject
$LabelPS2IP.Text = "Enter the IP address for the PS2:"
$LabelPS2IP.AutoSize = $true
$LabelPS2IP.Location = New-Object System.Drawing.Point( 60 , 80 )
$MainForm.Controls.Add( $LabelPS2IP )

$TextBoxPS2IP = New-Object $TextBoxObject
$TextBoxPS2IP.Text = $DefaultPS2IP
$TextBoxPS2IP.Width = "154"
$TextBoxPS2IP.Location = New-Object System.Drawing.Point( 400 , 80 )
$MainForm.Controls.Add( $TextBoxPS2IP )

$LabelPS2IPTest = New-Object $LabelObject
$LabelPS2IPTest.Text = "Test Connection to this IP address:"
$LabelPS2IPTest.AutoSize = $true
$LabelPS2IPTest.Location = New-Object System.Drawing.Point( 60 , 120 )
$MainForm.Controls.Add( $LabelPS2IPTest )

$CheckBoxPS2IPTest = New-Object $CheckBoxObject
$CheckBoxPS2IPTest.Width = "20"
$CheckBoxPS2IPTest.Checked = $true
$CheckBoxPS2IPTest.Location = New-Object System.Drawing.Point( 400 , 120 )
$MainForm.Controls.Add( $CheckBoxPS2IPTest )

$LabelShortcut = New-Object $LabelObject
$LabelShortcut.Text = "Please Choose where to Install Shortcuts:"
$LabelShortcut.AutoSize = $true
$LabelShortcut.Location = New-Object System.Drawing.Point( 20 , 160 )
$MainForm.Controls.Add( $LabelShortcut )

$ButtonShortcut = New-Object $ButtonObject
$ButtonShortcut.Text = "Choose Folder"
$ButtonShortcut.AutoSize = $true
$ButtonShortcut.Width = "154"
$ButtonShortcut.Location = New-Object System.Drawing.Point( 440 , 165 )
$ButtonShortcut.Add_Click( { $LabelShortcutPath.Text = Set-Folder $DefaultShortcutDir } )
$MainForm.Controls.Add( $ButtonShortcut )

$LabelShortcutPath = New-Object $LabelObject
$LabelShortcutPath.Text = $DefaultShortcutDir
$LabelShortcutPath.AutoSize = $true
$LabelShortcutPath.Location = New-Object System.Drawing.Point( 20 , 185 )
$MainForm.Controls.Add( $LabelShortcutPath )

$LabelInstall = New-Object $LabelObject
$LabelInstall.Text = "Please Choose where to Install Program Files:"
$LabelInstall.AutoSize = $true
$LabelInstall.Location = New-Object System.Drawing.Point( 20 , 220 )
$MainForm.Controls.Add( $LabelInstall )

$ButtonChooseInstall = New-Object $ButtonObject
$ButtonChooseInstall.Text = "Choose Folder"
$ButtonChooseInstall.AutoSize = $true
$ButtonChooseInstall.Width = "154"
$ButtonChooseInstall.Location = New-Object System.Drawing.Point( 440 , 225 )
$ButtonChooseInstall.Add_Click( { $LabelInstallPath.Text = Set-Folder $DefaultInstallDir } )
$MainForm.Controls.Add( $ButtonChooseInstall )

$LabelInstallPath = New-Object $LabelObject
$LabelInstallPath.Text = $DefaultInstallDir
$LabelInstallPath.AutoSize = $true
$LabelInstallPath.Location = New-Object System.Drawing.Point( 20 , 245 )
$MainForm.Controls.Add( $LabelInstallPath )

$LabelAddFirewallRule = New-Object $LabelObject
$LabelAddFirewallRule.Text = "(ADMIN) Allow communication past firewall:"
$LabelAddFirewallRule.AutoSize = $true
$LabelAddFirewallRule.Location = New-Object System.Drawing.Point( 20 , 280 )
$MainForm.Controls.Add( $LabelAddFirewallRule )

$CheckBoxAddFirewall = New-Object $CheckBoxObject
$CheckBoxAddFirewall.Width = "20"
$CheckBoxAddFirewall.Checked = $true
$CheckBoxAddFirewall.Location = New-Object System.Drawing.Point( 400 , 280 )
$MainForm.Controls.Add( $CheckBoxAddFirewall )

$LabelConvertCue = New-Object $LabelObject
$LabelConvertCue.Text = "Automatically Convert BIN+CUE to ISO:"
$LabelConvertCue.AutoSize = $true
$LabelConvertCue.Location = New-Object System.Drawing.Point( 60 , 320 )
$MainForm.Controls.Add( $LabelConvertCue )

$CheckBoxConvertCue = New-Object $CheckBoxObject
$CheckBoxConvertCue.Width = "20"
$CheckBoxConvertCue.Checked = $true
$CheckBoxConvertCue.Location = New-Object System.Drawing.Point( 400 , 320 )
$MainForm.Controls.Add( $CheckBoxConvertCue )

$LabelBoxArt = New-Object $LabelObject
$LabelBoxArt.Text = "Download Box Art for Icons:"
$LabelBoxArt.AutoSize = $true
$LabelBoxArt.Location = New-Object System.Drawing.Point( 60 , 360 )
$MainForm.Controls.Add( $LabelBoxArt )

$CheckBoxArt = New-Object $CheckBoxObject
$CheckBoxArt.Width = "20"
$CheckBoxArt.Checked = $false
$CheckBoxArt.Location = New-Object System.Drawing.Point( 400 , 360 )
$MainForm.Controls.Add( $CheckBoxArt )

$LabelVMC = New-Object $LabelObject
$LabelVMC.Text = "Enable Virtual Memory Cards:"
$LabelVMC.AutoSize = $true
$LabelVMC.Location = New-Object System.Drawing.Point( 60 , 400 )
$MainForm.Controls.Add( $LabelVMC )

$CheckBoxVMC = New-Object $CheckBoxObject
$CheckBoxVMC.Width = "20"
$CheckBoxVMC.Location = New-Object System.Drawing.Point( 400 , 400 )
$MainForm.Controls.Add( $CheckBoxVMC )

$LabelDisableTimeout = New-Object $LabelObject
$LabelDisableTimeout.Text = "(DEBUG) Keep ps2client Console Open:"
$LabelDisableTimeout.AutoSize = $true
$LabelDisableTimeout.Location = New-Object System.Drawing.Point( 60 , 440 )
$MainForm.Controls.Add( $LabelDisableTimeout )

$CheckBoxDisableTimeout = New-Object $CheckBoxObject
$CheckBoxDisableTimeout.Width = "20"
$CheckBoxDisableTimeout.Location = New-Object System.Drawing.Point( 400 , 440 )
$MainForm.Controls.Add( $CheckBoxDisableTimeout )

$ButtonCancel = New-Object $ButtonObject
$ButtonCancel.Text = "Cancel"
$ButtonCancel.AutoSize = $true
$ButtonCancel.Location = New-Object System.Drawing.Point( 520 , 500 )
$MainForm.CancelButton = $ButtonCancel
$MainForm.Controls.Add( $ButtonCancel )

$ButtonInstall = New-Object $ButtonObject
$ButtonInstall.Text = "Install"
$ButtonInstall.AutoSize = $true
$ButtonInstall.Location = New-Object System.Drawing.Point( 420 , 500 )
$ButtonInstall.DialogResult = "OK"
$MainForm.AcceptButton = $ButtonInstall
$MainForm.Controls.Add( $ButtonInstall )

$ButtonUninstall = New-Object $ButtonObject
$ButtonUninstall.Text = "Uninstall"
$ButtonUninstall.AutoSize = $true
$ButtonUninstall.Location = New-Object System.Drawing.Point( 20 , 500 )
$ButtonUninstall.DialogResult = "No"
$MainForm.Controls.Add( $ButtonUninstall )

$WMIVolume = Get-WmiObject Win32_Volume | Where-Object FileSystem -eq "exFAT" | Sort-Object DriveLetter
if ( $WMIVolume ) {
    $NumValidDrive = 0
    foreach ( $WMIVol in $WMIVolume ) {
        if ( $WMIVol.DriveLetter ) {
            $ComboBoxDrive.Items.Add( $WMIVol.DriveLetter ) | Out-Null
            $NumValidDrive++
        }
    }
    if ( $NumValidDrive -eq "0" ) {
        Write-Form "`r`nAn error has occured:`r`n`r`nThe exFAT drive does not have a drive letter assigned to it." "Error"
        exit
    }
    $ComboBoxDrive.SelectedIndex = "0"
}
else {
    Write-Form "`r`nAn error has occured:`r`n`r`nThe scirpt was unable to find an exFAT volume or partition." "Error"
    exit
}
$MainFormResult = $MainForm.ShowDialog()
if ( $MainFormResult -match "Cancel" ) {
    exit
}
elseif ( $MainFormResult -match "No" ) {
    Uninstall-Form
}
$ISODrive        = $ComboBoxDrive.SelectedItem
$PS2IP           = [ipaddress]$TextBoxPS2IP.Text.Trim()
$TestPS2IP       = $CheckBoxPS2IPTest.Checked
$ShortcutPath    = $LabelShortcutPath.Text

$InstallPath     = $LabelInstallPath.Text
$InstallFolder   = "$InstallPath\NPSL"
$Neutrino        = "$InstallFolder\neutrino.elf"

$AddFirewallRule = $CheckBoxAddFirewall.Checked
$ConvertCue      = $CheckBoxConvertCue.Checked
$EnableArt       = $CheckBoxArt.Checked
$EnableVMC       = $CheckBoxVMC.Checked
$DisableTimeout  = $CheckBoxDisableTimeout.Checked

Find-Error

if ( $TestPS2IP ) {
    
    if ( -not ( Test-Connection -ComputerName $PS2IP -Count "1" -Quiet ) ) {
        
        Write-Form "`r`nAn error has occured:`r`n`r`nTesting connection to PS2 with ip address $PS2IP failed." "Error"
        exit
    }
}
if ( ( ( Split-Path -Path $ShortcutPath -Qualifier ) -eq $ISODrive ) -or ( ( Split-Path -Path $InstallPath -Qualifier ) -eq $ISODrive ) ) {

    Write-Form "`r`nAn error has occured:`r`n`r`nThe installer is unable to install to the same partition as the exFAT volume with PS2 ISOs.`r`n" "Error"
    exit
}
Find-Error

if ( $EnableVMC ){
    if ( -not ( Test-Path -Path "$ISODrive\VMC" ) ) {
        New-Item -Path "$ISODrive\VMC" -ItemType Directory | Out-Null
    }
}
else {
    $VMCArgument = ""
}
if ( -not ( Test-Path $ImageMagick -NewerThan $SetupLastUpdated ) ) {
    
    Expand-Archive $SetupFilesZip -DestinationPath $SetupDir -Force
    $InstallLog += "`r`n`r`nInstalling Setup Files to $SetupDir"
}

if ( -not ( Test-Path $Neutrino -NewerThan $InstallLastUpdated ) ) {
    
    Expand-Archive $InstallFilesZip -DestinationPath $InstallFolder -Force
    $InstallLog += "`r`n`r`nInstalling Files to $InstallFolder"
}
$CfgUDPBD    = "$InstallFolder\config\bsd-udpbd.toml"
( Get-Content $CfgUDPBD ) -replace ( ( Get-Content -Path $CfgUDPBD | Select-String "args" ) -replace 'args = \["ip=|"\]' ) , $PS2IP | Set-Content $CfgUDPBD

Find-Error

if ( $AddFirewallRule ) {
    Start-Process powershell.exe -WindowStyle Hidden -Verb RunAs -Wait -ArgumentList "Remove-NetFirewallRule -DisplayName ps2client*; Remove-NetFirewallRule -DisplayName udpbd-server*; New-NetFirewallRule -DisplayName ps2client -Direction Inbound -Action Allow -EdgeTraversalPolicy Block -RemoteAddress $PS2IP,192.168.0.10,192.168.1.10 -Protocol UDP -Program $InstallFolder\ps2client.exe; New-NetFirewallRule -DisplayName udpbd-server -Direction Inbound -Action Allow -EdgeTraversalPolicy Block -RemoteAddress $PS2IP,192.168.0.10,192.168.1.10 -Protocol UDP -Program $InstallFolder\udpbd-server.exe"
    $InstallLog += "`r`n`r`nCreating a firewall rule for ps2client and udpbd-server"
}
Find-Error

if ( $EnableArt ) {
    if ( -not ( Test-Path -Path "$InstallFolder\Icons" ) ) {
        New-Item -Path "$InstallFolder\Icons" -ItemType Directory | Out-Null
    }
}
if ( $DisableTimeout ) {
    $Timeout = ""
}
else {
    $Timeout = " -t 1"
}
$AllCUEs = Get-ChildItem -Path $ISODrive -Recurse -Include *.cue
foreach ( $CUE in $AllCUEs ) {
    if ( $ConvertCue ) {
        Search-BadChar $AllCUEs
        $ScriptDir = Get-Location

        if ( -not (Test-Path -Path "$( $CUE.Directory )\$( $CUE.BaseName ).iso" -PathType Leaf) ) {
            
            Set-Location $CUE.Directory

            & $BChunk * $CUE.Name $CUE.BaseName | Out-Null
            $InstallLog += "`r`n`r`nConverting $( $CUE.Name )+.bin to $( $CUE.BaseName ).iso"

            Set-Location $ScriptDir
            if ( $Error ) {
                Write-Form "`r`nAn error has occured trying to convert $( $CUE.Name )+BIN to ISO:`r`n`r`n$( $Error -join "`r`n`r`n" )" "Error"
                exit
            }
        }
    }
}
$AllISOs = Get-ChildItem -Path "$ISODrive\CD" -Recurse -Include *.iso
$AllISOs += Get-ChildItem -Path "$ISODrive\DVD" -Recurse -Include *.iso
if ( -not $AllISOs ) {
    Write-Form "`r`nAn error has occured:`r`n`r`nThere are no ISOs found in ' $ISODrive '" "Error"
    exit
}
Search-BadChar $AllISOs
foreach ( $ISO in $AllISOs ) {
    $DiskImage = Mount-DiskImage -ImagePath $ISO -PassThru
    if ( $Error ) {
        Write-Form "`r`nAn error has occured:`r`n`r`nThe File $ISO is corrupted or unreadable.`r`n`r`n$( $Error -join "`r`n`r`n" )" "Error"
        exit
    }
    $ISODriveLetter = ( $DiskImage | Get-Volume ).DriveLetter

    if ( Test-Path -Path "$ISODriveLetter`:\SYSTEM.CNF" ) {
        $ISOInfo = ( Get-Content -Path "$ISODriveLetter`:\SYSTEM.CNF" ) -replace "cdrom0:\\" -replace "cdrom:\\" -replace ";1" | ConvertFrom-StringData
        $Serial = $ISOInfo.BOOT2

        Dismount-DiskImage -DevicePath $DiskImage.DevicePath | Out-Null

        if ( $Serial ) {
            $BaseName = $ISO.BaseName -replace "$Serial\."
            $TrimmedISOPath = $ISO -replace "$ISODrive\\" -replace "'" , "''"
            if ( $EnableVMC ) {
                
                $TempVMCGroup = Get-VMCGroup $Serial
                $TempVMCSize = Get-VMCGroupSize $Serial

                $VMCArgument = " -mc0=mass:VMC\${TempVMCGroup}_0.bin"
                $VMCFullName = "$ISODrive\VMC\${TempVMCGroup}_0.bin"

                if ( Test-Path -Path $VMCFullName -PathType Leaf ){
                    $InstallLog += "`r`n`r`n$BaseName VMC Already Exists $VMCFullName"
                }
                else {
                    $TempVMCFilename = $BlankVMC8
                    if ( $TempVMCSize -match "32" ) {
                        $TempVMCFilename = $BlankVMC32
                    }
                    Copy-Item $TempVMCFilename -Destination $VMCFullName
                    $InstallLog += "`r`n`r`nCreating $BaseName VMC $VMCFullName"
                }
            }
            $ShortcutFullName = "$ShortcutPath\$BaseName.lnk"
            $InstallLog += "`r`n`r`nCreating $ShortcutFullName"
            $WshShell = New-Object -ComObject WScript.Shell
            $Shortcut = $WshShell.CreateShortcut( $ShortcutFullName )
            $Shortcut.TargetPath = "powershell.exe"
            $Shortcut.Arguments = "&{if(!(ps udpbd*)){saps udpbd-server \\.\$ISODrive -V RunAs};saps ps2client '-h $PS2IP$Timeout execee host:neutrino.elf -bsd=udpbd -dvd=mass:`\`"$TrimmedISOPath`\`"$VMCArgument'}"
            $Shortcut.WorkingDirectory = $InstallFolder
            
            if ( $EnableArt ) {
                $BoxArt = $Serial -replace "_" , "-" -replace "\."
                if ( -not ( Test-Path -Path "$InstallFolder\Icons\$BoxArt.ico" -PathType Leaf ) ) {
                    
                    Find-Error
                    $ErrorActionPreference = "SilentlyContinue"

                    Invoke-WebRequest -Uri "$BoxArtDatabase$BoxArt.jpg" -OutFile "$InstallFolder\Icons\$BoxArt.jpg"

                    $ErrorActionPreference = "Continue"
                    if ( $Error ) {
                        $InstallLog += "`r`n`r`nUnable to download box art from $BoxArtDatabase$BoxArt.jpg"
                        $Error.Clear()
                    }
                    if ( Test-Path -Path "$InstallFolder\Icons\$BoxArt.jpg" -PathType Leaf ) {
                        
                        & $ImageMagick -background transparent "$InstallFolder\Icons\$BoxArt.jpg" -crop 512x666+0+70 -resize 197x256 -gravity center -extent 256x256 -define icon:auto-resize=16,24,32,48,64,256 "$InstallFolder\Icons\$BoxArt.ico"
                        Remove-Item -Path "$InstallFolder\Icons\$BoxArt.jpg"
                    }
                }
                if ( Test-Path -Path "$InstallFolder\Icons\$BoxArt.ico" -PathType Leaf ) {
                    $Shortcut.IconLocation = "$InstallFolder\Icons\$BoxArt.ico"
                }
            }
            $Shortcut.Save()
        }
    }
    else {
        Dismount-DiskImage -DevicePath $DiskImage.DevicePath | Out-Null
    }
    Find-Error
}
Write-Form "`r`nThe installation has successfully completed without any errors.$InstallLog" "Finished"
