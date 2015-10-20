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
    [string]$Path = "c:\windows\system32\iperf3.exe"
)

# The following functions are written in script-block format because 
# they are being used with Start-Job

# Simulate a UDP voice call $quality denotes codec bandwidth: Normally
# 32, 64, or 128 Kbps
$voice_call = { param($quality, $quantity, $duration, $ip, $iperf_path) `
                & $iperf_path `
                -i 0 `
                -p 5201 `
                -c $ip `
                -b $quality `
                -P $quantity `
                -t $duration `
                -u }

# Simulate a TCP file transfer. $file_size can be KB, MB, or GB
$file_transfer = { param($file_size, $quantity, $ip, $iperf_path) `
                   & $iperf_path `
                   -i 0 `
                   -p 5202 `
                   -c $ip `
                   -b $file_size `
                   -P $quantity }

# Simulate a UDP video stream.  Exactly the same as voice_call, but normally
# the bitrate is much higher (500 kbps - 6 Mbps)
# NOTE: Since we are not testing multicast functionality we can use a unicast
# stream here 
$video_stream = { param($bitrate, $quantity, $duration, $ip, $iperf_path) `
                  & $iperf_path `
                  -i 0 `
                  -p 5203 `
                  -c $ip `
                  -b $bitrate `
                  -P $quantity `
                  -t $duration `
                  -u }

if(! (Test-Path $Path))
{
    "ERROR: iPerf3.exe not found in $Path"
    "Please specify location with -Path parameter"
    Exit
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
        $job_name
    }
}

$jobs = @()

$job1 = Start-Job -ScriptBlock $voice_call -ArgumentList "64K","25","30", $ServerIP, $Path
$jobs += add_job $job1 "Voice Test"

$job2 = Start-Job -ScriptBlock $file_transfer -ArgumentList "300M", "15", $ServerIP, $Path
$jobs += add_job $job2 "File Test"

$job3 = Start-Job -ScriptBlock $video_stream -ArgumentList "6M","25","30", $ServerIP, $Path
$jobs += add_job $job3 "Video Test"

foreach ($result in $jobs)
{
    $output = $result | Wait-Job | Receive-Job | Select-String -Pattern SUM,ID,error
    $result.Type
    $output
}
