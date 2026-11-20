# YAZX Setup

Complete system restoration tool for Windows 11 IoT Enterprise LTSC 2024.  
One-click restore of all tweaks, programs, and configurations after a fresh install.

## System Specs
- **OS**: Windows 11 IoT Enterprise LTSC 2024 (Build 26100)
- **GPU**: NVIDIA GeForce RTX 3060 12GB
- **Tweaks**: TTCH + Oneclick (QuakedK) + YAZX

## Quick Start

1. Fresh install Windows 11 IoT Enterprise LTSC 2024
2. Copy `E:\YAZX_Backup` folder to E: drive
3. Clone this repo or copy to any location
4. Right-click `YAZX_Setup.bat` → Run as Administrator
5. Press `A` to run all modules, or select individual modules

## Modules (ordered by risk - lowest first)

| # | Module | Description |
|---|--------|-------------|
| 01 | System Check | Verify OS, GPU, RAM compatibility |
| 02 | NVIDIA Driver | NVCleanInstall guide + Profile Inspector |
| 03 | Programs | Install all applications |
| 04 | Configs | Restore Process Lasso, MSI Afterburner, EQ APO, etc. |
| 05 | Registry - Cosmetic | Explorer, Shell, UI tweaks |
| 06 | Registry - Gaming | GPU, MMCSS, Memory, Priority, Mouse, Keyboard |
| 07 | Registry - Network | TCP/IP, Nagle, Adapter optimization |
| 08 | Services | Disable unnecessary Windows services |
| 09 | BCD Tweaks | Timer configuration (useplatformtick, disabledynamictick) |
| 10 | MSI Mode | Message Signaled Interrupts on 7 devices |
| 11 | Power Plan | YAZX Ultimate Performance (QuakedK method) |
| 12 | Privacy | Telemetry disable, tracking cleanup |
| 13 | Oneclick | Run [QuakedK's Oneclick](https://github.com/QuakedK/Oneclick) **LAST** |

## Key Tweaks Applied

### Gaming Performance
- Win32PrioritySeparation = 0x26 (FPS Preset)
- MMCSS: SystemResponsiveness=0, NetworkThrottling=disabled
- Hardware GPU Scheduling enabled
- MPO disabled
- Mouse: 1:1 raw input, no acceleration
- GameDVR disabled

### NVIDIA
- NVCleanInstall (minimal driver, no telemetry)
- NVIDIA Profile Inspector with YAZX profile (Performances.nip)
- NVIDIA Containers disabled
- TdrDelay = 60s

### Network
- TCP auto-tuning disabled (TTCH Gaming Mode)
- Nagle algorithm disabled
- QoS throttle removed
- DNS cache optimized

### Timer Resolution
- TTCH Timer Resolution Service (STR)
- BCD: useplatformtick=yes, disabledynamictick=yes, tscsyncpolicy=Enhanced
- GlobalTimerResolutionRequests enabled

### Process Lasso
- 70+ game priority rules
- ProBalance configured
- CPU affinity optimization

## Backup Structure (E:\YAZX_Backup)

49 folders, 26,933 files, 7.22 GB — complete system state backup including:
- Full program installations
- All registry exports
- All user configs and profiles
- Pre-tweak registry hives (Tron backup from 2026-08-11)
- Post-tweak registry backup (PC_Backup from 2026-08-13)
- TTCH Timer Resolution service
- Oneclick Backup (QuakedK's backups)

## Credits
- [QuakedK/Oneclick](https://github.com/QuakedK/Oneclick) - Base debloat and optimization
- TTCH - Timer Resolution, Gaming Mode
- YAZX - Custom configs, game rules, automation

## Important Notes
- **Run Oneclick LAST** — it's the most invasive module
- **Backup folder required** on E: for full program restoration
- **NVCleanInstall** must be downloaded separately (not redistributable)
- All tweaks are reversible via the backup .reg files in `E:\YAZX_Backup`
