# https://github.com/jxroot/freeuse/
# Clear and overwrite logs
wevtutil cl Security
wevtutil cl Application
wevtutil cl System
wevtutil cl Setup
wevtutil cl ForwardedEvents

# Clear all restore points
vssadmin delete shadows /all /quiet

# Disable pagefile and hibernation
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "PagingFiles" -Value ""
powercfg -h off
