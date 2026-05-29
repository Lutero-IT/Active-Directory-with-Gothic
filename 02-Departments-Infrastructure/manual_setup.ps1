$GroupName = ""
$GroupsList = Get-ADGroup -SearchBase "OU=User Groups,OU=Groups,OU=Camp,DC=oldcamp,DC=gothic,DC=inc" -Filter * | Select-Object -ExpandProperty Name

while ( -not ($GroupsList -contains $GroupName)) {
    echo "Please choose a group for which you want to create a Folder."
    echo "The available groups are:"
    echo $GroupsList
    
    $GroupName = Read-Host -Prompt "Type a group name"
    echo "### Checking if $GroupName is a valid group name ###"

    if ( -not ($GroupsList -contains $GroupName)) {
    echo "Provided Group doesn't exist."
    }
}

echo "Provided group is on a list. Creating Folder for a group..."

### Tworzenie Folderów i Plików###
if (-not(Test-Path "C:\Departments")) {
    New-Item -Path "C:\" -Name "Departments" -ItemType Directory }
if (-not(Test-Path "C:\Departments\$GroupName")) {
    New-Item -Path "C:\Departments\" -Name "$GroupName" -ItemType Directory }
if (-not(Test-Path "C:\Departments\$GroupName\AdminNote.txt")) {
    New-Item -Path "C:\Departments\$GroupName\" -Type "File" -Name "AdminNote.txt" }

### Protokół NTFS ###
# 1.Tworzymy CZYSTY ACL dla folderu '$GroupName'
$Acl = New-Object System.Security.AccessControl.DirectorySecurity

# 2.Blokujemy dziedziczenie na zmiennej $Acl, żeby móc je edytować
$Acl.SetAccessRuleProtection($true, $false)

# 3. Tworzymy reguły ACE dla odpowiednich grup i użytkowników i dodajemy je do zapisanego ACL
$SystemAce = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "NT AUTHORITY\SYSTEM",
    "FullControl",
    "ContainerInherit, ObjectInherit",
    "None",
    "Allow"
)
$Acl.AddAccessRule($SystemAce)
$AdminAce = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "BUILTIN\Administrators",
    "FullControl",
    "ContainerInherit, ObjectInherit",
    "None",
    "Allow"
)
$Acl.AddAccessRule($AdminAce)
$DepartmentAce = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "OLDCAMP\$GroupName",
    "Modify",
    "ContainerInherit, ObjectInherit",
    "None",
    "Allow"
)
$Acl.AddAccessRule($DepartmentAce)

# 5.Ustawiamy nową, zmodyfikowaną regułę ACL dla folderu '$GroupName' ( protokół NTFS zakończony)
Set-Acl -Path "C:\Departments\$GroupName" -AclObject $Acl

### Protokół SmbShare ###
New-SmbShare `
-Name "Shadows-Share"  `
-Path "C:\Departments\Shadows"  `
-FullAccess "Authenticated Users" `
-FolderEnumerationMode 'AccessBased' `
-EncryptData $true `
-CachingMode None

# Po ustawieniu protokołów SbmShare i NTFS, sprawdzić listę dostepu za pomocą komend:
# dla SMB: Get-SmbShareAccess -Name "Shadows-Share" @@@ dla NTFS: $Acl.Access | Format-Table IdentityReference

