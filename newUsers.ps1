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