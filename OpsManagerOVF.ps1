# vCenter Server to deploy PKS Lab
$VIServer = "vc-fly.vmlive.italy"
$VIUsername = "administrator@vmlive.italy"
$VIPassword = "qwOPzx99"

Connect-VIServer $VIServer -User $VIUsername -Password $VIPassword -WarningAction SilentlyContinue


# Full Path to OVAs
$PKSOpsMgrOVA = "C:\PKS\pcf-vsphere-2.1-build.318.ova"

# General Deployment Configuration for OVAS
$VirtualSwitchType = "VSS" # VSS or VDS
$VMNetwork = "DVS_VLAN2"
$VMDatastore = "Management"
$VMNetmask = "255.255.255.0"
$VMGateway = "10.64.167.254"
$VMDNS = "10.64.144.133"
$VMNTP = "pool.ntp.org"
$VMPassword = "someComplexPWD"
$VMDomain = "vmlive.italy"
$VMSyslog = "10.64.167.190"
# Applicable to Nested ESXi only
$VMSSH = "true"
$VMVMFS = "false"
# Applicable to VC Deployment Target only
$RootDatacenterName = "VC-FLY"
$VMCluster = "PlatinumCluster"
$VMClusterManagement = "Management"


# Ops Manager VM
$OpsManagerDisplayName = "OpsManager"
$OpsManagerHostname = "opsmanager.vmlive.italy"
$OpsManagerIPAddress = "10.64.167.179"
$OpsManagerNetmask = "255.255.255.0"
$OpsManagerGateway = "10.64.167.254"
$OpsManagerOSPassword = "someComplexPWD"
    
#Load env variables    
$opsMgrOvfCOnfig = Get-OvfConfiguration $PKSOpsMgrOVA
$opsMgrOvfCOnfig.Common.ip0.Value = $OpsManagerIPAddress
$opsMgrOvfCOnfig.Common.custom_hostname.Value = $OpsManagerHostname
$opsMgrOvfCOnfig.Common.netmask0.Value = $OpsManagerNetmask
$opsMgrOvfCOnfig.Common.gateway.Value = $OpsManagerGateway
$opsMgrOvfCOnfig.Common.ntp_servers.Value = $VMNTP
$opsMgrOvfCOnfig.Common.DNS.Value = $VMDNS
$opsMgrOvfCOnfig.Common.admin_password.Value = $OpsManagerOSPassword
$opsMgrOvfCOnfig.NetworkMapping.Network_1.Value = $VMNetwork




#if(($isWindows) -or ($Env:OS -eq "Windows_NT")) {
#    $DestinationCtrThumprintStore = "$ENV:TMP\controller-thumbprint"
#    $DestinationVCThumbprintStore = "$ENV:TMP\vc-thumbprint"
#} else {
#    $DestinationCtrThumprintStore = "/tmp/controller-thumbprint"
#    $DestinationVCThumbprintStore = "/tmp/vc-thumbprint"
#}


#Connect to vCenter

$viConnection = Connect-VIServer $VIServer -User $VIUsername -Password $VIPassword -WarningAction SilentlyContinue

$cluster = Get-Cluster -Server $viConnection -Name $VMClusterManagement
$datacenter = $cluster | Get-Datacenter
$vmhost = $cluster | Get-VMHost | Select -First 1
$datastore = Get-Datastore -Server $viConnection -Name $VMDatastore | Select -First 1

    Write-Host "Deploying PKS Ops Manager $OpsManagerDisplayName ..."
    $opsmgr_vm = Import-VApp -Source $PKSOpsMgrOVA -OvfConfiguration $opsMgrOvfCOnfig -Name $OpsManagerDisplayName -Location $cluster -VMHost $vmhost -Datastore $datastore -DiskStorageFormat thin

    Write-Host "Powering On $OpsManagerDisplayName ..."
    $opsmgr_vm | Start-Vm -RunAsync | Out-Null
