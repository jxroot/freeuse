# freeuse
Some useful codes and scripts


# Powershell
find_file.ps1
This PowerShell script is designed to search for files across specified drives, filtering them based on their file extensions, and then returning information about the files.

Customization Options:

    To show only counts: Set $showPaths = $false.
    To process all files: Set $processAll = $true, and use $excludeExtensions to specify which file types to ignore.
    To include specific file types: Use $includeExtensions to list the extensions you want to process, and set $processAll = $false.
    To process all drives: Set $selectedDrives = @() to include all filesystem drives.

This script is flexible and allows detailed control over what types of files to search for, which drives to search, and whether to display full file paths or just counts.
