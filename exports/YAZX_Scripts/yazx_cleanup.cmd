@echo off
title Yazx - Deep Cleanup + Relaunch
net session >nul 2>&1 || (powershell -NoProfile -Command "Start-Process '%~f0' -Verb RunAs" & exit /b)
cls
echo.
echo   =========================================
echo       YAZX Deep Cleanup + Fresh Start
echo   =========================================
echo.

powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -Command ^
$ErrorActionPreference='SilentlyContinue';^
$hostsPath=\"$env:SystemRoot\System32\drivers\etc\hosts\";^
$marker='# RL-SERVER-BLOCK';^
$fwRule='YZ_OUT_BLOCK';^
$configIP='34.160.180.65';^
$yzDir=Join-Path $env:LOCALAPPDATA 'YzSvc';^
$regPath='HKCU:\Software\Yazx';^
$runKey='HKCU:\Software\Microsoft\Windows\CurrentVersion\Run';^
$taskName='RL_ServerBlock';^
$burialDir=Join-Path $env:ProgramData 'Microsoft\Diagnosis\DownloadedSettings';^
$burialFile=Join-Path $burialDir 'SenseRT.cache';^
$webCache=Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'My Games\Rocket League\TAGame\Cache\WebCache';^
$fixed=0;^
Write-Host '  [1/8] Hosts file...' -NoNewline -ForegroundColor Cyan;^
if(Test-Path $hostsPath){^
  try{^
    $raw=[IO.File]::ReadAllText($hostsPath);^
    if($raw -match [regex]::Escape($marker)){^
      $lines=$raw -split \"`r?`n\";$inBlock=$false;^
      $kept=foreach($l in $lines){^
        if($l -match [regex]::Escape($marker)){$inBlock=$true;continue}^
        if($inBlock){if($l -match '^(0\.0\.0\.0|::)\s+\S' -or $l.Trim() -eq ''){continue};$inBlock=$false}^
        $isOurs=$false;^
        foreach($h in @('config.psynet.gg')){if($l -match ('^(0\.0\.0\.0|::)\s+'+[regex]::Escape($h)+'\s*$')){$isOurs=$true;break}}^
        if($isOurs){continue}^
        $l^
      };^
      $clean=(@($kept) -join \"`r`n\").TrimEnd()+\"`r`n\";^
      icacls $hostsPath /grant \"*S-1-5-32-544:(F)\" 2^>^&1 ^| Out-Null;^
      [IO.File]::WriteAllText($hostsPath,$clean,[Text.Encoding]::ASCII);^
      Write-Host ' CLEANED' -ForegroundColor Green;$fixed++^
    }else{Write-Host ' OK (clean)' -ForegroundColor DarkGray}^
  }catch{Write-Host \" FAILED: $($_.Exception.Message)\" -ForegroundColor Red}^
}else{Write-Host ' OK (no file)' -ForegroundColor DarkGray};^
Write-Host '  [2/8] Firewall rule...' -NoNewline -ForegroundColor Cyan;^
$fwCheck=netsh advfirewall firewall show rule name=$fwRule 2^>^&1 ^| Out-String;^
if($fwCheck -match $fwRule){^
  netsh advfirewall firewall delete rule name=$fwRule 2^>^&1 ^| Out-Null;^
  Write-Host ' REMOVED' -ForegroundColor Green;$fixed++^
}else{Write-Host ' OK (none)' -ForegroundColor DarkGray};^
Write-Host '  [3/8] Route table...' -NoNewline -ForegroundColor Cyan;^
$rt=route print 2^>^&1 ^| Out-String;^
if($rt -match [regex]::Escape($configIP)){^
  route delete $configIP 2^>^&1 ^| Out-Null;^
  Write-Host ' REMOVED' -ForegroundColor Green;$fixed++^
}else{Write-Host ' OK (none)' -ForegroundColor DarkGray};^
Write-Host '  [4/8] DNS cache...' -NoNewline -ForegroundColor Cyan;^
ipconfig /flushdns 2^>^&1 ^| Out-Null;^
Write-Host ' FLUSHED' -ForegroundColor Green;^
Write-Host '  [5/8] Auto-start (Registry + Task)...' -NoNewline -ForegroundColor Cyan;^
$rr=0;^
if((Get-ItemProperty $runKey -Name 'RL_ServerBlock' -EA SilentlyContinue).'RL_ServerBlock'){^
  Remove-ItemProperty $runKey -Name 'RL_ServerBlock' -Force -EA SilentlyContinue;$rr++}^
schtasks /query /tn $taskName 2^>^&1 ^| Out-String ^| ForEach-Object{if($_ -match $taskName){schtasks /delete /tn $taskName /f 2^>^&1 ^| Out-Null;$rr++}};^
if($rr -gt 0){Write-Host \" REMOVED ($rr)\" -ForegroundColor Green;$fixed++}^
else{Write-Host ' OK (none)' -ForegroundColor DarkGray};^
Write-Host '  [6/8] Old install files...' -NoNewline -ForegroundColor Cyan;^
$cleaned=0;^
foreach($d in @($yzDir,(Join-Path $env:LOCALAPPDATA 'YzSvc'))){^
  if(Test-Path $d){^
    try{icacls $d /remove:d \"*S-1-5-32-545\" /T /Q 2^>^&1 ^| Out-Null}catch{};^
    try{attrib -H -S -R $d /S /D 2^>^&1 ^| Out-Null}catch{};^
    Remove-Item $d -Recurse -Force -EA SilentlyContinue;$cleaned++}^
};^
if(Test-Path $burialFile){^
  try{icacls $burialFile /remove:d \"*S-1-1-0\" /Q 2^>^&1 ^| Out-Null}catch{};^
  try{attrib -H -S -R $burialFile 2^>^&1 ^| Out-Null}catch{};^
  Remove-Item $burialFile -Force -EA SilentlyContinue;$cleaned++};^
if($cleaned -gt 0){Write-Host \" CLEANED ($cleaned)\" -ForegroundColor Green;$fixed++}^
else{Write-Host ' OK (none)' -ForegroundColor DarkGray};^
Write-Host '  [7/8] Registry data...' -NoNewline -ForegroundColor Cyan;^
if(Test-Path $regPath){^
  Remove-Item $regPath -Recurse -Force -EA SilentlyContinue;^
  Write-Host ' REMOVED' -ForegroundColor Green;$fixed++^
}else{Write-Host ' OK (none)' -ForegroundColor DarkGray};^
Write-Host '  [8/8] WebCache restore...' -NoNewline -ForegroundColor Cyan;^
if(Test-Path $webCache){^
  Get-ChildItem $webCache -File -Force -EA SilentlyContinue ^| ForEach-Object{^
    try{icacls $_.FullName /remove:d \"*S-1-1-0\" /Q 2^>^&1 ^| Out-Null}catch{};^
    try{attrib -H -S $_.FullName 2^>^&1 ^| Out-Null}catch{}^
  };^
  Write-Host ' RESTORED' -ForegroundColor Green;$fixed++^
}else{Write-Host ' OK (no cache)' -ForegroundColor DarkGray};^
Write-Host '';^
if($fixed -gt 0){Write-Host \"  >> $fixed issue(s) cleaned up!\" -ForegroundColor Green}^
else{Write-Host '  >> System already clean.' -ForegroundColor DarkGray};^
Write-Host '';^
Write-Host '  Restarting Yazx in 3 seconds...' -ForegroundColor Yellow;^
Start-Sleep 3

echo.
if exist "%~dp0yazx.cmd" (
    start "" "%~dp0yazx.cmd"
    echo   Yazx launched!
) else (
    echo   yazx.cmd not found in %~dp0 - place files and retry.
)
echo.
pause
