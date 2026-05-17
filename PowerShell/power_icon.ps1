$name_ext=".1234"
$command="powershell -c [console]::beep(300,2000)"
$icon_link="https://cdn-icons-png.flaticon.com/512/1747/1747658.png"


#make extention and set icons
New-Item -Path C:\ -Name $name_ext -ItemType Directory -Force
attrib +s +h +r "c:\$name_ext"
(New-Object System.Net.WebClient).DownloadFile("$icon_link", "c:\$name_ext\icon.png")
New-Item -Path 'Registry::HKEY_CLASSES_ROOT\' -Name $name_ext  -Force
New-Item -Path "Registry::HKEY_CLASSES_ROOT\$name_ext" -Name DefaultIcon  -Force
Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\$name_ext\DefaultIcon\" -Name '(Default)' -Value  "C:\$name_ext\icon.png"  -Force
#make open extention command
New-Item -Path "Registry::HKEY_CLASSES_ROOT\$name_ext" -Name shell  -Force
New-Item -Path "Registry::HKEY_CLASSES_ROOT\$name_ext\shell" -Name open  -Force
New-Item -Path "Registry::HKEY_CLASSES_ROOT\$name_ext\shell\open" -Name command  -Force
Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\$name_ext\shell\open\command" -Name '(Default)' -Value  $command  -Force
# restart explorer
taskkill /f /im explorer.exe
start explorer
