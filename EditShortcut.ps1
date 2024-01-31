$Error.Clear()

Add-Type -AssemblyName System.Windows.Forms

$FormObject = [System.Windows.Forms.Form]
$LabelObject = [System.Windows.Forms.Label]
$ButtonObject = [System.Windows.Forms.Button]
$TextBoxObject = [System.Windows.Forms.TextBox]
$OpenFileDialogObject = [System.Windows.Forms.OpenFileDialog]

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
$FormArgument = New-Object $FormObject
$FormArgument.ClientSize = "1600 , 120"
$FormArgument.FormBorderStyle = "FixedSingle"
$FormArgument.Text = "Edit Shortcut Arguments"
$FormArgument.Font = New-Object System.Drawing.Font( "Segoe UI" , 12 )

$TextBoxArgument = New-Object $TextBoxObject
$TextBoxArgument.Width = "1560"
$TextBoxArgument.Location = New-Object System.Drawing.Point( 20 , 40 )
$FormArgument.Controls.Add( $TextBoxArgument )

$ChooseShortcut = New-Object $OpenFileDialogObject
$ChooseShortcut.DereferenceLinks = $false
$ChooseShortcut.filter = "Shortcut (*.lnk)|*.lnk"

$WshShell = New-Object -comObject WScript.Shell
$LabelOldArgument = New-Object $LabelObject

$ButtonShortcut = New-Object $ButtonObject
$ButtonShortcut.Text = "Choose Shortcut"
$ButtonShortcut.Width = "150"
$ButtonShortcut.Location = New-Object System.Drawing.Point( 20 , 10 )
$ButtonShortcut.Add_Click( {
    $ChooseShortcut.ShowDialog()
    if ( $ChooseShortcut.FileName ) {
        $TextBoxArgument.Text = $WshShell.CreateShortcut( $ChooseShortcut.FileName ).Arguments
        $LabelOldArgument.Text = $TextBoxArgument.Text
    }
} )
$FormArgument.Controls.Add( $ButtonShortcut )

$LabelCharacter = New-Object $LabelObject
$LabelCharacter.Text = "The shortcut properties built into windows only supports up to 231 characters. This supports up to 1023 characters."
$LabelCharacter.AutoSize = $true
$LabelCharacter.Location = New-Object System.Drawing.Point( 20 , 80 )
$FormArgument.Controls.Add( $LabelCharacter )

$ButtonSave = New-Object $ButtonObject
$ButtonSave.Text = "Save"
$ButtonSave.Location = New-Object System.Drawing.Point( 1400 , 80 )
$ButtonSave.DialogResult = "OK"
$FormArgument.AcceptButton = $ButtonSave
$FormArgument.Controls.Add( $ButtonSave )

$ButtonCancel = New-Object $ButtonObject
$ButtonCancel.Text = "Cancel"
$ButtonCancel.Location = New-Object System.Drawing.Point( 1500 , 80 )
$FormArgument.CancelButton = $ButtonCancel
$FormArgument.Controls.Add( $ButtonCancel )

$Result = $FormArgument.ShowDialog()
if ( $Result -match "Cancel" -or ( -not ( $ChooseShortcut.FileName ) ) ) {
    exit
}
if ( $Error ) {
	Write-Form "`r`nAn error has occured:`r`n`r`n$( $Error -join "`r`n`r`n" )" "Error"
	exit
}
$SetShortcut = $WshShell.CreateShortcut( $ChooseShortcut.FileName )
$SetShortcut.Arguments = $TextBoxArgument.Text
$SetShortcut.Save()

if ( $Error ) {
    Write-Form "`r`nAn error has occured:`r`n`r`n$( $Error -join "`r`n`r`n" )`r`n`r`nTry running as administrator" "Error"
    exit
}
Write-Form "`r`nThe shortcut has successfully saved without any errors.`r`n`r`nOld Target:`r`n$( $SetShortcut.TargetPath ) $( $LabelOldArgument.Text )`r`n`r`nNew Target:`r`n$( $SetShortcut.TargetPath ) $( $TextBoxArgument.Text )" "Finished"
