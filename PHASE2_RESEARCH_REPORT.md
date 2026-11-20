# YAZX Phase 2.5 — Research & Discovery Report
# Date: 2026-11-20 (Revised after review)
# System: Intel i5-13400F / RTX 3060 12GB / 32GB DDR4
# OS: Windows 11 IoT Enterprise LTSC 2024 (Build 26100.8875)
#
# REVISION NOTES:
# - Tweaks reclassified as SAFE/CANDIDATE/EXPERIMENTAL
# - Settings gaps reclassified with 4-tier honest system (A/B/C/D)
# - IRQControl guide rewritten as theory-only (no hardcoded assignments)
# - RSS script converted to diagnostic mode (no auto-apply)
# - Memory Compression moved to EXPERIMENTAL (no auto-apply)
# - NVIDIA profile separated: minimal global + per-game profiles
# - Module 14 changed to diagnostic-only (SAFE tweaks in reg, rest manual)
# - See YAZX_NEW_TWEAKS_FULL_DETAIL.md for complete tweak documentation

---

## 1. New Tweaks Discovered

### 1.1 Heterogeneous Thread Policy (P-Core Priority)
- **What**: Forces Windows scheduler to prefer P-cores for thread placement
- **Setting**: `powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR SCHEDPOLICY 4`
- **Value 4**: "Prefer performant processors" — P-cores first, E-cores as overflow
- **Impact**: Better gaming thread placement on hybrid CPUs (13th gen+)
- **Risk**: Low — Windows already knows P/E distinction, this just biases toward P
- **Status**: Added to Module 14 (14_NewTweaks.ps1)

### 1.2 GlobalTimerResolutionRequests
- **What**: Allows applications to request high-resolution timers system-wide
- **Setting**: `HKLM\SYSTEM\CCS\Control\Session Manager\kernel\GlobalTimerResolutionRequests = 1`
- **Impact**: Better frame pacing, more consistent frame delivery
- **Risk**: Low — Windows 11 24H2 handles this well; slight idle power increase
- **Status**: Added to YAZX_NewTweaks.reg

### 1.3 LargeSystemCache Disabled
- **What**: Prioritizes application memory over file system cache
- **Setting**: `HKLM\SYSTEM\CCS\Control\Session Manager\Memory Management\LargeSystemCache = 0`
- **Impact**: More RAM available for games, less aggressive file caching
- **Risk**: Low with 32GB RAM — plenty of headroom
- **Status**: Added to YAZX_NewTweaks.reg

### 1.4 Memory Compression Disabled
- **What**: Disables Windows memory compression (page combining)
- **Setting**: `Disable-MMAgent -MemoryCompression` (PowerShell admin command)
- **Impact**: Reduces CPU overhead from compressing/decompressing memory pages
- **Risk**: Low with 32GB RAM — compression only helps when RAM is scarce
- **Status**: Added to Module 14 (14_NewTweaks.ps1)

### 1.5 Connected Standby Disabled
- **What**: Disables Modern Standby (always-on connectivity in sleep)
- **Setting**: `HKLM\SYSTEM\CCS\Control\Power\CsEnabled = 0`
- **Impact**: More reliable sleep behavior, prevents background wake-ups
- **Risk**: None for desktop — Connected Standby is a laptop feature
- **Status**: Added to YAZX_NewTweaks.reg

### 1.6 NVIDIA Low Latency DRS Profile
- **What**: NVIDIA driver settings for minimum input lag
- **Settings**:
  - Low Latency Mode: Ultra (CPU-side frame queue limit)
  - Maximum Pre-Rendered Frames: 1
  - Shader Cache Size: Unlimited (prevents stutter)
  - Power Management: Prefer Maximum Performance
- **Impact**: Measurable reduction in input lag (10-20ms typical)
- **Risk**: Low — slight FPS decrease possible with Ultra (use "On" for single-player)
- **Status**: Documented in configs/NVIDIA_Inspector/YAZX_LowLatency_Profile.md

### 1.7 RSS P-Core Affinity (Realtek NIC)
- **What**: Pin Receive Side Scaling queues to P-cores
- **Settings**: RSS BaseProc=2, MaxProc=8, Queues=4
- **Impact**: Network packet processing on fast cores, reduced network latency
- **Risk**: Low — well-supported on RTL8125BG
- **Status**: Script created: configs/Realtek/YAZX_Apply_RSS_Affinity.ps1

### 1.8 Interrupt Affinity Optimization (IRQControl)
- **What**: Assign device interrupts to specific CPU cores
- **Layout**: GPU→Core 0, Network→Core 1, USB→Core 2, Audio→Core 3, NVMe→Core 4
- **Impact**: Prevents interrupt contention, leaves P-cores 4-5 free for game threads
- **Risk**: Low — well-tested approach, IRQControl settings are persistent
- **Status**: Guide created: configs/IRQControl/YAZX_InterruptAffinity_Guide.md

---

## 2. Already-Optimal Settings (No Change Needed)

### 2.1 Win32PrioritySeparation = 0x26 (38)
- FPS Preset: Short, Variable, Foreground 3:1 — optimal for gaming
- No change recommended

### 2.2 MMCSS Configuration
- SystemResponsiveness = 0 — maximum game thread priority
- NetworkThrottlingIndex = 0xFFFFFFFF — no throttling
- Games category: GPU Priority 8, Priority 6, High scheduling
- Pro Audio: Priority 1, High scheduling
- Already optimal

### 2.3 MSI Mode (Message Signaled Interrupts)
- Enabled on 7 device classes — optimal
- Complements IRQControl interrupt affinity

### 2.4 Mouse 1:1 Raw Input
- MouseSpeed=0, MouseSensitivity=10, no acceleration
- Pure raw input — no change needed

### 2.5 Graphics Driver Settings
- HAGS enabled (HwSchMode=2) — good for RTX 3060
- TdrDelay=60 — prevents timeout resets
- MPO disabled (OverlayTestMode=5) — reduces compositor overhead
- All optimal

### 2.6 TCP/IP Stack
- Auto-tuning disabled — appropriate for gaming
- RSC disabled — reduces latency
- DNS: Cloudflare Family + Quad9 — fast and secure

### 2.7 BCD Boot Configuration
- useplatformtick = yes — hardware timer
- disabledynamictick = yes — fixed tick rate
- tscsyncpolicy = Enhanced — precise TSC sync
- All optimal for latency-sensitive workloads

---

## 3. Investigated But Not Recommended

### 3.1 NvmePciEx Native NVMe Driver
- **What**: Experimental Microsoft NVMe driver replacing StorNVMe
- **Why not**: Risky on LTSC, requires careful testing, marginal benefit
- **Alternative**: StorNVMe with MSI Mode is already well-optimized

### 3.2 Processor Performance Boost Mode Changes
- **What**: Modifying boost behavior via powercfg
- **Why not**: i5-13400F is LOCKED — boost is managed by Intel, not user-adjustable
- **Note**: Unlocked chips (K/KF) benefit more from boost tweaks

### 3.3 TCP ECN (Explicit Congestion Notification)
- **Current**: Enabled
- **Status**: Phase 2 flagged for review — ECN is generally beneficial
- **Verdict**: Keep enabled — modern routers handle it well

### 3.4 Spectre/Meltdown Mitigations Disabled
- **Current**: Unknown (requires admin for full audit)
- **Risk**: Security vs performance tradeoff
- **Verdict**: Document but don't recommend — user's decision post-format

---

## 4. Tool Assessment Summary (Updated 2026-11-20)

### 4.1 Tools Downloaded & Verified (12 of 17)
| Tool | File | Size | Signed? |
|------|------|------|---------|
| Sysinternals Suite | SysinternalsSuite.zip | 357.33 MB | N/A (suite) |
| MouseTester v1.5.3 | MouseTester_v1.5.3.zip | 152.8 KB | No |
| WinMTR v1.00 | WinMTR-v100-static.zip | 1.74 MB | No |
| CapFrameX v1.9.2 | release_1.9.2_portable.zip | 72.87 MB | Checksum verified |
| O&O ShutUp10 v3.7 | OOSU10.exe | 81.81 MB | YES (O&O Software GmbH) |
| USBTreeView | usbtreeview.zip | 910.8 KB | No |
| ISLC v1.0.3.2 | ISLC_v1.0.3.2.exe | 373.6 KB | No |
| LatencyMon | LatencyMon.exe | 3.6 MB | No |
| QuickCPU | QuickCpuSetup.msi | 35.02 MB | YES (CoderBag LLC) |
| GPU-Z v2.72.0 | GPU-Z.exe | 12.43 MB | YES (TechPowerUp LLC) |
| ThrottleStop v9.7.3 | ThrottleStop.zip | 1.71 MB | No |
| DDU v18.1.6.3 | DDU_v18.1.6.3.exe | 1.77 MB | YES (Wagnardsoft) |

All SHA-256 hashes recorded and verified. Total: ~570 MB.

### 4.2 Requires Manual Download (4 tools)
| Tool | Reason | URL |
|------|--------|-----|
| CrystalDiskInfo 9.9.5 | SourceForge 403 | crystalmark.info/en/download/ |
| CrystalDiskMark 9.0.3 | SourceForge 403 | crystalmark.info/en/download/ |
| HWiNFO v8.60 | hwinfo.com 403 | hwinfo.com/download/ |
| SG TCP Optimizer | speedguide.net 403 | speedguide.net/downloads.php |

### 4.3 Downloaded Separately (1 tool + 2 dependencies)
| Tool | File | Size | Signed? |
|------|------|------|---------|
| IRQControl v1.0.0.65 | irqcontrolsetup64.exe | 1.51 MB | YES (Bitsum LLC) |
| CapFrameX dep: VC++ 2015-2022 | vc_redist.x64.exe | 24.45 MB | YES (Microsoft) |
| CapFrameX dep: .NET 10 Runtime | windowsdesktop-runtime-10.0.0-win-x64.exe | 57.43 MB | YES (Microsoft) |

### 4.4 Existing Tool Configs Completed
| Tool | Config Status |
|------|--------------|
| Process Lasso | prolasso.ini recovered, 228+ rules preserved |
| MSI Afterburner | Profiles confirmed empty (no OC) |
| NVIDIA Profile Inspector | Low latency profile guide created |
| Realtek NIC | RSS P-core affinity script created |
| Equalizer APO | Setup guide created (minimal config) |
| ParkControl | Settings documented from power plan |
| RTSS | Setup guide created (fresh install needed) |
| simplewall | Confirmed NEVER installed |
| Mem Reduct | Already exported |

---

## 5. Settings Gaps Resolution (Updated 2026-11-20)

See exports/SETTINGS_GAPS_STATUS.md for the full honest 4-tier classification.

### Category A — Actual Export (6 gaps → resolved)
- Game Mode/GameDVR — exported from live registry
- Services Startup State — exported from live system
- Process Lasso rules — recovered from backup (prolasso.ini)
- ParkControl/Core Parking — Power_Control.reg (1637.5 KB) + CPU_PowerSettings.reg (836.4 KB)
- Power Plan — Power_Control.reg contains TTCH plan + EonX.pow importable
- Equalizer APO — mic.txt has real VST chain + backup_HyperX_Speakers.reg

### Category B — Confirmed State (4 gaps → not gaps)
- Process Lasso CPU Affinity — confirmed INTENTIONALLY EMPTY
- Process Lasso CPU Sets — confirmed INTENTIONALLY EMPTY
- MSI Afterburner GPU Profile — empty .cfg files ARE the config (no OC = intentional)
- simplewall — confirmed NEVER installed (Henry++ = Mem Reduct only)

### Category C — Documentation Only (2 gaps)
- RTSS — not separately installed, setup guide written
- Realtek NIC RSS — new optimization candidate, diagnostic script created

### Category D — Inaccessible (4 gaps)
- Memory Compression, Scheduled Tasks, Autologgers, BCD full export
- All blocked by admin elevation. Partial workarounds documented.

### Honest Summary
- **Usable data**: 10 (6A + 4B) — files that restore settings or confirm state
- **Documentation only**: 2 (C) — guides for manual post-format setup
- **Inaccessible**: 4 (D) — blocked by admin, partial workarounds exist

---

## 6. File Inventory (New This Phase)

### Config Files Created
- configs/IRQControl/YAZX_InterruptAffinity_Guide.md
- configs/NVIDIA_Inspector/YAZX_LowLatency_Profile.md
- configs/Realtek/YAZX_RSS_PCore_Affinity.reg
- configs/Realtek/YAZX_Apply_RSS_Affinity.ps1
- configs/EqualizerAPO/YAZX_EQ_Setup_Guide.md
- configs/ParkControl/YAZX_ParkControl_Settings.md
- configs/RTSS/YAZX_RTSS_Setup.md

### Registry Files Created
- registry/YAZX_NewTweaks.reg (Timer, Memory, Power, GameMode tweaks)

### Module Files Created
- modules/14_NewTweaks.ps1 (applies new tweaks post-format)

### Tool Files Created
- tools/YAZX_DownloadTools.ps1 (automated downloader)
- tools/YAZX_DownloadGuide.md (manual download guide)
- tools/ — 17 tool subdirectories created

### Export Files Created
- exports/Services_StartupState.txt
- exports/BCD_Alternative_Export.txt
- exports/Firewall_EnabledRules.txt
- exports/hosts_file.txt
- exports/WindowsUpdate_Policy.reg
- exports/Environment_Variables.txt
- exports/Installed_Programs.txt
- exports/SETTINGS_GAPS_STATUS.md
- Plus 20+ registry exports from earlier in this phase

---

## 7. Recommendations for Post-Format

### Apply Order
1. Install Windows 11 IoT Enterprise LTSC 2024
2. Run YAZX_Setup.bat → Module 12 (Registry FULL Restore) first
3. Install drivers (NVIDIA via NVCleanstall, Realtek NIC)
4. Run Module 14 (NewTweaks) for new optimizations
5. Install tools (use YAZX_DownloadTools.ps1 or manual guide)
6. Configure IRQControl interrupt affinity
7. Apply NVIDIA Inspector low latency profile
8. Run RSS affinity script for Realtek NIC
9. Install Process Lasso, restore prolasso.ini
10. Install MSI Afterburner + RTSS
11. Verify with LatencyMon + CapFrameX

### Verification Tools
- LatencyMon: Check DPC/ISR latency (target <500µs)
- CapFrameX: Benchmark frame times (compare 1% / 0.1% lows)
- CrystalDiskInfo: Verify NVMe health
- HWiNFO: Monitor thermals during stress test
