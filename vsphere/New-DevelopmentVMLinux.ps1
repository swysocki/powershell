<#
Usage: New-DevelopmentVMLinux -Quantity 10 -Template RHEL_6.4 -Type dev

Parameters:
    Quantity = How many VM's to deploy
    Template = The VMware guest template used as a clone target (example RedHat6_base)
        default = RedHat6_base
    Type = The customization type (Dev, Prod, etc)
        default = dev
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True)]
    [ValidateRange(1,30)]
    [Int]
    $Quantity, 

    [Parameter(Mandatory=$True)]
    [ValidateSet("RedHat6_base", "CentOS6_base")]
    [String]
    $Template = "RedHat6_base",
    
    [Parameter(Mandatory=$True)]
    [ValidateSet("dev", "prod")]
    [String]
    $Type = "dev"
)
function MakeVMConfig($type)
<#
  Creates the VM configuration object from a hashtable
  used to signal which type of server is to be created
  This can easily be expanded for staging, testing, etc.
#>
{
    if ($type -eq "dev")
    {
        $network = "99"
        $vswitch = "Development"
        $name = "dev_net"
    }
    elseif ($type -eq "prod")
    {
        $network = "101"
        $vswitch = "Production 01"
        $name = "prod_net"
    }

    $properties = @{'Network' = $network;
                    'Name' = $name;
                    'VSwitch' = $vswitch
                    }
    
    $config = New-Object -TypeName PSObject -Property $properties
    $config
}

function MakeVMSpec($config, $number)
<#
  Creates a VMware Guest Specification file
  Uses the "development_spec" as a baseline for the spec object and then overwrites attributes as necessary.  The baseline spec is not required but makes life much easier
#>
{
    "Making Spec for VM: " + $number
    $spec = Get-OSCustomizationSpec -Name "development_spec" |
        New-OSCustomizationSpec -Name 'temp' -Type NonPersistent
    Get-OSCustomizationNicMapping -OSCustomizationSpec 'temp' |
        Set-OSCustomizationNicMapping -IpMode UseStaticIP `
            -IpAddress "192.168.$($config.Network).$($number+100)" `
            -SubnetMask '255.255.255.0' `
            -DefaultGateway "192.168.$($config.Network).1"
    $spec
}

function RandomString
<#
  Create a random 8 char string to be used make hostnames unique-ish
#>
{
    if($uniq){ Remove-Variable uniq}
    $chars = 97..122 | % {[char]$_ }
    1..8 | % { $uniq += $chars | Get-Random }
    $uniq
}

function CreateVM($vm_num, $tmpl, $vmspec, $vmconf)
<#
  Creates the actual VM Guest in vSphere
  It also move the Network Adapter to the proper network and
  remove the temporary specification file
#>
{  
    $myrand_name = RandomString
    New-VM -Name "$($vmconf.Name)-$myrand_name" `
        -VMHost $(Get-VMHost -Name "esx$(Get-Random  -Min 1 -Max 4)") `
        -Location $($vmconf.Name) `
        -Template $(Get-Template -Name $tmpl) `
        -Datastore $(Get-Datastore | Sort-Object -Descending FreeSpaceGB | Select-Object -First 1).Name `
        -OSCustomizationSpec 'development_spec' `
        | Start-VM -RunAsync
    Get-VM -Name "$($vmconf.Name)-$myrand_name" | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $vmconf.VSwitch -Confirm:$false
   # Remove-OSCustomizationSpec -OSCustomizationSpec 'temp' -Confirm:$false
    
}    

function ConnectServer
<#
  Tests to see if an existing VIServer connection is present
#>
{
    if (-not $defaultviserver.isConnected)
    {
        "Connecting to Server, please wait..."
        Connect-VIServer "vcsa.dev.local"
    }
    else
    {
        "Connected to: $($defaultviserver.Name)"
    }
}

function runBatch($quantity, $template, $type)
<#
  Wraps the functions to run a batch of VM Guest creation
  Nearly all calls support the createVM function.  The previous
  output is needed for the next step
#>
{
    ConnectServer
    $conf = MakeVMConfig $type
    
    for($i = 1; $i -le $quantity; $i++)
    {
        #$spec = MakeVMSpec $conf $i
        createVM $i $template $spec $conf
   }
}

# the actual call, no main() exists in PowerShell
runBatch $Quantity $Template $Type
