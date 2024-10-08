# https://github.com/jxroot/freeuse
# This PowerShell script is designed to search for files across specified drives, filtering them based on their file extensions, and then returning information about the files.
# Set this variable to $true to show file paths, or $false to show only counts
$showPaths = $false  # Change this to $false if you want to show only counts

# Define the extensions to include
# Ignore when use $processAll = $true you can use $excludeExtensions = @('.mp3')
$includeExtensions = @('.rdp','.mkv','.dbs') # Example: only include these extensions

# Define extensions to exclude when processing all files
$excludeExtensions = @()  # Example: exclude these extensions

$processAll = $false                     # Set to $true to process all files regardless of the extensions

# Define the drives to process (leave empty for all drives)
$selectedDrives = @('D:\')       # Example: specific drives to include
# $selectedDrives = @()                   # Uncomment to process all drives

# Get all the filesystem drives (e.g., C:\, D:\, etc.)
if ($selectedDrives.Count -eq 0) {
    $list = Get-PSDrive -PSProvider 'FileSystem' | ForEach-Object { $_.Name + ':\' }
} else {
    $list = $selectedDrives
}

# Initialize an empty array to hold the file information from all drives
$allFiles = @()

# Loop through each drive and collect files
foreach ($drive in $list) {
    $filesOnDrive = Get-ChildItem -Path $drive -Filter *.* -Recurse -Attributes Archive -Force -ErrorAction SilentlyContinue

    # Filter based on include and exclude lists, if applicable
    if (-not $processAll) {
        $filesOnDrive = $filesOnDrive | Where-Object {
            # If include list is provided, filter by it
            if ($includeExtensions.Count -gt 0) {
                $_.Extension -in $includeExtensions
            }
            # If neither is set, process all files (default)
            else {
                $true
            }
        }
    } else {
        # When processing all, exclude certain extensions
        $filesOnDrive = $filesOnDrive | Where-Object {
            -not ($excludeExtensions -contains $_.Extension)
        }
    }

    # Add the filtered files to the allFiles array with drive information
    foreach ($file in $filesOnDrive) {
        $allFiles += [PSCustomObject]@{
            Drive     = $drive
            FilePath  = $file.FullName
            Extension = $file.Extension
        }
    }
}

# Group files by drive and extension, and create a custom object with counts and file paths
$groupedFiles = $allFiles | Group-Object Drive, Extension | Where-Object { $_.Count -gt 0 } | ForEach-Object {
    [PSCustomObject]@{
        Drive     = $_.Group[0].Drive      # Access the first item to get the Drive
        Extension = $_.Group[0].Extension  # Access the first item to get the Extension
        Count     = $_.Count
        Files     = $_.Group.FilePath
    }
}

# Prepare output based on the showPaths variable
if ($showPaths) {
    # Display file paths along with their counts
    $groupedFiles | ForEach-Object {
        [PSCustomObject]@{
            Drive     = $_.Drive
            Extension = $_.Extension
            Count     = $_.Count
            Files     = $_.Files
        }
    } | ConvertTo-Json
} else {
    # Display only counts
    $groupedFiles | Select-Object Drive, Extension, Count | ConvertTo-Json
}
