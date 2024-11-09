# https://github.com/jxroot/freeuse

# Define the output HTML file path
$outputFile = "./SystemInfo.html"
$uptime = (Get-Date) - (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
# Collect system information
$sysInfo = @{
    "Computer Name"              = $env:COMPUTERNAME
    "Username"                   = $env:USERNAME
    "Operating System"           = (Get-CimInstance Win32_OperatingSystem).Caption
    "Version"                    = (Get-CimInstance Win32_OperatingSystem).Version
    "Architecture"               = (Get-CimInstance Win32_OperatingSystem).OSArchitecture
    "Manufacturer"               = (Get-CimInstance Win32_ComputerSystem).Manufacturer
    "Model"                      = (Get-CimInstance Win32_ComputerSystem).Model
    "Total Physical Memory (MB)" = [math]::round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1MB, 2)
    "Free Physical Memory (MB)"  = [math]::round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB, 2)
    "Total Virtual Memory (MB)"  = [math]::round((Get-CimInstance Win32_OperatingSystem).TotalVirtualMemorySize / 1MB, 2)
    "Free Virtual Memory (MB)"   = [math]::round((Get-CimInstance Win32_OperatingSystem).FreeVirtualMemory / 1MB, 2)
    "System Uptime"              = "{0} Days, {1} Hours, {2} Minutes, {3} Seconds" -f $uptime.Days, $uptime.Hours, $uptime.Minutes, $uptime.Seconds
    "Domain/Workgroup"           = (Get-CimInstance Win32_ComputerSystem).Domain
}
# Collect additional network information
$networkInfo = Get-NetAdapter | ForEach-Object {
    $adapter = $_
    $ipConfig = Get-NetIPConfiguration -InterfaceAlias $adapter.Name

    [PSCustomObject]@{
        InterfaceAlias       = $adapter.Name
        InterfaceDescription = $adapter.InterfaceDescription
        MacAddress           = $adapter.MacAddress
        LinkSpeed            = $adapter.LinkSpeed
        Status               = $adapter.Status
        IPv4Address          = ($ipConfig.IPv4Address | ForEach-Object { $_.IPAddress }) -join ", "
        IPv6Address          = ($ipConfig.IPv6Address | ForEach-Object { $_.IPAddress }) -join ", "
        DefaultGateway       = ($ipConfig.IPv4DefaultGateway | ForEach-Object { $_.NextHop }) -join ", "
    }
}
$diskInfo = Get-Disk | Select-Object -Property Number, Model, SerialNumber, 
@{Name = 'HealthStatus'; Expression = { $_.OperationalStatus } },
@{Name = 'PartitionStyle'; Expression = { $_.PartitionStyle } },
@{Name = 'TotalSize (GB)'; Expression = { [math]::round($_.Size / 1GB, 2) } },
@{Name = 'FriendlyName'; Expression = { $_.FriendlyName } } 

# Get process information
$processes = Get-Process | Select-Object Name, Id, 
@{Name = "CPU (s)"; Expression = { $_.CPU } }, 
@{Name = "Memory (MB)"; Expression = { [math]::round($_.WorkingSet / 1MB, 2) } }, 
StartTime, 
@{Name = "Path"; Expression = { try { (Get-Process -Id $_.Id).Path } catch { "N/A" } } }
$antivirus_info = Get-CimInstance -Namespace "root/SecurityCenter2" -ClassName AntivirusProduct | Select-Object displayName
$cpuInfo = Get-CimInstance Win32_Processor | Select-Object -Property Name, NumberOfCores, NumberOfLogicalProcessors
$gpuInfo = Get-CimInstance Win32_VideoController | Select-Object -Property Name, AdapterRAM

# Collect system uptime information
# $uptime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
# $uptimeFormatted = $null

# # Check if LastBootUpTime is valid and convert
# if ($uptime -and $uptime -match '(\d{14})') {
#     $uptimeFormatted = [Management.ManagementDateTimeConverter]::ToDateTime($uptime)
# } else {
#     $uptimeFormatted = "N/A"  # Set a default value if LastBootUpTime is invalid
# }

# Collect installed software information
$softwareInfo = Get-CimInstance Win32_Product | Select-Object -Property Name, Version, Vendor

# Collect system services information
$serviceInfo = Get-Service | Select-Object -Property DisplayName, Status, ServiceType, StartType

# Collect user information
$userInfo = Get-LocalUser | Select-Object -Property Name, Enabled, LastLogon

# Collect firewall status information
$firewall = Get-NetFirewallProfile | Select-Object -Property Name, Enabled

# Collect open ports information
$openPorts = Get-NetTCPConnection | Where-Object { $_.State -eq "Listen" -or $_.State -eq "Established" }
# Collect arp information
$arp_info = Get-NetNeighbor
# Determine CPU brand for banner image
$cpuName = $cpuInfo.Name
$cpuBannerImage = ""

if ($cpuName -like "*Intel*") {
    $cpuBannerImage = "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1e/Intel_logo.svg/1280px-Intel_logo.svg.png" # Intel logo
}
elseif ($cpuName -like "*AMD*") {
    $cpuBannerImage = "https://upload.wikimedia.org/wikipedia/commons/thumb/8/8c/AMD_logo.svg/1280px-AMD_logo.svg.png" # AMD logo
}
else {
    $cpuBannerImage = "https://upload.wikimedia.org/wikipedia/commons/thumb/8/8c/AMD_logo.svg/1280px-AMD_logo.svg.png" # Default to AMD logo if not found
}

# Create HTML content with tabs and icons
$htmlContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>System Information</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
      <style>
        body {
            font-family: 'Arial', sans-serif;
            background-color: #121212;
            color: #e0e0e0;
            margin: 0;
            padding: 20px;
            transition: background-color 0.5s, color 0.5s;
        }
        body.light-mode {
            background-color: #ffffff;
            color: #000000;
        }
        h1 {
            color: #e0e0e0;
            text-align: center;
            margin-bottom: 20px;
        }
        .banner {
            text-align: center;
            margin: 20px 0;
        }
        .banner img {
            max-width: 300px;
        }
        .tab {
            display: flex;
            justify-content: center;
            overflow: hidden;
            border: 1px solid #444;
            background-color: #1f1f1f; /* Dark mode tab background */
            border-radius: 5px;
            margin-bottom: 20px;
        }
        body.light-mode .tab {
            background-color: #e0e0e0; /* Light mode tab background */
        }
        .tab button {
            background-color: inherit;
            border: none;
            outline: none;
            cursor: pointer;
            padding: 14px 16px;
            transition: 0.3s;
            font-size: 17px;
            color: #e0e0e0; /* Dark mode button text color */
            border-bottom: 3px solid transparent;
        }
        body.light-mode .tab button {
            color: #000; /* Light mode button text color */
        }
        .tab button:hover {
            background-color: #444; /* Dark mode hover */
        }
        body.light-mode .tab button:hover {
            background-color: #ccc; /* Light mode hover */
        }
        .tab button.active {
            background-color: #1a73e8; /* Active tab color */
            color: white;
            border-bottom: 3px solid #e0e0e0; /* Active tab border */
        }
        body.light-mode .tab button.active {
            background-color: #e0e0e0; /* Light mode active tab color */
            color: #1a73e8; /* Light mode active text color */
            border-bottom: 3px solid #1a73e8; /* Light mode active tab border */
        }
        .tabcontent {
            display: none;
            padding: 20px;
            border-top: none;
            background-color: #1b1b1b; /* Dark mode tab content */
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.5);
            border-radius: 5px;
        }
        body.light-mode .tabcontent {
            background-color: #f0f0f0; /* Light mode tab content */
            color: #000;
        }
        .tabcontent table {
            width: 100%;
            border-collapse: collapse;
        }
        .tabcontent table, th, td {
            border: 1px solid #444;
        }
        th, td {
            padding: 12px;
            text-align: left;
        }
        th {
            background-color: #1a73e8;
            color: white;
        }
        tr:nth-child(even) {
            background-color: #2a2a2a;
        }
        body.light-mode tr:nth-child(even) {
            background-color: #d0d0d0;
        }
        .icon {
            margin-right: 8px;
        }
        .float-button {
            position: fixed;
            bottom: 20px;
            right: 20px;
            background-color: #1a73e8;
            color: white;
            border: none;
            border-radius: 50%;
            width: 50px;
            height: 50px;
            font-size: 24px;
            cursor: pointer;
            box-shadow: 0 2px 5px rgba(0, 0, 0, 0.3);
            transition: background-color 0.3s;
        }
        .float-button:hover {
            background-color: #0d47a1;
        }
    </style>
    <script>
        function openTab(evt, tabName) {
            var i, tabcontent, tablinks;
            tabcontent = document.getElementsByClassName("tabcontent");
            for (i = 0; i < tabcontent.length; i++) {
                tabcontent[i].style.display = "none";  
            }
            tablinks = document.getElementsByClassName("tablinks");
            for (i = 0; i < tablinks.length; i++) {
                tablinks[i].className = tablinks[i].className.replace(" active", "");
            }
            document.getElementById(tabName).style.display = "block";  
            evt.currentTarget.className += " active"; // Add 'active' class
        }
        
        function toggleDarkMode() {
            document.body.classList.toggle("light-mode");
            document.querySelector(".float-button").classList.toggle("light-mode");
            const tabButtons = document.querySelectorAll(".tab button");
            tabButtons.forEach(button => {
                button.classList.toggle("light-mode");
            });
        }
    </script>
</head>
<body>

    <h1>System Information</h1>

 

    <div class="tab">
        <button class="tablinks" onclick="openTab(event, 'GeneralInfo')"><i class="fas fa-info-circle icon"></i>General Information</button>
        <button class="tablinks" onclick="openTab(event, 'NetworkInfo')"><i class="fas fa-network-wired icon"></i>Network Information</button>
        <button class="tablinks" onclick="openTab(event, 'DiskInfo')"><i class="fas fa-hdd icon"></i>Disk Information</button>
    

        <button class="tablinks" onclick="openTab(event, 'SoftwareInfo')"><i class="fas fa-cogs icon"></i>Installed Software</button>
        <button class="tablinks" onclick="openTab(event, 'ServiceInfo')"><i class="fas fa-tools icon"></i>Services</button>
        <button class="tablinks" onclick="openTab(event, 'TaskSCHInfo')"><i class="fas fa-tools icon"></i>Task SCH</button>
        <button class="tablinks" onclick="openTab(event, 'ProcessInfo')"><i class="fas fa-tools icon"></i>Process</button>
        <button class="tablinks" onclick="openTab(event, 'UserInfo')"><i class="fas fa-user icon"></i>Users</button>
    </div>

    <div id="GeneralInfo" class="tabcontent">
        <h2>General Information <i class="fas fa-info-circle icon"></i></h2>
        <table>
            <tr><th>Property <i class="fas fa-th icon"></i></th><th>Value <i class="fas fa-list icon"></i></th></tr>
"@

# Populate HTML table with system information
foreach ($key in $sysInfo.Keys) {
    $htmlContent += "<tr><td>$key</td><td>$($sysInfo[$key])</td></tr>"
}
$htmlContent += @"
        </table>

        <h2>CPU Information <i class="fas fa-microchip icon"></i></h2>
        <table>
            <tr><th>CPU Name <i class="fas fa-cog icon"></i></th><th>Cores <i class="fas fa-cogs icon"></i></th><th>Logical Processors <i class="fas fa-tasks icon"></i></th></tr>
"@

# Populate HTML table with CPU information
foreach ($cpu in $cpuInfo) {
    $htmlContent += "<tr><td>$($cpu.Name)</td><td>$($cpu.NumberOfCores)</td><td>$($cpu.NumberOfLogicalProcessors)</td></tr>"
}




$htmlContent += @"
        </table>

        <h2>GPU Information <i class="fas fa-video icon"></i></h2>
        <table>
            <tr><th>GPU Name <i class="fas fa-desktop icon"></i></th><th>Adapter RAM (GB) <i class="fas fa-memory icon"></i></th></tr>
"@

# Populate HTML table with GPU information
foreach ($gpu in $gpuInfo) {
    $ramGB = [math]::round($gpu.AdapterRAM / 1GB, 2)
    $htmlContent += "<tr><td>$($gpu.Name)</td><td>$ramGB</td></tr>"
}







$htmlContent += @"
        </table>

        <h2>Antivirus Information <i class="fas fa-video icon"></i></h2>
        <table>
            <tr><th> Name <i class="fas fa-desktop icon"></i></th></tr>
"@

# Populate HTML table with AV information
foreach ($av in $antivirus_info) {
    $htmlContent += "<tr><td>$($av.displayName)</td></tr>"
}















$htmlContent += @"
        </table>
    </div>

    <div id="NetworkInfo" class="tabcontent">
        <h2>Network Information <i class="fas fa-network-wired icon"></i></h2>
        <table>
        <tr><th>Interface Alias</th><th>Interface Description</th><th>MAC Address</th><th>Link Speed</th><th>Status</th><th>IPv4 Address</th><th>IPv6 Address</th><th>Default Gateway</th></tr>
"@

# Populate HTML table with network information
foreach ($network in $networkInfo) {
    # Filter out IPv4 and IPv6 addresses
    $ipv4Addresses = $network.IPv4Address -join ", "
    $ipv6Addresses = $network.IPv6Address -join ", "
    $defaultGateway = $network.DefaultGateway -join ", "

    $htmlContent += "<tr>
        <td>$($network.InterfaceAlias)</td>
        <td>$($network.InterfaceDescription)</td>
        <td>$($network.MacAddress)</td>
        <td>$($network.LinkSpeed)</td>
        <td>$($network.Status)</td>
        <td>$ipv4Addresses</td>
        <td>$ipv6Addresses</td>
        <td>$defaultGateway</td>
    </tr>"
}

$htmlContent += @"
        </table>
        <h3>Firewall Status</h3>
        <table>
            <tr><th>Profile <i class="fas fa-shield-alt icon"></i></th><th>Enabled <i class="fas fa-toggle-on icon"></i></th></tr>
"@

# Populate HTML table with firewall information
foreach ($fw in $firewall) {
    $htmlContent += "<tr><td>$($fw.Name)</td><td>$($fw.Enabled)</td></tr>"
}

$htmlContent += @"
        </table>
        <h3>Open Ports</h3>
        <table>
            <tr><th>Name <i class="fas fa-check-circle icon"></i></th><th>Local Address <i class="fas fa-globe icon"></i></th><th>Local Port <i class="fas fa-tag icon"></i></th><th>Status <i class="fas fa-check-circle icon"></i></th></tr>
"@




# Populate HTML table with openPorts information
foreach ($port in $openPorts) {
    $proc = Get-Process -Id $port.OwningProcess -ErrorAction SilentlyContinue
    $ProcessName = if ($proc) { $proc.Name } else { "Unknown" }
    $htmlContent += "<tr><td>$($ProcessName)</td><td>$($port.LocalAddress)</td><td>$($port.LocalPort)</td><td>$($port.State)</td></tr>"

}






$htmlContent += @"
        </table>
          <h3>Arp ( Get-NetNeighbor )</h3>
              <table>
            <tr><th>Name <i class="fas fa-check-circle icon"></i></th><th>Local Address <i class="fas fa-globe icon"></i></th><th>Local Port <i class="fas fa-tag icon"></i></th><th>Status <i class="fas fa-check-circle icon"></i></th></tr>
"@
foreach ($arp in $arp_info) {
    
    $htmlContent += "<tr><td>$($arp.ifIndex)</td><td>$($arp.IPAddress)</td><td>$($arp.LinkLayerAddress)</td><td>$($arp.State)</td></tr>"

}


$htmlContent += @"
</table>
    </div>

    <div id="DiskInfo" class="tabcontent">
        <h2>Disk Information <i class="fas fa-hdd icon"></i></h2>
        <table>
            <tr>
                <th>Drive Letter <i class="fas fa-folder icon"></i></th>
                <th>Total Size (GB) <i class="fas fa-layer-group icon"></i></th>
                <th>Health Status <i class="fas fa-heartbeat icon"></i></th>
                <th>Partition Style <i class="fas fa-th-list icon"></i></th>
                <th>Serial Number <i class="fas fa-barcode icon"></i></th>
                <th>Friendly Name <i class="fas fa-tags icon"></i></th>
            </tr>
"@

# Combine disk and partition information for HTML output
foreach ($disk in $diskInfo) {
    # Get unique partitions for the current disk
    $partitions = Get-Partition -DiskNumber $disk.Number
    # Prepare a list of drive letters and their sizes
    $driveList = @()
    foreach ($partition in $partitions) {
        $sizeGB = [math]::round($partition.Size / 1GB, 2)
        $driveList += "$($partition.DriveLetter):$sizeGB GB"
    }

    # Join the drive list into a single string
    $driveListString = $driveList -join ",   "

    # Output the friendly name and drive list
   
    $htmlContent += "<tr>
            <td>$driveListString</td>
            <td>$($disk.'TotalSize (GB)')</td>
            <td>$($disk.HealthStatus)</td>
            <td>$($disk.PartitionStyle)</td>
            <td>$($disk.SerialNumber)</td>
            <td>$($disk.FriendlyName)</td>
        </tr>"
}

$htmlContent += @"
        </table>
        <h2>File Format Information <i class="fas fa-hdd icon"></i></h2>
        <table>
            <tr>
                <th>Format <i class="fas fa-folder icon"></i></th>
                <th>Count <i class="fas fa-layer-group icon"></i></th>
             
            </tr>


"@
# Get all drives on the system
$drives = Get-PSDrive -PSProvider FileSystem

# Initialize a hashtable to store file extensions and their counts
$fileCounts = @{}

# Iterate over each drive
foreach ($drive in $drives) {
    # Get all files in the current drive recursively
    Get-ChildItem -Path $drive.Root -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
        # Get the file extension
        $extension = $_.Extension.ToLower()

        # Increment the count for this file extension
        if ($extension) {
            if ($fileCounts.ContainsKey($extension)) {
                $fileCounts[$extension]++
            }
            else {
                $fileCounts[$extension] = 1
            }
        }
    }
}
# Output the results in HTML format
$fileCounts.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
    $htmlContent += "<tr>
        <td>$($_.Key)</td>
        <td>$($_.Value)</td>
    </tr>"
}

$htmlContent += @"
</table>
    </div>

    <div id="SoftwareInfo" class="tabcontent">
        <h2>Installed Software <i class="fas fa-cogs icon"></i></h2>
        <table>
            <tr><th>Software Name <i class="fas fa-box icon"></i></th><th>Version <i class="fas fa-tags icon"></i></th><th>Vendor <i class="fas fa-user-tie icon"></i></th></tr>
"@

# Populate HTML table with installed software information
foreach ($software in $softwareInfo) {
    $htmlContent += "<tr><td>$($software.Name)</td><td>$($software.Version)</td><td>$($software.Vendor)</td></tr>"
}

$htmlContent += @"
        </table>
    </div>

    <div id="ServiceInfo" class="tabcontent">
        <h2>System Services <i class="fas fa-tools icon"></i></h2>
        <table>
            <tr><th>Service Name <i class="fas fa-toolbox icon"></i></th><th>Status <i class="fas fa-check-circle icon"></i></th><th>Service Type <i class="fas fa-cogs icon"></i></th><th>Start Type <i class="fas fa-cogs icon"></i></th></tr>
"@

# Populate HTML table with service information
foreach ($service in $serviceInfo) {
    $htmlContent += "<tr><td>$($service.DisplayName)</td><td>$($service.Status)</td><td>$($service.ServiceType)</td><td>$($service.StartType)</td></tr>"
}

$htmlContent += @"
        </table>
    </div>
 <div id="ProcessInfo" class="tabcontent">
        <h2>Process Info <i class="fas fa-user icon"></i></h2>
                <table>
            <tr>
                <th>Process Name <i class="fas fa-file-alt icon"></i></th>
                <th>Process ID (PID) <i class="fas fa-id-badge icon"></i></th>
                <th>CPU Usage (s) <i class="fas fa-chart-line icon"></i></th>
                <th>Memory Usage (MB) <i class="fas fa-memory icon"></i></th>
                <th>Start Time <i class="fas fa-clock icon"></i></th>
                <th>Executable Path <i class="fas fa-file icon"></i></th>
            </tr>
"@

   
            
# Combine process information for HTML output
foreach ($process in $processes) {
    $htmlContent += "<tr>
                    <td>$($process.Name)</td>
                    <td>$($process.Id)</td>
                    <td>$($process.'CPU (s)')</td>
                    <td>$($process.'Memory (MB)')</td>
                    <td>$($process.StartTime)</td>
                    <td>$($process.Path)</td>
                </tr>"
}



$htmlContent += @"
             </table>
        </div>
"@
$htmlContent += @"
<div id="TaskSCHInfo" class="tabcontent">
        <h2>Task Scheduler Info <i class="fas fa-user icon"></i></h2>
                <table>
          <tr>
            <th>Task Name <i class="fas fa-file-alt icon"></i></th>
            <th>Status <i class="fas fa-check-circle icon"></i></th>
            <th>Author <i class="fas fa-user icon"></i></th>
        </tr>



"@


# Get Task Scheduler Information
Get-ScheduledTask | ForEach-Object {
    $taskName = $_.TaskName
    $taskStatus = $_.State
    $author = $_.Principal.UserId
  
    # Append task details as a new row in HTML
    $htmlContent += @"
        <tr>
            <td>$taskName</td>
            <td>$taskStatus</td>
            <td>$author</td>
        </tr>
"@
}




$htmlContent += @"

</table>
</div>
    <div id="UserInfo" class="tabcontent">
        <h2>Users <i class="fas fa-user icon"></i></h2>
        <table>
            <tr><th>User Name <i class="fas fa-user icon"></i></th><th>Enabled <i class="fas fa-toggle-on icon"></i></th><th>Last Logon <i class="fas fa-clock icon"></i></th></tr>


"@
# Populate HTML table with user information
foreach ($user in $userInfo) {
    $lastLogon = $user.LastLogon -as [datetime] 
    $htmlContent += "<tr><td>$($user.Name)</td><td>$($user.Enabled)</td><td>$lastLogon</td></tr>"
}

$htmlContent += @"
        </table>

<h2>Command History <i class="fas fa-user icon"></i></h2>
         <table>
            <tr><th>User Name <i class="fas fa-user icon"></i></th><th>Enabled <i class="fas fa-toggle-on icon"></i></th><th>Last Logon <i class="fas fa-clock icon"></i></th></tr>
"@
# Get PowerShell command history
# $psHistory = Get-History | Select-Object -Property CommandLine

# Get Command Prompt history directly
# $cmdHistory = cmd.exe /c "doskey /history" | Out-String | Select-String -Pattern '.*' | ForEach-Object { $_.ToString().Trim() }

# Add PowerShell history to HTML
# foreach ($entry in $psHistory) {
#     $htmlContent += "<tr><td>$($entry.CommandLine)</td></tr>"
# }

# Add Command Prompt history to HTML
# foreach ($entry in $cmdHistory) {
#     $htmlContent += "<tr><td>$entry</td></tr>"
# }
$netProfiles = Get-NetConnectionProfile

$htmlContent += @"
        </table>
<h2>Net Connection Profile <i class="fas fa-user icon"></i></h2>
         <table>

           <tr>
            <th>Name</th>
            <th>Interface Alias</th>
            <th>InterfaceIndex</th>
            <th>Network Category</th>
            <th>DomainAuthenticationKind</th>
            <th>IPv4 Connectivity</th>
            <th>IPv6 Connectivity</th>
        </tr>
"@

        # Add each network profile to the HTML table
        foreach ($profile in $netProfiles) {
            $htmlContent += @"
                <tr>
                    <td>$($profile.Name)</td>
                    <td>$($profile.InterfaceAlias)</td>
                    <td>$($profile.InterfaceIndex)</td>
                    <td>$($profile.NetworkCategory)</td>
                    <td>$($profile.DomainAuthenticationKind)</td>
                    <td>$($profile.IPv4Connectivity)</td>
                    <td>$($profile.IPv6Connectivity)</td>
                </tr>
"@
        }
$htmlContent += @"
 </table>

"@
        
$htmlContent += @"
<h2>Wireless Profile<i class="fas fa-user icon"></i></h2>
         <table>

        <tr><th>Profile Name <i class="fas fa-id-badge"></i></th><th>Password <i class="fas fa-key"></i></th></tr>
"@

# Get wireless profiles
$profiles = netsh wlan show profiles

# Extract profile names
$profileNames = $profiles | Select-String "All User Profile" | ForEach-Object {
    $_ -replace '.*:\s*', ''
}

# Loop through each profile and get the password
foreach ($profile in $profileNames) {
    $profileDetails = netsh wlan show profile name="$profile" key=clear
    $password = $profileDetails | Select-String "Key Content" | ForEach-Object {
        $_ -replace '.*:\s*', ''
    }

    $passwordOutput = if ($password) { $password } else { "N/A" }
    $htmlContent += "<tr><td>$profile</td><td>$passwordOutput</td></tr>"
}
$htmlContent += @"
 </table>

    </div>

    <button class="float-button" onclick="toggleDarkMode()"><i class="fas fa-adjust"></i></button>

    <script>
        // Initialize the first tab to be open
        document.addEventListener("DOMContentLoaded", function() {
            document.querySelector(".tablinks").click();
        });
    </script>
</body>
</html>
"@

# Write the HTML content to the file
$htmlContent | Out-File -FilePath $outputFile -Encoding utf8

# Open the HTML file in the default browser
Start-Process $outputFile


