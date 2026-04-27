# ================================================================
# ReShade Installer Launcher - by INSIDEX
# iex (irm 'https://raw.githubusercontent.com/xintapayyasiriphumi-web/reshadexinstaller/main/install.ps1')
# ================================================================

# KeyAuth Config — แก้ให้ตรงกับ dashboard
$KEYAUTH_NAME    = "General Key"
$KEYAUTH_OWNERID = "h73NBoWgLW"
$KEYAUTH_VERSION = "1.0"
$KEYAUTH_URL     = "https://keyauth.win/api/1.2/"

# Download URL
$EXE_URL  = "https://github.com/xintapayyasiriphumi-web/reshadexinstaller/releases/download/v1.0.1/ReShadeInstaller.exe"
$EXE_NAME = "ReShadeInstaller.exe"
$EXE_PATH = "$env:TEMP\$EXE_NAME"

# ================================================================
# UI Helpers
# ================================================================

function Write-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "  =================================================" -ForegroundColor DarkCyan
    Write-Host "  |                                               |" -ForegroundColor DarkCyan
    Write-Host "  |       RESHADEX INSTALLER  by INSIDEX          |" -ForegroundColor Cyan
    Write-Host "  |                                               |" -ForegroundColor DarkCyan
    Write-Host "  =================================================" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "  Powered by Shxrk  |  INSIDEX" -ForegroundColor DarkGray
    Write-Host ""
}

function Write-Status($msg, $color = "Cyan") {
    Write-Host "  » $msg" -ForegroundColor $color
}

function Write-Success($msg) {
    Write-Host "  ✓ $msg" -ForegroundColor Green
}

function Write-Fail($msg) {
    Write-Host "  ✗ $msg" -ForegroundColor Red
}

# ================================================================
# HWID
# ================================================================

function Get-HWID {
    $raw = "$env:COMPUTERNAME-$env:USERNAME-$env:PROCESSOR_IDENTIFIER"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($raw)
    $hash  = [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
    return ([BitConverter]::ToString($hash) -replace '-','').ToLower().Substring(0, 32)
}

# ================================================================
# KeyAuth
# ================================================================

function KeyAuth-Init {
    try {
        $body = "type=init&name=$KEYAUTH_NAME&ownerid=$KEYAUTH_OWNERID&ver=$KEYAUTH_VERSION"
        $resp = Invoke-RestMethod -Uri $KEYAUTH_URL -Method Post -Body $body -ContentType "application/x-www-form-urlencoded" -TimeoutSec 10
        return $resp
    } catch {
        return $null
    }
}

function KeyAuth-License($sessionId, $licenseKey, $hwid) {
    try {
        $body = "type=license&key=$licenseKey&hwid=$hwid&sessionid=$sessionId&name=$KEYAUTH_NAME&ownerid=$KEYAUTH_OWNERID"
        $resp = Invoke-RestMethod -Uri $KEYAUTH_URL -Method Post -Body $body -ContentType "application/x-www-form-urlencoded" -TimeoutSec 10
        return $resp
    } catch {
        return $null
    }
}

# ================================================================
# MAIN
# ================================================================

Write-Banner

# รับ License Key
Write-Host "  กรอก License Key ของคุณ:" -ForegroundColor Yellow
Write-Host ""
$licenseKey = Read-Host "  License Key"

if ([string]::IsNullOrWhiteSpace($licenseKey)) {
    Write-Fail "ไม่ได้กรอก License Key"
    Write-Host ""
    pause
    exit 1
}

Write-Host ""
Write-Status "กำลัง verify license..."

# Init session
$init = KeyAuth-Init
if (-not $init -or -not $init.success) {
    $msg = if ($init) { $init.message } else { "ไม่สามารถเชื่อมต่อ auth server" }
    Write-Fail "Auth server error: $msg"
    Write-Host ""
    pause
    exit 1
}

# Verify license
$hwid    = Get-HWID
$verify  = KeyAuth-License $init.sessionid $licenseKey.Trim() $hwid

if (-not $verify -or -not $verify.success) {
    $msg = if ($verify) { $verify.message } else { "ไม่สามารถ verify ได้" }
    Write-Fail "License ไม่ถูกต้อง: $msg"
    Write-Host ""
    pause
    exit 1
}

Write-Success "License ถูกต้อง!"
Write-Host ""

# Download exe
Write-Status "กำลัง download ReShade Installer..."

try {
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($EXE_URL, $EXE_PATH)
    Write-Success "Download สำเร็จ"
} catch {
    Write-Fail "Download ไม่สำเร็จ: $_"
    Write-Host ""
    pause
    exit 1
}

Write-Host ""
Write-Status "กำลังเปิด ReShade Installer..." "Green"
Write-Host ""

# Launch exe
Start-Process -FilePath $EXE_PATH

Start-Sleep -Seconds 2