# Define paths for Chrome and Edge history databases
$ChromeHistory = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\History"
$EdgeHistory = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\History"

# Find Firefox profile path dynamically
$FirefoxProfilePath = Get-ChildItem -Path "$env:APPDATA\Mozilla\Firefox\Profiles" | Where-Object { $_.PSIsContainer -and $_.Name -match "\.default-release" } | Select-Object -ExpandProperty FullName
if (-not $FirefoxProfilePath) {
    $FirefoxProfilePath = Get-ChildItem -Path "$env:APPDATA\Mozilla\Firefox\Profiles" | Where-Object { $_.PSIsContainer -and $_.Name -match "\.default" } | Select-Object -ExpandProperty FullName
}
$FirefoxHistory = "$FirefoxProfilePath\places.sqlite"

# Define backup folder
$BackupFolder = "$env:TEMP\BrowserBackup"
if (!(Test-Path $BackupFolder)) {
    New-Item -ItemType Directory -Path $BackupFolder -Force
}

# Copy history files (if they exist)
if (Test-Path $ChromeHistory) {
    Copy-Item -Path $ChromeHistory -Destination "$BackupFolder\Chrome_History.db" -Force
}
if (Test-Path $EdgeHistory) {
    Copy-Item -Path $EdgeHistory -Destination "$BackupFolder\Edge_History.db" -Force
}
if (Test-Path $FirefoxHistory) {
    Copy-Item -Path $FirefoxHistory -Destination "$BackupFolder\Firefox_History.db" -Force
}

# Define ZIP file path
$ZipFile = "$env:USERPROFILE\Desktop\BrowserHistoryBackup.zip"

# Create ZIP archive
if (Test-Path $ZipFile) {
    Remove-Item -Path $ZipFile -Force  # Remove existing ZIP if present
}
Compress-Archive -Path "$BackupFolder\*" -DestinationPath $ZipFile -Force

# Cleanup: Remove backup folder after zipping
Remove-Item -Path $BackupFolder -Recurse -Force

Write-Output "✅ Browser history saved to: $ZipFile"
