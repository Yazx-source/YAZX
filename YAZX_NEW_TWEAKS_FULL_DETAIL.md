# YAZX Phase 2.5 — All 8 New Tweaks: Full Detail
# Each tweak: name, explanation, source, compatibility, risk, restore method

---

## Tweak 1: Connected Standby Disabled (CsEnabled = 0)

**Registry**: `HKLM\SYSTEM\CurrentControlSet\Control\Power\CsEnabled = 0`

**What it does**: Disables Modern Standby (Connected Standby), which keeps
the system in a low-power connected state during sleep, allowing background
network activity (email sync, app updates, etc.).

**Why for gaming**: On desktops, Connected Standby serves no purpose. It can
cause unexpected wake-ups, background CPU activity, and inconsistent sleep
behavior. Disabling it gives clean S3 sleep instead.

**Source**: Microsoft documentation on Modern Standby power management. Widely
recommended in LTSC/IoT gaming optimization guides.

**Compatibility**: Windows 10/11 all versions. Specifically tested on LTSC 2024
Build 26100. No issues reported on desktop systems.

**Risk**: NONE on desktop. Connected Standby is designed for laptops/tablets
with always-on network. Disabling it on a desktop changes nothing about normal
operation — only sleep behavior becomes the traditional S3.

**Restore**: Set `CsEnabled = 1` or delete the registry value.

**Classification**: SAFE — applied automatically by YAZX_NewTweaks.reg

---

## Tweak 2: Game Mode Enabled (AutoGameModeEnabled = 1)

**Registry**:
- `HKCU\Software\Microsoft\GameBar\AutoGameModeEnabled = 1`
- `HKCU\Software\Microsoft\GameBar\AllowAutoGameMode = 1`

**What it does**: Windows Game Mode reduces background activity when a
fullscreen game is detected. It deprioritizes Windows Update, some
notifications, and certain background processes during gameplay.

**Why for gaming**: Reduces context switches and background interruptions.
On Windows 11, Game Mode also integrates with Game Bar features.

**Source**: Microsoft documentation. This is the CURRENT system state being
preserved, not a new change.

**Compatibility**: Windows 10 1703+ and all Windows 11 versions.

**Risk**: NONE. This is preserving the existing setting.

**Restore**: Set `AutoGameModeEnabled = 0` to disable.

**Classification**: SAFE — preserves current state

---

## Tweak 3: GameDVR Disabled (GameDVR_Enabled = 0)

**Registry**:
- `HKCU\System\GameConfigStore\GameDVR_Enabled = 0`
- `HKCU\System\GameConfigStore\GameDVR_FSEBehavior = 2`
- `HKCU\System\GameConfigStore\GameDVR_FSEBehaviorMode = 2`
- `HKCU\System\GameConfigStore\GameDVR_HonorUserFSEBehaviorMode = 1`
- `HKCU\System\GameConfigStore\GameDVR_DXGIHonorFSEWindowsCompatible = 1`
- `HKCU\System\GameConfigStore\GameDVR_EFSEFeatureFlags = 0`

**What it does**: Disables Windows Game DVR (background game recording/
screenshot capture). The FSE values control Fullscreen Exclusive behavior,
ensuring games can use true FSE instead of borderless windowed.

**Why for gaming**: GameDVR adds measurable input lag (5-15ms in some tests)
due to its frame capture pipeline. Disabling it and honoring FSE mode gives
lower latency and sometimes higher FPS.

**Source**: Widely documented. Microsoft acknowledged GameDVR impact. FSE
values from Windows gaming optimization research.

**Compatibility**: Windows 10 1607+ and all Windows 11 versions.

**Risk**: NONE. This is preserving the existing setting. Loses ability to
use Win+G for game clips/screenshots, which was already disabled.

**Restore**: Set `GameDVR_Enabled = 1`.

**Classification**: SAFE — preserves current state

---

## Tweak 4: GlobalTimerResolutionRequests = 1

**Registry**: `HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel\GlobalTimerResolutionRequests = 1`

**What it does**: Starting with Windows 11 22H2, Microsoft changed timer
resolution behavior. By default, only the foreground process's timer
resolution request is honored. Setting this to 1 reverts to the old
behavior where the HIGHEST resolution request from ANY process is honored
system-wide.

**Important distinction**: This does NOT set the timer resolution itself.
It allows applications (games, media players, audio drivers) that call
NtSetTimerResolution() to actually get the resolution they request. Without
this, a game requesting 0.5ms resolution may be ignored if it's not the
foreground window, or if Windows decides to aggregate timer requests.

**Why for gaming**: Games and media applications request high-resolution
timers for consistent frame pacing. Without this, timer resolution may
revert to 15.6ms (default) when the game loses focus or Windows overrides.

**Source**: Microsoft DevBlog on timer resolution changes in Windows 11.
Registry key documented in Windows Internals community research.

**Compatibility**: Windows 11 22H2+ (Build 22621+). Present on LTSC 2024
Build 26100. The key is ignored on older Windows versions.

**Risk**: LOW. May increase idle power consumption by ~0.5-1W if a background
process holds a high-resolution timer request. No stability risk.

**Restore**: Set to 0 or delete the value.

**Classification**: CANDIDATE — requires manual application and testing

---

## Tweak 5: LargeSystemCache = 0

**Registry**: `HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\LargeSystemCache = 0`

**What it does**: Controls whether the memory manager prioritizes application
working sets (value 0) or the filesystem cache (value 1). Value 0 means
applications get memory priority; value 1 means file caching gets priority.

**Why for gaming**: With 32GB RAM, there's plenty for both. But setting to 0
ensures that if memory pressure occurs, the game's working set is preserved
over filesystem cache. This prevents the rare scenario where aggressive file
caching forces a game's memory pages to be paged out.

**Source**: Microsoft documentation (KB article on LargeSystemCache). This
is a well-documented Windows setting since Windows NT 4.0.

**Compatibility**: All Windows versions. The default on workstation SKUs
(including Windows 11 IoT Enterprise LTSC) is ALREADY 0. This tweak may be
redundant — verify current value before applying.

**Risk**: MINIMAL. If the current value is already 0 (likely on workstation
SKU), this changes nothing. If it were 1, changing to 0 reduces filesystem
cache aggressiveness, which is desirable for gaming.

**Restore**: Set to 0 (which is the workstation default).

**Classification**: CANDIDATE — may already be the default value

---

## Tweak 6: Disable Memory Compression

**Method**: PowerShell command `Disable-MMAgent -MemoryCompression`
(No registry equivalent — must be run as admin)

**What it does**: Disables Windows memory page compression. When enabled,
Windows compresses memory pages in RAM instead of paging them to disk,
using CPU cycles to save disk I/O. When disabled, the system pages to
disk instead of compressing.

**Why for gaming**: Compression/decompression uses CPU cycles, which could
theoretically cause micro-stutters during intense gameplay. Disabling it
removes this CPU overhead.

**Source**: Windows Internals (Russinovich). The concept is discussed in
gaming optimization forums, but THERE IS NO published benchmark showing
consistent, measurable gaming benefit from disabling this.

**Compatibility**: Windows 10 1607+ and all Windows 11 versions.

**Risk**: MEDIUM.
- With 32GB RAM and typical gaming workloads, memory pressure is unlikely,
  so the risk is low in practice.
- HOWEVER: If a game or application causes memory pressure beyond 32GB
  (possible with heavy modding, Chrome tabs open, etc.), the system will
  page to disk instead of compressing. Paging to disk is SLOWER than
  compressed memory, resulting in WORSE performance.
- Microsoft enables compression by default because it is beneficial for
  the vast majority of workloads.

**Restore**: `Enable-MMAgent -MemoryCompression` (run as admin)

**Classification**: EXPERIMENTAL — no auto-apply, benchmark required

---

## Tweak 7: Heterogeneous Thread Policy = 4 (Prefer Performant Processors)

**Method**: `powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR SCHEDPOLICY 4`
(Power plan setting, not registry)

**What it does**: On hybrid CPUs (Intel 12th gen+), this tells the Windows
thread scheduler to prefer P-cores (Performance cores) for thread placement.
Value 4 means "Prefer performant processors" — threads are placed on P-cores
first, with E-cores used as overflow.

**Values**:
- 0 = Automatic (default) — Windows decides based on QoS hints
- 1 = Prefer efficient processors (E-cores first)
- 2 = Prefer efficient if possible
- 3 = Automatic (same as 0 in practice)
- 4 = Prefer performant processors (P-cores first)
- 5 = Force efficient processors only

**Why for gaming**: Game threads benefit from P-core performance. The default
"Automatic" mode relies on the application's QoS hints and Intel Thread
Director. Some games don't set proper QoS hints, causing threads to land on
E-cores unnecessarily. Value 4 biases toward P-cores.

**Source**: Microsoft Power Plan documentation. The GUID
`93b8b6dc-0698-4d1c-9ee4-0644e900c85d` under `SUB_PROCESSOR` is documented
in powercfg hidden settings.

**Compatibility**: Windows 11 on Intel 12th gen+ (Alder Lake, Raptor Lake,
etc.) or AMD with heterogeneous cores. Specifically compatible with
i5-13400F (Raptor Lake, 6P + 4E). The setting is ignored on systems
without heterogeneous cores.

**Risk**: LOW. This is a well-documented power plan setting. The scheduler
still uses E-cores when P-cores are fully loaded. The risk is slightly
higher power consumption (P-cores use more power than E-cores at the same
load) and potentially worse performance for heavily threaded workloads
where E-cores would have been beneficial for auxiliary threads.

**Restore**: `powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR SCHEDPOLICY 0`

**Classification**: CANDIDATE — requires testing on this specific system

---

## Tweak 8: PCIe ASPM Off (Link State Power Management = 0)

**Method**: `powercfg /setacvalueindex SCHEME_CURRENT 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0`
(Power plan setting)

**What it does**: Disables Active State Power Management on PCIe links.
ASPM allows PCIe devices (GPU, NVMe, NIC) to enter low-power link states
(L0s, L1) when idle. When a device needs to communicate, it must exit the
low-power state, which takes a small amount of time (microseconds).

**Values**:
- 0 = Off (no power saving, lowest latency)
- 1 = Moderate power saving (L0s only)
- 2 = Maximum power saving (L0s + L1)

**Why for gaming**: The L0s/L1 exit latency is typically 1-10 microseconds.
On its own this is negligible, but during rapid burst I/O patterns (GPU
command submission, NVMe reads during asset streaming, NIC packet processing),
the cumulative effect of frequent ASPM transitions can add measurable
latency. Disabling ASPM keeps links at full speed always.

**Source**: PCIe specification (ASPM is defined in PCIe 2.0+). Common
recommendation in gaming optimization, especially for NVMe and GPU.

**Compatibility**: All systems with PCIe. The setting exists in all Windows
power plans. Compatible with i5-13400F platform.

**Risk**: LOW. Increases system power consumption by a few watts (PCIe links
stay at full power). No stability risk. The TTCH ULTIMATE PERFORMANCE plan
may already have this set to 0.

**Restore**: `powercfg /setacvalueindex SCHEME_CURRENT 501a4d13... ee12f906... 2`

**Classification**: CANDIDATE — may already be set by the existing power plan

---

## Summary Table

| # | Tweak | Classification | Auto-Applied? | Risk |
|---|-------|---------------|--------------|------|
| 1 | CsEnabled = 0 | SAFE | YES (YAZX_NewTweaks.reg) | None |
| 2 | Game Mode enabled | SAFE | YES (preserves current) | None |
| 3 | GameDVR disabled | SAFE | YES (preserves current) | None |
| 4 | GlobalTimerResolution | CANDIDATE | NO | Low |
| 5 | LargeSystemCache = 0 | CANDIDATE | NO (may be default) | Minimal |
| 6 | Memory Compression off | EXPERIMENTAL | NO | Medium |
| 7 | P-core thread policy | CANDIDATE | NO | Low |
| 8 | PCIe ASPM off | CANDIDATE | NO (may be set already) | Low |

**SAFE (3)**: Auto-applied. Either preserve current state or are universally appropriate.
**CANDIDATE (4)**: Require manual testing. Well-documented settings with low risk.
**EXPERIMENTAL (1)**: Memory Compression. No proven gaming benefit, medium risk.
