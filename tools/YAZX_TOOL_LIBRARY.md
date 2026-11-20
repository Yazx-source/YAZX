# YAZX Tool Library — Phase 4 Manifest
# Updated: 2026-11-20
# Total: 17 tools + 2 dependencies + 268 VST plugin files
# Structure: Each tool has name, version, files, source, SHA-256,
#            dependencies, config files, and collection status.

---

## Tool 01: Sysinternals Suite

- **Version**: Latest (downloaded 2026-11-19)
- **Status**: COMPLETE
- **Files**:
  - tools/Sysinternals/SysinternalsSuite.zip (357.33 MB)
  - tools/Sysinternals/extracted/ (164 files, 445.1 MB)
- **Source**: https://download.sysinternals.com/files/SysinternalsSuite.zip
- **SHA-256**: E7F49D1F4477E416B3051636DC44929B20AE025B46A1EE4CD8C1F1E869AF6AE6
- **Signed**: N/A (suite of mixed tools)
- **Dependencies**: None
- **Config files**: None (portable tools)
- **Key tools**: Process Explorer, Process Monitor, Autoruns, TCPView,
  RAMMap, Handle, PsExec, Sysmon, Coreinfo, Clockres, sigcheck

---

## Tool 02: MouseTester

- **Version**: v1.5.3
- **Status**: COMPLETE
- **Files**:
  - tools/MouseTester/MouseTester_v1.5.3.zip (152.8 KB)
- **Source**: https://github.com/microe1/MouseTester/releases/download/v1.5.3/MouseTester.v1.5.3.zip
- **SHA-256**: D7E63DD67C8948777A43BB65D9D8F377A5E81254DA480DAAFF70E2BC121A01E1
- **Signed**: No (open-source)
- **Dependencies**: .NET Framework (included in Windows)
- **Config files**: None

---

## Tool 03: WinMTR

- **Version**: v1.00 (static build)
- **Status**: COMPLETE
- **Files**:
  - tools/WinMTR/WinMTR-v100-static.zip (1.74 MB)
- **Source**: https://github.com/White-Tiger/WinMTR/releases/download/v1.00/WinMTR-v100-static.zip
- **SHA-256**: 2DA85A22A319E87705FA846E949E28B9A23726D161816228D49AF402D55EA60E
- **Signed**: No (open-source)
- **Dependencies**: None (static build)
- **Config files**: None

---

## Tool 04: CapFrameX

- **Version**: v1.9.2 (portable)
- **Status**: COMPLETE (with dependencies)
- **Files**:
  - tools/CapFrameX/release_1.9.2_portable.zip (72.87 MB)
  - tools/CapFrameX/SHA256SUMS.txt (official checksums)
- **Source**: https://github.com/CXWorld/CapFrameX/releases/download/v1.9.2/release_1.9.2_portable.zip
- **SHA-256**: 0C3374D382ABB359439F8898BDAAA1C4E6A7CC0FDD936022C0EAD0CA213BDA08
- **Checksum**: VERIFIED against official SHA256SUMS.txt
- **Signed**: No (open-source, official checksums provided)
- **Dependencies**:
  - VC++ 2015-2022 Redistributable x64: tools/CapFrameX/vc_redist.x64.exe (24.45 MB)
    SHA-256: CC0FF0EB1DC3F5188AE6300FAEF32BF5BEEBA4BDD6E8E445A9184072096B713B
    Signed: Microsoft Corporation, v14.44.35211.0
  - .NET 10.0 Desktop Runtime x64: tools/CapFrameX/windowsdesktop-runtime-10.0.0-win-x64.exe (57.43 MB)
    SHA-256: FC0494EAF529B15F74B10D920784CC618FF0845BEBFDFD5D85D585E921157A5C
    Signed: .NET, Microsoft Corporation
- **Config files**: None (portable, creates config on first run)

---

## Tool 05: O&O ShutUp10++

- **Version**: v3.7.1143.0
- **Status**: COMPLETE
- **Files**:
  - tools/OO_ShutUp10/OOSU10.exe (81.81 MB)
- **Source**: https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe
- **SHA-256**: EA2790422AA81D62F22AE93E995C205D4D7A6AC9825877CF34AD4E65A8253ECE
- **Signed**: YES — O&O Software GmbH, Berlin
- **Dependencies**: None (standalone)
- **Config files**: None (settings applied via UI, can export .cfg)

---

## Tool 06: USBTreeView

- **Version**: Latest
- **Status**: COMPLETE
- **Files**:
  - tools/USBTreeView/usbtreeview.zip (910.8 KB)
- **Source**: https://www.uwe-sieber.de/files/usbtreeview.zip
- **SHA-256**: 558620110D614A0859D08550C9D0259C2CABC7D8444DC8DF43754A64380B85D4
- **Signed**: Not checked (zip archive)
- **Dependencies**: None (portable)
- **Config files**: None

---

## Tool 07: ISLC (Intelligent Standby List Cleaner)

- **Version**: v1.0.3.2
- **Status**: COMPLETE
- **Files**:
  - tools/ISLC/ISLC_v1.0.3.2.exe (373.6 KB)
- **Source**: https://www.wagnardsoft.com/ISLC/ISLC%20v1.0.3.2.exe
- **SHA-256**: FC4961D4FFA095EB150B29CEB9D26A77098988C6549FE6187DBB80BFA2A6A381
- **Signed**: Not checked (publisher: Wagnardsoft)
- **Dependencies**: None (standalone)
- **Config files**: None (saves settings in-app)

---

## Tool 08: LatencyMon

- **Version**: Latest
- **Status**: COMPLETE
- **Files**:
  - tools/LatencyMon/LatencyMon.exe (3.6 MB)
- **Source**: https://www.resplendence.com/download/LatencyMon.exe
- **SHA-256**: C124342DA2A844DA0699901476B27226DA1D0D30BF8E940C9F847D67D46A1157
- **Signed**: Not checked (publisher: Resplendence Software Projects)
- **Dependencies**: None (standalone)
- **Config files**: None

---

## Tool 09: QuickCPU

- **Version**: Latest
- **Status**: COMPLETE
- **Files**:
  - tools/QuickCPU/QuickCpuSetup.msi (35.02 MB)
- **Source**: https://coderbag.com/assets/downloads/quickcpu/QuickCpuSetup.msi
- **SHA-256**: 9668D980F36087B56849D207A5ABEB709686D9167F621AB2076F8BEBE52AED6A
- **Signed**: YES — CoderBag LLC, California
- **Dependencies**: None
- **Config files**: None (reads system state live)
- **Note**: MSI installer, not portable

---

## Tool 10: GPU-Z

- **Version**: v2.72.0
- **Status**: COMPLETE
- **Files**:
  - tools/GPU-Z/GPU-Z.exe (12.43 MB)
- **Source**: TechPowerUp (2-step POST download)
- **SHA-256**: 3B15545F3EDF7F2C714A32C7EE2BEDD9823FEE7D23A20E15F2E29CD2FEE25323
- **Signed**: YES — TechPowerUp LLC, Washington
- **Dependencies**: None (standalone)
- **Config files**: None

---

## Tool 11: ThrottleStop

- **Version**: v9.7.3
- **Status**: COMPLETE
- **Files**:
  - tools/ThrottleStop/ThrottleStop.zip (1.71 MB)
- **Source**: TechPowerUp (2-step POST download)
- **SHA-256**: 7B5E1A650A845CDAB200BD6A7766D8F56AE458F633A6F2F3DF5A9EC72847098A
- **Signed**: Not checked (zip archive)
- **Dependencies**: None (portable)
- **Config files**: None (creates ThrottleStop.ini on first run)
- **Note**: Limited on LOCKED i5-13400F — no voltage/ratio changes.
  Useful for: monitoring, C-state control, TSC frequency lock, SpeedShift.

---

## Tool 12: DDU (Display Driver Uninstaller)

- **Version**: v18.1.6.3
- **Status**: COMPLETE
- **Files**:
  - tools/DDU/DDU_v18.1.6.3.exe (1.77 MB) — Self-extracting EXE
- **Source**: TechPowerUp (2-step POST download)
- **SHA-256**: 3D53FCC3506F4B9A55204B0C7E98F0B0E7A67ABA113856B87AC6F4F631E481A6
- **Signed**: YES — Wagnardsoft, Quebec, CA
- **Dependencies**: None
- **Config files**: None

---

## Tool 13: IRQControl (Standalone)

- **Version**: v1.0.0.65 **BETA**
- **Status**: COMPLETE
- **Files**:
  - tools/IRQControl/irqcontrolsetup64.exe (1.51 MB)
- **Source**: https://dl.bitsum.com/files/beta/irqcontrolsetup64.exe
- **SHA-256**: 0B3113EB359C88678310A2DFD66EBE9AB80CEED1D60EA4FB2EBCB5F5B67451D7
- **Signed**: YES — Bitsum Technologies (Bitsum LLC)
- **Dependencies**: None
- **Config files**:
  - configs/IRQControl/YAZX_InterruptAffinity_Guide.md (theory guide)
- **Note**: Standalone free tool from Bitsum. Also integrated in
  Process Lasso Pro. This is the BETA standalone installer.
  IRQ affinity assignments are NOT pre-configured — the guide
  provides theory only. Apply manually post-format after benchmarking.

---

## Tool 14: CrystalDiskInfo

- **Version**: 9.9.5 (target)
- **Status**: NOT DOWNLOADED — requires manual download
- **Files**: tools/CrystalDiskInfo/ (EMPTY)
- **Source**: https://crystalmark.info/en/download/
- **Alt source**: https://sourceforge.net/projects/crystaldiskinfo/files/9.9.5/
- **SHA-256**: Not yet available
- **Signed**: Unknown
- **Dependencies**: None (portable ZIP)
- **Config files**: None
- **Why not downloaded**: SourceForge and crystalmark.info block automated HTTP (403)
- **Priority**: Medium — NVMe health monitoring

---

## Tool 15: CrystalDiskMark

- **Version**: 9.0.3 (target)
- **Status**: NOT DOWNLOADED — requires manual download
- **Files**: tools/CrystalDiskMark/ (EMPTY)
- **Source**: https://crystalmark.info/en/download/
- **Alt source**: https://sourceforge.net/projects/crystaldiskmark/files/9.0.3/
- **SHA-256**: Not yet available
- **Signed**: Unknown
- **Dependencies**: None (portable ZIP)
- **Config files**: None
- **Why not downloaded**: SourceForge and crystalmark.info block automated HTTP (403)
- **Priority**: Medium — storage benchmark

---

## Tool 16: HWiNFO

- **Version**: v8.60+ (target)
- **Status**: NOT DOWNLOADED — requires manual download
- **Files**: tools/HWiNFO/ (EMPTY)
- **Source**: https://www.hwinfo.com/download/
- **SHA-256**: Not yet available
- **Signed**: Unknown
- **Dependencies**: None (choose portable version)
- **Config files**: None
- **Why not downloaded**: hwinfo.com blocks automated HTTP (403)
- **Priority**: High — comprehensive hardware monitoring

---

## Tool 17: SG TCP Optimizer

- **Version**: Latest
- **Status**: NOT DOWNLOADED — requires manual download
- **Files**: tools/SG_TCP_Optimizer/ (EMPTY)
- **Source**: https://www.speedguide.net/downloads.php
- **SHA-256**: Not yet available
- **Signed**: Unknown
- **Dependencies**: None (standalone EXE)
- **Config files**: None
- **Why not downloaded**: speedguide.net blocks automated HTTP (403)
- **Priority**: High — TCP/IP optimization

---

## VST Plugins (for Equalizer APO)

- **Status**: COMPLETE (copied to YAZX_GitHub)
- **Files**:
  - exports/VSTPlugins/rnnoise_stereo.dll (8.4 MB) — RNNoise noise suppression
  - exports/VSTPlugins/ReaPlugs/ (267 files, 4.1 MB) — REAPER VST plugin suite
    Key DLLs: reacomp-standalone.dll, reagate-standalone.dll,
    reaeq-standalone.dll, reafir_standalone.dll, reastream-standalone.dll
- **Source**: Original backup (E:\YAZX_Backup\yazx_VSTPlugins)
- **Dependencies**: Equalizer APO must be installed first
- **Config files**:
  - exports/EqualizerAPO/mic.txt — HyperX mic VST processing chain:
    1. RNNoise stereo (noise suppression, VAD threshold 0.85)
    2. ReaComp (compressor with specific parameters)
    3. ReaGate (noise gate with specific parameters)
  - exports/EqualizerAPO/backup_HyperX_Speakers.reg — Device selection
  - exports/EqualizerAPO/config.txt — 0 bytes (no speaker EQ, intentional)
- **Restore steps**:
  1. Install Equalizer APO
  2. Copy rnnoise_stereo.dll to EQ APO VSTPlugins directory
  3. Install ReaPlugs (or copy DLLs to VSTPlugins directory)
  4. Write `Include: mic.txt` to EQ APO config.txt
  5. Import backup_HyperX_Speakers.reg for device selection

---

## Existing Tool Configurations (not tools themselves)

### Process Lasso
- **Config**: exports/ProcessLasso/prolasso.ini (17.9 KB)
- **Rules**: 85 priority + 75 IO + 1 GPU + 68 memory = 229 total
- **Registry**: exports/ProcessLasso/ProcessLasso_HKCU.reg (11.5 KB)
- **Registry**: exports/ProcessLasso/ProcessLasso_HKLM.reg (1.7 KB)
- **CPU Affinity**: EMPTY (intentional)
- **CPU Sets**: EMPTY (intentional)
- **Restore**: Copy prolasso.ini to Process Lasso install directory

### MSI Afterburner
- **Config**: exports/MSI_Afterburner/MSIAfterburner.cfg (7.8 KB)
- **RTCore**: exports/MSI_Afterburner/RTCore.cfg (7.6 KB)
- **GPU Profile**: exports/MSI_Afterburner/Profiles/VEN_10DE...cfg (152 B)
  ALL empty = no overclock/undervolt (intentional)
- **Monitoring plugins**: 5 plugin configs in Plugins/Monitoring/
- **Restore**: Copy entire MSI_Afterburner/ to AB install directory

### NVIDIA Profile Inspector
- **Profiles**:
  - configs/NVIDIA_Inspector/Performances.nip (22.1 KB)
  - configs/NVIDIA_Inspector/Performances_CPU.nip (22.1 KB)
  - configs/NVIDIA_Inspector/QuakedV2.nip (6.5 KB)
- **Guide**: configs/NVIDIA_Inspector/YAZX_LowLatency_Profile.md
- **Restore**: Import .nip files in NVIDIA Profile Inspector

### Realtek NIC
- **Current config**: exports/Realtek_Current.reg
- **Alternative**: exports/Realtek_Balanced_Alt.reg
- **Comparison**: configs/Realtek/YAZX_Realtek_Config_Comparison.md
- **RSS optimization**: configs/Realtek/YAZX_Apply_RSS_Affinity.ps1 (diagnostic)
- **RSS registry**: configs/Realtek/YAZX_RSS_PCore_Affinity.reg

### LibreWolf (Full Profile Data)
- **Preferences**: configs/LibreWolf/prefs.js (13,191 bytes)
- **Extension List**: configs/LibreWolf/extensions.json (80,887 bytes)
- **Handler Config**: configs/LibreWolf/handlers.json (297 bytes)
- **Search Config**: configs/LibreWolf/search.json.mozlz4 (313 bytes)
- **Extensions (XPI)**: configs/LibreWolf/extensions/ (5 files, 37.6 MB)
  - CookieAutoDelete@kennydo.com.xpi (747 KB)
  - skipredirect@sblask.xpi (84 KB)
  - uBlock0@raymondhill.net.xpi (6.0 MB) — uBlock Origin
  - {74145f27-f039-47ce-a470-a662b129930a}.xpi (1.0 MB)
  - {b86e4813-687a-43e6-ab65-0bde4ab75758}.xpi (28.9 MB)
- **Extension Storage**: configs/LibreWolf/storage_default/ (42 files, 40.5 MB)
  - uBlock Origin data (custom filters, rules, settings)
  - Other extension persistent data (CookieAutoDelete, etc.)
- **Total**: 51 files, 77.32 MB
- **Sensitive Data**: EXCLUDED — no passwords (key4.db), no cookies
  (cookies.sqlite), no certificates (cert9.db), no logins (logins.json),
  no form history, no browsing history
- **Note**: prefs.js + extensions.json alone do NOT represent a complete
  profile. XPI files provide the actual extension packages, and
  storage_default preserves uBlock Origin's custom filter lists and
  extension settings that would otherwise be lost on a fresh install.
- **Restore**: Copy entire configs/LibreWolf/ contents to new LibreWolf
  profile directory. Extensions may still need manual enabling on first launch.

### Mem Reduct
- **Config**: exports/Henry_simplewall/memreduct.ini (minimal)
- **Restore**: Copy memreduct.ini to Mem Reduct directory

### ExplorerPatcher
- **Registry**: exports/ExplorerPatcher/ExplorerPatcher_HKCU.reg (3.1 KB)
- **Installer**: Download fresh from ExplorerPatcher GitHub
- **Restore**: Install, then import ExplorerPatcher_HKCU.reg

### OpenShell
- **Registry**: exports/OpenShell/OpenShell_HKCU.reg (5,020 bytes)
- **Data Cache**: exports/OpenShell/DataCache.db (536,742 bytes)
- **Localization**:
  - exports/OpenShell/StartMenuHelperL10N.ini (12,012 bytes)
  - exports/OpenShell/StartMenuL10N.ini (295,458 bytes)
- **Program Files**: exports/OpenShell/Program/ (9 files, 5.2 MB)
  - StartMenu.exe, StartMenuDLL.dll, OpenShell.chm, PolicyDefinitions.zip,
    OpenShellReadme.rtf, Start Menu Settings.lnk, Start Screen.lnk,
    StartMenuHelperL10N.ini, StartMenuL10N.ini
- **Skins**: exports/OpenShell/Skins/ (16 files, 4.2 MB)
  - Classic Skin (.skin + .skin7), Full Glass, Immersive (.skin + .skin7),
    Metallic (.skin7), Metro (.skin + .skin7), Midnight (.skin7),
    Smoked Glass, Windows 8 (.skin + .skin7), Windows Aero (.skin + .skin7),
    Windows Basic, Windows XP Luna
- **Total**: 29 files, 10.12 MB
- **XML Layout**: NOT FOUND in backup — no exported menu layout .xml exists.
  The HKCU registry contains menu settings including skin selection.
  REG alone does NOT guarantee full custom layout restore; skins + program
  files are required for the visual design to apply correctly.
- **Installer**: Download fresh from OpenShell GitHub
- **Restore**: Install, copy Skins/ to install dir, import OpenShell_HKCU.reg

---

## Power Plans

- **Power_Control.reg** (1637.5 KB): FULL HKLM\...\Control\Power tree
  Contains TTCH ULTIMATE PERFORMANCE plan (GUID: fd7463fc-d008-4a42-9497-1007fc9baaf0)
  with ALL 70+ settings. IMPORTABLE with `reg import`.
- **CPU_PowerSettings.reg** (836.4 KB): Full power settings schema (570 values)
- **TTCH_UltimatePerformance_Full.txt** (12.4 KB): Text reference (`powercfg /query` dump)
- **TTCH_UltimatePerformance.pow**: 0 bytes — INVALID, do NOT use
  No valid .pow binary exists for TTCH plan. Use Power_Control.reg for restore.
- **EonX.pow** (12 KB): Alternative plan, importable with `powercfg /import`
- **EonX_Idle.pow** (262.5 KB): Idle variant, importable

---

## Discovered Kernel Settings (preserve post-format)

**Source**: exports/TweakRegistry/Kernel.reg
**Registry path**: HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel

These settings were DISCOVERED on the current system. They are
documented as existing state, NOT as recommendations. Discovery
does not prove all are beneficial — each should be evaluated
independently post-format.

| Setting | Value | Type | Purpose |
|---------|-------|------|---------|
| GlobalTimerResolutionRequests | 1 | DWORD | Allow apps to request high-res timers |
| SerializeTimerExpiration | 2 | DWORD | Distribute timer expiration across CPUs |
| DistributeTimers | 1 | DWORD | Distribute software timers across CPUs |
| DpcWatchdogProfileOffset | 0x2710 (10000) | DWORD | Extended DPC watchdog period (10 sec) |
| DynamicHeteroCpuPolicyMask | 3 | DWORD | Hetero CPU scheduling mask |
| DefaultDynamicHeteroCpuPolicy | 3 | DWORD | Default hetero CPU policy |
| DynamicHeteroCpuPolicyImportant | 1 | DWORD | Important threads → P-cores |
| DynamicHeteroCpuPolicyImportantShort | 1 | DWORD | Short important threads → P-cores |
| DynamicHeteroCpuPolicyImportantPriority | 8 | DWORD | Priority threshold for P-core |
| EnablePerCpuClockTickScheduling | 2 | DWORD | Per-CPU clock tick optimization |
| TimerCheckFlags | 0 | DWORD | Timer check disabled |

**Also present but NOT performance tweaks:**
- ObUnsecureGlobalNames (REG_MULTI_SZ): Shared memory objects
- SeTokenSingletonAttributesConfig = 3 (DWORD): Token attribute config
- obcaseinsensitive = 1 (DWORD): Standard Windows setting
- DisableExceptionChainValidation = 0 (DWORD): Security setting
- MitigationOptions (binary): Spectre/Meltdown mitigation flags
- EAFModules (empty string): EAF module list

**FileSystem settings** (exports/TweakRegistry/FileSystem.reg):

| Setting | Value | Type | Path |
|---------|-------|------|------|
| NtfsDisable8dot3NameCreation | 2 | DWORD | HKLM\..\FileSystem | Per-volume |
| NtfsDisableLastAccessUpdate | 0x80000002 | DWORD | HKLM\..\FileSystem | Disabled (optimal) |
| NtfsMemoryUsage | 0 | DWORD | HKLM\..\FileSystem | Default |
| LongPathsEnabled | 1 | DWORD | HKLM\..\FileSystem | Enabled |
| DisableDeleteNotification | 0 | DWORD | HKLM\..\FileSystem | TRIM enabled |

---

## Summary

| Category | Count | Status |
|----------|-------|--------|
| Tools COMPLETE | 13 | Downloaded with SHA-256 |
| Tools NOT DOWNLOADED | 4 | Manual download required |
| Dependencies | 2 | VC++ 2015-2022 + .NET 10 Runtime |
| VST plugins | 268 files | Copied from backup |
| Tool configs | 7 sets | Process Lasso, MSI AB, NVIDIA, Realtek, EQ APO, Mem Reduct, ParkControl |
| App configs | 2 sets | ExplorerPatcher, OpenShell |
| Power plans | 3 valid | Power_Control.reg, EonX.pow, EonX_Idle.pow |
| Power plans INVALID | 1 | TTCH .pow = 0 bytes |
| Kernel settings | 11 | Documented from Kernel.reg |
| FileSystem settings | 5 | Documented from FileSystem.reg |
| Controller profiles | 3 | PS5 DualSense .vdf |
| Driver inventory | 3 files | CSV + details + pnputil |
| Hardware info | 7 files | BIOS, CPU, Disk, GPU, MB, Network, RAM |
