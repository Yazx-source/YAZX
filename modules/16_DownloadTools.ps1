param(
    [string]$YazxDir,
    [string]$BackupDir,
    [string]$LogFile,
    [switch]$Auto
)

# YAZX Module 16 - Tools Downloader
# Auto-downloads all portable tools that YAZX tweaks depend on
# Each tool is tagged with which module uses it

. "$PSScriptRoot\YAZX_Common.ps1"

Write-Host ""
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host "    YAZX Module 16: Tools Downloader" -ForegroundColor Cyan
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host ""
YAZX-Log $LogFile "Module 16 ToolsDownloader: Started"

$ToolsDir = Join-Path $YazxDir "tools"
if (-not (Test-Path $ToolsDir)) { New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null }

$ProgressPreference = "SilentlyContinue"
$hasWinget = [bool](Get-Command winget -ErrorAction SilentlyContinue)

# === Helpers ===

function Get-ToolFile {
    param([string]$Url, [string]$OutPath)
    $dir = Split-Path $OutPath
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    try {
        Invoke-WebRequest -Uri $Url -OutFile $OutPath -UseBasicParsing -TimeoutSec 120 -ErrorAction Stop
        $sz = [math]::Round((Get-Item $OutPath).Length / 1MB, 1)
        Write-Host " ${sz} MB" -ForegroundColor Green
        return $true
    } catch {
        Write-Host " FAILED" -ForegroundColor Red
        if (Test-Path $OutPath) { Remove-Item $OutPath -Force -ErrorAction SilentlyContinue }
        return $false
    }
}

function Get-GitHubLatest {
    param([string]$Repo, [string]$AssetFilter, [string]$OutPath)
    try {
        $rel = Invoke-RestMethod "https://api.github.com/repos/$Repo/releases/latest" -UseBasicParsing -TimeoutSec 30
        $asset = $rel.assets | Where-Object { $_.name -like $AssetFilter } | Select-Object -First 1
        if ($asset) {
            return Get-ToolFile -Url $asset.browser_download_url -OutPath $OutPath
        }
    } catch {}
    return $false
}

function Install-Winget {
    param([string]$Id)
    if (-not $hasWinget) { return $false }
    Write-Host " winget..." -NoNewline -ForegroundColor Gray
    $r = winget install --id $Id --accept-package-agreements --accept-source-agreements --silent 2>&1
    if ($LASTEXITCODE -eq 0 -or "$r" -match "already installed") {
        Write-Host " OK" -ForegroundColor Green
        return $true
    }
    Write-Host " FAILED" -ForegroundColor Red
    return $false
}

function Test-ToolReady {
    param([string]$Dir, [string]$Pattern)
    $p = Join-Path $ToolsDir $Dir
    if (-not (Test-Path $p)) { return $false }
    return [bool](Get-ChildItem $p -Filter $Pattern -Recurse -Depth 2 -ErrorAction SilentlyContinue | Select-Object -First 1)
}

function Expand-ToolZip {
    param([string]$Zip, [string]$Dest)
    if (-not (Test-Path $Dest)) { New-Item -ItemType Directory -Path $Dest -Force | Out-Null }
    try {
        Expand-Archive -Path $Zip -DestinationPath $Dest -Force -ErrorAction Stop
        Write-Host "    [OK] Extracted" -ForegroundColor DarkGreen
    } catch {
        Write-Host "    [!] Extract failed" -ForegroundColor Yellow
    }
}

function Confirm-ToolHash {
    param([string]$FilePath, [string]$ToolDir)
    if (-not $knownHashes.ContainsKey($ToolDir)) { return $true }
    $entry = $knownHashes[$ToolDir]
    $actual = (Get-FileHash $FilePath -Algorithm SHA256).Hash
    if ($actual -eq $entry.Hash) {
        Write-Host "    [OK] SHA-256 verified" -ForegroundColor DarkGreen
        return $true
    }
    if ($entry.Mode -eq "strict") {
        Write-Host "    [!!] SHA-256 MISMATCH - file rejected (pinned version)" -ForegroundColor Red
        Write-Host "    Expected: $($entry.Hash)" -ForegroundColor Red
        Write-Host "    Got:      $actual" -ForegroundColor Red
        Remove-Item $FilePath -Force -ErrorAction SilentlyContinue
        YAZX-Log $LogFile "SECURITY: Hash mismatch for $ToolDir (strict) - file deleted"
        return $false
    }
    Write-Host "    [!] SHA-256 differs from known hash (tool may have been updated)" -ForegroundColor Yellow
    Write-Host "    Known:  $($entry.Hash)" -ForegroundColor Yellow
    Write-Host "    Got:    $actual" -ForegroundColor Yellow
    YAZX-Log $LogFile "WARNING: Hash differs for $ToolDir (warn mode) - file kept"
    return $true
}

# === Tool Catalog (18 tools) ===

$catalog = @(
    # --- Direct URL downloads ---
    @{ Name="Sysinternals Suite"; Dir="Sysinternals"; Check="extracted\*.exe"
       Url="https://download.sysinternals.com/files/SysinternalsSuite.zip"
       File="SysinternalsSuite.zip"; ExtractTo="extracted"
       For="Autoruns, Process Explorer, TCPView, RAMMap" },

    @{ Name="ISLC (Standby List Cleaner)"; Dir="ISLC"; Check="ISLC*.exe"
       Url="https://www.wagnardsoft.com/ISLC/ISLC%20v1.0.3.2.exe"
       File="ISLC_v1.0.3.2.exe"
       For="Module 14 - memory and timer management" },

    @{ Name="DDU (Display Driver Uninstaller)"; Dir="DDU"; Check="DDU*.exe"
       Url="https://www.wagnardsoft.com/DDU/download/DDU%20v18.0.9.3.exe"
       File="DDU_Setup.exe"
       For="Module 02 - clean GPU driver removal" },

    @{ Name="LatencyMon"; Dir="LatencyMon"; Check="LatencyMon.exe"
       Url="https://www.resplendence.com/download/LatencyMon.exe"
       File="LatencyMon.exe"
       For="Module 01 - DPC latency testing" },

    @{ Name="OO ShutUp10++"; Dir="OO_ShutUp10"; Check="OOSU10.exe"
       Url="https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe"
       File="OOSU10.exe"
       For="Module 12 - privacy hardening" },

    @{ Name="IRQControl"; Dir="IRQControl"; Check="irqcontrol*.exe"
       Url="https://dl.bitsum.com/files/beta/irqcontrolsetup64.exe"
       File="irqcontrolsetup64.exe"
       For="Module 10 - IRQ affinity after MSI mode" },

    @{ Name="QuickCPU"; Dir="QuickCPU"; Check="QuickCpu*"
       Url="https://coderbag.com/assets/downloads/quickcpu/QuickCpuSetup.msi"
       File="QuickCpuSetup.msi"
       For="Module 11 - CPU core and power management" },

    @{ Name="USBTreeView"; Dir="USBTreeView"; Check="*.zip"
       Url="https://www.uwe-sieber.de/files/usbtreeview.zip"
       File="usbtreeview.zip"
       For="USB device management" },

    # --- GitHub releases ---
    @{ Name="MouseTester"; Dir="MouseTester"; Check="*.zip"
       Url="https://github.com/microe1/MouseTester/releases/download/v1.5.3/MouseTester.v1.5.3.zip"
       File="MouseTester_v1.5.3.zip"
       For="Mouse polling rate test" },

    @{ Name="WinMTR"; Dir="WinMTR"; Check="*.zip"
       Url="https://github.com/White-Tiger/WinMTR/releases/download/v1.00/WinMTR-v100-static.zip"
       File="WinMTR-v100-static.zip"
       For="Network route/latency test" },

    @{ Name="CapFrameX"; Dir="CapFrameX"; Check="*.zip"
       Url="https://github.com/CXWorld/CapFrameX/releases/download/v1.9.2/release_1.9.2_portable.zip"
       File="release_1.9.2_portable.zip"
       For="Frame time analysis" },

    @{ Name="NVIDIA Profile Inspector"; Dir="NVIDIAProfileInspector"; Check="nvidiaProfileInspector.exe"
       GHRepo="Orbmu2k/nvidiaProfileInspector"; GHAsset="*.zip"
       File="nvidiaProfileInspector.zip"; ExtractTo="."
       For="Module 02 - NVIDIA driver profiles" },

    # --- Winget fallback (sites block automated download) ---
    @{ Name="GPU-Z"; Dir="GPU-Z"; Check="GPU-Z*.exe"
       WingetId="TechPowerUp.GPU-Z"
       For="GPU monitoring" },

    @{ Name="HWiNFO"; Dir="HWiNFO"; Check="HWiNFO*"
       WingetId="REALiX.HWiNFO"
       For="Hardware monitoring" },

    @{ Name="CrystalDiskInfo"; Dir="CrystalDiskInfo"; Check="DiskInfo*"
       WingetId="CrystalDewWorld.CrystalDiskInfo"
       For="Disk health (S.M.A.R.T.)" },

    @{ Name="CrystalDiskMark"; Dir="CrystalDiskMark"; Check="DiskMark*"
       WingetId="CrystalDewWorld.CrystalDiskMark"
       For="Disk speed benchmark" },

    @{ Name="ThrottleStop"; Dir="ThrottleStop"; Check="ThrottleStop*"
       WingetId="TechPowerUp.ThrottleStop"
       For="CPU power/speed monitor" },

    @{ Name="SG TCP Optimizer"; Dir="SG_TCP_Optimizer"; Check="TCPOptimizer*"
       ManualUrl="https://www.speedguide.net/downloads.php"
       For="Network optimization" }
)

# === Known SHA-256 Hashes (from YAZX_TOOL_LIBRARY.md) ===
# strict = reject on mismatch (version-pinned URL)
# warn   = alert but keep (mutable/latest URL, hash may change on update)

$knownHashes = @{
    Sysinternals     = @{ Hash="E7F49D1F4477E416B3051636DC44929B20AE025B46A1EE4CD8C1F1E869AF6AE6"; Mode="warn" }
    ISLC             = @{ Hash="FC4961D4FFA095EB150B29CEB9D26A77098988C6549FE6187DBB80BFA2A6A381"; Mode="strict" }
    DDU              = @{ Hash="3D53FCC3506F4B9A55204B0C7E98F0B0E7A67ABA113856B87AC6F4F631E481A6"; Mode="warn" }
    LatencyMon       = @{ Hash="C124342DA2A844DA0699901476B27226DA1D0D30BF8E940C9F847D67D46A1157"; Mode="warn" }
    OO_ShutUp10      = @{ Hash="EA2790422AA81D62F22AE93E995C205D4D7A6AC9825877CF34AD4E65A8253ECE"; Mode="warn" }
    IRQControl       = @{ Hash="0B3113EB359C88678310A2DFD66EBE9AB80CEED1D60EA4FB2EBCB5F5B67451D7"; Mode="warn" }
    QuickCPU         = @{ Hash="9668D980F36087B56849D207A5ABEB709686D9167F621AB2076F8BEBE52AED6A"; Mode="warn" }
    USBTreeView      = @{ Hash="558620110D614A0859D08550C9D0259C2CABC7D8444DC8DF43754A64380B85D4"; Mode="warn" }
    MouseTester      = @{ Hash="D7E63DD67C8948777A43BB65D9D8F377A5E81254DA480DAAFF70E2BC121A01E1"; Mode="strict" }
    WinMTR           = @{ Hash="2DA85A22A319E87705FA846E949E28B9A23726D161816228D49AF402D55EA60E"; Mode="strict" }
    CapFrameX        = @{ Hash="0C3374D382ABB359439F8898BDAAA1C4E6A7CC0FDD936022C0EAD0CA213BDA08"; Mode="strict" }
    GPU_Z            = @{ Hash="3B15545F3EDF7F2C714A32C7EE2BEDD9823FEE7D23A20E15F2E29CD2FEE25323"; Mode="warn" }
    ThrottleStop     = @{ Hash="7B5E1A650A845CDAB200BD6A7766D8F56AE458F633A6F2F3DF5A9EC72847098A"; Mode="warn" }
}

# === Process each tool ===

$stats = @{ OK=0; Downloaded=0; Winget=0; Failed=0 }
$failList = @()

foreach ($tool in $catalog) {
    $ready = Test-ToolReady -Dir $tool.Dir -Pattern $tool.Check
    Write-Host "  [$($tool.Name)]" -NoNewline -ForegroundColor White
    Write-Host " - $($tool.For)" -ForegroundColor DarkGray

    if ($ready) {
        Write-Host "    [OK] Already present" -ForegroundColor Green
        $stats.OK++
        continue
    }

    $success = $false
    $outDir = Join-Path $ToolsDir $tool.Dir

    # Strategy 1: Direct URL
    if ($tool.ContainsKey('Url') -and $tool.Url) {
        $outFile = Join-Path $outDir $tool.File
        Write-Host "    Downloading..." -NoNewline -ForegroundColor Gray
        $success = Get-ToolFile -Url $tool.Url -OutPath $outFile
        if ($success) {
            $success = Confirm-ToolHash -FilePath $outFile -ToolDir $tool.Dir
        }
        if ($success -and $tool.ContainsKey('ExtractTo') -and $tool.File -like "*.zip") {
            $extractDest = Join-Path $outDir $tool.ExtractTo
            Expand-ToolZip -Zip $outFile -Dest $extractDest
        }
    }

    # Strategy 2: GitHub latest release
    if (-not $success -and $tool.ContainsKey('GHRepo') -and $tool.GHRepo) {
        $outFile = Join-Path $outDir $tool.File
        Write-Host "    GitHub release..." -NoNewline -ForegroundColor Gray
        $success = Get-GitHubLatest -Repo $tool.GHRepo -AssetFilter $tool.GHAsset -OutPath $outFile
        if ($success) {
            $success = Confirm-ToolHash -FilePath $outFile -ToolDir $tool.Dir
        }
        if ($success -and $tool.ContainsKey('ExtractTo') -and $tool.File -like "*.zip") {
            $extractDest = Join-Path $outDir $tool.ExtractTo
            Expand-ToolZip -Zip $outFile -Dest $extractDest
        }
    }

    # Strategy 3: Winget
    if (-not $success -and $tool.ContainsKey('WingetId') -and $tool.WingetId) {
        Write-Host "    Installing via" -NoNewline -ForegroundColor Gray
        $success = Install-Winget -Id $tool.WingetId
        if ($success) { $stats.Winget++ }
    }

    # Result
    if ($success) {
        $stats.Downloaded++
        YAZX-Log $LogFile "Tool downloaded: $($tool.Name)"
    } else {
        $stats.Failed++
        $url = if ($tool.ContainsKey('ManualUrl')) { $tool.ManualUrl }
               elseif ($tool.ContainsKey('Url')) { $tool.Url }
               else { "search online" }
        Write-Host "    [!!] Manual download needed: $url" -ForegroundColor Red
        $failList += @{ Name=$tool.Name; Url=$url }
        YAZX-Log $LogFile "Tool MISSING: $($tool.Name) - manual download needed"
    }
}

# === Summary ===

Write-Host ""
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host "    Download Summary" -ForegroundColor Green
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host "    Already present : $($stats.OK)" -ForegroundColor Green
Write-Host "    Downloaded      : $($stats.Downloaded)" -ForegroundColor $(if ($stats.Downloaded -gt 0) { "Green" } else { "Gray" })
Write-Host "    Winget installed: $($stats.Winget)" -ForegroundColor $(if ($stats.Winget -gt 0) { "Green" } else { "Gray" })
Write-Host "    Manual needed   : $($stats.Failed)" -ForegroundColor $(if ($stats.Failed -gt 0) { "Yellow" } else { "Green" })

if ($failList.Count -gt 0) {
    Write-Host ""
    Write-Host "    Tools needing manual download:" -ForegroundColor Yellow
    foreach ($f in $failList) {
        Write-Host "      - $($f.Name): $($f.Url)" -ForegroundColor Gray
    }
}

$total = $stats.OK + $stats.Downloaded + $stats.Winget
Write-Host ""
Write-Host "    $total / $($catalog.Count) tools ready" -ForegroundColor $(if ($stats.Failed -eq 0) { "Green" } else { "Yellow" })
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host ""

$logMsg = "Module 16 ToolsDownloader: $total of $($catalog.Count) ready, $($stats.Downloaded) downloaded, $($stats.Winget) winget, $($stats.Failed) manual. Completed"
YAZX-Log $LogFile $logMsg
