# https://github.com/jxroot/freeuse/
# Function to securely delete files
function Secure-Delete {
    param (
        [string]$path
    )
    if (Test-Path $path) {
        $fs = [System.IO.File]::Open($path, 'Open', 'ReadWrite', 'None')
        $length = $fs.Length
        $fs.SetLength($length)
        $buffer = New-Object byte[] $length
        (New-Object Random).NextBytes($buffer)
        $fs.Write($buffer, 0, $length)
        $fs.Close()
        Remove-Item -Path $path -Force
    }
}
