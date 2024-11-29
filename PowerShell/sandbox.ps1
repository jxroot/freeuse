# https://github.com/jxroot/freeuse
# Function to detect a sandbox, virtual machine, or Hyper-V environment
function Detect-SandboxOrVM {
    $detectionResults = @{}

    # 1. Detect virtualization services
    $vmServices = @("VBoxService", "vmtoolsd", "vmwaretray", "vmmouse", "prl_tools", "xenservice", "vmcompute", "vmms", "vmsrvc", "vmsp")
    $detectionResults["Virtualization_Services"] = Get-Service | Where-Object { $vmServices -contains $_.Name } | Select-Object -ExpandProperty Name

    # 2. Detect virtualization-related files
    $vmFiles = @(
        "C:\windows\system32\vboxdisp.dll",
        "C:\windows\system32\vm3dmp.dll",
        "C:\Program Files\VMware\VMware Tools\vmtoolsd.exe",
        "C:\windows\system32\drivers\vmmouse.sys",
        "C:\windows\system32\drivers\vmhgfs.sys",
        "C:\windows\system32\drivers\vboxguest.sys",
        "C:\windows\system32\drivers\vmgid.sys",          # Hyper-V
        "C:\windows\system32\drivers\vmgencounter.sys"   # Hyper-V
    )
    $detectionResults["Virtualization_Files"] = $vmFiles | Where-Object { Test-Path $_ }

    # 3. Detect VM-specific registry keys
    $vmRegistryKeys = @(
        "HKEY_LOCAL_MACHINE\HARDWARE\ACPI\DSDT\VBOX__",
        "HKEY_LOCAL_MACHINE\HARDWARE\ACPI\FADT\VBOX__",
        "HKEY_LOCAL_MACHINE\SOFTWARE\Oracle\VirtualBox Guest Additions",
        "HKEY_LOCAL_MACHINE\SOFTWARE\VMware, Inc.\VMware Tools",
        "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Virtual Machine\Guest",
        "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\vmicheartbeat", # Hyper-V
        "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\vmicvss",       # Hyper-V
        "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\vmicshutdown"  # Hyper-V
    )
    $detectionResults["VM_Registry_Keys"] = $vmRegistryKeys | ForEach-Object {
        try {
            Get-ItemProperty -Path $_
        } catch {
            $null
        }
    } | Where-Object { $_ -ne $null }

    # 4. Detect running virtualization-related processes
    $vmProcesses = @("VBoxTray.exe", "vmtoolsd.exe", "prl_cc.exe", "qemu-ga.exe", "vboxservice.exe", "xenservice.exe", "vmms.exe", "vmcompute.exe") # Hyper-V
    $detectionResults["VM_Processes"] = Get-Process | Where-Object { $vmProcesses -contains $_.Name } | Select-Object -ExpandProperty Name

    # 5. Detect unusual MAC addresses (associated with VMs)
    $vmMacPrefixes = @(
        "00:05:69", "00:0C:29", "00:1C:14", "00:50:56",  # VMware
        "08:00:27",                                     # VirtualBox
        "52:54:00",                                     # QEMU
        "00:1C:42",                                     # Parallels
        "00:16:3E",                                     # Xen
        "00:15:5D"                                      # Hyper-V
    )
    $networkAdapters = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.MACAddress -ne $null }
    $detectionResults["VM_Mac_Addresses"] = $networkAdapters | Where-Object {
        $mac = $_.MACAddress -replace ":", "-"
        $vmMacPrefixes | ForEach-Object { $mac.StartsWith($_) }
    }

    # 6. Detect sandbox-specific files or behaviors (e.g., Any.Run, Cuckoo)
    $sandboxFiles = @(
        "C:\Windows\FakePath",
        "C:\Tools\Network Emulation",
        "C:\SampleAnalysis",
        "C:\python27\Scripts\cuckoo.py"  # Cuckoo-specific path
    )
    $detectionResults["Sandbox_Files"] = $sandboxFiles | Where-Object { Test-Path $_ }

    # 7. Check suspicious CPU or BIOS information
    $biosInfo = Get-WmiObject Win32_BIOS
    $detectionResults["BIOS_Manufacturer"] = $biosInfo.Manufacturer
    $detectionResults["BIOS_SerialNumber"] = $biosInfo.SerialNumber

    # Common BIOS values for VMs
    $suspiciousBIOS = @("VBox", "VMware", "Xen", "QEMU", "Parallels", "VirtualBox", "Microsoft Corporation") # Hyper-V
    $detectionResults["Suspicious_BIOS"] = $suspiciousBIOS | Where-Object { $biosInfo.Manufacturer -like "*$_*" }

    # 8. Detect Hyper-V specific WMI data
    try {
        $hyperVCheck = Get-WmiObject -Namespace "root\virtualization\v2" -Class Msvm_ComputerSystem | Select-Object -First 1
        $detectionResults["HyperV_Installed"] = $hyperVCheck -ne $null
    } catch {
        $detectionResults["HyperV_Installed"] = $false
    }

    # 9. Detect unusual system uptime (sandbox may reset frequently)
    $uptime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
    $uptimeHours = ((Get-Date) - $uptime).TotalHours
    $detectionResults["System_Uptime_Hours"] = [math]::Round($uptimeHours, 2)

    # Check for very short uptime (less than 2 hours could be suspicious)
    $detectionResults["Is_Short_Uptime"] = $uptimeHours -lt 2

    # Output results
    Write-Host "`n--- Sandbox/VM Detection Results ---`n"
    foreach ($key in $detectionResults.Keys) {
        Write-Host "${key}:" -ForegroundColor Yellow
        if ($detectionResults[$key] -is [System.Array]) {
            $detectionResults[$key] | ForEach-Object { Write-Host "`t$_" -ForegroundColor Green }
        } elseif ($detectionResults[$key]) {
            Write-Host "`t$($detectionResults[$key])" -ForegroundColor Green
        } else {
            Write-Host "`tNot Found" -ForegroundColor Red
        }
    }
}

# Run the comprehensive sandbox and Hyper-V detection
Detect-SandboxOrVM
