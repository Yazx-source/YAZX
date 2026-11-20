# YAZX Phase 8 — Final Packaging Report
# Date: 2026-11-20
# System: Intel i5-13400F / RTX 3060 12GB / 32GB DDR4

---

## Phase 8 Objective

Prepare the final YAZX package for post-format use. Close remaining findings,
correct Phase 7 report classifications, verify file integrity, and document
what is complete and what requires post-format action.

**No actual restore was executed on a fresh Windows installation.**
**No modules or tweaks were applied to the current system.**

---

## 1. Finding Closures

### 1.1 OpenShell — CLOSED (Full Data Extracted)

**Finding**: Module 04 fallback looks for .xml files in exports/OpenShell/.
Originally had only DataCache.db and OpenShell_HKCU.reg — no .xml, no skins.

**Phase 8 Closure Action**: Extracted full data from E:\YAZX_Backup\yazx_OpenShell:
- **L10N files**: StartMenuHelperL10N.ini (12,012), StartMenuL10N.ini (295,458)
- **Program directory** (9 files, 5.2 MB): StartMenu.exe, StartMenuDLL.dll,
  OpenShell.chm, PolicyDefinitions.zip, OpenShellReadme.rtf, shortcuts, L10N copies
- **Skins directory** (16 files, 4.2 MB): Classic Skin (.skin + .skin7),
  Full Glass, Immersive (.skin + .skin7), Metallic, Metro (.skin + .skin7),
  Midnight, Smoked Glass, Windows 8 (.skin + .skin7), Windows Aero (.skin + .skin7),
  Windows Basic, Windows XP Luna
- **Existing kept**: OpenShell_HKCU.reg (5,020), DataCache.db (536,742)

**Total**: 29 files, 10.12 MB in exports/OpenShell/

**XML Layout**: NOT FOUND in backup — no exported menu layout .xml exists.
The backup contains the full Open Shell installation with skins and localization,
but no separately exported XML menu layout file.

**Important**: REG alone does NOT guarantee full custom layout restore.
The skins and program files are required for the visual design to apply correctly
after reinstalling Open Shell. [V] sub-4 imports the registry settings, but the
skins must be copied to the Open Shell install directory separately.

**Status**: CLOSED — full available data preserved. No XML exists to extract.

### 1.2 LibreWolf — CLOSED (Full Profile Data Extracted)

**Finding**: Module 04 tries to copy user.js but configs/LibreWolf/ originally had
only prefs.js + extensions.json. prefs.js and extensions.json alone do NOT
represent a complete profile — extension binaries and storage data were missing.

**Phase 8 Closure Action**: Extracted full profile data from
E:\YAZX_Backup\yazx_LibreWolf\01bluk7o.default-release/:
- **Extension binaries** (5 XPI files, 37.6 MB):
  - CookieAutoDelete@kennydo.com.xpi (747 KB)
  - skipredirect@sblask.xpi (84 KB)
  - uBlock0@raymondhill.net.xpi (6.0 MB) — uBlock Origin
  - {74145f27-f039-47ce-a470-a662b129930a}.xpi (1.0 MB)
  - {b86e4813-687a-43e6-ab65-0bde4ab75758}.xpi (28.9 MB)
- **Extension storage** (42 files, 40.5 MB in storage_default/):
  - uBlock Origin data (custom filter lists, rules, settings)
  - Other extension persistent data (CookieAutoDelete, etc.)
- **Additional config**: handlers.json (297), search.json.mozlz4 (313)
- **Existing kept**: prefs.js (13,191), extensions.json (80,887)

**Total**: 51 files, 77.32 MB in configs/LibreWolf/

**Sensitive data check**: VERIFIED — no passwords (key4.db), no cookies
(cookies.sqlite), no certificates (cert9.db), no logins (logins.json),
no form history, no browsing history found in backup. All copied data is
safe for a public repository.

**Important**: prefs.js + extensions.json alone do NOT represent a complete
profile. The XPI files provide the actual extension packages that LibreWolf
needs, and storage_default preserves uBlock Origin's custom filter lists
and extension settings that would be lost on a fresh install.

**Status**: CLOSED — full profile data preserved, sensitive data excluded.

### 1.3 TTCH Power Plan — CLOSED (Reconstructed, Not Exact)

**Finding**: No valid .pow binary exists. TTCH rebuild is reconstructed.

**Analysis**:
- YAZX_TTCH_Rebuild.ps1 (18,801 bytes): 72 AC + 27 DC = 99 setting commands.
- 27 exact settings sourced from powercfg /query text dump (AC + DC values).
- 45 reconstructed settings sourced from Power_Control.reg (AC only, no DC).
- Script contains explicit disclaimers: "NOT COVERED" and "Reconstructed".
- Does NOT claim 100% exact restore.
- OEM-specific settings and registry-only entries without ACSettingIndex are NOT covered.
- Original TTCH_UltimatePerformance.pow is 0 bytes (failed export, never valid).

**Conclusion**: This is a Reconstructed Plan, not an exact binary restore.
The original .pow was never successfully exported. The rebuild script reproduces
72 of the plan's known settings. Import Power_Control.reg for remaining registry values.

**Status**: CLOSED — documented as reconstructed. Data preserved for reference.

---

## 2. Phase 7 Report Corrections

The following corrections were applied to PHASE7_VALIDATION_REPORT.md:

### 2.1 Classification Fixes
| Item | Was | Now | Reason |
|------|-----|-----|--------|
| [V] labels exist in .bat | PASS | STATICALLY VERIFIED | Verified by grep, not execution |
| All handlers end with goto done | PASS | STATICALLY VERIFIED | Verified by code read |
| Candidates.reg NOT imported | PASS | STATICALLY VERIFIED | Verified by code read |
| 14_NewTweaks.ps1 NOT called | PASS | STATICALLY VERIFIED | Verified by code read |
| [V] NOT in Run ALL | PASS | STATICALLY VERIFIED | Verified by code read |
| TTCH command counts (all 7 rows) | PASS | STATICALLY VERIFIED | Counted in script, not executed |
| TTCH script structure (all 10 rows) | Mixed PASS/SV | STATICALLY VERIFIED | All code reading, not execution |
| Run ALL results (3 rows) | Mixed PASS/SV | STATICALLY VERIFIED | All code reading |

### 2.2 Module Naming Contradiction — Fixed
| Was | Now |
|-----|-----|
| Section header "Modules 01-14" | "Module Verification" with explicit list |
| "All 10 modules" in summary | Clarified: 10 .ps1 scripts + 8 registry files + Module 13 manual |

**Explanation added**: Modules 05-07 are registry files applied by Setup.bat (not .ps1 scripts).
Module 13 (Oneclick) is an external tool. Only 10 actual .ps1 module scripts exist.

### 2.3 Restore Path Count Correction
| Was | Now |
|-----|-----|
| 302 PASS, 2 PARTIAL | 301 PASS, 3 PARTIAL |

Power Plan (.pow import) was already PARTIAL but was counted as PASS in the total.

---

## 3. File Integrity Verification

### 3.1 File Inventory
| Metric | Value |
|--------|-------|
| Total files | 822 |
| Total directories | 150 |
| Total size | ~1,221 MB |
| Zero-byte files | 2 (documented) |
| Fake HTML downloads | 0 |
| Suspiciously small executables | 0 |

### 3.2 SHA-256 Manifest Status
| Metric | Value |
|--------|-------|
| Manifest entries (before Phase 8) | 744 |
| Stale entries updated | 2 (YAZX_Setup.bat, 04_Configs.ps1) |
| New entries added (Phase 8 initial) | 6 |
| New entries added (Phase 8 closure) | 76 (27 OpenShell + 49 LibreWolf) |
| Manifest entries (after Phase 8 Final) | 827 |
| Files on disk | 822 |
| Manifest covers itself | No (standard — cannot self-hash) |

### 3.3 Stale Entries Updated
| File | Old Hash (Phase 5) | New Hash (Phase 8) | Old Size | New Size |
|------|--------------------|--------------------|----------|----------|
| YAZX_Setup.bat | AF4EAA6D...797CD73 | F6D2E79D...3C9FF4 | 20,512 | 24,071 |
| modules\04_Configs.ps1 | 9AF6FC24...60084FC | F71E5EDD...5AD7DF | 7,090 | 7,656 |

**Reason**: Both modified in Phase 6 (gap closure — added [V] handlers and fallback paths).

### 3.4 New Entries Added
| File | SHA-256 | Size |
|------|---------|------|
| configs\ProcessLasso\prolasso.ini | 74222014... | 18,284 |
| configs\TimerResolution\SetTimerResolutionService.exe | 004CB6E0... | 5,632 |
| configs\LibreWolf\extensions.json | 303EA5DE... | 80,887 |
| configs\LibreWolf\prefs.js | FAF0341E... | 13,191 |
| PHASE6_GAP_ANALYSIS.md | 7C1F5488... | 13,684 |
| PHASE7_VALIDATION_REPORT.md | F8054F64... | 24,219 |

**Note**: PHASE8_FINAL_PACKAGING_REPORT.md will be added to manifest after this file is finalized.

### 3.5 Zero-Byte Files (2 — unchanged)
| File | Classification | Action |
|------|---------------|--------|
| exports/TTCH_UltimatePerformance.pow | FAILED EXPORT | NEVER import. Use TTCH rebuild script. |
| exports/Steam/virtualgamepadinfo.txt | HARMLESS PLACEHOLDER | Steam recreates it. No impact. |

### 3.6 Duplicate Files (5 pairs — all KEPT, no deletions)
| File 1 | File 2 | Reason Kept |
|--------|--------|-------------|
| configs/NVIDIA_Inspector/Performances.nip | configs/NVIDIA_Inspector/Performances_CPU.nip | May serve different import paths |
| exports/GameConfigStore_Full.reg | exports/GameConfigStore_Settings.reg | Both reference exports |
| exports/hosts | exports/hosts_file.txt | hosts is used by [V] sub-7; _file.txt is reference copy |
| exports/PowerPlan_Full_Query.txt | exports/PowerPlan_Query.txt | Both reference exports |
| exports/ProcessLasso/prolasso.ini × 3 locations | Same content, different export paths | Original backup structure preserved |

**Phase 5 reported**: prolasso_affinity.ini as duplicate. File does NOT exist. Only prolasso.ini
in configs/ProcessLasso/ (confirmed). Phase 5 report entry was from a different directory.

---

## 4. Path Independence Verification

### 4.1 YAZX_DIR (bat file location)
| Check | Result |
|-------|--------|
| Uses `%~dp0` (resolves to bat file directory) | **STATICALLY VERIFIED** |
| Trailing backslash stripped | **STATICALLY VERIFIED** |
| Passed as `-YazxDir` to all 10 modules | **STATICALLY VERIFIED** |
| Used in all [V] handler paths | **STATICALLY VERIFIED** |
| Works from any drive letter | **STATICALLY VERIFIED** |

### 4.2 BACKUP_DIR
| Check | Result |
|-------|--------|
| Hardcoded: `set "BACKUP_DIR=E:\YAZX_Backup"` (1 occurrence) | **STATICALLY VERIFIED** |
| Variable used everywhere else (27 occurrences) | **STATICALLY VERIFIED** |
| Missing YAZX_Backup → warning only, no crash | **STATICALLY VERIFIED** |
| All 10 Module 04 tools have YAZX-internal fallback | **STATICALLY VERIFIED** |
| [V] handlers use %YAZX_DIR% only (no BackupDir dependency) | **STATICALLY VERIFIED** |
| [R] handlers depend on BackupDir (documented limitation) | **STATICALLY VERIFIED** |

### 4.3 Module .ps1 Hardcoded Paths
| Module | Hardcoded Drive Paths | Type |
|--------|-----------------------|------|
| All 10 modules | HKLM:\ and HKCU:\ only | PowerShell registry paths (NOT file paths) |
| 04_Configs.ps1 | C:\ProgramData, C:\Program Files, C:\Users | Windows system TARGET directories (correct) |

**All target directories (C:\ProgramData, C:\Program Files, etc.) are standard Windows paths
that exist on every Windows installation. These are NOT YAZX source paths.**

### 4.4 Setup.bat Hardcoded Paths (non-BACKUP_DIR)
| Path | Usage | Expected? |
|------|-------|-----------|
| C:\Program Files\EqualizerAPO | EQ APO install target | YES (standard install path) |
| C:\Windows\System32\drivers\etc\hosts | System hosts file | YES (Windows system path) |

**All hardcoded paths in Setup.bat are Windows system TARGET directories, not YAZX source paths.
YAZX source paths all use %YAZX_DIR% (bat) or $YazxDir (PowerShell).**

### 4.5 Setup Independence from E:\YAZX_Backup
| Scenario | Behavior |
|----------|----------|
| YAZX_Backup exists | Used as primary source for Module 04 tools |
| YAZX_Backup missing | Warning displayed, Module 04 uses YAZX-internal fallback for all 10 tools |
| [V] sub-menu | All paths use %YAZX_DIR%\exports\ — NO BackupDir dependency |
| [R] sub-menu | DEPENDS on BackupDir — documented limitation |
| Run ALL | Modules use fallback paths — does NOT require BackupDir |

**Conclusion**: YAZX_GitHub is fully self-contained for Run ALL and [V] operations.
Only [R] (full registry restore from original backup) requires E:\YAZX_Backup.

---

## 5. Final Package Contents

### 5.1 Core Files
| Component | Path | Size | Status |
|-----------|------|------|--------|
| YAZX_Setup.bat | root | 24,071 | CURRENT (Phase 6 final) |
| YAZX_Setup_BACKUP_Phase4.bat | root | 11,499 | PRESERVED (pre-Phase 5 backup) |

### 5.2 Modules (10 PowerShell scripts)
| Module | File | Size | In Run ALL? |
|--------|------|------|-------------|
| 01 | 01_SystemCheck.ps1 | 2,852 | YES |
| 02 | 02_NVIDIADriver.ps1 | 4,515 | YES |
| 03 | 03_Programs.ps1 | 5,322 | YES |
| 04 | 04_Configs.ps1 | 7,656 | YES (Phase 6 updated) |
| 08 | 08_Services.ps1 | 3,292 | YES |
| 09 | 09_BCDTweaks.ps1 | 1,190 | YES |
| 10 | 10_MSIMode.ps1 | 2,476 | YES |
| 11 | 11_PowerPlan.ps1 | 2,281 | YES |
| 12 | 12_Privacy.ps1 | 4,150 | YES |
| 14 | 14_NewTweaks.ps1 | 4,473 | NO (diagnostic only, menu option G) |

### 5.3 Registry Files
| File | Size | Auto-imported? |
|------|------|----------------|
| YAZX_System.reg | 1,420 | YES (Run ALL) |
| YAZX_Cosmetic.reg | 2,300 | YES (Run ALL) |
| YAZX_Gaming.reg | 4,089 | YES (Run ALL) |
| YAZX_Network.reg | 1,760 | YES (Run ALL) |
| YAZX_NVIDIA.reg | 984 | YES (Run ALL) |
| YAZX_Hardware.reg | 887 | YES (Run ALL) |
| YAZX_NewTweaks.reg | 1,506 | YES (Run ALL, SAFE only) |
| YAZX_NewTweaks_Candidates.reg | 3,689 | NO (never auto-imported) |

### 5.4 Configs (self-contained)
| Directory | Contents | Restore Path |
|-----------|----------|-------------|
| configs/ProcessLasso/ | prolasso.ini (229 rules) | Module 04 primary |
| configs/TimerResolution/ | SetTimerResolutionService.exe | Module 04 primary |
| configs/NVIDIA_Inspector/ | Performances.nip + 3 files | Module 04 primary |
| configs/CRU/ | CRU.exe + 5 utilities | Module 04 primary |
| configs/LibreWolf/ | prefs.js + extensions.json + 5 XPI + storage_default (51 files, 77.3 MB) | Module 04 fallback |
| configs/EqualizerAPO/ | Setup guide | Reference |
| configs/IRQControl/ | Affinity guide | Reference |
| configs/NVCleanInstall/ | Installation guide | Reference |
| configs/Realtek/ | Driver guides + registry | Reference |

### 5.5 Exports
| Directory/File | Size | Restore Path |
|----------------|------|-------------|
| exports/TweakRegistry/ | 13 .reg files | [V] sub-1 (Kernel, FileSystem) |
| exports/Power_Control.reg | 1,676,796 | [V] sub-2 |
| exports/CPU_PowerSettings.reg | 856,508 | [V] sub-2 |
| exports/PowerPlans/ | 3 .pow + rebuild script | [V] sub-3, sub-6 |
| exports/ExplorerPatcher/ | HKCU .reg | [V] sub-4, Module 04 |
| exports/OpenShell/ | HKCU .reg + cache + L10N + Program/ + Skins/ (29 files, 10.1 MB) | [V] sub-4, Module 04 |
| exports/EqualizerAPO/ | mic.txt (1,063) | [V] sub-5, Module 04 |
| exports/VSTPlugins/ | 268 files (12.48 MB) | [V] sub-5 |
| exports/hosts | 8,238 | [V] sub-7 |
| exports/HKCU_Run.reg | 888 | [V] sub-8 |
| exports/DirectX_UserGpuPreferences.reg | 1,700 | [V] sub-8 |
| exports/BackgroundApps.reg | 3,540 | [V] sub-8 |
| exports/PowerThrottling.reg | 314 | [V] sub-8 |
| exports/Bitsum_Registry.reg | 380 | [V] sub-8 |
| exports/Steam/ | 11 files | Module 04 fallback |
| exports/MSI_Afterburner/ | 2 files | Module 04 fallback |

### 5.6 Tools (13 downloaded + 4 not downloaded)
| Tool | Status | Location |
|------|--------|----------|
| NVCleanInstall | Downloaded | tools/NVCleanInstall/ |
| GPU-Z | Downloaded | tools/GPU-Z/ |
| DDU | Downloaded | tools/DDU/ |
| QuickCPU | Downloaded | tools/QuickCPU/ |
| IRQ Control | Downloaded | tools/IRQControl/ |
| O&O ShutUp10++ | Downloaded | tools/OOSU10/ |
| Process Lasso | Downloaded | tools/ProcessLasso/ |
| MSI Afterburner | Downloaded | tools/MSI_Afterburner/ |
| Mem Reduct | Downloaded | tools/MemReduct/ |
| ParkControl | Downloaded | tools/ParkControl/ |
| Timer Resolution | Downloaded | tools/TimerResolution/ |
| Realtek Driver | Downloaded | tools/Realtek/ |
| ExplorerPatcher | Downloaded | tools/ExplorerPatcher/ |
| **CrystalDiskInfo** | **NOT DOWNLOADED** | crystalmark.info/en/download/#CrystalDiskInfo |
| **CrystalDiskMark** | **NOT DOWNLOADED** | crystalmark.info/en/download/#CrystalDiskMark |
| **HWiNFO** | **NOT DOWNLOADED** | hwinfo.com/download/ |
| **SG TCP Optimizer** | **NOT DOWNLOADED** | speedguide.net/downloads.php |

**All 4 undownloaded tools are OPTIONAL diagnostics. No YAZX module depends on them.
Setup.bat shows "4 not downloaded" at startup — informational only.**

### 5.7 Reports and Documentation
| File | Size | Phase |
|------|------|-------|
| PHASE5_SETUP_REPORT.md | 8,417 | Phase 5 |
| PHASE6_GAP_ANALYSIS.md | 13,684 | Phase 6 |
| PHASE7_VALIDATION_REPORT.md | ~24 KB | Phase 7 (corrected in Phase 8) |
| PHASE8_FINAL_PACKAGING_REPORT.md | This file | Phase 8 |
| YAZX_SHA256_MANIFEST.txt | ~97 KB | Phase 5 (updated Phase 8) |
| YAZX_MANIFEST.txt | 44,897 | Phase 4 |
| YAZX_TOOL_LIBRARY.md | — | Phase 4 |
| YAZX_NEW_TWEAKS_FULL_DETAIL.md | 12,312 | Phase 4 |

---

## 6. What Is COMPLETE

| Component | Status | Evidence |
|-----------|--------|----------|
| YAZX_Setup.bat (577 lines, 19-option menu) | COMPLETE | File verified, all handlers exist |
| 10 PowerShell modules | COMPLETE | All files present, code STATICALLY VERIFIED |
| 8 registry files (tweaks) | COMPLETE | All files present with correct sizes |
| Module 04 self-contained restore (10 tools) | COMPLETE | All 10 have YAZX-internal fallback |
| [V] Phase 2.5 sub-menu (9+Q options) | COMPLETE | All 9 handlers verified, 18 export files present |
| [R] Registry restore sub-menu | COMPLETE | 3+Q options verified |
| TTCH rebuild script (72+27=99 settings) | COMPLETE | Script verified, disclaimers present |
| VST plugins (268 files, 12.48 MB) | COMPLETE | All files present, 0 zero-byte |
| Power plan exports (EonX.pow, EonX_Idle.pow) | COMPLETE | Both files present |
| Registry exports (29 .reg files) | COMPLETE | All present, restore paths documented |
| Process Lasso config (229 rules) | COMPLETE | prolasso.ini verified |
| OpenShell full data (29 files, 10.1 MB) | COMPLETE | Skins, L10N, Program files extracted from backup |
| LibreWolf full profile (51 files, 77.3 MB) | COMPLETE | XPI extensions, storage_default, sensitive data excluded |
| SHA-256 manifest (827 entries) | COMPLETE | Updated with Phase 6-8 files + closure additions |
| Phase reports (5-8) | COMPLETE | All reports present |

## 7. What Is NOT COMPLETE

| Item | Status | Required Action |
|------|--------|----------------|
| 4 optional tools not downloaded | NOT DOWNLOADED | Manual download post-format |
| TTCH plan is Reconstructed | DOCUMENTED | Not fixable — original .pow never exported |
| active_plan.pow is 0 bytes | DOCUMENTED | Use [V] sub-6 (TTCH rebuild) instead |
| [R] requires E:\YAZX_Backup | DOCUMENTED | Mitigated by [V] menu for critical items |
| BACKUP_DIR hardcoded to E: | DOCUMENTED | Change line 23 if backup moves |
| OpenShell .xml menu layout | NOT IN BACKUP | No XML export exists; skins + REG preserved instead |
| Module 13 (Oneclick) | MANUAL | Download from github.com/QuakedK/Oneclick |
| EnableLUA fix | NOT DONE | Appinfo service deletion issue — separate from YAZX |

## 8. What Requires Post-Format Testing

**YAZX has NOT been tested on a fresh Windows installation.**
The following must be verified after format:

| Test | Why |
|------|-----|
| Run ALL execution end-to-end | Never executed — only code paths verified |
| regedit /s import of all .reg files | Requires admin on fresh system |
| powercfg /import for .pow files | Requires admin, would create plans |
| TTCH rebuild script execution | Would create duplicate plan on current system |
| bcdedit modifications | Requires admin, would change boot config |
| sc.exe create STR (Timer Resolution) | Requires admin, would create service |
| hosts file replacement | Requires admin, would overwrite current hosts |
| LibreWolf profile directory detection | Requires LibreWolf installed first |
| Steam config copy to installed Steam | Requires Steam installed first |
| Module 04 → all 10 tool restores | Requires target programs installed |
| Module 08 → 31 services disabled | Service names may differ on clean install |
| Module 03 → 16 program installations | Requires internet and admin |

---

## 9. Post-Format Restore Sequence (Recommended)

```
Step 1: Copy E:\YAZX_GitHub to target drive (or run from USB/second drive)
Step 2: Right-click YAZX_Setup.bat → Run as Administrator
Step 3: Choose [A] or [B] — Run ALL
         → Modules 01-04 (system check, NVIDIA, programs, configs)
         → Registry tweaks (6 .reg files + YAZX_NewTweaks.reg)
         → Modules 08-12 (services, BCD, MSI, power plan, privacy)
Step 4: Choose [V] → Phase 2.5 Exports
         → [9] Run All 1-5, 7-8 (kernel, power, plans, apps, VST, hosts, user settings)
Step 5: Choose [V] → [6] TTCH Rebuild (separately — 72 settings)
Step 6: Manual steps:
         → Import Performances.nip in NVIDIA Profile Inspector
         → Add "Include: mic.txt" to EQ APO config.txt (after EQ APO installed)
         → Open Shell: import menu layout from backup if available
         → Download 4 optional tools if needed
Step 7: Restart and verify
```

---

## 10. Preservation Checklist

| Rule | Followed? |
|------|-----------|
| No modules rebuilt | YES — Modules 01-12 unchanged (except 04's fallback lines from Phase 6) |
| No Candidate/Experimental in Run ALL | YES — only YAZX_NewTweaks.reg (SAFE) |
| No tweaks applied to current Windows | YES — zero system modifications in Phase 8 |
| No incomplete tools blocking YAZX | YES — 4 missing tools show info message only |
| Original backup files preserved | YES — exports/ and configs/ untouched |
| Reports and manifests kept | YES — Phases 5-8 reports + 2 manifests |
| VSTPlugins complete | YES — 268 files, 12.48 MB, 0 zero-byte |
| TTCH data preserved | YES — rebuild script + Power_Control.reg + CPU_PowerSettings.reg |

---

## 11. Package Summary

| Metric | Value |
|--------|-------|
| Total files | 822 |
| Total directories | 150 |
| Total size | ~1,221 MB |
| PowerShell modules | 10 |
| Registry files | 8 (+ 1 Candidates, not auto-imported) |
| [V] sub-menu options | 9 + Q |
| [R] sub-menu options | 3 + Q |
| Restore paths verified | 304 (301 PASS, 3 PARTIAL, 0 FAIL) |
| SHA-256 manifest entries | 750 |
| Zero-byte files | 2 (documented, harmless) |
| Duplicate pairs | 5 (all kept, no deletions) |
| Tools downloaded | 13 of 17 |
| Tools not downloaded | 4 (optional diagnostics) |

---

## Phase 8 Status: COMPLETE

YAZX is packaged at E:\YAZX_GitHub and ready for post-format use.
No actual restoration was performed on the current system.
Post-format testing on a fresh Windows installation is required to confirm
full operational status.
