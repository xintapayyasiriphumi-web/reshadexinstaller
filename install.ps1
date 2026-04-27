# ================================================================
# ReShade Installer Launcher - by INSIDEX
# iex (irm 'https://raw.githubusercontent.com/xintapayyasiriphumi-web/reshadexinstaller/main/install.ps1')
# ================================================================

$KEYAUTH_NAME    = "reshadexinstall"
$KEYAUTH_OWNERID = "h73NBoWgLW"
$KEYAUTH_VERSION = "1.0"
$KEYAUTH_URL     = "https://keyauth.win/api/1.2/"

$EXE_URL  = "https://github.com/xintapayyasiriphumi-web/reshadexinstaller/releases/download/v1.0.1/ReShadeInstaller.exe"
$EXE_NAME = "ReShadeInstaller.exe"
$EXE_PATH = "$env:TEMP\$EXE_NAME"

$FIVEM_PATHS = @(
    "$env:LOCALAPPDATA\FiveM\FiveM.app",
    "$env:LOCALAPPDATA\FiveM\FiveM Application Data"
)

function Write-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "    RESHADEX INSTALLER" -ForegroundColor White
    Write-Host "    by INSIDEX  |  Powered by Shxrk" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   ----------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
}

function Write-Step($step, $msg) { Write-Host "   [$step] $msg" -ForegroundColor Cyan }
function Write-OK($msg)          { Write-Host "   [OK] $msg" -ForegroundColor Green }
function Write-ERR($msg)         { Write-Host "   [ERROR] $msg" -ForegroundColor Red }
function Write-Line              { Write-Host "   ----------------------------------------" -ForegroundColor DarkGray }

function Get-HWID {
    $raw   = "$env:COMPUTERNAME-$env:USERNAME-$env:PROCESSOR_IDENTIFIER"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($raw)
    $hash  = [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
    return ([BitConverter]::ToString($hash) -replace '-','').ToLower().Substring(0, 32)
}

function KeyAuth-Init {
    try {
        $body = "type=init&name=$KEYAUTH_NAME&ownerid=$KEYAUTH_OWNERID&ver=$KEYAUTH_VERSION"
        $resp = Invoke-RestMethod -Uri $KEYAUTH_URL -Method Post -Body $body -ContentType "application/x-www-form-urlencoded" -TimeoutSec 10
        return $resp
    } catch { return $null }
}

function KeyAuth-License($sessionId, $licenseKey, $hwid) {
    try {
        $body = "type=license&key=$licenseKey&hwid=$hwid&sessionid=$sessionId&name=$KEYAUTH_NAME&ownerid=$KEYAUTH_OWNERID"
        $resp = Invoke-RestMethod -Uri $KEYAUTH_URL -Method Post -Body $body -ContentType "application/x-www-form-urlencoded" -TimeoutSec 10
        return $resp
    } catch { return $null }
}

function Run-Uninstall {
    Write-Host ""
    Write-Line
    Write-Host ""
    Write-Step "1/1" "Removing ReShade files from FiveM..."
    Write-Host ""

    $found = $false
    foreach ($basePath in $FIVEM_PATHS) {
        if (Test-Path $basePath) {
            $found = $true
            $pluginPath = Join-Path $basePath "plugins"
            $files = @("dxgi.dll", "ReShade.ini", "ReShadePreset.ini", "ReShade.log")
            foreach ($f in $files) {
                $fp = Join-Path $pluginPath $f
                if (Test-Path $fp) {
                    Remove-Item $fp -Force
                    Write-OK "Removed: $f"
                }
            }
            $dataPath = Join-Path $pluginPath "reshade-data"
            if (Test-Path $dataPath) {
                Remove-Item $dataPath -Recurse -Force
                Write-OK "Removed: reshade-data folder"
            }
        }
    }

    if (-not $found) {
        Write-ERR "FiveM installation not found."
        Write-Host ""; pause; exit 1
    }

    Write-Host ""
    Write-Line
    Write-Host ""
    Write-Host "   ReShade has been removed successfully." -ForegroundColor Green
    Write-Host ""
    pause
}

function Download-WithProgress($url, $dest) {
    $req = [System.Net.HttpWebRequest]::Create($url)
    $req.AllowAutoRedirect = $true
    $resp = $req.GetResponse()
    $total = $resp.ContentLength
    $stream = $resp.GetResponseStream()
    $out = [System.IO.File]::Create($dest)
    $buf = New-Object byte[] 8192
    $downloaded = 0

    while ($true) {
        $read = $stream.Read($buf, 0, $buf.Length)
        if ($read -le 0) { break }
        $out.Write($buf, 0, $read)
        $downloaded += $read
        if ($total -gt 0) {
            $pct   = [math]::Floor($downloaded * 100 / $total)
            $dlMB  = [math]::Round($downloaded / 1MB, 1)
            $totMB = [math]::Round($total / 1MB, 1)
            $bar   = ("=" * [math]::Floor($pct / 5)).PadRight(20, '-')
            Write-Host "`r   [$bar] $pct%  ($dlMB MB / $totMB MB)  " -NoNewline -ForegroundColor Cyan
        }
    }

    $out.Close()
    $stream.Close()
    Write-Host ""
}

# ================================================================
# MAIN
# ================================================================

Write-Banner

Write-Host "   Enter your license key to continue." -ForegroundColor Gray
Write-Host ""
$licenseKey = Read-Host "   License Key"
Write-Host ""

if ([string]::IsNullOrWhiteSpace($licenseKey)) {
    Write-ERR "No license key entered."
    Write-Host ""; pause; exit 1
}

Write-Line
Write-Host ""
Write-Step "1/3" "Verifying license..."

$init = KeyAuth-Init
if (-not $init -or -not $init.success) {
    $msg = if ($init) { $init.message } else { "Cannot connect to auth server." }
    Write-ERR "Auth failed: $msg"
    Write-Host ""; pause; exit 1
}

$hwid   = Get-HWID
$verify = KeyAuth-License $init.sessionid $licenseKey.Trim() $hwid

if (-not $verify -or -not $verify.success) {
    $msg = if ($verify) { $verify.message } else { "Verification failed." }
    Write-ERR "Invalid license: $msg"
    Write-Host ""; pause; exit 1
}

Write-OK "License verified."
Write-Host ""
Write-Line
Write-Host ""

Write-Host "   Select an option:" -ForegroundColor Yellow
Write-Host ""
Write-Host "   [1] Install ReShade" -ForegroundColor White
Write-Host "   [2] Uninstall ReShade" -ForegroundColor White
Write-Host ""
$choice = Read-Host "   Enter 1 or 2"

if ($choice -eq "2") { Run-Uninstall; exit 0 }
if ($choice -ne "1") {
    Write-ERR "Invalid option."
    Write-Host ""; pause; exit 1
}

Write-Host ""
Write-Step "2/3" "Downloading ReShade Installer..."
Write-Host ""

try {
    Download-WithProgress $EXE_URL $EXE_PATH
    Write-OK "Download complete."
} catch {
    Write-ERR "Download failed: $_"
    Write-Host ""; pause; exit 1
}

Write-Host ""
Write-Step "3/3" "Launching ReShade Installer..."
Write-Host ""
Write-Line
Write-Host ""

$proc = Start-Process -FilePath $EXE_PATH -PassThru
$proc.WaitForExit() | Out-Null

Start-Sleep -Seconds 1
if (Test-Path $EXE_PATH) {
    Remove-Item $EXE_PATH -Force -ErrorAction SilentlyContinue
}