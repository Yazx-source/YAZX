# YAZX Phase 2 — Technical Audit Report
> Generated: 2026-11-20 | System: Windows 11 IoT Enterprise LTSC 2024 (Build 26100.8875)
> CPU: Intel i5-13400F (10C/16T) | GPU: RTX 3060 12GB | NIC: Realtek Gaming 2.5GbE
> Storage: Lexar NM710 1TB (NVMe) + Kingston SA400 480G (SATA SSD)

---

## STATUS LEGEND
| Status | Meaning |
|--------|---------|
| **EXISTING & COMPLETE** | Present and fully preserved |
| **EXISTING & INCOMPLETE** | Present but settings/files missing |
| **EXISTING & NEEDS BETTER CONFIG** | Present but alternative config worth preparing |
| **MISSING** | Not found, should be added |
| **DUPLICATE** | Function covered by another tool |
| **OUTDATED** | Newer version/tool available |
| **HARDWARE INCOMPATIBLE** | Not suitable for this hardware |
| **NO BENEFIT** | No convincing reason to add |

---

## 1. CPU / AFFINITY / INTERRUPTS

| Tool | Status | Details |
|------|--------|---------|
| **Process Lasso** | **EXISTING & INCOMPLETE** | Installed at `C:\Program Files\Process Lasso`. prolasso.ini has 85 priority rules, 75 IO priority rules, 68 memory priority rules, 1 GPU priority rule (rocketleague.exe). **Missing:** CPU affinity masks per-process (not in INI), CPU Set assignments (CPUSets=true but empty value), Watchdog rules (WatchdogRules2 empty), Instance rules. ProBalance active. SmartTrim disabled. ProgramData config NOT found — Process Lasso may store native rules in a database (`ProcessGovernor.db` or similar) that wasn't exported. |
| **ParkControl** | **EXISTING & INCOMPLETE** | Installed at `C:\Program Files\ParkControl\ParkControl.exe` (679KB). **No config file, no registry settings found.** ParkControl stores its settings via power plan parameters, not its own config file. Current Core Parking values are set by the TTCH Ultimate Performance power plan. Need to export actual power plan processor settings (Core Parking Min/Max, Frequency Boost, EPP). |
| **IRQControl** | **MISSING** | Not found anywhere on system. **Priority: HIGH.** IRQControl (Bitsum) manages Interrupt Affinity, Interrupt Priority, MSI mode per-device. Current MSI Mode module only enables MSI — does NOT set CPU affinity for interrupts. Download from Bitsum and export default interrupt affinity map. |
| **LatencyTest (Bitsum)** | **MISSING** | Not found. Useful for ISR/DPC testing alongside LatencyMon. Lower priority than IRQControl. |
| **Quick CPU** | **MISSING** | Not found. Provides GUI for C-States, Speed Shift, EPP, Turbo Boost. **For Intel i5-13400F:** useful for P-core/E-core management and EPP tuning. Worth collecting as a portable tool. |
| **ThrottleStop** | **MISSING** | Not found. **Compatible with i5-13400F** (Intel 13th Gen Raptor Lake). Can disable power limits and set per-core multipliers. Useful for undervolting (if BIOS allows) and monitoring. |
| **Intel XTU** | **HARDWARE INCOMPATIBLE** | i5-13400F is a **locked** (non-K) processor. Intel XTU has very limited functionality on locked CPUs — no multiplier changes, no voltage offset on most 13400F boards. **Not worth adding.** |
| **AMD Ryzen Master** | **HARDWARE INCOMPATIBLE** | Intel system. Not applicable. |
| **ZenTimings** | **HARDWARE INCOMPATIBLE** | AMD Ryzen only. Not applicable. |
| **Coreinfo (Sysinternals)** | **MISSING** | Not found on system. Part of Sysinternals Suite. Shows CPU topology, NUMA nodes, cache hierarchy. Useful for understanding P-core/E-core layout on 13th Gen. Lightweight, worth collecting. |
| **IMOD Disabler** | **EXISTING & COMPLETE** | At `C:\IMOD Disabler Tools\`. Scripts: Backup-XHCI-IMOD.ps1, Restore-XHCI-IMOD.ps1, XHCI-IMOD-Interval-Test.ps1, XHCI-IMOD-Interval.ps1. Runs at startup via HKLM Run. Fully preserved. |

### Key Findings — CPU Category
1. **Process Lasso native rules ARE in prolasso.ini** but CPU affinity masks and CPU Set assignments are NOT. The INI covers priorities/IO/memory but not per-process core pinning. Need to check if `ProcessGovernor.db` exists or if affinity rules are stored elsewhere.
2. **IRQControl is the #1 missing tool** — MSI Mode alone doesn't cover interrupt affinity assignment.
3. **i5-13400F has 6 P-cores + 4 E-cores** — Thread Director and core parking configuration is critical. ThrottleStop and Quick CPU both useful for this.

---

## 2. NVIDIA / GPU / FRAME TIMING

| Tool | Status | Details |
|------|--------|---------|
| **MSI Afterburner** | **EXISTING & INCOMPLETE** | Installed at `C:\Program Files (x86)\MSI Afterburner`. MSIAfterburner.cfg and RTCore.cfg present. Profiles directory exists. Monitoring plugins present (AIDA64, CPU, HwInfo, PerfCounter, Ping, SMART). **Missing:** Need to verify all GPU profiles (1-5) are actually configured vs default. Startup settings in Afterburner.cfg should be exported. HwInfo.cfg monitoring plugin config present. |
| **RTSS (RivaTuner Statistics Server)** | **EXISTING & INCOMPLETE** | **NOT installed separately.** Only `RTSSSetup.exe` found in Afterburner Redist folder. RTSS is NOT running. No RTSS config, profiles, or OSD settings exist. If Afterburner OSD is used, RTSS must be installed alongside it. **RTSS needs to be installed post-format or its setup included in tool library.** |
| **NVCleanstall** | **EXISTING & COMPLETE** | Config and guide at `E:\YAZX_GitHub\configs\NVCleanInstall\YAZX_NVCleanInstall_Guide.txt`. Tool itself should be collected for the tool library. |
| **NVIDIA Profile Inspector** | **EXISTING & INCOMPLETE** | Executable at `C:\stservices\nvidiaProfileInspector.exe`. Two .nip profiles found: `Performances.nip` (22KB) and `QuakedV2.nip` (6.7KB). **However:** NVIDIA DRS database at `C:\ProgramData\NVIDIA Corporation\Drs\` contains nvdrsdb0.bin (2.6MB) — this is the ACTUAL active profiles database with ALL game-specific and global settings. The .nip files are Profile Inspector snapshots but may not include all DRS changes. **Need to export full DRS to .nip for complete backup.** |
| **DDU (Display Driver Uninstaller)** | **MISSING** | Not found on system. Essential cleanup tool for driver reinstallation. Download latest portable version. |
| **CapFrameX** | **MISSING** | Not found. **Priority: HIGH.** Records frame times, FPS, 1% lows, 0.1% lows with sensor data overlay. Essential for benchmarking and comparing before/after tweak changes. Download from GitHub. |
| **Intel PresentMon** | **MISSING** | Not found. PresentMon is the engine CapFrameX uses. Standalone version also useful. Available from GitHub. |
| **GPU-Z** | **MISSING** | Not found anywhere. Lightweight GPU monitoring tool. Shows BIOS version, clocks, memory type, sensor data. Worth collecting as portable tool. |
| **NVIDIA FrameView** | **NO BENEFIT** | CapFrameX already provides better frame timing analysis with more features. FrameView's power measurement features require specific hardware. Skip. |

### Key Findings — GPU Category
1. **Performances.nip is classified as NVIDIA Profile, NOT CPU Affinity** (correcting the backup folder classification where it was under `yazx_CPUAffinity`).
2. **NVIDIA DRS database (nvdrsdb0.bin, 2.6MB)** contains the actual active profile data. The .nip files are snapshots from Profile Inspector. Both should be preserved.
3. **Per-Game GPU Preferences in registry:** Discord, Spotify, MSI AB, Steam, Chrome, Brave all set to GpuPreference=1 (high-performance GPU). RocketLeague has AppStatus=0.
4. **SwapEffectUpgradeEnable=1** — Flip Model swap effect upgrade is enabled globally (DirectX UserGpuPreferences).
5. **GameConfigStore has 55 game entries.**
6. **RTSS not being installed is a significant gap** if OSD monitoring is needed post-format.

---

## 3. NETWORK / TCP/IP / REALTEK

| Tool | Status | Details |
|------|--------|---------|
| **SG TCP Optimizer** | **MISSING** | Not found. **Priority: HIGH.** Provides GUI for TCP/IP settings including hidden parameters not exposed in Windows GUI. Version 4.1.1 is current. Download for the tool library. |
| **WinMTR** | **MISSING** | Not found. Combines traceroute + continuous ping. Useful for diagnosing routing issues. Worth collecting. |
| **PingPlotter** | **MISSING** | Not found. Commercial tool — free version exists. Similar to WinMTR but with visualization. Lower priority since WinMTR covers the need. |
| **Wireshark** | **MISSING** | Not found. Full packet capture and analysis. Heavyweight but essential for deep network diagnostics. Collect portable/installer. |
| **NetLimiter** | **MISSING** | Not found. No evidence of previous use. |
| **NetBalancer** | **MISSING** | Not found. No evidence of previous use. |
| **cFosSpeed** | **MISSING** | Not found. No evidence of previous driver or use. Network traffic shaping driver. **Caution:** installs as NDIS filter driver — can cause issues. Only add if specifically wanted. |
| **DNS Jumper** | **NO BENEFIT** | DNS is already set to 1.1.1.2 + 1.0.0.2 (Cloudflare Family) + 9.9.9.9 + 149.112.112.112 (Quad9). DNS Jumper just switches between presets — same thing can be done with a simple script. The current DNS config is good. |
| **simplewall** | **EXISTING & INCOMPLETE** | Henry++ simplewall exports at `E:\YAZX_GitHub\exports\Henry_simplewall\memreduct.ini` (this is actually Mem Reduct config). **simplewall itself not found installed on system.** The export folder name is misleading. Need to verify if simplewall was used or just Mem Reduct. |

### REALTEK GAMING 2.5GbE — COMPLETE SETTINGS AUDIT

**Driver:** Realtek 10.80.20.407 (2026-04-07) on PCI\VEN_10EC&DEV_8125 (RTL8125BG)

| Property | Current Value | Default | Assessment |
|----------|--------------|---------|------------|
| **\*SpeedDuplex** | 2500 (2.5 Gbps Full) | 0 (Auto) | Forced to max speed. Good if link is stable at 2.5G. Auto-neg is safer for compatibility. **KEEP** |
| **\*FlowControl** | 0 (Disabled) | 3 (Rx & Tx) | Disabled reduces latency by preventing pause frames. **CORRECT for gaming.** |
| **\*InterruptModeration** | 0 (Disabled) | 1 (Enabled) | Disabling IMOD reduces latency BUT increases CPU interrupt load. On a 10C/16T CPU this is acceptable. **CORRECT for low-latency gaming.** |
| **\*IPChecksumOffloadIPv4** | 0 (Disabled) | 3 (Rx & Tx) | **NEEDS REVIEW.** Disabling forces CPU to calculate checksums. On 2.5G link with 10C CPU, re-enabling Tx offload would reduce CPU overhead with no latency penalty. |
| **\*TCPChecksumOffloadIPv4** | 0 (Disabled) | 3 (Rx & Tx) | **NEEDS REVIEW.** Same as above. TCP Checksum offload to NIC hardware reduces CPU cycles. |
| **\*UDPChecksumOffloadIPv4** | 0 (Disabled) | 3 (Rx & Tx) | **NEEDS REVIEW.** UDP is used by most game traffic. Offloading checksum to hardware reduces CPU load. |
| **\*TCPChecksumOffloadIPv6** | 3 (Rx & Tx Enabled) | 3 | Interesting: IPv6 offloads are ON while IPv4 are OFF. Inconsistent. |
| **\*UDPChecksumOffloadIPv6** | 3 (Rx & Tx Enabled) | 3 | Same inconsistency — IPv6 offloads enabled, IPv4 disabled. |
| **\*LsoV2IPv4** | 0 (Disabled) | 1 (Enabled) | LSO (Large Send Offload) disabled. **CORRECT.** LSO adds latency by batching packets. Gaming benefits from immediate sends. |
| **\*LsoV2IPv6** | 0 (Disabled) | 1 (Enabled) | Same — **CORRECT.** |
| **\*RSS** | 1 (Enabled) | 1 | RSS is ON. **CORRECT.** Distributes receive processing across CPUs. |
| **\*NumRssQueues** | 4 | 8 | Using 4 of 8 available queues. **Consider increasing to 8** for better CPU distribution on a 16-thread system, OR keep at 4 to dedicate more cores to games. Worth testing. |
| **\*ReceiveBuffers** | 2048 | 1024 | Doubled from default. **GOOD** — more receive buffer space. Max is usually 4096 but higher isn't always better. |
| **\*TransmitBuffers** | 1024 | 512 | Doubled from default. **GOOD.** |
| **\*JumboPacket** | 1514 (Disabled) | 1514 | Jumbo frames disabled. **CORRECT** unless entire LAN supports jumbo (router, switch, all endpoints). Most don't. |
| **\*PriorityVlanTag** | 0 (Disabled) | 3 | VLAN tagging disabled. **CORRECT** for home use. |
| **\*PMARPOffload** | 0 (Disabled) | 1 | ARP offload disabled. **CORRECT** — not needed when WoL is off. |
| **\*PMNSOffload** | 0 (Disabled) | 1 | NS offload disabled. **CORRECT.** |
| **\*WakeOnMagicPacket** | 0 (Disabled) | 1 | WoL disabled. **CORRECT** for gaming — prevents idle wake and power draw. |
| **\*WakeOnPattern** | 0 (Disabled) | 1 | **CORRECT.** |
| **S5WakeOnLan** | 0 (Disabled) | 1 | **CORRECT.** |
| **\*EEE** | 0 (Disabled) | 0 | Energy Efficient Ethernet disabled. **CORRECT** — EEE adds transition latency. |
| **AdvancedEEE** | 0 (Disabled) | 0 | **CORRECT.** |
| **EnableGreenEthernet** | 0 (Disabled) | 1 | Green Ethernet disabled. **CORRECT** for performance. |
| **GigaLite** | 0 (Disabled) | 1 | GigaLite disabled. **CORRECT.** |
| **PowerSavingMode** | 0 (Disabled) | 0 | **CORRECT.** |
| **PowerDownPll** | 0 | 0 | PLL power down off. **CORRECT.** |
| **PnPCapabilities** | 280 | - | Prevents device power management. **CORRECT.** |
| **ASPM** | 0 | 0 | PCIe ASPM disabled for NIC. **CORRECT.** |

### Realtek Verdict
**Current config is 90% correct for gaming.** The main question mark is IPv4 Checksum Offloads being OFF while IPv6 Offloads are ON — this is inconsistent and may have been an oversight in the tweaker. 

**Recommendation:** Prepare TWO alternate config files for post-format testing:
1. **Current config** (all offloads OFF except IPv6) — maximum latency reduction
2. **Balanced config** — Re-enable TCP/UDP/IP Checksum Offload for IPv4 (Tx only), keep LSO OFF, keep RSS ON. This reduces CPU overhead while maintaining low latency for send operations.

### TCP/IP Global Settings
| Setting | Current | Assessment |
|---------|---------|------------|
| TCP Auto-Tuning | Disabled | **CORRECT** for gaming — prevents receive window scaling issues |
| Scaling Heuristics | Disabled | **CORRECT** |
| ECN Capability | Enabled | **REVIEW** — ECN can help with congestion but some ISPs/servers handle it poorly. Test disabled. |
| Receive Segment Coalescing (RSC) | Disabled | **CORRECT** — RSC adds latency by coalescing segments |
| Chimney Offload | Disabled | **CORRECT** (deprecated in modern Windows) |
| Task Offload | Enabled | **CORRECT** |
| NetworkDirect (RDMA) | Enabled | Neutral — only used with RDMA-capable hardware |
| Packet Coalescing Filter | Enabled | **REVIEW** — coalescing can add latency. Consider disabling. |
| DNS Servers | 1.1.1.2, 1.0.0.2, 9.9.9.9, 149.112.112.112 | **GOOD** — Cloudflare Family + Quad9. Fast and secure. |

---

## 4. DPC / ISR / WINDOWS PERFORMANCE

| Tool | Status | Details |
|------|--------|---------|
| **LatencyMon** | **MISSING** | Not found. **Priority: HIGH.** Monitors DPC, ISR, Hard Pagefaults in real-time. Identifies which drivers cause latency. Essential diagnostic tool. Download from resplendence.com. |
| **WPR (Windows Performance Recorder)** | **EXISTING & COMPLETE** | Built into Windows at `C:\Windows\System32\wpr.exe`. Available without additional install. |
| **WPA (Windows Performance Analyzer)** | **MISSING** | WPA is NOT built into LTSC. Needs ADK (Assessment and Deployment Kit) or Windows Performance Toolkit install. `wpr.exe` can record but `wpa.exe` is needed for analysis. Download WPT from Microsoft. |
| **Xperf** | **EXISTING & INCOMPLETE** | Xperf binaries in WinSxS suggest Windows Performance Toolkit components are partially present. Need to verify xperf.exe availability. |
| **PerfView** | **MISSING** | Not found. .NET ETW analysis tool. Lower priority — WPR/WPA cover most needs. |
| **Sysinternals Suite** | **EXISTING & INCOMPLETE** | Only Autoruns (v14.3) and TCPView found in Downloads. **Missing from suite:** Process Explorer, Process Monitor, RAMMap, VMMap, ClockRes, PsPing, Coreinfo, Handle, ListDLLs, Sysmon, etc. |
| **ClockRes** | **MISSING** | Sysinternals tool for measuring timer resolution. Not found. Download as part of Sysinternals collection. |
| **PsPing** | **MISSING** | Sysinternals network latency measurement. Not found. |
| **TCPView** | **EXISTING & COMPLETE** | Found in Downloads: `C:\Users\Y\Downloads\TCPView\`. Shows per-process network connections. |

---

## 5. RAM / MEMORY MANAGEMENT

| Tool | Status | Details |
|------|--------|---------|
| **Mem Reduct** | **EXISTING & INCOMPLETE** | Installed at `C:\Program Files\Mem Reduct\`. Config at `C:\Users\Y\AppData\Roaming\Henry++\Mem Reduct\memreduct.ini` (144 bytes) — minimal settings: only CheckUpdatesLast, IsShowReductConfirmation=false, window position. **Missing:** Auto-reduct thresholds, hotkey settings, tray behavior, cleanup areas selection. The ini is so minimal it may be using all defaults. 86 cache .tmp files in AppData. History.txt present (6.8KB). **Backup should include memreduct.ini.** |
| **RAMMap** | **MISSING** | Sysinternals memory analysis tool. Not found. Shows physical memory usage by type (Process Private, Mapped File, etc.). Worth collecting. |
| **ISLC (Intelligent Standby List Cleaner)** | **MISSING** | Not found. ISLC by Wagnard clears standby list when it exceeds threshold. **Comparison with Mem Reduct:** Mem Reduct is more aggressive (clears working sets + standby), ISLC is lighter (standby only). For gaming, ISLC is generally preferred as it doesn't flush working sets. **Recommend collecting ISLC as an alternative.** |
| **VMMap** | **MISSING** | Sysinternals per-process memory analysis. Worth collecting as part of Sysinternals bundle. |
| **MemTest86** | **MISSING** | Not found. USB-bootable RAM testing tool. Essential for stability testing after XMP/DOCP. Download from memtest86.com. |
| **TestMem5** | **MISSING** | Not found. Faster RAM stability testing than MemTest86. Good for quick verification. |
| **OCCT** | **MISSING** | Not found. Stress test for CPU, GPU, RAM, PSU. Comprehensive stability testing tool. |
| **WinMemoryCleaner** | **EXISTING & COMPLETE** | Found on Desktop: `C:\Users\Y\Desktop\WinMemoryCleaner.exe`. Standalone portable. |

### Memory Settings Status
| Setting | Current Value | Assessment |
|---------|--------------|------------|
| DisablePagingExecutive | 1 | **CORRECT** — keeps kernel in RAM |
| Pagefile | C:\pagefile.sys 2432MB | System-managed, adequate for 32GB RAM |
| LargeSystemCache | (not set) | Default behavior. OK. |
| ClearPageFileAtShutdown | 0 | **CORRECT** — no need to clear on gaming system |
| Memory Compression | Unknown (needs elevation) | Should be verified post-format |
| Power Throttling | OFF (PowerThrottlingOff=1) | **CORRECT** |
| Background Apps | Disabled (GlobalUserDisabled=1) | **CORRECT** |

---

## 6. STORAGE / NVMe / SSD

| Tool | Status | Details |
|------|--------|---------|
| **CrystalDiskInfo** | **MISSING** | Not found. **Important:** Shows SMART data, health, temperature for both Lexar NM710 and Kingston SA400. Essential monitoring tool. Download portable version. |
| **CrystalDiskMark** | **MISSING** | Not found. Standard benchmark for storage speed. Download portable. |
| **DiskSpd** | **MISSING** | Microsoft's storage benchmark tool. Command-line, more advanced than CrystalDiskMark. Lower priority. |
| **Samsung Magician** | **HARDWARE INCOMPATIBLE** | Lexar NM710 + Kingston SA400 — neither is Samsung. |
| **WD Dashboard** | **HARDWARE INCOMPATIBLE** | No WD drives present. |
| **Crucial Storage Executive** | **HARDWARE INCOMPATIBLE** | No Crucial drives present. |
| **Solidigm Storage Tool** | **HARDWARE INCOMPATIBLE** | No Solidigm/Intel drives. |

### Storage Settings Status
| Setting | Registry Key | Status |
|---------|-------------|--------|
| NVMe IdleTimeout | stornvme\Parameters\Device\IdleTimeout=0 | **IN YAZX_Hardware.reg** — CORRECT |
| AHCI HIPM/DIPM/HDPM | storahci\Parameters\Device | **IN YAZX_Hardware.reg** — All disabled, CORRECT |
| Write Caching | (needs elevation to verify) | Unknown — should check post-format |
| PCIe ASPM (NIC) | 0 (disabled) | **CORRECT** in Realtek settings |
| PCIe ASPM (Global) | No AspmDisablePolicy set | **GAP** — should set global ASPM disable via power plan or registry |

---

## 7. USB / CONTROLLER / AUDIO

| Tool | Status | Details |
|------|--------|---------|
| **USBTreeView** | **MISSING** | Not found. **Priority: HIGH** given IMOD Disabler and XHCI scripts are in use. Shows USB topology, controllers, hubs, device connections. Download from uwe-sieber.de. |
| **USBDeview** | **MISSING** | NirSoft tool showing all USB devices ever connected. Historical record useful for troubleshooting. |
| **USBLogView** | **MISSING** | NirSoft tool logging USB connect/disconnect events. Lower priority. |
| **Peace Equalizer APO GUI** | **MISSING** | Not found. Equalizer APO is installed but config.txt is minimal (`Include: mic.txt` — 16 bytes). No GUI for creating/managing EQ profiles. If EQ APO is used for audio processing, Peace provides a user-friendly interface. |
| **DS4Windows** | **MISSING** | Not found. No evidence of previous use. Only needed if using DualShock/DualSense controllers. |
| **HidHide** | **MISSING** | Not found. Hides game controllers from applications to prevent double-input. Only needed with controller remapping tools. |
| **DualSenseX / DSX** | **MISSING** | Not found (DSX hit was a PowerShell transcript filename). |
| **MouseTester** | **MISSING** | Not found. Tests mouse polling rate and sensor data. Useful for verifying 1:1 raw input setup. |

### Audio Status
| Component | Status | Details |
|-----------|--------|---------|
| Equalizer APO | **EXISTING & INCOMPLETE** | Installed at `C:\Program Files\EqualizerAPO`. **config.txt = `Include: mic.txt` only (16 bytes)**. This means: either mic processing only, or configuration was lost/reset. No custom EQ profile exists. Demo, example, iir_lowpass, multichannel, selective_delay configs are stock examples. **Missing: Device Selection (Configurator output), custom profiles, VST plugins directory is empty.** |
| MMCSS Audio | EXISTING | SystemResponsiveness=0, Games task Priority=6, GPU Priority=8, Scheduling Category=High, SFIO Priority=High. All in MMCSS.reg export. |

---

## 8. WINDOWS TWEAKING / DEBLOAT / PRIVACY

| Tool | Status | Details |
|------|--------|---------|
| **Winaero Tweaker** | **EXISTING & COMPLETE** | Found at `E:\PRIVATE\my stuff\winaerotweaker\WinaeroTweaker-1.65.0.0-setup.exe`. Installer present, not currently installed. Available for future use. |
| **O&O ShutUp10++** | **MISSING** | Not found. Privacy/telemetry tool with granular toggles. Many of its functions overlap with Oneclick's privacy tweaks. **Worth collecting** as a verification/comparison tool. |
| **Sophia Script** | **MISSING** | Not found. PowerShell-based Windows debloating script. Advanced, regularly updated. Some functions unique vs Oneclick (AppX package removal, context menu customization). |
| **Chris Titus WinUtil** | **MISSING** | Not found. PowerShell one-liner installation/debloat tool. Good for quick post-install setup. |
| **Optimizer (hellzerg)** | **DUPLICATE** | `Network_Optimizer_v2.0.exe` found on Desktop and E:\. This is a network optimizer, not hellzerg's Optimizer utility. Hellzerg's Optimizer not found. The Network Optimizer is a simple tool — its functions are covered by registry tweaks. |
| **Bloatynosy** | **MISSING** | Not found. LTSC doesn't have most bloatware it removes. **NO BENEFIT** for LTSC. |
| **W10Privacy** | **MISSING** | Not found. Privacy tool. Many functions overlap with Oneclick + hosts file blocking. |
| **WPD** | **MISSING** | Not found (hits were Windows Portable Devices system files). WPD (Windows Privacy Dashboard) manages telemetry. Overlap with existing hosts file + registry tweaks. |
| **NTLite** | **MISSING** | Not found. Pre-install image customization. Only useful if creating custom Windows ISO. Worth noting but not needed in post-format tool library unless building custom images. |
| **MSMG Toolkit** | **MISSING** | Not found. Similar to NTLite — Windows image customization. Same assessment. |
| **O&O AppBuster** | **NO BENEFIT** | LTSC doesn't come with AppX bloatware. |
| **Windows Update Blocker** | **DUPLICATE** | NoAutoUpdate=1 already in YAZX_System.reg. Standalone tool is redundant. |
| **Firewall App Blocker** | **MISSING** | Not found. Simple GUI for Windows Firewall rules. simplewall covers this better. |
| **Sordum Utilities** | **MISSING** | Collection of small utilities. Some are unique: Defender Control, Easy Context Menu, Windows Update Blocker, etc. Worth selectively collecting individual tools, not the whole bundle. |

---

## 9. EXISTING TOOLS — CONFIG COMPLETENESS AUDIT

| Tool | Config Status | Missing Items | Priority |
|------|--------------|---------------|----------|
| **Process Lasso** | 85 priority + 75 IO + 68 memory + 1 GPU rules in prolasso.ini | CPU affinity masks per-process, CPU Set assignments (enabled but empty), Watchdog rules, Instance rules, ProgramData config (not found) | **HIGH** |
| **ParkControl** | No config file found | Actual Core Parking parameters from power plan, EPP settings, Frequency Scaling values | **MEDIUM** |
| **MSI Afterburner** | CFG + RTCore + Plugins present | GPU profiles (need to verify 1-5 are configured), monitoring layout, startup settings, OSD config | **MEDIUM** |
| **RTSS** | NOT INSTALLED | Everything — full install, config, profiles, OSD layout | **HIGH** |
| **NVIDIA Inspector** | 2 .nip files (Performances + QuakedV2) | Full DRS database export (nvdrsdb0.bin is active but .nip may not capture all), per-game profile list, Global Profile separate export | **HIGH** |
| **CRU** | 5 .bin profiles on Desktop | EDID override details, active monitor timing documentation, which .bin applies to which display | **LOW** |
| **Equalizer APO** | config.txt = mic.txt include only (16 bytes) | Device Selection (which audio device APO is attached to), any custom EQ profiles, VST plugin configs | **MEDIUM** |
| **Mem Reduct** | memreduct.ini found (144 bytes, minimal) | Full settings (using defaults: auto-reduct threshold, cleanup areas, hotkey). memreduct.ini needs to be added to exports. | **LOW** |
| **Steam** | config.vdf, libraryfolders.vdf, loginusers.vdf, controller configs, 10 avatar PNGs | Per-game controller layouts from userdata (user 154878663, 4 game folders), localconfig.vdf (62KB), Steam Cloud save data | **MEDIUM** |
| **LibreWolf** | prefs.js (12.9KB), places.sqlite (5MB), 5 extensions | Missing: user.js (no custom user overrides), logins.json (no saved passwords), bookmarkbackups dir is empty, extension data/settings | **MEDIUM** |
| **Brave** | Preferences (87.7KB), Secure Preferences (16KB), Login Data (40KB), History (6.8MB) | Missing: Bookmarks, Cookies, Local State (encryption key), Extensions dir empty (1 extension ID present but no data). Only 1 extension (eimadpbcbfnmbkopoojfekhnkhdbieeh) | **MEDIUM** |
| **HWiNFO** | Only as Afterburner monitoring plugin (HwInfo.dll + cfg) | Standalone HWiNFO64 NOT installed. No sensor config, no logging config, no custom monitoring layout | **MEDIUM** |
| **Timer Resolution (STR)** | Service running, SetTimerResolutionService.exe + 4 old versions + YAZXFix variants | Service registry fully documented. Multiple .exe versions preserved. YAZXFixService.cs source code present. | **COMPLETE** |
| **Realtek NIC** | Full registry export with all advanced properties | Need alternative config file for comparison testing (checksum offload variants). IPv4 vs IPv6 offload inconsistency. | **MEDIUM** |

---

## 10. TWEAKS & SETTINGS COVERAGE MATRIX

### Documented vs Undocumented

| Domain | Setting | In Registry Exports? | In YAZX .reg files? | Current Value | Notes |
|--------|---------|---------------------|---------------------|---------------|-------|
| **CPU** | Win32PrioritySeparation | PriorityControl.reg | YAZX_Gaming.reg (assumed) | 0x26 (38, FPS) | COVERED |
| **CPU** | Processor Boost Mode | NOT EXPORTED | NOT IN .REG | Unknown | **GAP** — in power plan, needs powercfg export |
| **CPU** | EPP (Energy Performance Preference) | NOT EXPORTED | NOT IN .REG | Unknown | **GAP** — set via power plan |
| **CPU** | HWP (Hardware P-states) | NOT EXPORTED | NOT IN .REG | Unknown | **GAP** — BIOS + power plan |
| **CPU** | Speed Shift Technology | NOT EXPORTED | NOT IN .REG | Unknown | **GAP** — Intel-specific, in power plan |
| **CPU** | C-States | NOT EXPORTED | NOT IN .REG | Unknown | **GAP** — BIOS setting, cannot read from registry without admin |
| **CPU** | Core Parking Min/Max | NOT EXPORTED directly | NOT IN .REG | In power plan | **GAP** — need `powercfg /query` for processor subgroup |
| **CPU** | CPU Sets | Process Lasso CPUSets=true | NOT IN .REG | Enabled, empty | **INCOMPLETE** — enabled but no assignments |
| **Scheduling** | MMCSS SystemResponsiveness | MMCSS.reg | YAZX_Gaming.reg (assumed) | 0 | COVERED |
| **Scheduling** | MMCSS NetworkThrottlingIndex | MMCSS.reg | YAZX_Gaming.reg (assumed) | 0xFFFFFFFF | COVERED |
| **Scheduling** | Games Task Priority | MMCSS.reg | YAZX_Gaming.reg (assumed) | 6 | COVERED |
| **Scheduling** | Games Task GPU Priority | MMCSS.reg | YAZX_Gaming.reg (assumed) | 8 | COVERED |
| **Scheduling** | Games Scheduling Category | MMCSS.reg | YAZX_Gaming.reg (assumed) | High | COVERED |
| **Interrupts** | MSI Mode (7 devices) | - | Module 10_MSIMode.ps1 | Enabled | COVERED |
| **Interrupts** | Interrupt Affinity Policy | NOT EXPORTED | NOT COVERED | Unknown per-device | **GAP** — needs IRQControl |
| **Interrupts** | DevicePriority | NOT EXPORTED | NOT COVERED | Unknown | **GAP** |
| **Interrupts** | RSS Processor Affinity | Realtek export | NOT IN .REG | 4 queues, auto | **PARTIAL** |
| **Memory** | Memory Compression | NOT CHECKED (needs elevation) | NOT IN .REG | Unknown | **GAP** |
| **Memory** | Standby List clearing | Mem Reduct present | NOT IN .REG | Via Mem Reduct | COVERED (tool-based) |
| **Memory** | DisablePagingExecutive | MemoryManagement.reg | YAZX_Gaming.reg (assumed) | 1 | COVERED |
| **Memory** | Large System Cache | MemoryManagement.reg | NOT IN .REG | Not set | **GAP** — may want to test |
| **Memory** | Pool Paged/Nonpaged | MemoryManagement.reg | NOT IN .REG | 0/0 (auto) | OK — auto is correct for most systems |
| **NVIDIA** | HwSchMode (HAGS) | GraphicsDrivers.reg | YAZX_NVIDIA.reg | 2 (enabled) | COVERED |
| **NVIDIA** | TdrDelay | GraphicsDrivers.reg | YAZX_NVIDIA.reg | 60 | COVERED |
| **NVIDIA** | OverlayTestMode (MPO) | DWM.reg | YAZX_NVIDIA.reg | 5 (disabled) | COVERED |
| **NVIDIA** | Power Mgmt Mode | In .nip profiles | NOT IN .REG | In DRS | **PARTIAL** — in .nip but not easily scriptable |
| **NVIDIA** | Shader Cache | In DRS/profiles | NOT IN .REG | Unknown | **GAP** — DRS setting |
| **NVIDIA** | Low Latency Mode | In DRS/profiles | NOT IN .REG | Unknown | **GAP** — DRS setting |
| **NVIDIA** | Threaded Optimization | In DRS/profiles | NOT IN .REG | Unknown | **GAP** — DRS setting |
| **NVIDIA** | G-SYNC / VRR | In NVIDIA CP | NOT IN .REG | Unknown | **GAP** |
| **DirectX** | Fullscreen Optimizations | GameConfigStore.reg | NOT IN .REG | Per-game | COVERED (55 entries) |
| **DirectX** | Flip Model | DirectX UserGpuPreferences | NOT IN .REG | SwapEffectUpgradeEnable=1 | COVERED |
| **Gaming** | Game Mode | NOT EXPORTED | NOT IN .REG | Unknown | **GAP** |
| **Gaming** | Game DVR | GameDVR_Policy.reg + GameDVR_User.reg | NOT IN .REG | Captured | COVERED |
| **Gaming** | GameConfigStore | GameConfigStore.reg | NOT IN .REG | 55 entries | COVERED |
| **Gaming** | Per-Game GPU Preferences | NOT EXPORTED | NOT IN .REG | 8 apps set | **GAP** — should export UserGpuPreferences |
| **Network** | RSS | Realtek: Enabled, 4 queues | NOT IN .REG | Active | COVERED |
| **Network** | TCP Auto-Tuning | TCPIP.reg (assumed) | NOT IN .REG | Disabled | COVERED |
| **Network** | ECN | NOT EXPORTED | NOT IN .REG | Enabled | **REVIEW** |
| **Network** | Packet Coalescing | NOT EXPORTED | NOT IN .REG | Enabled | **REVIEW** |
| **Timer** | Global Timer Resolution | STR Service running | NOT IN .REG | Via STR service | COVERED |
| **Timer** | Dynamic Tick (BCD) | DOCUMENTED but not exported | Module 09_BCDTweaks.ps1 | disabledynamictick=yes | COVERED (in module) |
| **Timer** | HPET | DOCUMENTED | Module 09_BCDTweaks.ps1 | Via BCD | COVERED (in module) |
| **Timer** | TSC Sync Policy | DOCUMENTED | Module 09_BCDTweaks.ps1 | Enhanced | COVERED (in module) |
| **USB** | XHCI IMOD | IMOD Disabler scripts | NOT IN .REG | Disabled via scripts | COVERED |
| **USB** | Selective Suspend | USBClass.reg + YAZX_Hardware.reg | YAZX_Hardware.reg | Disabled | COVERED |
| **USB** | Hub Power Management | YAZX_Hardware.reg | YAZX_Hardware.reg | Disabled | COVERED |
| **Audio** | MMCSS Audio | MMCSS.reg | YAZX_Gaming.reg (assumed) | High priority | COVERED |
| **Audio** | APO Registration | EQ APO installed | NOT IN .REG | Minimal config | **INCOMPLETE** |
| **Audio** | Exclusive Mode | NOT EXPORTED | NOT IN .REG | Unknown | **GAP** |
| **Audio** | Buffer Settings | NOT EXPORTED | NOT IN .REG | Unknown | **GAP** |
| **Storage** | NVMe Power States | NVMe.reg + YAZX_Hardware.reg | YAZX_Hardware.reg | IdleTimeout=0 | COVERED |
| **Storage** | AHCI Power Mgmt | AHCI.reg + YAZX_Hardware.reg | YAZX_Hardware.reg | HIPM/DIPM/HDPM=0 | COVERED |
| **Storage** | PCIe ASPM (Global) | NOT SET | NOT IN .REG | No policy | **GAP** |
| **Windows** | Services (64 total) | Services_All.csv | Module 08_Services.ps1 | 15 disabled, 24 manual, 25 auto | COVERED |
| **Windows** | Scheduled Tasks | ACCESS DENIED | NOT COVERED | Unknown | **GAP** (needs elevation) |
| **Windows** | Autologgers | NOT EXPORTED | NOT COVERED | Unknown | **GAP** |
| **Windows** | Power Throttling | NOT EXPORTED | NOT IN .REG | OFF | **GAP** — should be in .reg |
| **Windows** | Background Apps | NOT EXPORTED | NOT IN .REG | Disabled globally | **GAP** — should be in .reg |

---

## 11. PRIORITY ACTION ITEMS

### CRITICAL (Must do before format)

1. **Export Process Lasso full config** — The prolasso.ini has priorities but no CPU affinity masks. Check if `C:\ProgramData\Bitsum` or Process Lasso install directory has additional config files after elevation. The 85+75+68 rules ARE the native rules for priorities; affinity may require manual re-setup.

2. **Export NVIDIA DRS database** — Copy `C:\ProgramData\NVIDIA Corporation\Drs\nvdrsdb0.bin` and `nvdrsdb1.bin` to exports. These ARE the full profile database. Also export using Profile Inspector to .nip for a human-readable backup.

3. **Export Per-Game GPU Preferences registry** — `HKCU\Software\Microsoft\DirectX\UserGpuPreferences` (8 app entries) needs to be in a .reg export.

4. **Export Mem Reduct config** — Copy `C:\Users\Y\AppData\Roaming\Henry++\Mem Reduct\memreduct.ini` to exports.

5. **Prepare alternative Realtek config** — Create a second .reg with IPv4 checksum offloads re-enabled (Tx only) for comparative testing.

### HIGH PRIORITY (Collect for tool library)

6. **IRQControl** — Download from Bitsum. Essential for interrupt affinity management.
7. **CapFrameX** — Download from GitHub. Essential for frame timing benchmarks.
8. **LatencyMon** — Download from resplendence.com. Essential for DPC/ISR analysis.
9. **DDU** — Download from wagnardsoft.com. Essential for clean driver installs.
10. **GPU-Z** — Download portable from TechPowerUp.
11. **CrystalDiskInfo** — Download portable. Drive health monitoring.
12. **USBTreeView** — Download from uwe-sieber.de. USB topology mapping.
13. **RTSS installer** — Already in Afterburner Redist. Ensure it's part of post-format install sequence.

### MEDIUM PRIORITY (Useful additions)

14. **SG TCP Optimizer** — Download for TCP/IP settings GUI.
15. **ThrottleStop** — Download for Intel CPU tuning (compatible with i5-13400F).
16. **Quick CPU** — Download for P-core/E-core management.
17. **ISLC** — Download as alternative to Mem Reduct for standby list management.
18. **Sysinternals bundle** — Download full suite (includes Coreinfo, ClockRes, PsPing, RAMMap, VMMap, Process Explorer, Process Monitor).
19. **CrystalDiskMark** — Download portable for storage benchmarks.
20. **WinMTR** — Download for network route diagnostics.
21. **O&O ShutUp10++** — Download for privacy verification.
22. **HWiNFO standalone** — Download for comprehensive hardware monitoring.

### LOW PRIORITY (Nice to have)

23. **Wireshark** — Full packet analysis, large install.
24. **PresentMon** — CapFrameX already includes its engine.
25. **MemTest86 / TestMem5** — USB-bootable, only for stability testing.
26. **OCCT** — Stress testing, only for stability verification.
27. **Peace EQ GUI** — Only if EQ APO is actively used for audio processing.
28. **MouseTester** — Only for verifying polling rate setup.

### NOT NEEDED

- Intel XTU (locked CPU)
- AMD Ryzen Master / ZenTimings (Intel system)
- Samsung/WD/Crucial/Solidigm tools (wrong drives)
- Bloatynosy (LTSC doesn't have bloatware)
- O&O AppBuster (LTSC doesn't have AppX bloat)
- Windows Update Blocker (covered by registry)
- DNS Jumper (DNS already properly configured)
- NVIDIA FrameView (CapFrameX is better)
- NTLite / MSMG Toolkit (not building custom ISOs)
- cFosSpeed (NDIS filter driver risk, questionable benefit)

---

## 12. SETTINGS GAPS — REGISTRY EXPORTS NEEDED

These settings exist on the system but are NOT in any export:

1. `HKCU\Software\Microsoft\DirectX\UserGpuPreferences` — Per-game GPU preferences (8 entries)
2. `HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling` — PowerThrottlingOff=1
3. `HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications` — GlobalUserDisabled=1
4. Power Plan processor settings (Core Parking, EPP, Boost Mode) — via `powercfg /query`
5. `HKCU\System\GameConfigStore` — 55 game entries
6. Memory Compression state — needs elevation to check
7. Audio Exclusive Mode settings — needs per-device check
8. PCIe ASPM global policy — not set, should be added
9. Autologger entries — unknown, needs elevation

---

*Report generated by YAZX Phase 2 Technical Audit. No tweaks applied. All findings are for pre-format documentation and post-format preparation only.*
