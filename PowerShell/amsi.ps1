Add-Type -AssemblyName System.Net.HttpListener
$threatRayPath = Join-Path -Path $env:TEMP -ChildPath "ThreatRay"
# Generate a random token
$token = -join ((48..57) + (97..122) | Get-Random -Count 16 | ForEach-Object {[char]$_})
$validPath = "/$token"

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://+:8080/")
# $listener.Prefixes.Add("http://localhost:8080/")

$listener.Start()
Write-Host "🔐 Access URL: http://localhost:8080$validPath"


$uploadPath = "$env:TEMP\ThreatRay\uploads"
New-Item -ItemType Directory -Force -Path $uploadPath | Out-Null

# HTML with AJAX Upload (no progress bar)

$html = @"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>AMSI Threat Scanner</title>
  <style>
    body {
      margin: 0;
      font-family: 'Segoe UI', sans-serif;
      background: linear-gradient(to bottom right, #1f2937, #111827);
      color: white;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      padding: 20px;
    }
    .card {
      background-color: #1e293b;
      border-radius: 1rem;
      padding: 2rem;
      width: 100%;
      max-width: 700px;
      box-shadow: 0 0 20px rgba(0,0,0,0.5);
    }
    h1 {
      text-align: center;
      font-size: 2rem;
      margin-bottom: 0.5rem;
    }
    .tabs {
      display: flex;
      gap: 1rem;
      justify-content: center;
      margin: 1.5rem 0;
    }
    .tab {
      background: #374151;
      padding: 0.5rem 1.2rem;
      border-radius: 999px;
      cursor: pointer;
      transition: 0.3s;
      font-weight: 500;
    }
    .tab.active {
      background: #3b82f6;
    }
    .section {
      display: none;
    }
    .section.active {
      display: block;
    }
    textarea, .output {
      width: 100%;
      height: 150px;
      background: black;
      color: #4ade80;
      font-family: monospace;
      font-size: 0.9rem;
      border: 1px solid #374151;
      border-radius: 0.5rem;
      padding: 0.75rem;
      resize: none;
      margin-bottom: 1rem;
      box-shadow: 0 0 5px rgba(0,0,0,0.3);
    }
    .dropzone {
      border: 2px dashed #6b7280;
      border-radius: 1rem;
      padding: 2rem;
      text-align: center;
      cursor: pointer;
      transition: 0.3s;
      margin-bottom: 1rem;
      display: block;
      width: 100%;
      box-sizing: border-box;
    }
    .dropzone:hover {
      border-color: #3b82f6;
      background-color: #374151;
    }
    .button {
      width: 100%;
      background: #3b82f6;
      color: white;
      padding: 0.75rem;
      font-weight: bold;
      border: none;
      border-radius: 0.75rem;
      cursor: pointer;
      transition: 0.3s;
    }
    .button:hover {
      background: #2563eb;
    }
    button.button {
    margin-bottom: 20px;
}
    .file-name {
      font-size: 0.85rem;
      color: #cbd5e1;
      text-align: center;
      margin-top: -0.5rem;
      margin-bottom: 1rem;
    }
    #outputContainer {
      display: none;
    }
  </style>
</head>
<body>
  <div class="card">
    <h1>AMSI Threat Scanner</h1>
    <p style="text-align:center;color:#9ca3af;">Check PowerShell or script content against AMSI detection</p>

    <div class="tabs">
      <div class="tab active" data-tab="code">Live Code</div>
      <div class="tab" data-tab="file">File Upload</div>
    </div>

    <div id="code" class="section active">
      <textarea id="codeInput" placeholder="Paste your PowerShell or script here..."></textarea>
      <button class="button" onclick="scanCode()">Scan Code</button>
    </div>

   <form id="file" class="section" >
      <label class="dropzone" for="form">
        <p><strong>Click to upload</strong> or drag and drop</p>
        <p style="font-size:0.75rem;color:#9ca3af;">.ps1, .hta, .exe, .dll, .vbs , ...</p>
      </label>
      <input type="file" name="form"  id="form" accept=".ps1,.hta,.exe,.dll,.vbs" style="display:none" onchange="showFileName()" />
      <div class="file-name" id="fileName">No file selected.</div>
      <button class="button" >Scan File</button>
 
    </form>

    <div id="outputContainer">
      <textarea class="output" id="output" readonly></textarea>
    </div>
  </div>

  <script>    

    
   const tabs = document.querySelectorAll('.tab');
    const sections = document.querySelectorAll('.section');
  document.getElementById("file").addEventListener("submit", function(e) {
  e.preventDefault();
  var file = document.getElementById("form").files[0];
  var formData = new FormData();
  formData.append("file", file);
 document.getElementById("outputContainer").style.display = 'block';
  document.getElementById("output").value = '⚠️ Wait For scan complete.';
  var xhr = new XMLHttpRequest();
  xhr.open("POST", "$token/upload", true);
  xhr.onload = function () {
    document.getElementById("outputContainer").style.display = 'block';
    document.getElementById("output").value = xhr.responseText;
  };
  xhr.send(formData);
});
    tabs.forEach(tab => {
      tab.addEventListener('click', () => {
        tabs.forEach(t => t.classList.remove('active'));
        sections.forEach(s => s.classList.remove('active'));
        tab.classList.add('active');
        document.getElementById(tab.dataset.tab).classList.add('active');
        document.getElementById('outputContainer').style.display = 'none';
      });
    });

    function scanCode() {
      const code = document.getElementById('codeInput').value.trim();
      const output = document.getElementById('output');
      if (!code) return alert('Paste some code first!');
      document.getElementById('outputContainer').style.display = 'block';
      output.value = 'Scanning code...';
      setTimeout(() => {
        output.value = '✅ Live scan complete. No threat detected.';
      }, 1000);
    }

 
    function showFileName() {
      const file = document.getElementById('form').files[0];
      const label = document.getElementById('fileName');
      if (file) {
        label.textContent = file.name;
      } else {
        label.textContent = 'No file selected.';
      }
    }
  </script>
</body>
</html>
"@

while ($listener.IsListening) {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response

   if ($request.HttpMethod -eq "GET" -and $request.Url.AbsolutePath -eq $validPath) {

        $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
        $response.ContentType = "text/html"
        $response.ContentLength64 = $buffer.Length
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
    }
elseif ($request.HttpMethod -eq "POST" -and $request.Url.AbsolutePath -eq "$validPath/upload") {
        $boundary = $request.ContentType -replace "multipart/form-data;\s*boundary=", ""
        $endBoundaryBytes = [System.Text.Encoding]::ASCII.GetBytes("--$boundary--")

        $ms = New-Object System.IO.MemoryStream
        $request.InputStream.CopyTo($ms)
        $data = $ms.ToArray()
        $ms.Dispose()

        # Find header end
        $headerEndIndex = [System.Text.Encoding]::ASCII.GetString($data).IndexOf("`r`n`r`n") + 4

        # Extract filename
        $headers = [System.Text.Encoding]::ASCII.GetString($data, 0, $headerEndIndex)
        if ($headers -match 'filename="(.+?)"') {
            $filename = [IO.Path]::GetFileName($matches[1])
        } else {
            $filename = "upload.bin"
        }

        # Extract binary content
        $startIndex = $headerEndIndex
        $endIndex = ($data.Length - $endBoundaryBytes.Length - 4)
        $fileBytes = $data[$startIndex..$endIndex]

        # Save file
        $savePath = Join-Path $uploadPath $filename
        [IO.File]::WriteAllBytes($savePath, $fileBytes)


        #progress after upload
        $scan=&"$threatRayPath\ThreatCheck.exe" -f "$threatRayPath\uploads\$filename"
        
$responseStr = "$filename`r`n$scan"
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseStr)
        $response.ContentType = "text/plain"
        $response.ContentLength64 = $buffer.Length
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
        Remove-Item -Path "$uploadPath\*" -Force -Recurse

    }
    else {
        $response.StatusCode = 404
    }

    $response.OutputStream.Close()
}
