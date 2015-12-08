
##Prerequisites:
To run Powershell scripts, you must enable execution of 3rd party scripts in your environment.

Open a Powershell prompt as Administrator by right clicking on the Powershell icon and selecting "Run as Administrator".  
Once Powershell has opened run 
> Set-ExecutionPolicy RemoteSigned
Select "Y" for yes when prompted
Close Powershell


##iPerf Scripts:
After unzipping wireless-testing.zip you will have 3 components:
README.txt (this file)
iperf_wrapper.ps1 (test driver)
iper2 folder (the iperf libraries)

The easiest way to run the test is to move the components to the c:\ directory.  It can be run from anywhere in the file system,
but you will need to know the components' locations.

Assuming the components are at C:\ will simply launch the Powershell console, and change to the c:\ directory.

> set-location c:\

You will now be in the same directory where you have the test components

To run a test you will need to know 3 mandatory parameters.  The iPerf Server IP Address, the path to the iPerf executable and
the "Load" of the test you want to run.

For example, a "Low Load" run would look like:

> .\iperf_wrapper.ps1 -ServerIP 192.168.101.24 -Path c:\iperf2\iperf.exe -Load Low

This will run, by default for 60 seconds.  During that time no output will be written to Powershell.  When the test is complete
the results will be displayed in the console.

Here is a summary of the script parameters:
-ServerIP = the IP address of the server that is listening for iPerf tests
-Path = the absolute path to the iPerf executable
-Load = the load profile you want to run (Low, Medium, High)
-Time = the length of time the test should run, in seconds (default 60)

NOTE: the parameters are tab-completable

## iPerf Output

The iperf_wrapper.ps1 writes its output to the Powershell console (standard out).  If it is desired to write the output to a file,
this can be accomplished by "tee-ing" the output to a writable location such as the user's directory.

Powershell accomplishes this with the pipe capable Tee-Object commandlet.  For instance if you want to write the iPerf output to file in your
user's directory:

> .\iperf_wrapper.ps1 -ServerIP 192.168.101.24 -Path c:\iperf2\iperf.exe -Load Low | Tee-Object c:\users\test\test_output.txt
