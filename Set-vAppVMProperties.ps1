################################################################################
#
# Enables editing VApp VM properties. The script removes and adds new properties
# if they already exist. This way it allows reconfiguring ptoperties that are 
# marked as not configurable.
#
# Usage example:
#    $vm= Get-VM -Name 'newlyDeployedPoweredOffVM'  
#    $props= @{}
#    $props['guestinfo.cis.appliance.ssh.enabled']= $True
#    $props['guestinfo.cis.vmdir.site-name']= 'Default-First-Site'
#    $props['guestinfo.cis.vmdir.domain-name']= 'vsphere.local'
#
#    Set-vAppVmProperties.ps1 -VM $vm -Properties $props
#
################################################################################
param(
   $VM,
   [hashtable]$Properties
)

$spec = new-object 'VMware.Vim.VirtualMachineConfigSpec'
$spec.VAppConfig = New-Object 'VMware.Vim.VmConfigSpec'

$propertySpecList = @()

$keyNumber = ($vm.ExtensionData.Config.VAppConfig.Property | Measure-Object -Property Key -Maximum).Maximum
foreach ($keyValue in $properties.GetEnumerator()) {      
   $existingProp = $vm.ExtensionData.Config.VAppConfig.Property |  ? {$_.Id -eq $keyValue.Key}
   if ($existingProp) {
      $propSpec =new-object 'VMware.Vim.VAppPropertySpec'
      $propSpec.operation = 'remove'
      $propSpec.removeKey = $existingProp.Key
      $propertySpecList += $propSpec
   }

   $propSpec =new-object 'VMware.Vim.VAppPropertySpec'
   $propInfo =new-object 'vmware.vim.VAppPropertyInfo'
   $propInfo.Key = (++$keyNumber)
   $propInfo.Id = $keyValue.Key
   $propInfo.UserConfigurable = $true
   $propInfo.Value = $keyValue.Value
   $propSpec.Info = $propInfo
   $propertySpecList += $propSpec
}

$spec.VAppConfig.Property = $propertySpecList
$vm.ExtensionData.ReconfigVM($spec)
