<#
Created By: Kristopher Roy
Last Updated By: BTL
Last Updated On: 29Nov2021
#>

$cred = Get-Credential

Connect-AzureAD -Credential $cred

$users = import-csv C:\projects\gtil\TheHub-Import.csv

FOREACH($User in $users)
{
    $get = $User.User
    $aaduser = Get-AzureADUser -filter "Mail eq '$get'"|select *
    IF($aaduser -eq $null){$aaduser = Get-AzureADUser -filter "UserPrincipalName eq '$get'"|select *}
    If($aaduser -eq $null)
    {
        write-host "No User Account $get"
        $user.DisplayName = (($user.user.split("@")[0].split(".")[0]).substring(0,1).toupper()+($user.user.split("@")[0].split(".")[0]).substring(1).toLower())+" "+(($user.user.split("@")[0].split(".")[1]).substring(0,1).toupper()+($user.user.split("@")[0].split(".")[1]).substring(1).toLower())
        write-host "Creating Guest account for "($user.Displayname)
        New-AzureADMSInvitation -InvitedUserDisplayName $User.DisplayName -InvitedUserEmailAddress $user.user -InviteRedirectURL https://gtinetorg.sharepoint.com/sites/theHUB -SendInvitationMessage $true
        start-sleep 10
        $aaduser = Get-AzureADUser -filter "Mail eq '$get'"
        Add-AzureADGroupMember -ObjectId 1bc2445f-5478-4d22-aac1-29c000817f7b -RefObjectID $aaduser.ObjectId
    }
    ELSE
    {
        Add-AzureADGroupMember -ObjectId 1bc2445f-5478-4d22-aac1-29c000817f7b -RefObjectID $aaduser.ObjectId
    }
    $User.UserType = $aaduser.UserType
    $User.UPN = $aaduser.UserPrincipalName
    $User.DisplayName = $aaduser.DisplayName
    $User.ObjectID = $aaduser.ObjectID
}

$USERS|export-csv C:\projects\gtil\TheHub-Import-11Feb22-GrabbedandAddedUsers.csv -NoTypeInformation


FOREACH($user in $users)
{
    $get = $User.User
    $aaduser = Get-AzureADUser -filter "Mail eq '$get'"
    IF($aaduser -eq $null){$aaduser = Get-AzureADUser -filter "UserPrincipalName eq '$get'"|select *}
    $object = (Get-AzureADUser -filter "UserPrincipalName eq '$get'"|Get-AzureADUserMembership | % {Get-AzureADObjectByObjectId -ObjectId 1bc2445f-5478-4d22-aac1-29c000817f7b})[0]
    $get
    $object
    If($object -eq $Null)
    {Add-AzureADGroupMember -ObjectId 1bc2445f-5478-4d22-aac1-29c000817f7b -RefObjectID $aaduser.ObjectId}
}



