

$Error.Clear()
$InstallLog = $null
$UninstallLog = $null
$UninstallFiles = $null

Add-Type -AssemblyName System.Windows.Forms

$FormObject = [System.Windows.Forms.Form]
$ButtonObject = [System.Windows.Forms.Button]
$TextBoxObject = [System.Windows.Forms.TextBox]

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
Write-Form "The Online version has been deprecated.
Please download the repository and use OfflineSetup.ps1`r`n
https://github.com/MegaBitmap/NPSL" "Online Version Deprecated."


