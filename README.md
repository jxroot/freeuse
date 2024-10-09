
<h3 align="center"><img src="https://www.svgrepo.com/show/429910/script-coding-programming.svg" alt="logo" height="250px"></h3>
<p align="center">
    <b>freeuse</b><br>
    </p>
<hr>
<p align="center">
  <b>Some useful codes and scripts</b>
    </p>


   

  
</p>

<h2 id="table-of-contents">📜 Table of Contents</h2>
<ul>

<li><a href="#Powershell">Powershell</a>
<ul>
<li><a href="#find_file.ps1">find_file.ps1</a></li>
<li><a href="#system_info.ps1">system_info.ps1</a></li>
<li><a href="#check_cred.ps1">check_cred.ps1</a></li>
</ul>
</li>
<li><a href="#Bash">Bash</a>
<ul>
<li><a href="#setup_tor_apache.sh">setup_tor_apache.sh</a></li>

</ul>
</li>
<li><a href="#Python">Python</a>
<ul>


</ul>
</li>
</ul>

# Powershell

<p align="center"  id="Powershell">
  <img src="https://upload.wikimedia.org/wikipedia/commons/2/2f/PowerShell_5.0_icon.png" alt="PowerShell" width="200"/>
</p>



<details  id="find_file.ps1"><summary>

`find_file.ps1` tested on powershell v5+
</summary>

<p></p>

<p align="center">
  <img src="https://raw.githubusercontent.com/jxroot/freeuse/refs/heads/main/Source/find_file.ps1.png" alt="find_file" width="700"/>
</p>


> This PowerShell script is designed to search for files across specified drives, filtering them based on their file extensions, and then returning information about the files.




Customization Options:

    To show only counts: Set $showPaths = $false.
    To process all files: Set $processAll = $true, and use $excludeExtensions to specify which file types to ignore.
    To include specific file types: Use $includeExtensions to list the extensions you want to process, and set $processAll = $false.
    To process all drives: Set $selectedDrives = @() to include all filesystem drives.

This script is flexible and allows detailed control over what types of files to search for, which drives to search, and whether to display full file paths or just counts.
</details>


<details id="system_info.ps1"><summary>

`system_info.ps1` tested on powershell v5+

</summary>

<p></p>

<p align="center">
  <img src="https://raw.githubusercontent.com/jxroot/freeuse/refs/heads/main/Source/system_info.ps1.png" alt="system_info" width="700"/>
</p>


> This PowerShell script collects a variety of system information, formats it into an HTML page, and opens that page in the default web browser.


</details>

<details  id="check_cred.ps1"><summary>

`check_cred.ps1` tested on powershell v5+
</summary>

<p></p>

<p align="center">
  <img src="https://raw.githubusercontent.com/jxroot/freeuse/refs/heads/main/Source/check_cred.ps1.png" alt="check_cred" width="700"/>
</p>


> Function to test credentials locally or remotely




Usage:

```powershell
# Example usage for local testing with a plain-text password
Test-Credential -Scope "Local" -CredentialUserName "mohammad" -PlainPassword "MySecurePassword123"

# Example usage for remote testing with a plain-text password
Test-Credential -Scope "Remote" -ComputerName "RemoteServer01" -CredentialUserName "DOMAIN\Username" -PlainPassword "MySecurePassword123"
```

</details>

# Bash

<p align="center" id="Bash">
  <img src="https://www.svgrepo.com/show/353478/bash-icon.svg" alt="Python" width="170"/>
</p>

<details id="setup_tor_apache.sh"><summary>

`setup_tor_apache.sh` tested on ubuntu 23

</summary>

<p></p>

<p align="center">
  <img src="https://raw.githubusercontent.com/jxroot/freeuse/refs/heads/main/Source/setup_tor_apache.sh.png" alt="system_info" width="700"/>
</p>


> The provided script automates the process of setting up a Tor hidden service using Apache on an Ubuntu system.


</details>

# Python

<p align="center" id="Python">
  <img src="https://www.python.org/static/community_logos/python-logo.png" alt="Python" width="320"/>
</p>



</p>







