$name_ext=".hhh"
Remove-Item "Registry::HKEY_CLASSES_ROOT\$name_ext" -Recurse -Force
Remove-Item "c:\$name_ext" -Recurse -Force
# restart explorer
taskkill /f /im explorer.exe
start explorer
