
function Get-VMSnapshotConfigSetting {
param(
   [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
   [ValidateNotNull()]
   [VMware.VimAutomation.Types.VirtualMachine]
   $vm,

   [Parameter(Mandatory=$true)]
   [ValidateNotNull()]
   [string]
   $key
)

PROCESS {
   $content = Get-VMSnapshotConfigContent -vm $vm

   $keyMatch = $content | Select-String ('{0} = "(?<value>.*)"' -f $key)
   # result
   $keyMatch.Matches[0].Groups["value"].Value
}
}

function Get-VMSnapshotConfigContent {
param(
   [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
   [ValidateNotNull()]
   [VMware.VimAutomation.Types.VirtualMachine]
   $vm
)

PROCESS {
   # Create web client from current session
   $sessionKey = $vm.GetClient().ConnectivityService.CurrentUserSession.SoapSessionKey
   $certValidationHandler = $vm.GetClient().ConnectivityService.GetValidationHandlerForCurrentServer()
   $webClient = [vmware.vimautomation.common.util10.httpclientUtil]::CreateHttpClientWithSessionReuse($certValidationHandler, $sessionKey, $null)

   # Build VMSD file http URI
   # https://code.vmware.com/apis/358/vsphere#/doc/vim.FileManager.html
   $vmName = $vm.Name
   $datastoreName = ($vm | Get-Datastore).Name
   $dcName = ($vm | Get-Datacenter).Name
   $serverAddress = $vm.GetClient().ConnectivityService.ServerAddress
   $vmsdUri = [uri]"https://$serverAddress/folder/$vmName/$vmName.vmsd?dcPath=$dcName&dsName=$datastoreName"

   # Get VMSD content as string
   $task = $webClient.GetAsync($vmsdUri)
   $task.Wait()
   $vmsdContent = $task.Result.Content.ReadAsStringAsync().Result

   # Dispose web client
   $webClient.Dispose()

   # Result
   $vmsdContent
}

}