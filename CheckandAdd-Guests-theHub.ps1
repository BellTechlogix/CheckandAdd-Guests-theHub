<#
Created By: Kristopher Roy
Last Updated By: BTL
Last Updated On: 29Nov2021
#>

$cred = Get-Credential

Connect-AzureAD -Credential $cred

#$users = import-csv C:\projects\gtil\TheHub-Import.csv
Function InputBox($header,$text,$icon)
{
    #creates a prompt for the new user being input
    $Input = @()
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    $form = New-Object System.Windows.Forms.Form
    $form.Text = $header
    $form.Size = New-Object System.Drawing.Size(300,400)
    $form.AutoSizeMode = 'GrowAndShrink'
    $form.StartPosition = 'CenterScreen'
    $formicon = New-Object system.drawing.icon ($icon)
    $form.Icon = $formicon
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(75,280)
    $okButton.Size = New-Object System.Drawing.Size(75,23)
    $okButton.Text = 'OK'
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $okButton
    $form.Controls.Add($okButton)
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(150,280)
    $cancelButton.Size = New-Object System.Drawing.Size(75,23)
    $cancelButton.Text = 'Cancel'
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.CancelButton = $cancelButton
    $form.Controls.Add($cancelButton)
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10,20)
    $label.Size = New-Object System.Drawing.Size(280,20)
    $label.Text = $text
    $form.Controls.Add($label)
    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point(10,40)
    $textBox.Size = New-Object System.Drawing.Size(260,200)
    $textBox.AcceptsReturn = $true
    $textBox.AcceptsTab = $false
    $textBox.Multiline = $true
    $textBox.ScrollBars = 'Both'
    $form.Controls.Add($textBox)
    $form.Topmost = $true
    $form.Add_Shown({$textBox.Select()})
    $form.StartPosition = "CenterScreen"
    $result = $form.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK)
            {
    Return $textBox.Text
    }
}

#Grab Users from InputBox
$users = (InputBox -header "Email List" -text "Please List Emails from ticket to be added" -icon "C:\Windows\SystemApps\Microsoft.Windows.SecHealthUI_cw5n1h2txyewy\Assets\Account.theme-light.ico").split('')

#Loop through and check users then add them as Guest accounts if missing, and then add them to theHub Guest users group
FOREACH($User in ($users.split('')))
{
    $aaduser = Get-AzureADUser -filter "Mail eq '$user'"|select *
    IF($aaduser -eq $null){$aaduser = Get-AzureADUser -filter "UserPrincipalName eq '$user'"|select *}
    If($aaduser -eq $null)
    {
        write-host "No User Account $user"
        $user.DisplayName = (($user.split("@")[0].split(".")[0]).substring(0,1).toupper()+($user.split("@")[0].split(".")[0]).substring(1).toLower())+" "+(($user.split("@")[0].split(".")[1]).substring(0,1).toupper()+($user.split("@")[0].split(".")[1]).substring(1).toLower())
        write-host "Creating Guest account for "($user.Displayname)
        New-AzureADMSInvitation -InvitedUserDisplayName $User.DisplayName -InvitedUserEmailAddress $user -InviteRedirectURL https://gtinetorg.sharepoint.com/sites/theHUB -SendInvitationMessage $true
        start-sleep 10
        $aaduser = Get-AzureADUser -filter "Mail eq '$user'"
        Add-AzureADGroupMember -ObjectId 1bc2445f-5478-4d22-aac1-29c000817f7b -RefObjectID $aaduser.ObjectId
    }
    ELSE
    {
        Add-AzureADGroupMember -ObjectId 1bc2445f-5478-4d22-aac1-29c000817f7b -RefObjectID $aaduser.ObjectId
    }
    #$User.UserType = $aaduser.UserType
    #$User.UPN = $aaduser.UserPrincipalName
    #$User.DisplayName = $aaduser.DisplayName
    #$User.ObjectID = $aaduser.ObjectID
}

#$USERS|export-csv C:\projects\gtil\TheHub-Import-11Feb22-GrabbedandAddedUsers.csv -NoTypeInformation



