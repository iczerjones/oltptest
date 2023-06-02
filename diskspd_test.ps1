[ValidateCount(0,2)]
param(
    [Parameter(Position = 0, Mandatory=$false, 
               HelpMessage="        
               Usage: ./diskspd_test.ps1 <log suffix/ID> <data/log disk>
               Example: ./diskspd_test.ps1 run1 D
               (this will append results to appear as 'results_run1.txt' and assume D: is the data/log disk
               Note: A suffix will be generated if not supplied and we'll assume C: if not provided")]
    [string]$logsuffix,
    [Parameter(Position = 1, Mandatory=$false)]
    [ValidateLength(1,1)]
    [string]$datalog = "C"
)

### Create C:\Temp if not already present
if (-not(Test-Path -Path C:\Temp)){
    try {
        New-Item -Path 'C:\Temp' -ItemType Directory
    }
    catch {
        throw $_.Exception.Message
    }
}

### Download and unpack DISKSPD if necessary
if (-not(Test-Path -Path $env:USERPROFILE\Downloads\DISKSPD\amd64\diskspd.exe -PathType Leaf)) {
    try {
        $client = New-Object System.Net.WebClient
        $client.DownloadFile("https://github.com/microsoft/diskspd/releases/download/v2.1/DiskSpd.zip","$env:USERPROFILE\Downloads\DiskSpd-2.1.zip")
        Expand-Archive -Path $env:USERPROFILE\Downloads\DiskSpd-2.1.zip -DestinationPath $env:USERPROFILE\Downloads\DISKSPD
    }
    catch {
        throw $_.Exception.Message
    }
}

## Set a logsuffix if not defined
if ($logsuffix -eq $null){
    $logsuffix = Get-Date -UFormat "%b%d"
}

## Create the executable
$diskspd = "$env:USERPROFILE\Downloads\DISKSPD\amd64\diskspd.exe"

### Clean up any previous logs
Remove-Item C:\Temp\*_results.txt

### Test #1: MSSQL OLTP Workload
# oltpw30
& $diskspd -D -L -d600 -W300 -Sh -b8K -r -w30 -t8 -o32 -Z1M -c64D "$($datalog):\oltpio.dat" > "C:\Temp\oltpw30_results.txt"
# oltpw70
& $diskspd -D -L -d600 -W300 -Sh -b8K -r -w70 -t8 -o32 -Z1M -c64D "$($datalog):\oltpio.dat" > "C:\Temp\oltpw70_results.txt"

### Test #2: MSSQL Logfile Workload
& $diskspd -D -L -d600 -W300 -Sh -b60K -s -w100 -t1 -o32 -Z1M -c1G "$($datalog):\logio.dat" > "C:\Temp\logw_results).txt"

### Test #3: MSSQL Read-ahead Workload
& $diskspd -D -L -d600 -W300 -Sh -b512K -s -w0 -t1 -o32 -Z1M -c1G "$($datalog):\readaheadio.dat" > "C:\Temp\readahead_results.txt"

### Zip up results and place on the desktop
$dtpath = [Environment]::GetFolderPath("Desktop")
Compress-Archive -Path C:\Temp\*_results.txt -DestinationPath "$($dtpath)\results_$($logsuffix).zip"

### Clean up test results
Remove-Item C:\Temp\*_results.txt
