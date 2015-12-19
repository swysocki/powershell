<#
    Searches all VM Guests for an hd audio device
    This device is incompatible with vSphere Vmotion and will raise warnings when trying
    to migrate a VM from one host to the next
    
    This relies on PowerCLI
#>

function findHdAudio($vmguest)
# Returns the audio device object if found
{
    $vmguest.ExtensionData.Config.Hardware.Device | where { $_.GetType().Name -eq "VirtualHdAudioCard" }
}

function createSpec($audio_card)
# Create the spec object using the audio card object
{
    $dev_spec = New-Object Vmware.Vim.VirtualDeviceConfigSpec
    $dev_spec.Device = $audio_card
    $dev_spec.Operation = "remove"
    
    $vm_spec = New-Object VMware.Vim.VirtualMachineConfigSpec 
    $vm_spec.deviceChange += $dev_spec
    return $vm_spec
}
function removeHdAudio($vmguest, $spec)
{
    "Removing HD Audio For:" + $vmguest
    $vmguest.ExtensionData.ReconfigVM($spec)
}

function checkPowerStateOff($vmguest)
{
    $vmguest.PowerState -eq "PoweredOff"
}

foreach($guest in $foo)
{
    "Processing " + $guest
    $audio = findHdAudio $guest
    if ($audio)
    {
        "Found HD Audio device on VM: " + $guest
        if (checkPowerStateOff $guest)
        {
            $remove_spec = createSpec $audio
            removeHdAudio $guest $remove_spec
        }
        else
        {
            "ABORTING: VM Guest must be powered off"
        }
    }
}

