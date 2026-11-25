$ErrorActionPreference = 'Stop'

$fileListPath = Join-Path $PSScriptRoot 'filelist.txt'
$pollSeconds = 10
$knownFiles = @{}
$unavailableFiles = @{}
$notifyIcon = $null

if (-not (Test-Path -LiteralPath $fileListPath -PathType Leaf)) {
    throw "File list not found: $fileListPath"
}

$paths = @(
    Get-Content -LiteralPath $fileListPath -Encoding UTF8 |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -and -not $_.StartsWith('#') } |
        Select-Object -Unique
)

if ($paths.Count -eq 0) {
    throw "No file paths found in $fileListPath. Add one UNC path per line."
}

foreach ($path in $paths) {
    if ($path -notmatch '^\\\\[^\\]+\\[^\\]+') {
        throw "Not a valid UNC path: $path"
    }
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Icon = [System.Drawing.SystemIcons]::Information
$notifyIcon.Text = 'UNC file monitor'
$notifyIcon.Visible = $true

Write-Host "Monitoring $($paths.Count) file(s) every $pollSeconds seconds. Press Ctrl+C to stop."

try {
    while ($true) {
        foreach ($path in $paths) {
            try {
                $file = Get-Item -LiteralPath $path -ErrorAction Stop
                if ($file.PSIsContainer) {
                    throw "Path is a directory: $path"
                }

                $snapshot = '{0}|{1}' -f $file.Length, $file.LastWriteTimeUtc.Ticks
                if ($knownFiles.ContainsKey($path)) {
                    if ($knownFiles[$path] -ne $snapshot) {
                        $name = [System.IO.Path]::GetFileName($path)
                        $notifyIcon.ShowBalloonTip(
                            10000,
                            "File updated: $name",
                            $path,
                            [System.Windows.Forms.ToolTipIcon]::Info
                        )
                        Write-Host "Updated: $path"
                    }
                }
                else {
                    Write-Host "Initial state recorded: $path"
                }

                $knownFiles[$path] = $snapshot
                if ($unavailableFiles.ContainsKey($path)) {
                    Write-Host "File is accessible again: $path"
                    $unavailableFiles.Remove($path)
                }
            }
            catch {
                if (-not $unavailableFiles.ContainsKey($path)) {
                    Write-Warning "Cannot check '$path': $($_.Exception.Message)"
                    $unavailableFiles[$path] = $true
                }
            }
        }

        Start-Sleep -Seconds $pollSeconds
    }
}
finally {
    if ($notifyIcon) {
        $notifyIcon.Visible = $false
        $notifyIcon.Dispose()
    }
}
