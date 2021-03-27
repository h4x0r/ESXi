# Build ESXi installer with NIC drivers (built-in and USB) for NUC 10
#
# Prerequisite
# 1. https://download3.vmware.com/software/vmw-tools/ESXi670-NE1000-32543355-offline_bundle-15486963.zip
# 2. ESXi700-VMKUSB-NIC-FLING-39035884-component-16770668.zip from https://flings.vmware.com/usb-network-native-driver-for-esxi

# Install VMware PowerCLI module
Install-Module -Name VMware.PowerCLI -Scope CurrentUser -AllowClobber

# Do not send back data
Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false

# Build profile names
$baseProfile = "ESXi-7.0.0-15843807-standard"
$newProfile = "ESXi-7.0.0-15843807-NUC"

# Clear existing ESX software depots
Get-EsxSoftwareDepot | Remove-EsxSoftwareDepot

# Download ESX base profile software depot
Add-EsxSoftwareDepot https://hostupdate.vmware.com/software/VUM/PRODUCTION/main/vmw-depot-index.xml
Export-ESXImageProfile -ImageProfile $baseProfile -ExportToBundle -filepath ($baseProfile + ".zip")
Remove-EsxSoftwareDepot https://hostupdate.vmware.com/software/VUM/PRODUCTION/main/vmw-depot-index.xml
Add-EsxSoftwareDepot (".\" + $baseProfile + ".zip")

# Add drivers as ESX software depots
Add-EsxSoftwareDepot .\ESXi670-NE1000-32543355-offline_bundle-15486963.zip
Add-EsxSoftwareDepot .\ESXi700-VMKUSB-NIC-FLING-39035884-component-16770668.zip

# Create new NUC profile
Remove-EsxImageProfile -ImageProfile $newProfile
New-EsxImageProfile -CloneProfile $baseProfile -name $newProfile -Vendor "virten.net"

# Inject new ne1000 NIC driver
Remove-EsxSoftwarePackage -ImageProfile $newProfile -SoftwarePackage "ne1000"
Add-EsxSoftwarePackage -ImageProfile $newProfile -SoftwarePackage "ne1000 0.8.4-3vmw.670.3.99.32543355"

# Inject USB NIC Fling driver
Add-EsxSoftwarePackage -ImageProfile $newProfile -SoftwarePackage "vmkusb-nic-fling"

# Export ESXi install ISO and bundle
Export-ESXImageProfile -ImageProfile $newProfile -ExportToISO -filepath (".\" + $newProfile + ".iso")
Export-ESXImageProfile -ImageProfile $newProfile -ExportToBundle -filepath (".\" + $newProfile + ".zip")
