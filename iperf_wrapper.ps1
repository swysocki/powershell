<# 
Test-Network script for sending multiple parallel data types

The iPerf utility can send parallel streams of the same protocol
(UDP/TCP) to the same socket.  This script allows running multiple
iPerf processes to simulate concurrent network activity.

This utility only works with iPerf3, which is not compatible with 
iPerf2
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True)]
    [string]$ServerIP,
    [Parameter(Mandatory=$False)]
    [string]$Path = "c:\windows\system32\iperf.exe",
    [Parameter(Mandatory=$False)]
    [string]$FilePath
)


if(! (Test-Path $Path))
{
    "ERROR: iPerf3.exe not found in $Path"
    "Please specify location with -Path parameter"
    Exit
}

if($FilePath -ne "")
{
    if(! (Test-Path $FilePath))
    {
        "ERROR: $FilePath does not exist"
        Exit
    }
}

# Global Jobs list - this should be a singleton but that is not easily
# achieved in PowerShell
$Global:jobs = @()

# The following functions are written in script-block format because 
# they are being used with Start-Job

# Simulate a UDP voice call $quality denotes codec bandwidth: Normally
# 32, 64, or 128 Kbps
$voice_call = { param($quality, $quantity, $duration, $ip, $iperf_path) `
                & $iperf_path `
                -i 1 `
                -p 5201 `
                -c $ip `
                -P $quantity `
                -t $duration `
                -u -b $quality
               }

# Simulate a TCP file transfer
$file_transfer = { param($duration, $ip, $iperf_path) `
                   & $iperf_path `
                   -i 1 `
                   -p 5202 `
                   -c $ip `
                   -t $duration
                  }

# Simulate a UDP video stream.  Exactly the same as voice_call, but normally
# the bitrate is much higher (500 kbps - 6 Mbps)
# NOTE: Since we are not testing multicast functionality we can use a unicast
# stream here 
$video_stream = { param($bitrate, $quantity, $duration, $ip, $iperf_path) `
                  & $iperf_path `
                  -i 1 `
                  -p 5203 `
                  -c $ip `
                  -u -b $bitrate `
                  -P $quantity `
                  -t $duration
                  }

function add_job($job_name, $job_type)
{
    if ($job_name.State -eq "Failed")
    {
        "Job Failed"
        $job_name | Receive-Job
    }
    else
    {
        $job_name | Add-Member -NotePropertyName "Type" -NotePropertyValue $job_type
        $Global:jobs += $job_name
    }
}

# Normal Usage test
# 1 64K phone call
# 1 TCP file transfer
# 1 3M video stream
function test_low($time="60")
{
    
    add_job $(Start-Job -ScriptBlock $voice_call -ArgumentList "64K","1", $time, $ServerIP, $Path) "Voice-Test"
    
    add_job $(Start-Job -ScriptBlock $file_transfer -ArgumentList $time, $ServerIP, $Path) "File Test"

    add_job $(Start-Job -ScriptBlock $video_stream -ArgumentList "3M","1",$time, $ServerIP, $Path) "Video Test"
}

function run()
{
    foreach ($result in $Global:jobs)
    {
        $output = $result | Wait-Job | Receive-Job | Select-Object -Last 10
        $result.Type
        $output
    }
}

test_low "10"
run


