### Wybór Grupy ###

$GroupName = ""
$GroupsList = Get-ADGroup -SearchBase "OU=User Groups,OU=Groups,OU=Camp,DC=oldcamp,DC=gothic,DC=inc" -Filter * | Select-Object -ExpandProperty Name

while ( -not ($GroupsList -contains $GroupName)) {
    Write-Host "Please choose a group for which you want to create a Folder."
    Write-Host "The available groups are:"
    Write-Host $GroupsList
    
    $GroupName = Read-Host -Prompt "Type a group name"
    Write-Host "### Checking if $GroupName is a valid group name ###"

    if ( -not ($GroupsList -contains $GroupName)) {
    Write-Host "Provided Group doesn't exist"
    }
}

Write-Host "Provided group is on a list. Creating Folder for a group..."

### Tworzenie Folderów i Plików###
if (-not(Test-Path "C:\Departments")) {
    New-Item -Path "C:\" -Name "Departments" -ItemType Directory
    Write-Host "Folder C:\Departments created..." }
if (-not(Test-Path "C:\Departments\$GroupName")) {
    New-Item -Path "C:\Departments\" -Name "$GroupName" -ItemType Directory
    Write-Host "Folder C:\Departments\$GroupName created..." }
if (-not(Test-Path "C:\Departments\$GroupName\AdminNote.txt")) {
    New-Item -Path "C:\Departments\$GroupName\" -Type "File" -Name "AdminNote.txt" 
    Write-Host "File C:\Departments\$GroupName\AdminNote.txt created..."}

Write-Host "Folder and File Creation finished"

### Protokół NTFS ###

Write-Host "### Setting ACL permissions###"
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
Write-Host "Added 'NT AUTHORITY\SYSTEM' to ACL..."

$Acl.AddAccessRule($SystemAce)
$AdminAce = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "BUILTIN\Administrators",
    "FullControl",
    "ContainerInherit, ObjectInherit",
    "None",
    "Allow"
)
Write-Host "Added BUILTIN\Administrators to ACL..."

$Acl.AddAccessRule($AdminAce)
$DepartmentAce = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "OLDCAMP\$GroupName",
    "Modify",
    "ContainerInherit, ObjectInherit",
    "None",
    "Allow"
)
Write-Host "Added OLDCAMP\$GroupName to ACL ..."

$Acl.AddAccessRule($DepartmentAce)

# 5.Ustawiamy nową, zmodyfikowaną regułę ACL dla folderu '$GroupName' ( protokół NTFS zakończony)
Set-Acl -Path "C:\Departments\$GroupName" -AclObject $Acl
Write-Host "### Setting ACL permissions finished ###"

### Protokół SmbShare ###

$SmbName = "$GroupName-Share"
Write-Host "### Checking if SmbShare exitsts in database ###"
if (Get-SmbShare -Name $SmbName -ErrorAction SilentlyContinue) {
    Write-Host "SmbShare for $GroupName group found in database. Removing stale records."
    Remove-SmbShare -Name $SmbName -Force
    Write-Host "Records removed."
} else {
    Write-Host "SmbShare not found in database. Setting SmbShare for $GroupName group..."
}

New-SmbShare `
-Name $SmbName  `
-Path "C:\Departments\$GroupName"  `
-FullAccess "Authenticated Users" `
-FolderEnumerationMode 'AccessBased' `
-EncryptData $true `
-CachingMode None
Write-Host "New SmbShare under name $SmbName created"

Write-Host "Setting SmbShare finished"

# Po ustawieniu protokołów SbmShare i NTFS, sprawdzić listę dostepu za pomocą komend:
# dla SMB: Get-SmbShareAccess -Name "$GroupName-Share" @@@ dla NTFS: $Acl.Access | Format-Table IdentityReference

### DRIVE-MAPPING, czyli ustawianie udostepnionych Folderów jako Dysków ###

### Pobranie FQDN dla parametru '-Domain' ###
$CanonName = (Get-ADGroup $GroupName -Properties CanonicalName).CanonicalName
$DomainFQDN = $CanonName.Split('/')[0]
$GPOName = "GPP_U_DriveMap_$GroupName"
$TargetOU = "OU=User Groups,OU=Groups,OU=Camp,DC=oldcamp,DC=gothic,DC=inc"

### Tworzenie GPO i podpięcię go do folderu Działu ###

Write-Host "### Checking if Drive Mapping GPO exists in database ###"
if (Get-GPO -Name $GPOName -Domain $DomainFQDN -ErrorAction SilentlyContinue) {
    Write-Host "GPO for $GroupName group found in database. Removing stale records."
    Remove-GPO -Name $GPOName -Domain $DomainFQDN
    Write-Host "Records removed."
} else {
    Write-Host "GPO for $GroupName group not found in database. Setting new GPO..."
}

New-GPO `
-Name $GPOName `
-Comment "This is Drive Mapping GPO for $GroupName Department" `
-Domain $DomainFQDN
Write-Host "New GPO under name $GPOName created"

New-GPLink `
-Name $GPOName `
-Domain $DomainFQDN `
-Target $TargetOU
Write-Host "$GPOName linked to: $TargetOU"
