### Tworzenie Folderów ###
# The location under which I executed the commands was: 
# [OldCampServer]: PS C:\
New-Item -Path . -Name "Departments" -ItemType Directory
New-Item -Path . -Name "Shadows" -ItemType Directory

# Current location:
# [OldCampServer]: PS C:\Departments\Shadows

New-Item -Type "File" -Name "AdminNote.txt"

### Protokół NTFS ###
# 1.Pobieramy ACL dla folderu 'Shadows'
$Acl = Get-Acl -Path "C:\Departments\Shadows"

# 2.Blokujemy dziedziczenie na zmiennej $Acl, żeby móc je edytować
$Acl.SetAccessRuleProtection($true, $true)

# 3. Usuwamy groups and users ze zmiennej $Acl, które nie są uprawnione do przeglądania folderu.
$RulesToRemove = $Acl.Access | Where-Object { $_.IdentityReference -eq "BUILTIN\Users" }
foreach ($Rule in $RulesToRemove) {
    $Acl.RemoveAccessRule($Rule)
}

# 4. Tworzymy regułę ACE i dodajemy ją do zapisanego ACL
$Identity = "oldcamp\Shadows"
$Rights = "Modify"
$Inheritance = "ContainerInherit, ObjectInherit"
$Propagation = "None"
$Type = "Allow"
$Ace = New-Object System.Security.AccessControl.FileSystemAccessRule($Identity, $Rights, $Inheritance, $Propagation, $Type)
$Acl.AddAccessRule($Ace)

# 5.Ustawiamy nową, zmodyfikowaną regułę ACL dla folderu 'Shadows' ( protokół NTFS zakończony)
Set-Acl -Path "C:\Departments\Shadows" -AclObject $Acl

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

