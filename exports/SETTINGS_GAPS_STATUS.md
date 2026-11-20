# YAZX Settings Gaps — Phase 2.5 Revised Assessment
# From Phase 2 Audit: 16 gaps identified
# REVISED: 2026-11-20 after backup discovery + Power_Control.reg analysis
# Classification:
#   A = Actual export recovered (binary/registry file usable for restore)
#   B = Confirmed state from backup (intentionally empty or never existed)
#   C = Documentation only (guide written, no exportable config)
#   D = Inaccessible (blocked, no workaround)

## Category A: Actual Export (5 gaps)

1. **Game Mode / GameDVR** — [A] ACTUAL EXPORT
   - Exported: GameBar_Settings.reg, GameConfigStore_Full.reg (163 KB)
   - Contains current values directly importable post-format
   - GameDVR=0, FSEBehavior=2, all FSE values preserved

2. **Services Startup State** — [A] ACTUAL EXPORT
   - Exported: Services_StartupState.txt + Services_All.csv
   - Contains all 64 services with startup type and status
   - Note: Text/CSV reference — manual restore per-service post-format

3. **Process Lasso Native Rules** — [A] ACTUAL EXPORT (from backup)
   - File: exports/ProcessLasso/prolasso.ini (17.9 KB)
   - Recovered from E:\YAZX_Backup — contains all 85+75+68+1 = 229 rules
   - Directly usable: copy to Process Lasso install directory post-format

4. **ParkControl / Core Parking Settings** — [A] UPGRADED from C
   - **Power_Control.reg** (1637.5 KB) — FULL `HKLM\...\Control\Power` tree
     Contains 70 TTCH ULTIMATE PERFORMANCE plan entries with actual values
     for core parking, processor states, boost behavior, EPP — everything
   - **CPU_PowerSettings.reg** (836.4 KB) — Full power settings schema with
     570 ACSettingIndex/DCSettingIndex values, 20 core parking entries
   - **CPU_PowerCfg_Current.txt** (42.4 KB) — Text reference of current state
   - All importable via reg import or as reference for powercfg commands
   - Covers everything ParkControl configures and more

5. **Power Plan Export** — [A] UPGRADED from D
   - **Power_Control.reg** (1637.5 KB) — Contains the TTCH ULTIMATE PERFORMANCE
     plan (GUID: fd7463fc-d008-4a42-9497-1007fc9baaf0) with ALL settings in
     registry format. Importable with `reg import`.
   - **EonX.pow** (12 KB) — Real importable .pow file (alternative plan)
   - **EonX_Idle.pow** (262.5 KB) — Real importable .pow file (idle variant)
   - **TTCH_UltimatePerformance.pow** — 0 bytes (failed export, unusable)
   - **PowerPlan_Full_Query.txt** (12.1 KB) — Text reference
   - Recovery path: Import Power_Control.reg to restore full power settings
     including TTCH plan, then import EonX.pow as supplementary plan

## Category B: Confirmed State (4 gaps)

6. **Process Lasso CPU Affinity** — [B] CONFIRMED EMPTY in backup
   - prolasso.ini confirms DefaultAffinitiesEx is empty
   - INTENTIONAL — user never set CPU affinity rules
   - NOT a gap to fill. Preserve as-is.

7. **Process Lasso CPU Sets** — [B] CONFIRMED EMPTY in backup
   - CPU Sets were never configured by the user
   - INTENTIONAL — Preserve as-is.

8. **MSI Afterburner GPU Profile** — [B] UPGRADED from C
   - Profile .cfg files exist: MSI_Afterburner/Profiles/MSIAfterburner.cfg (3.5 KB)
   - Per-GPU profile: VEN_10DE&DEV_2504&...cfg (0.1 KB) — RTX 3060 specific
   - ALL values empty = INTENTIONAL no overclock/undervolt state
   - The .cfg files themselves ARE the exportable config (empty is the config)
   - Full MSIAfterburner.cfg (7.8 KB) + RTCore.cfg (7.6 KB) also preserved

9. **simplewall Config** — [B] CONFIRMED NEVER INSTALLED
   - Henry++ = Mem Reduct only, NOT simplewall
   - Mem Reduct config exported: Henry_simplewall/memreduct.ini (minimal)
   - No gap exists. The original assumption was wrong.

## Category C: Documentation Only (2 gaps)

10. **Equalizer APO Device Selection** — [A] UPGRADED from C
    - **mic.txt** (1 KB) — REAL user config with 3 VST plugins:
      1. RNNoise stereo (noise suppression, VAD threshold 0.85)
      2. ReaComp (compressor with specific parameters)
      3. ReaGate (noise gate with specific parameters)
      Device: Microphone HyperX Virtual Surround Sound
    - **backup_HyperX_Speakers.reg** (0.4 KB) — Device selection backup
    - config.txt is 0 bytes — speaker config was never customized (intentional)
    - Example files preserved (demo.txt, iir_lowpass.txt, etc.)
    - Recovery: Install EQ APO, write `Include: mic.txt` to config.txt,
      install RNNoise + ReaPlugs VST, import HyperX backup reg

11. **RTSS Installation** — [C] DOCUMENTATION ONLY
    - RTSS was not separately installed (only in Afterburner Redistributable)
    - No config to export. No RTSS settings files exist.
    - Setup guide: configs/RTSS/YAZX_RTSS_Setup.md

12. **Realtek NIC RSS Optimization** — [C] NEW OPTIMIZATION
    - Current RSS config is driver default (auto-assigned queues)
    - Created diagnostic script: configs/Realtek/YAZX_Apply_RSS_Affinity.ps1
    - This is a NEW optimization candidate, not an existing setting to export
    - Current Realtek NIC settings already exported: Realtek_Current.reg

## Category D: Inaccessible (4 gaps)

13. **Memory Compression State** — [D] INACCESSIBLE
    - Get-MMAgent requires admin elevation
    - DisablePageCombining not in registry (using system default)
    - Cannot determine or export current state
    - Workaround: Document in Module 14 for post-format diagnostic check

14. **Scheduled Tasks Export** — [D] INACCESSIBLE
    - reg export of HKLM TaskCache\Tree requires elevation
    - Cannot access custom task definitions
    - Workaround: Critical tasks documented from Services_All.csv cross-reference

15. **Autologgers/ETW Export** — [D] INACCESSIBLE
    - reg export of HKLM Autologger requires elevation
    - Cannot access logger configurations
    - Workaround: Document known loggers for manual post-format setup

16. **BCD Store Full Export** — [D] PARTIAL DATA
    - bcdedit requires elevation for full export
    - Partial data from registry (SystemStartOptions):
      NOEXECUTE=OPTIN, USEPLATFORMTICK, DISABLEDYNAMICTICK, NOVGA
    - BCD_Alternative_Export.txt (0.8 KB) — partial capture
    - Full BCD enum unavailable without admin

## Revised Summary

| Category | Count | Was | Description |
|----------|-------|-----|-------------|
| A — Actual export | **6** | 3 | +ParkControl, +Power Plan, +EQ APO (mic.txt has real VST config) |
| B — Confirmed state | **4** | 2 | +MSI Afterburner (empty=intentional), +simplewall (never existed) |
| C — Documentation only | **2** | 6 | RTSS, Realtek RSS |
| D — Inaccessible | **4** | 5 | -Power Plan (moved to A via reg export) |
| **Total** | **16** | 16 | |

## Key Improvements from Backup Discovery

1. **Power_Control.reg** (1637.5 KB) — The single most important file found.
   Contains the ENTIRE `HKLM\SYSTEM\CCS\Control\Power` tree including:
   - TTCH ULTIMATE PERFORMANCE plan with all 70+ setting entries
   - Core parking configuration (what ParkControl manages)
   - CPU performance states, boost mode, EPP values
   - Hibernate disabled, Modern Standby disabled, power saving off
   - Class1InitialUnparkCount = 64 (all cores unparked)

2. **EonX.pow** + **EonX_Idle.pow** — Real importable power plans
   Not the TTCH plan, but alternative plans the user had configured.

3. **MSI Afterburner .cfg files** — The empty profile configs ARE the config.
   "No overclock applied" is a preserved state, not a missing export.

## Honest Assessment
- **Usable data**: 10 (A+B) — files that restore settings or confirm state
- **Documentation only**: 2 (C) — guides for manual post-format setup (RTSS, Realtek RSS)
- **Still inaccessible**: 4 (D) — blocked by admin, partial workarounds exist
- Previous claim of 5 usable → now 10 usable. Major improvement from backup discovery.
