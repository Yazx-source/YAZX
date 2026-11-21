param($YazxDir, $BackupDir, $LogFile, [switch]$Auto)
# YAZX Module 03 - Install All Programs
# Installs from backup or downloads

. "$PSScriptRoot\YAZX_Common.ps1"
function Log($msg) { YAZX-Log $LogFile $msg }

Write-Host "`n  === YAZX Module 03: Programs ===" -ForegroundColor Cyan
Log "Module 03 Programs: Started"

# Program list with install methods
$programs = @(
    @{Name="7-Zip"; Check="C:\Program Files\7-Zip\7z.exe"; WingetId="7zip.7zip"; Url="https://www.7-zip.org/a/7z2402-x64.exe"; Silent="/S"}
    @{Name="Process Lasso"; Check="C:\Program Files\Process Lasso\ProcessLasso.exe"; Backup="yazx_ProcessLasso"; Url="https://dl.bitsum.com/files/processlassosetup64.exe"; Silent="/S"}
    @{Name="MSI Afterburner"; Check="C:\Program Files (x86)\MSI Afterburner\MSIAfterburner.exe"; Backup="yazx_MSI_Afterburner"; Url="https://download.msi.com/uti_exe/vga/MSIAfterburnerSetup466.zip"; Silent="/S"}
    @{Name="Equalizer APO"; Check="C:\Program Files\EqualizerAPO\Editor.exe"; WingetId="jthedering.EqualizerAPO"; Backup="yazx_EqualizerAPO"; Url="https://sourceforge.net/projects/equalizerapo/files/latest/download"; Silent="/S"}
    @{Name="Open-Shell"; Check="C:\Program Files\Open-Shell\StartMenu.exe"; Backup="yazx_OpenShell"; Silent="QUIET"}
    @{Name="ParkControl"; Check="C:\Program Files\ParkControl\ParkControl.exe"; Backup="yazx_ParkControl"; Url="https://dl.bitsum.com/files/parkcontrolsetup64.exe"; Silent="/S"}
    @{Name="Mem Reduct"; Check="C:\Program Files\Mem Reduct\memreduct.exe"; Backup="yazx_MemReduct"; Portable=$true}
    @{Name="LibreWolf"; Check="C:\Program Files\LibreWolf\librewolf.exe"; WingetId="LibreWolf.LibreWolf"; Url="https://librewolf.net/installation/windows/"; Manual=$true}
    @{Name="Steam"; Check="C:\Program Files (x86)\Steam\steam.exe"; WingetId="Valve.Steam"; Url="https://cdn.akamai.steamstatic.com/client/installer/SteamSetup.exe"; Silent="/S"}
    @{Name="Discord"; Check="$env:LOCALAPPDATA\Discord\Update.exe"; WingetId="Discord.Discord"; Url="https://discord.com/api/downloads/distributions/app/installers/latest?channel=stable&platform=win&arch=x64"; Silent="-s"}
    @{Name="Brave"; Check="C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe"; WingetId="Brave.Brave"; Url="https://laptop-updates.brave.com/latest/winx64"; Silent="--silent --install"}
    @{Name="Git"; Check="C:\Program Files\Git\git-cmd.exe"; WingetId="Git.Git"; Url="https://github.com/git-for-windows/git/releases/latest"; Manual=$true}
    @{Name="VS Code"; Check="$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe"; WingetId="Microsoft.VisualStudioCode"; Url="https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user"; Silent="/VERYSILENT"}
    @{Name="Revo Uninstaller"; Check="C:\Program Files\VS Revo Group\Revo Uninstaller Pro\RevoUninPro.exe"; Backup="yazx_RevoUninstaller"; Manual=$true}
    @{Name="ExplorerPatcher"; Backup="yazx_ExplorerPatcher"; Manual=$true}
    @{Name="RW-Everything"; Backup="yazx_BIOS"; Portable=$true}
)

$installed = 0
$needInstall = 0
$hasWinget = [bool](Get-Command winget -ErrorAction SilentlyContinue)

foreach ($prog in $programs) {
    $exists = $false
    if ($prog.ContainsKey('Check')) {
        $exists = Test-Path $prog.Check
    }

    if ($exists) {
        Write-Host "  [OK] $($prog.Name) - Already installed" -ForegroundColor Green
        $installed++
    } else {
        $needInstall++
        if ($prog.Manual -and -not $prog.ContainsKey('WingetId')) {
            Write-Host "  [!!] $($prog.Name) - Manual install needed" -ForegroundColor Red
            if ($prog.Url) { Write-Host "       URL: $($prog.Url)" -ForegroundColor Gray }
            if ($prog.Backup -and (Test-Path "$BackupDir\$($prog.Backup)")) {
                Write-Host "       Backup available: $BackupDir\$($prog.Backup)" -ForegroundColor Yellow
            }
            Log "$($prog.Name): Manual install needed"
        } elseif ($hasWinget -and $prog.ContainsKey('WingetId')) {
            Write-Host "  [=>] $($prog.Name) - Installing via winget..." -ForegroundColor Yellow
            $wingetResult = winget install --id $prog.WingetId --accept-package-agreements --accept-source-agreements --silent 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  [OK] $($prog.Name) - Installed via winget" -ForegroundColor Green
                Log "$($prog.Name): Installed via winget ($($prog.WingetId))"
            } else {
                Write-Host "  [!] $($prog.Name) - Winget failed, manual install needed" -ForegroundColor Yellow
                if ($prog.Url) { Write-Host "       URL: $($prog.Url)" -ForegroundColor Gray }
                Log "$($prog.Name): Winget failed, needs manual install"
            }
        } elseif ($prog.Portable -and $prog.Backup -and (Test-Path "$BackupDir\$($prog.Backup)")) {
            Write-Host "  [=>] $($prog.Name) - Copying from backup..." -ForegroundColor Yellow
            $dst = "C:\Program Files\$($prog.Name)"
            New-Item -ItemType Directory -Path $dst -Force -ErrorAction SilentlyContinue | Out-Null
            Copy-Item "$BackupDir\$($prog.Backup)\*" "$dst\" -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  [OK] $($prog.Name) - Copied from backup" -ForegroundColor Green
            Log "$($prog.Name): Installed from backup"
        } else {
            Write-Host "  [!!] $($prog.Name) - Needs installation" -ForegroundColor Red
            if ($prog.Url) { Write-Host "       URL: $($prog.Url)" -ForegroundColor Gray }
            Log "$($prog.Name): Not installed, needs download"
        }
    }
}

# VC++ Redistributables (auto-install missing via winget)
Write-Host "`n  --- Visual C++ Redistributables ---" -ForegroundColor Yellow
$vcRedists = @(
    @{Year="2005"; Match="2005"; WingetId="Microsoft.VCRedist.2005.x64"},
    @{Year="2008"; Match="2008"; WingetId="Microsoft.VCRedist.2008.x64"},
    @{Year="2010"; Match="2010"; WingetId="Microsoft.VCRedist.2010.x64"},
    @{Year="2012"; Match="2012"; WingetId="Microsoft.VCRedist.2012.x64"},
    @{Year="2013"; Match="2013"; WingetId="Microsoft.VCRedist.2013.x64"},
    @{Year="2015-2022"; Match="201[5-9]|202[0-9]"; WingetId="Microsoft.VCRedist.2015+.x64"}
)
foreach ($vc in $vcRedists) {
    $found = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -match "Visual C\+\+.*($($vc.Match))" }
    if ($found) {
        Write-Host "  [OK] VC++ $($vc.Year)" -ForegroundColor Green
    } elseif ($hasWinget) {
        Write-Host "  [=>] VC++ $($vc.Year) - Installing via winget..." -ForegroundColor Yellow
        winget install --id $vc.WingetId --accept-package-agreements --accept-source-agreements --silent 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] VC++ $($vc.Year) - Installed" -ForegroundColor Green
            Log "VC++ $($vc.Year): Installed via winget"
        } else {
            Write-Host "  [!] VC++ $($vc.Year) - Winget failed" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [!!] VC++ $($vc.Year) - Missing (no winget)" -ForegroundColor Red
    }
}

Write-Host "`n  Summary: $installed already installed, $needInstall need installation" -ForegroundColor Cyan
Log "Module 03 Programs: $installed installed, $needInstall needed. Completed"
Write-Host "  [OK] Programs module complete.`n" -ForegroundColor Green
