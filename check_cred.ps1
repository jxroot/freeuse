# https://github.com/jxroot/freeuse
# Function to test credentials locally or remotely
function Test-Credential {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Local", "Remote")]
        [string]$Scope,

        [Parameter(Mandatory = $false)]
        [string]$ComputerName,

        [Parameter(Mandatory = $true)]
        [string]$CredentialUserName,

        [Parameter(Mandatory = $true)]
        [string]$PlainPassword
    )

    # Convert plain-text password to a SecureString
    $SecurePassword = $PlainPassword | ConvertTo-SecureString -AsPlainText -Force

    # Create the credential object from the username and converted password
    $Credential = New-Object System.Management.Automation.PSCredential($CredentialUserName, $SecurePassword)

    if ($Scope -eq "Local") {
        # Test credential on the local machine
        try {
            $UserCheck = [ADSI]"WinNT://$env:COMPUTERNAME/$($Credential.UserName)"
            $UserCheck.psbase.Invoke("ChangePassword", $Credential.GetNetworkCredential().Password, $Credential.GetNetworkCredential().Password)
            Write-Host "Credentials are valid on the local machine" -ForegroundColor Green
        } catch {
            Write-Host "Invalid credentials for local machine" -ForegroundColor Red
        }
    }
    elseif ($Scope -eq "Remote") {
        # Ensure the ComputerName parameter is provided for remote check
        if (-not $ComputerName) {
            Write-Host "Please provide a remote computer name for testing credentials remotely." -ForegroundColor Yellow
            return
        }

        # Test connection to the remote machine
        $PingResult = Test-Connection -ComputerName $ComputerName -Count 1 -ErrorAction SilentlyContinue

        if ($PingResult) {
            # Attempt to create a session using the provided credentials
            try {
                $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential -ErrorAction Stop
                Write-Host "Credentials are valid for $ComputerName" -ForegroundColor Green
                Remove-PSSession $Session
            } catch {
                Write-Host "Invalid credentials or unable to establish session with $ComputerName" -ForegroundColor Red
            }
        } else {
            Write-Host "Unable to reach $ComputerName. Please check the network connection." -ForegroundColor Yellow
        }
    }
}

# Example usage for local testing with a plain-text password
# Test-Credential -Scope "Local" -CredentialUserName "mohammad" -PlainPassword "MySecurePassword123"

# Example usage for remote testing with a plain-text password
# Test-Credential -Scope "Remote" -ComputerName "RemoteServer01" -CredentialUserName "DOMAIN\Username" -PlainPassword "MySecurePassword123"