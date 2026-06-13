$ErrorActionPreference = 'Stop'

# Resolve a Windows clipboard image to a file under %TEMP% and print
# `IMAGE_PATH=<forward-slash path>`. Agent CLIs (Claude Code, Codex) attach an
# image when a path to it is pasted, so we always emit a space-free temp path
# with forward slashes (their path detector stops at whitespace).
#
# Two clipboard shapes are handled:
#   1. A bitmap, e.g. a Win+Shift+S screenshot        -> Clipboard.ContainsImage()
#   2. An image file copied in Explorer with Ctrl+C   -> Clipboard.ContainsFileDropList() (CF_HDROP)

$image = $null

function Write-ImagePath([string]$path) {
  Write-Output ("IMAGE_PATH=" + ($path -replace '\\', '/'))
}

try {
  Add-Type -AssemblyName System.Windows.Forms
  Add-Type -AssemblyName System.Drawing

  $outputDir = Join-Path ([System.IO.Path]::GetTempPath()) 'wezterm-clipboard'
  $null = New-Item -Path $outputDir -ItemType Directory -Force

  # Best-effort purge of stale paste temps from earlier sessions; Windows does
  # not auto-clean %TEMP%, and each paste drops a throwaway PNG here. Anything
  # older than a day was long since attached. Never let cleanup fail the paste.
  Get-ChildItem -LiteralPath $outputDir -File -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-1) } |
    Remove-Item -Force -ErrorAction SilentlyContinue

  $stamp = [System.Guid]::NewGuid().ToString('N').Substring(0, 8)

  # 1. Bitmap on the clipboard (screenshot).
  if ([System.Windows.Forms.Clipboard]::ContainsImage()) {
    $image = [System.Windows.Forms.Clipboard]::GetImage()
    if ($null -ne $image) {
      $path = Join-Path $outputDir "clip-$stamp.png"
      $image.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
      Write-ImagePath $path
      exit 0
    }
  }

  # 2. Image file copied in Explorer (Ctrl+C => file drop list). Copy it into the
  #    temp dir so the pasted path is space-free regardless of the source location.
  if ([System.Windows.Forms.Clipboard]::ContainsFileDropList()) {
    foreach ($file in [System.Windows.Forms.Clipboard]::GetFileDropList()) {
      if (($file -match '\.(png|jpe?g|gif|webp|bmp)$') -and (Test-Path -LiteralPath $file)) {
        $dest = Join-Path $outputDir ("clip-$stamp" + [System.IO.Path]::GetExtension($file))
        Copy-Item -LiteralPath $file -Destination $dest -Force
        Write-ImagePath $dest
        exit 0
      }
    }
  }

  Write-Output 'NO_IMAGE'
  exit 2
} catch {
  Write-Output "ERROR=$($_.Exception.Message)"
  exit 1
} finally {
  if ($null -ne $image) {
    $image.Dispose()
  }
}
