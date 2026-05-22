$ErrorActionPreference = 'Stop'

$image = $null

try {
  Add-Type -AssemblyName System.Windows.Forms
  Add-Type -AssemblyName System.Drawing

  if (-not [System.Windows.Forms.Clipboard]::ContainsImage()) {
    Write-Output 'NO_IMAGE'
    exit 2
  }

  $image = [System.Windows.Forms.Clipboard]::GetImage()
  if ($null -eq $image) {
    Write-Output 'NO_IMAGE'
    exit 2
  }

  $outputDir = Join-Path ([System.IO.Path]::GetTempPath()) 'codex-clipboard'
  $null = New-Item -Path $outputDir -ItemType Directory -Force

  $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
  $suffix = [System.Guid]::NewGuid().ToString('N').Substring(0, 8)
  $fileName = "codex-clipboard-$timestamp-$suffix.png"
  $path = Join-Path $outputDir $fileName

  $image.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  Write-Output "IMAGE_PATH=$path"
  exit 0
} catch {
  Write-Output "ERROR=$($_.Exception.Message)"
  exit 1
} finally {
  if ($null -ne $image) {
    $image.Dispose()
  }
}
