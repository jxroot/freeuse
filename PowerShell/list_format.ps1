# https://github.com/jxroot/freeuse
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
            } else {
                $fileCounts[$extension] = 1
            }
        }
    }
}

# Output the results
$fileCounts.GetEnumerator() | Sort-Object Value -Descending | Format-Table -AutoSize
