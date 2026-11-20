# YAZX Phase 2.5 — Extended Tweak Research
# Beyond the original 8 tweaks — additional optimization candidates
# System: i5-13400F / RTX 3060 12GB / Win11 IoT LTSC 2024
# Date: 2026-11-20
#
# CONSTRAINTS:
# - DO NOT apply any tweak to current Windows
# - Research only — document current state, proposed change, risk
# - Keep current and alternative SEPARATE
# - Don't promote experimental tweaks to auto-apply

---

## Already Documented (8 tweaks in YAZX_NEW_TWEAKS_FULL_DETAIL.md)

| # | Tweak | Classification |
|---|-------|---------------|
| 1 | CsEnabled=0 (Connected Standby off) | SAFE |
| 2 | Game Mode enabled | SAFE |
| 3 | GameDVR disabled | SAFE |
| 4 | GlobalTimerResolutionRequests=1 | CANDIDATE |
| 5 | LargeSystemCache=0 | CANDIDATE |
| 6 | Memory Compression disabled | EXPERIMENTAL |
| 7 | Heterogeneous Thread Policy=4 | CANDIDATE |
| 8 | PCIe ASPM off | CANDIDATE |

## DISCOVERED — Existing Kernel Tweaks (from yazx_TweakRegistry\Kernel.reg)

These settings were ALREADY applied on the current system but were NOT
previously documented. They MUST be preserved post-format.

| Setting | Current Value | What it Does |
|---------|--------------|-------------|
| GlobalTimerResolutionRequests | 1 | Allows apps to request high-res timers (documented as Tweak #4) |
| SerializeTimerExpiration | 2 | Distributes timer expiration across all CPUs — reduces DPC contention |
| DistributeTimers | 1 | Distributes software timers across CPUs — reduces single-core timer load |
| DpcWatchdogProfileOffset | 0x2710 (10000) | Extended DPC watchdog period (10 seconds) |
| DynamicHeteroCpuPolicyMask | 3 | Mask for heterogeneous CPU scheduling policy |
| DefaultDynamicHeteroCpuPolicy | 3 | Default dynamic hetero CPU policy (Automatic) |
| DynamicHeteroCpuPolicyImportant | 1 | Important threads use specific hetero policy |
| DynamicHeteroCpuPolicyImportantShort | 1 | Short important threads use hetero policy |
| DynamicHeteroCpuPolicyImportantPriority | 8 | Priority threshold for P-core preference |
| EnablePerCpuClockTickScheduling | 2 | Per-CPU clock tick scheduling optimization |
| TimerCheckFlags | 0 | Timer check disabled |

**FileSystem settings already in place:**
- NtfsDisable8dot3NameCreation = 2 (per-volume, partially optimized)
- NtfsDisableLastAccessUpdate = 0x80000002 (disabled, optimal)
- LongPathsEnabled = 1 (good)
- DisableDeleteNotification = 0 (TRIM enabled, good for SSD/NVMe)

**All these are preserved in:** exports/TweakRegistry/Kernel.reg and FileSystem.reg

---

## Already Optimal (no change needed — from Phase 2 audit)

| Setting | Current Value | Why Optimal |
|---------|--------------|-------------|
| Win32PrioritySeparation | 0x26 (38) | FPS Preset: Short, Variable, Foreground 3:1 |
| MMCSS SystemResponsiveness | 0 | Maximum game thread priority |
| MMCSS NetworkThrottlingIndex | 0xFFFFFFFF | No throttling |
| MSI Mode | 7 devices | Interrupt optimization already maxed |
| Mouse 1:1 raw input | MouseSpeed=0, Sensitivity=10 | Pure raw input |
| HAGS | HwSchMode=2 | Good for RTX 3060 |
| TdrDelay | 60 | Prevents timeout resets |
| MPO disabled | OverlayTestMode=5 | Reduces compositor overhead |
| TCP auto-tuning | Disabled | Appropriate for gaming |
| RSC | Disabled | Reduces latency |
| BCD tick settings | useplatformtick, disabledynamictick | Fixed tick rate |
| TSC sync | Enhanced | Precise timing |
| USB Selective Suspend | 0 (disabled) in TTCH plan | No USB power saving |
| TCPNoDelay | 1 (Nagle disabled) | No TCP write delay |
| Hibernate | Disabled (all 3 keys) | No hibernate overhead |
| Modern Standby | MSDisabled=1 | Already off |

---

## NEW TWEAKS — CPU Scheduling & Thread Management

### Tweak 9: Thread DPC Redirection
- **Registry**: `HKLM\SYSTEM\CCS\Control\Session Manager\kernel\ThreadDpcEnable = 1`
- **Current**: Not set (using default = 0)
- **Proposed**: 1
- **What it does**: Enables Threaded DPCs, allowing Deferred Procedure Calls to run
  as schedulable threads rather than at DISPATCH_LEVEL. This means DPCs can be
  preempted by higher-priority threads (like game threads).
- **Why for gaming**: DPCs from device drivers (NIC, audio, storage) can delay
  game thread execution when they run at DISPATCH_LEVEL. Threaded DPCs run at
  lower priority and can be preempted.
- **Risk**: LOW — Windows 11 handles threaded DPCs well. Some very old drivers
  may not be compatible, but all current drivers on this system are modern.
- **Compatibility**: Windows 10 2004+ and all Windows 11.
- **Restore**: Delete the value or set to 0.
- **Classification**: CANDIDATE — requires DPC latency testing (LatencyMon)

### Tweak 10: Processor Idle Disable
- **Power plan**: `powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR IDLEDISABLE 1`
- **Current**: Unknown (not visible in text export; likely 0 = idle states enabled)
- **Proposed**: 1
- **What it does**: Prevents processor from entering C-states (idle states).
  CPU stays at maximum frequency at all times.
- **Why for gaming**: Eliminates C-state exit latency (microseconds per transition).
  Prevents the brief frequency ramp-up delay when load arrives.
- **Risk**: MEDIUM — Increases power consumption and heat significantly.
  Desktop with adequate cooling: safe. NOT recommended for thermal-limited systems.
  With i5-13400F at stock: power draw increases ~10-20W at idle.
- **Compatibility**: All x86 processors. i5-13400F is LOCKED so no thermal risk
  from boost beyond spec.
- **Restore**: `powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR IDLEDISABLE 0`
- **Classification**: EXPERIMENTAL — significant power/heat tradeoff

---

## NEW TWEAKS — Network Optimization

### Tweak 11: TcpAckFrequency Consistency Fix
- **Registry**: Per-interface under `HKLM\SYSTEM\CCS\Services\Tcpip\Parameters\Interfaces\{GUID}`
- **Current**: INCONSISTENT
  - Some interfaces: TcpAckFrequency=8 (ACK every 8th packet — HIGH latency)
  - One interface: TcpAckFrequency=1 (ACK every packet — optimal)
- **Proposed**: TcpAckFrequency=1 on ALL active interfaces (especially the
  Realtek Gaming 2.5GbE adapter's interface GUID)
- **What it does**: Controls how many TCP segments the receiver waits for before
  sending an ACK back. Value of 1 = immediate ACK = lowest network latency.
  Value of 8 means receiver waits for 8 segments, adding 7 segments worth of
  delay before the sender knows its data arrived.
- **Why for gaming**: Online games send many small TCP packets. Delayed ACKs
  increase effective RTT. TcpAckFrequency=1 is the universal gaming recommendation.
- **Risk**: NONE — This fixes an inconsistency. TcpAckFrequency=1 is strictly
  better for latency-sensitive workloads. Very slight increase in ACK overhead
  (negligible on 2.5GbE).
- **Compatibility**: All Windows versions. The Realtek RTL8125BG driver supports it.
- **Restore**: Delete TcpAckFrequency values (reverts to default = 2).
- **Classification**: SAFE — this is a bug fix, not an experiment
- **NOTE**: The interface GUID changes after format. Must find the new Realtek
  adapter GUID post-format before applying.

### Tweak 12: AFD PriorityBoost Enable
- **Registry**: `HKLM\SYSTEM\CCS\Services\AFD\Parameters\PriorityBoost = 1`
- **Current**: 0 (disabled)
- **Proposed**: 1
- **What it does**: When enabled, AFD (Ancillary Function Driver — Windows' Winsock
  kernel driver) temporarily boosts thread priority when processing I/O completion
  port operations. This helps network-heavy threads get scheduled faster.
- **Why for gaming**: Game networking threads often use I/O completion ports.
  Priority boost means the game thread processes incoming network data sooner.
- **Risk**: NONE — This is a minor scheduling hint. The boost is temporary and
  the system recovers naturally.
- **Compatibility**: All Windows versions.
- **Restore**: Set to 0.
- **Classification**: SAFE

### Tweak 13: AFD Buffer Size Investigation
- **Registry**: `HKLM\SYSTEM\CCS\Services\AFD\Parameters`
- **Current**:
  - DefaultSendWindow=0x00065535 (hex) = 415,029 bytes (~405 KB)
  - DefaultReceiveWindow=0x00065535 (hex) = 415,029 bytes (~405 KB)
- **FINDING**: These values appear to be a MISTAKE. The standard TCP window size
  is 65,535 bytes (0x0000FFFF). It looks like someone wrote the DECIMAL value
  "65535" directly into a DWORD field that expects HEX, resulting in 0x65535 =
  415,029 bytes — roughly 6.3x larger than intended.
- **Impact**: Larger buffers = more memory used for each socket, but no latency
  penalty. With 32GB RAM, the extra memory is negligible. The larger buffers
  might actually help high-throughput scenarios.
- **Proposed**: Document but DO NOT CHANGE. The current values work and changing
  them could break the tweaker's other optimizations.
- **Classification**: DOCUMENTED — keep as-is, note the quirk

---

## NEW TWEAKS — Storage Optimization

### Tweak 14: NVMe IoTimeoutValue
- **Registry**: `HKLM\SYSTEM\CCS\Services\stornvme\Parameters\IoTimeoutValue`
- **Current**: 10 (0x0A) — 10 seconds
- **Proposed**: NO CHANGE
- **Reason**: This is the standard Microsoft default. Some guides recommend lowering
  to 5 for "faster error detection" but this INCREASES the risk of false timeouts
  during heavy NVMe loads (shader cache writes, game asset loading). The Lexar
  NM710 is a consumer NVMe that can have occasional latency spikes during garbage
  collection. Keep at 10.
- **Classification**: OPTIMAL — no change needed

### Tweak 15: NTFS 8.3 Short Name Disable
- **Command**: `fsutil behavior set disable8dot3 1` (admin required, post-format)
- **Current**: Not set (default = enabled per-volume)
- **Proposed**: 1 (disabled)
- **What it does**: Prevents NTFS from creating 8.3-format short filenames
  (legacy DOS compatibility). Every file creation normally generates two entries.
- **Why for gaming**: Slight reduction in NTFS metadata writes and directory
  enumeration time. Noticeable on directories with thousands of files (shader caches,
  mod folders, temp directories).
- **Risk**: NONE on modern software. Only ancient 16-bit applications need 8.3 names.
  Games, Steam, and all modern tools work with long filenames only.
- **Compatibility**: All NTFS volumes. Windows 11 IoT LTSC 2024 fully supports it.
- **Restore**: `fsutil behavior set disable8dot3 0`
- **Classification**: SAFE — zero risk, minor benefit

### Tweak 16: NTFS Memory Usage
- **Registry**: `HKLM\SYSTEM\CCS\Control\FileSystem\NtfsMemoryUsage = 2`
- **Current**: Not set (default = 1)
- **Proposed**: 2
- **What it does**: Increases the paged pool memory NTFS uses for read-ahead and
  write-behind operations. With 32GB RAM, Windows can afford to give NTFS more
  memory for caching metadata.
- **Why for gaming**: Faster file system operations during asset loading. The game
  loads thousands of small files; more NTFS memory = faster metadata lookups.
- **Risk**: LOW — Uses slightly more kernel memory. With 32GB total RAM, the
  increase is negligible. NOT the same as LargeSystemCache (which controls
  user-space caching priority).
- **Compatibility**: All NTFS volumes, all Windows versions.
- **Restore**: Delete value or set to 1.
- **Classification**: CANDIDATE

---

## NEW TWEAKS — DPC/ISR & Interrupt Optimization

### Tweak 17: DpcWatchdogProfileOffset
- **Registry**: `HKLM\SYSTEM\CCS\Control\Session Manager\kernel\DpcWatchdogProfileOffset`
- **Current**: Not set (default varies by HAL)
- **Proposed**: NO CHANGE
- **Reason**: Adjusting the DPC watchdog timer masks real latency problems rather
  than solving them. If DPC latency is high, the solution is MSI Mode + interrupt
  affinity (already configured), not extending the watchdog period.
- **Classification**: NOT RECOMMENDED — masks issues

### Tweak 18: Interrupt Affinity Policy for Audio
- **Registry**: Per-device under HKLM\SYSTEM\CCS\Enum\{device}\Device Parameters\
  Interrupt Management\Affinity Policy
- **Current**: Default (system-assigned)
- **Proposed**: Pin audio interrupt to dedicated P-core (via IRQControl post-format)
- **What it does**: Forces the audio driver's interrupts to a specific P-core,
  preventing them from being processed on E-cores (which have higher latency)
  or on the same core as the game's main thread.
- **Why for gaming**: audiodg.exe is already HIGH priority in Process Lasso. Pinning
  its interrupts to a dedicated P-core (e.g., Core 3) ensures consistent audio
  processing without contention.
- **Risk**: NONE — well-tested approach, documented in IRQControl guide.
- **Classification**: Already in IRQControl guide — not a new tweak

---

## NEW TWEAKS — Windows Background Reduction

### Tweak 19: Delivery Optimization Disable (LTSC)
- **Registry**: `HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization\DODownloadMode = 0`
- **Current**: Not found in exports (may be using default)
- **Proposed**: 0 (HTTP only, no P2P)
- **What it does**: Prevents Windows Update from using peer-to-peer distribution.
  Mode 0 = download from Microsoft only. Default mode allows P2P with LAN and
  sometimes Internet peers, consuming bandwidth.
- **Why for gaming**: Eliminates background P2P upload/download during gameplay.
  LTSC receives minimal updates anyway, so P2P savings are negligible.
- **Risk**: NONE — LTSC doesn't benefit from P2P (infrequent updates, no
  Microsoft Store). Updates still work via HTTP.
- **Compatibility**: Windows 10/11 all versions.
- **Restore**: Delete value (reverts to default P2P mode).
- **Classification**: SAFE

### Tweak 20: SvcHost Split Threshold
- **Registry**: `HKLM\SYSTEM\CCS\Control\SvcHostSplitThresholdInKB`
- **Current**: Not found in exports (using default = auto-calculated from RAM)
- **Default with 32GB**: Very high threshold = many svchost.exe instances (~80+)
- **Proposed**: NO CHANGE
- **Reason**: The common "optimization" of reducing svchost.exe count is a myth.
  Splitting services into individual processes improves reliability (one crash
  doesn't take down others) with negligible memory cost on 32GB. The ~2-3 MB per
  extra process is irrelevant. CPU overhead of context switching is also negligible.
- **Classification**: NOT RECOMMENDED — myth-based "optimization"

### Tweak 21: Background Apps Disable
- **Registry**: `HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications\GlobalUserDisabled = 1`
- **Current**: Likely already set (BackgroundApps.reg exported, 3.5 KB)
- **Proposed**: Verify = 1
- **What it does**: Prevents UWP apps from running in the background. Reduces
  CPU wakes, memory usage, and network activity from background apps.
- **Why for gaming**: LTSC has fewer UWP apps, but some may still run (Settings,
  Calculator, etc.). Disabling background access reduces context switches.
- **Risk**: NONE on LTSC — minimal UWP app usage.
- **Compatibility**: Windows 10 1709+, all Windows 11.
- **Restore**: Set to 0 or delete.
- **Classification**: SAFE — verify current state post-format

---

## NEW TWEAKS — GPU Optimization

### Tweak 22: NVIDIA Shader Cache Location
- **Current**: Default (C:\Users\<user>\AppData\Local\NVIDIA\DXCache)
- **Proposed**: Move shader cache to NVMe drive root (e.g., D:\ShaderCache)
- **What it does**: Relocates NVIDIA's shader compilation cache to a dedicated
  folder on the fastest drive.
- **Why for gaming**: If the system drive gets fragmented, shader cache access
  slows. A dedicated location on the NVMe keeps access fast and makes cleanup
  easier.
- **Risk**: NONE — purely a path change. If the folder doesn't exist, NVIDIA
  recreates it.
- **How**: NVIDIA Profile Inspector → Global → Shader Cache Size = Unlimited,
  or via environment variable `__GL_SHADER_DISK_CACHE_PATH`
- **Classification**: CANDIDATE — minor benefit, clean organization

### Tweak 23: GPU Preemption Level
- **Registry**: NVIDIA-specific DRS settings
- **Current**: Default (fine-grained preemption)
- **Proposed**: NO CHANGE
- **Reason**: GPU preemption level changes are highly game-specific and can cause
  more problems than they solve. The RTX 3060 handles preemption well with the
  default settings. Only competitive titles with known preemption issues benefit
  from changes, and those should be per-game profile adjustments (already
  documented in NVIDIA Inspector guide).
- **Classification**: NOT RECOMMENDED — per-game only if needed

---

## NEW TWEAKS — Memory & Pagefile

### Tweak 24: Fixed Pagefile Size
- **Current**: System-managed (auto-sized)
- **Proposed**: Fixed size = 8192 MB (8 GB) on NVMe
- **What it does**: Sets a fixed pagefile size instead of letting Windows auto-manage.
  Prevents pagefile fragmentation and size changes during gameplay.
- **Why for gaming**: With 32GB RAM, the pagefile is rarely used but some games
  and anti-cheat systems require it. A fixed size prevents Windows from resizing
  it during gameplay (which can cause a brief stutter).
- **Risk**: LOW — 8GB is generous for a 32GB system. The only risk is if a
  workload needs more than 32GB+8GB combined (extremely unlikely for gaming).
- **How**: System Properties → Performance → Virtual Memory → Custom Size
  Initial=8192 Maximum=8192 on the NVMe drive.
- **Classification**: CANDIDATE — minor stutter prevention

---

## SUMMARY — Extended Tweaks

### New SAFE tweaks (3)
| # | Tweak | Why |
|---|-------|-----|
| 11 | TcpAckFrequency=1 (fix inconsistency) | Fixes existing bug — some interfaces at 8 |
| 12 | AFD PriorityBoost=1 | Zero-risk scheduling hint for network threads |
| 19 | Delivery Optimization off | LTSC doesn't need P2P updates |

### New CANDIDATE tweaks (4)
| # | Tweak | Why |
|---|-------|-----|
| 9 | ThreadDpcEnable=1 | DPCs as schedulable threads |
| 15 | NTFS 8.3 name disable | Minor filesystem improvement |
| 16 | NtfsMemoryUsage=2 | More NTFS cache for asset loading |
| 24 | Fixed pagefile 8GB | Prevents pagefile resize stutter |

### New EXPERIMENTAL tweaks (1)
| # | Tweak | Why |
|---|-------|-----|
| 10 | Processor Idle Disable | Eliminates C-state latency but HIGH power cost |

### NOT RECOMMENDED (3)
| # | Tweak | Why |
|---|-------|-----|
| 17 | DpcWatchdogProfileOffset | Masks real issues |
| 20 | SvcHostSplitThreshold | Myth-based optimization |
| 23 | GPU Preemption Level | Per-game only, risky globally |

### DOCUMENTED — No Change (2)
| # | Tweak | Why |
|---|-------|-----|
| 13 | AFD Buffer sizes | Quirky but functional, don't break |
| 14 | NVMe IoTimeoutValue | Default is correct |

### Already Covered (3)
| # | Tweak | Why |
|---|-------|-----|
| 18 | Audio interrupt affinity | In IRQControl guide |
| 21 | Background apps | Verify post-format, likely already set |
| 22 | Shader cache location | Minor, organizational |

---

## GRAND TOTAL — All Tweaks

| Classification | Original 8 | Extended | Total |
|---------------|-----------|----------|-------|
| SAFE | 3 | 3 | **6** |
| CANDIDATE | 4 | 4 | **8** |
| EXPERIMENTAL | 1 | 1 | **2** |
| NOT RECOMMENDED | — | 3 | 3 |
| DOCUMENTED ONLY | — | 2 | 2 |
| **Actionable Total** | **8** | **8** | **16** |

The 16 actionable tweaks (6 SAFE + 8 CANDIDATE + 2 EXPERIMENTAL) are what
YAZX should prepare for post-format application. The 5 NOT RECOMMENDED and
DOCUMENTED items are recorded for completeness only.
