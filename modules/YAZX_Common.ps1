# YAZX Common Functions — Shared utilities for all modules
# Dot-source: . "$PSScriptRoot\YAZX_Common.ps1"

function YAZX-Log {
    param([string]$File, [string]$Msg)
    if ($File) {
        "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] $Msg" | Out-File $File -Append -Encoding UTF8
    }
}

function YAZX-Choose {
    param(
        [string]$Title,
        [string[]]$Labels,
        [object[]]$Values,
        [int]$Default = 0,
        [bool]$Auto = $false
    )
    if ($Auto) {
        Write-Host "    -> $($Labels[$Default]) (auto)" -ForegroundColor DarkGray
        return $Values[$Default]
    }
    Write-Host ""
    Write-Host "  $Title" -ForegroundColor Cyan
    for ($i = 0; $i -lt $Labels.Count; $i++) {
        if ($i -eq $Default) {
            Write-Host "    [$($i+1)] $($Labels[$i]) << YAZX Default" -ForegroundColor Green
        } else {
            Write-Host "    [$($i+1)] $($Labels[$i])" -ForegroundColor Gray
        }
    }
    $resp = Read-Host "    Select [Enter = $($Default+1)]"
    if ([string]::IsNullOrWhiteSpace($resp)) { return $Values[$Default] }
    $idx = 0
    if ([int]::TryParse($resp, [ref]$idx) -and $idx -ge 1 -and $idx -le $Labels.Count) {
        return $Values[$idx - 1]
    }
    return $Values[$Default]
}

function YAZX-Apply {
    param(
        [string]$LogFile,
        [string]$Path,
        [string]$Name,
        [object]$Value,
        [string]$Type = "DWord",
        [string]$Desc = ""
    )
    $old = $null
    try { $old = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop).$Name } catch {}
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force
    $label = if ($Desc) { $Desc } else { "$Path\$Name" }
    if ($null -ne $old -and $old -ne $Value) {
        Write-Host "    [OK] $label = $Value (was: $old)" -ForegroundColor Green
        YAZX-Log $LogFile "$label`: $old -> $Value"
    } else {
        Write-Host "    [OK] $label = $Value" -ForegroundColor Green
        YAZX-Log $LogFile "$label`: set to $Value"
    }
}
