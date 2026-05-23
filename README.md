# PowerShell Script to create new users from a csv file in Active Directory #

I'm learning how to use PowerShell to automate repeating tasks, such as creating new users in
Active Directory. Because of that I wrote a script that takes some information about a user
from a csv file and assign them in according parameters of a New-ADUser cmdlet.

I created AD structure with OUs, groups and users reflecting groups and characters from the game Gothic 1 and the place called Old Camp, one of the fractions in the game.

All the AD Objects are created via the PowerShell by using cmdlets such as New-ADOrganizationalUnit or New-ADGroup. All the users are created by newUsers.ps1 script.

## Domain Architecture ##

The name of the domain is: oldcamp.gothic.inc
This domain is a child domain of a parent domain and forest root domain controller: gothic.inc.
The DC for the domian oldcamp.gothic.inc is a computer: OldCampServer.

## OU and Groups Structure ##

```text
DC=oldcamp,DC=gothic,DC=inc
└── OU = Camp
    ├── OU = Groups
    │    ├── OU =Administrative Groups
    │    │  ├── Camp-Managers
    │    │  ├── Castle-Managers
    │    │  ├── InnerRing-Managers
    │    │  └── OuterRing-Managers
    │    └── OU = User Groups
    │       ├── Diggers
    │       ├── Fire Mages
    │       ├── Guards
    │       ├── Ore Barons
    │       └── Shadows
    ├── OU = Inner Ring
    │    ├── OU = Castle
    │    └── OU = The Temple of Innos
    ├── OU = Outer Ring
    └── OU = Test Folder
```
## CSV File Specification ##

In csv file the columns are as follow:
    1. Path - the path to the OU where user object should be placed.
    2. FirstName - first name of a user.
    3. DisplayName - display name of a user.
    4. Description - short description of a user.
    5. Email - user's email.
    6. JobTitle - user's job title.
    7. Department - a department where user works.
    8. Company - a user's comapny.
    9. UserPrincipalName - a name of a user in form of a mail, also user logon name.
    10. SamAccountName - a name of a user in a plain form, also user logon name (Pre-Windows 2000).
    11. Password - preset user password that should be changed by the user at the next logon.
    12. ChangePasswordAtLogon - parameter used to indicate whether password should be changed.
    13. Group - a group to which user will be added.
    14. Enabled - parameter specyfing wheter user account is active or inactive.

### CSV File Example ###
```csv
Path,FirstName,DisplayName,Description,Email,JobTitle,Department,Company,UserPrincipalName,SamAccountName,Password,ChangePasswordAtLogon,Group,Enabled
"OU=Castle,OU=Inner Ring,OU=Camp,DC=oldcamp,DC=gothic,DC=inc",Raven,Raven,Second-in-command of the Old Camp and the right hand of Gomez,raven@oldcamp.gothic.inc,Ore Baron,Castle,Old Camp,raven@oldcamp.gothic.inc,raven,OldCamp1234,$true,Ore Barons, $true
```

## PowerShell Automation Script ##

```powershell
$csvFileName = Read-Host -Prompt "Provide name of the csv file to import"

if ($csvFileName.EndsWith(".csv") -ne $true) { $csvFileName = "$csvFileName.csv" }

$csvFilePath = Get-ChildItem -Path "C:\Users" -Filter "$csvFileName" -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
$csvFileObject = Import-Csv -Path $csvFilePath
$OUPath = ""

#FOR TEST PURPOSES SHOW THE csvFileObject#
#echo $csvFileObject

#CREATE USER FOREACH LOOP#
foreach ($person in $csvFileObject) {
New-ADUser -Path $person.Path`
-Name $person.FirstName `
-DisplayName $person.DisplayName `
-Description $person.Description `
-EmailAddress $person.Email `
-Title $person.JobTitle `
-Department $person.Department `
-Company $person.Company `
-UserPrincipalName $person.UserPrincipalName `
-SamAccountName $person.SamAccountName `
-AccountPassword (ConvertTo-SecureString -String $person.Password -AsPlainText -Force) `
-ChangePasswordAtLogon $true `
-Enabled $true

#ADD TO DEDICATED GROUP#
$groupList = $person.Group.Split(';')

foreach ($group in $groupList) {
$cleanGroup = $group.Trim()
Add-ADGroupMember -Identity $cleanGroup -Members $person.SamAccountName
}

#SAVE OU PATH
$OUPath = $person.Path
}

#END-LINER
echo "Users has been succesfully created under the path:"
$OUPath
```

### Script Explanation ###
At first user is aksed to provide a csv file name. The script recognizes whether input has a file extension and if extension is missing, script adds it automatically. Next file is searched under the C: drive, 'Users' folder. After the file is found we save a path to it for our 'Import-csv' cmdlet and create an object that we can loop through and get all the values for our new user's attributes.
Inside the loop in addition to retrieving standard values ​​from a CSV file it is worth noticing that we convert string provided by a csv file in the column 'Password' into a SecureString that can be used as a password in Active Directory.
Since column 'Group' can contain more than one group, we need to create a list that splits groups in this column using the semicolon as a separator and method '.Split()'.
After we get a list, we loop through the list and add a user to all the specified groups.

## How to run the scirpt ##
To run the script you have to have Windows Server with the ActiveDirectory Domain Services role installed and / or RSAT if you manage such a server from remote.
To run the script witohout any errors it is recommended to run PowerShell in Administrator mode.
After your environment is ready it is time to create your csv file. That file must be placed under the path 'C:\Users', otherwise script won't find it and work as intended. If you prefer other path or use other drive to save your csv files, feel free to change path to search in $csvFilePath variable under the -Path parameter of the 'Get-ChildItem' cmdlet.
When you have your csv file ready and saved launch the script and provide name of the csv file with or without extension. If the name is correct, csv file will be found and script will create new users.

### Example ###

```powershell
PS C:\Users\Administrator\Documents> .\newUsers.ps1
Provide name of the csv file to import: orebarons

Users has been succesfully created under the path:
OU=Castle,OU=Inner Ring,OU=Camp,DC=oldcamp,DC=gothic,DC=inc
```
