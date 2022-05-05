$ver = '2.05'
<#
Created By: Kristopher Roy
Last Updated By: BTL
Created On: 29Nov2021
Last Updated On: 05May2022
#>

#Begin Script
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

#Verify most recent version being used
$curver = $ver
$data = Invoke-RestMethod -Method Get -Uri https://raw.githubusercontent.com/BellTechlogix/CheckandAdd-Guests-theHub/master/CheckandAdd-Guests-theHub.ps1
Invoke-Expression ($data.substring(0,13))
if($curver -ge $ver){powershell -Command "& {[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); [System.Windows.Forms.MessageBox]::Show('You are running the most current script version $ver')}"}
ELSEIF($curver -lt $ver){powershell -Command "& {[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); [System.Windows.Forms.MessageBox]::Show('You are running $curver the most current script version is $ver. Ending')}" 
start-sleep -seconds 10
EXIT}

#Verify Azure Module loaded
IF(Get-Module -ListAvailable|where{$_.name -like "AzureAD*"}){$AAD = $True}Else{
    Install-Module -Name AzureAD
    start-sleep -seconds 5
	IF(Get-Module -ListAvailable|where{$_.name -like "AzureAD*"}){$AAD = $True}ELSE{
		powershell -Command "& {[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); [System.Windows.Forms.MessageBox]::Show('AzureAD Module is missing and will not auto-install please resolve then re-run')}"
		start-sleep -seconds 10 
		Exit
			}
}

$cred = Get-Credential

Connect-AzureAD -Credential $cred

#Grab Users from InputBox
$users = (InputBox -header "Email List" -text "Please List Emails from ticket to be added" -icon "C:\Windows\SystemApps\Microsoft.Windows.SecHealthUI_cw5n1h2txyewy\Assets\Account.theme-light.ico").split('')

#Loop through and check users then add them as Guest accounts if missing, and then add them to theHub Guest users group
#Loop through and check users then add them as Guest accounts if missing, and then add them to theHub Guest users group
FOREACH($User in ($users.split('')|where{$_}))
{
    $user
    $aaduser = Get-AzureADUser -filter "DisplayName eq '$user'"|select *
    IF($aaduser -eq $null){$aaduser = Get-AzureADUser -filter "Mail eq '$user'"|select *}
    IF($aaduser -eq $null){$aaduser = Get-AzureADUser -filter "UserPrincipalName eq '$user'"|select *}
    If($aaduser -eq $null){$aaduser = Get-AzureADUser -filter "OtherMails eq '$user'"|select *}
    If($aaduser -eq $null)
    {
        write-host "No User Account $user"
        $DisplayName = (($user.split("@")[0].split(".")[0]).substring(0,1).toupper()+($user.split("@")[0].split(".")[0]).substring(1).toLower())+" "+(($user.split("@")[0].split(".")[1]).substring(0,1).toupper()+($user.split("@")[0].split(".")[1]).substring(1).toLower())
        powershell -Command "& {[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); [System.Windows.Forms.MessageBox]::Show('Creating Guest account for $Displayname')}"
        New-AzureADMSInvitation -InvitedUserDisplayName $DisplayName -InvitedUserEmailAddress $user -InviteRedirectURL https://gtinetorg.sharepoint.com/sites/theHUB -SendInvitationMessage $true
        start-sleep 15
        $aaduser = Get-AzureADUser -filter "DisplayName eq '$user'"
        IF($aaduser -eq $null){$aaduser = Get-AzureADUser -filter "Mail eq '$user'"}
        If($aaduser -eq $null){$aaduser = Get-AzureADUser -filter "OtherMails eq '$user'"|select *}
        IF($aaduser -eq $null)
        {
            powershell -Command "& {[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); [System.Windows.Forms.MessageBox]::Show('"($user)" not found, waiting 30 seconds then trying again')}"
            start-sleep 30
            $aaduser = Get-AzureADUser -filter "DisplayName eq '$user'"
            IF($aaduser -eq $null){$aaduser = Get-AzureADUser -filter "Mail eq '$user'"}
            IF($aaduser -eq $null){$aaduser = Get-AzureADUser -filter "UserPrincipalName eq '$user'"|select *}
            If($aaduser -eq $null){$aaduser = Get-AzureADUser -filter "OtherMails eq '$user'"|select *}
            IF($aaduser -eq $null)
            {
                powershell -Command "& {[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); [System.Windows.Forms.MessageBox]::Show('"($user)" still not found, waiting another 30 seconds then trying again')}"
                start-sleep 30
                $aaduser = Get-AzureADUser -filter "DisplayName eq '$user'"
                IF($aaduser -eq $null){$aaduser = Get-AzureADUser -filter "Mail eq '$user'"}
                IF($aaduser -eq $null){$aaduser = Get-AzureADUser -filter "UserPrincipalName eq '$user'"|select *}
                If($aaduser -eq $null){$aaduser = Get-AzureADUser -filter "OtherMails eq '$user'"|select *}
                IF($aaduser -eq $null){powershell -Command "& {[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); [System.Windows.Forms.MessageBox]::Show('"($user)" still not found, please end and troubleshoot, user not added to group')}"}
                exit
            }
        }
        powershell -Command "& {[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); [System.Windows.Forms.MessageBox]::Show('"($aaduser.userprincipalname)" exists adding to groups')}"
        Add-AzureADGroupMember -ObjectId 1bc2445f-5478-4d22-aac1-29c000817f7b -RefObjectID $aaduser.ObjectId
    }
    ELSE
    {
        write-host $aaduser.UserPrincipalName
        powershell -Command "& {[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); [System.Windows.Forms.MessageBox]::Show('"($aaduser.userprincipalname)" exists adding to groups')}"
        Add-AzureADGroupMember -ObjectId 1bc2445f-5478-4d22-aac1-29c000817f7b -RefObjectID $aaduser.ObjectId
    }
}

#$USERS|export-csv C:\projects\gtil\TheHub-Import-11Feb22-GrabbedandAddedUsers.csv -NoTypeInformation

