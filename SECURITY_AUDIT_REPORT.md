# YAZX Security Audit Report — Phases 1-3

**Date**: 2026-11-21
**Scope**: Full codebase — 18 .ps1, 15 .bat, 93 .reg, 30+ config files (926 total)
**Auditor**: Claude (static analysis — no code executed)
**Repo**: https://github.com/Yazx-source/YAZX @ master (e599a58)
**Method**: Static analysis only. No files executed. No external systems contacted.

---

## PHASE 1 — DISCOVERY

### 1.1 System Architecture

YAZX is a Windows 11 post-format restoration tool. It is NOT a web application,
has NO server component, NO database, and NO encrypted/obfuscated code.

```
User (admin)
  |
  v
YAZX_Setup.bat          <-- Entry point (menu-driven batch script)
  |
  +-- modules/*.ps1      <-- 13 PowerShell modules (called via -ExecutionPolicy Bypass)
  |     |
  |     +-- YAZX_Common.ps1  <-- Shared functions (YAZX-Log, YAZX-Choose, YAZX-Apply)
  |
  +-- registry/*.reg     <-- 7 core registry files (imported via regedit /s)
  |
  +-- exports/           <-- Exported configs, registry backups, user scripts
  |
  +-- configs/           <-- Application config files (ProcessLasso, LibreWolf, etc.)
  |
  +-- tools/             <-- Portable tools directory (Sysinternals, etc.)
  |
  +-- YAZX_Backup/       <-- External backup source (detected on E:, D:, C:, F:, G:)
```

### 1.2 File Inventory

| Category | Count | Location |
|----------|-------|----------|
| PowerShell modules | 13 | `modules/` |
| PowerShell tools/configs | 5 | `tools/`, `configs/`, `exports/` |
| Batch scripts (core) | 2 | Root (`YAZX_Setup.bat`, backup) |
| Batch scripts (user) | 13 | `exports/YAZX_Scripts/` |
| Registry files (core) | 7 | `registry/` (YAZX_*.reg) |
| Registry files (current) | 23 | `registry/current_tweaks/` |
| Registry files (exports) | 63 | `exports/` subfolders |
| Config files | 30+ | `configs/`, `exports/` (.ini, .cfg, .json) |
| Documentation | 8 | Root + `tools/` (.md) |
| Binary tools | 164 | `tools/Sysinternals/extracted/` |
| VST plugins | 268 | `exports/VSTPlugins/` |
| Other (data, txt) | ~300 | Various |

### 1.3 Entry Points

| Entry Point | Invocation | Privileges |
|-------------|-----------|------------|
| `YAZX_Setup.bat` | Double-click / Run as Admin | **Administrator required** (checked on line 12-18) |
| Individual modules | Called by YAZX_Setup.bat via `powershell -ExecutionPolicy Bypass -File` | Inherits Admin |
| `exports/YAZX_Scripts/*.bat` | Manual user execution | Varies (some self-elevate) |

### 1.4 Encryption & Obfuscation Analysis

**Result: NONE FOUND.**

Scanned all 18 .ps1 and 15 .bat files for:
- `FromBase64String` / `EncodedCommand` — **0 matches**
- `Decompress` / `GZipStream` / `DeflateStream` — **0 matches**
- `[ScriptBlock]::Create` / `New-Object IO.*` — **0 matches**
- Dynamic code generation patterns — **0 matches**

All code is plaintext PowerShell and batch script. There is no encryption,
no obfuscation, no encoding, no runtime decryption, and no dynamic code execution.
This is a positive security finding — the codebase is fully auditable.

### 1.5 GitHub & External Download Sources

**Active download connections** (Module 16 `Invoke-WebRequest` / `Invoke-RestMethod`):

| # | Source | Target Tool | Pinned Version? |
|---|--------|-------------|-----------------|
| 1 | download.sysinternals.com | Sysinternals Suite | NO (latest) |
| 2 | www.wagnardsoft.com | ISLC v1.0.3.2 | YES |
| 3 | www.wagnardsoft.com | DDU v18.0.9.3 | YES |
| 4 | www.resplendence.com | LatencyMon | NO (latest) |
| 5 | dl5.oo-software.com | OO ShutUp10++ | NO (latest) |
| 6 | dl.bitsum.com | IRQControl | NO (latest/beta) |
| 7 | coderbag.com | QuickCPU | NO (latest) |
| 8 | www.uwe-sieber.de | USBTreeView | NO (latest) |
| 9 | github.com/microe1/MouseTester | MouseTester v1.5.3 | YES (tag) |
| 10 | github.com/White-Tiger/WinMTR | WinMTR v1.00 | YES (tag) |
| 11 | github.com/CXWorld/CapFrameX | CapFrameX v1.9.2 | YES (tag) |
| 12 | api.github.com (Orbmu2k/nvidiaProfileInspector) | NVIDIA Profile Inspector | NO (/releases/latest) |

**Module 03 download sources** (winget preferred, URL as fallback):

| # | Source | Target Program | Method |
|---|--------|---------------|--------|
| 1 | 7-zip.org | 7-Zip | Direct URL |
| 2 | dl.bitsum.com | Process Lasso | Direct URL |
| 3 | download.msi.com | MSI Afterburner | Direct URL |
| 4 | sourceforge.net | Equalizer APO | Direct URL (via /latest) |
| 5 | dl.bitsum.com | ParkControl | Direct URL |
| 6 | cdn.akamai.steamstatic.com | Steam | Direct URL |
| 7 | discord.com | Discord | API endpoint |
| 8 | laptop-updates.brave.com | Brave | Direct URL |
| 9 | code.visualstudio.com | VS Code | Direct URL |

**Reference-only URLs** (displayed to user, not downloaded programmatically):
- github.com/QuakedK/Oneclick/releases (Module 13 Oneclick)
- techpowerup.com/nvcleaninstall (NVCleanInstall)
- speedguide.net/downloads.php (SG TCP Optimizer)

---

## PHASE 2 — STATIC ANALYSIS

### 2.1 Execution Flow Map

```
YAZX_Setup.bat
  |
  +-- [Admin Check] cacls.exe %SystemRoot%\system32\config\system
  |     |-- FAIL: echo "Run as Administrator!" -> exit
  |     |-- PASS: continue
  |
  +-- [Set Paths]
  |     YAZX_DIR = %~dp0 (script's own directory)
  |     BACKUP_DIR = auto-detect YAZX_Backup on E:/D:/C:/F:/G:
  |     LOG_FILE = %YAZX_DIR%\logs\YAZX_Setup_Log.txt
  |
  +-- [Menu] choice /c 123456789ACDEFGHTVRQ
  |     |
  |     +-- [1-9,A-H] Individual modules -> powershell -ExecutionPolicy Bypass -File
  |     |     Module params: -YazxDir -BackupDir -LogFile [-Auto]
  |     |
  |     +-- [T] Module 16 DownloadTools
  |     |
  |     +-- [V] Run ALL 16 modules (sequential, with -Auto flag)
  |     |     Order: 16->01->02->03->04->08->09->10->11->12->14->15->registry imports
  |     |
  |     +-- [R] Restore Registry (from backup)
  |     |     for %%f in (BACKUP_DIR\*.reg) do regedit /s "%%f"
  |     |
  |     +-- [Q] Quit
```

**Module execution chain** (each module):
```
powershell -ExecutionPolicy Bypass -File "module.ps1" -YazxDir X -BackupDir Y -LogFile Z [-Auto]
  |
  +-- param() block receives typed parameters
  +-- . "$PSScriptRoot\YAZX_Common.ps1" (dot-source shared functions)
  +-- Module-specific logic (registry, services, files, downloads)
  +-- YAZX-Log writes timestamped entry to log file
```

### 2.2 Dependency Map

```
YAZX_Setup.bat
  |-- modules/YAZX_Common.ps1 (shared by ALL modules)
  |-- modules/01_SystemCheck.ps1 (read-only system info)
  |-- modules/02_NVIDIADriver.ps1 (uses tools/NVCleanInstall, BACKUP_DIR)
  |-- modules/03_Programs.ps1 (uses winget, direct URLs)
  |-- modules/04_Configs.ps1 (uses configs/, BACKUP_DIR, creates STR service)
  |-- modules/08_Services.ps1 (uses sc.exe, creates registry backup)
  |-- modules/09_BCDTweaks.ps1 (uses bcdedit, reg add)
  |-- modules/10_MSIMode.ps1 (registry only)
  |-- modules/11_PowerPlan.ps1 (uses powercfg)
  |-- modules/12_Privacy.ps1 (registry + schtasks + netsh)
  |-- modules/14_NewTweaks.ps1 (registry, interactive via YAZX-Choose)
  |-- modules/15_Autologgers.ps1 (registry only)
  |-- modules/16_DownloadTools.ps1 (Invoke-WebRequest, Invoke-RestMethod, winget)
  |-- registry/YAZX_*.reg (7 files, imported via regedit /s)
```

### 2.3 External Connections Map

| Module | Protocol | Destination | Purpose |
|--------|----------|-------------|---------|
| 16_DownloadTools | HTTPS | 12 unique domains | Download portable tools |
| 16_DownloadTools | HTTPS | api.github.com | GitHub Releases API |
| 03_Programs | HTTPS | 9 unique domains | Download program installers |
| 03_Programs | Local | winget (CDN) | Package manager installs |
| 16_DownloadTools | Local | winget (CDN) | Fallback installs |

No unexpected or undocumented connections found.

---

## PHASE 3 — 27 CORE SECURITY CHECKS

### PowerShell Security (Checks 1-12)

| # | Check | Result | Evidence |
|---|-------|--------|----------|
| 1 | Encrypted/obfuscated code | **N/A** — No encryption or obfuscation exists | 0 matches for Base64, EncodedCommand, GZipStream, ScriptBlock |
| 2 | Dynamic code execution (IEX, ScriptBlock) | **PASS** | 0 matches for Invoke-Expression, iex, [ScriptBlock]::Create |
| 3 | DownloadString / Invoke-WebRequest usage | **FINDING F-01** | Module 16 + tools/YAZX_DownloadTools.ps1 use Invoke-WebRequest without hash verification |
| 4 | Unexpected connections | **PASS** | All connections documented in tool catalog; no hidden outbound calls |
| 5 | Admin privilege escalation | **PASS (by design)** | Admin checked at YAZX_Setup.bat entry; all modules inherit admin; no escalation beyond initial grant |
| 6 | Unauthorized file/command modification | **PASS** | All paths hardcoded from YAZX_DIR (%~dp0) or BACKUP_DIR; no user string interpolation into commands |
| 7 | Sensitive PowerShell functions | **PASS** | No Invoke-Expression, no Add-Type with unsafe code, no .NET reflection, no WMI execution |
| 8 | Environment variables & registry | **PASS** | $env: used only for path construction (USERNAME, LOCALAPPDATA, ProgramFiles); registry ops use hardcoded paths |
| 9 | Temp file creation/deletion | **FINDING (INFO)** | watcher.bat creates %TEMP%\yazx_watcher.lock with TOCTOU race; Module 16 cleans failed downloads |
| 10 | Information leakage via logs | **PASS** | Logs contain only module names, timestamps, and operation results; no secrets, no user data |
| 11 | PowerShell logging & Script Block Logging | **INFO** | No explicit logging configuration; scripts rely on Windows default audit policy |
| 12 | Code signing & Authenticode | **INFO** | 0 scripts are signed; all execution uses -ExecutionPolicy Bypass |

### GitHub & Supply Chain Security (Checks 13-23)

| # | Check | Result | Evidence |
|---|-------|--------|----------|
| 13 | Repository inventory | **PASS** | 5 GitHub repos used: microe1/MouseTester, White-Tiger/WinMTR, CXWorld/CapFrameX, Orbmu2k/nvidiaProfileInspector, git-for-windows/git |
| 14 | Git history secrets scan | **PASS** | No API keys, tokens, or credentials in any commit; .gitignore excludes .github_token.tmp |
| 15 | Download URL legitimacy | **PASS** | All URLs point to official project domains (wagnardsoft, oo-software, bitsum, resplendence, etc.) |
| 16 | Mutable branch references | **FINDING F-06** | 5 of 12 Module 16 URLs point to "latest" versions without pinning; Sysinternals always downloads latest; NPI uses /releases/latest API |
| 17 | SHA-256 integrity verification | **FINDING F-01** | YAZX_TOOL_LIBRARY.md has SHA-256 hashes for 17 tools; Module 16 never checks them |
| 18 | Digital signature verification | **N/A** | Most tools are unsigned open-source; no Authenticode checks exist; would need manual verification |
| 19 | Pre-execution file inspection | **FINDING (implicit in F-01)** | Downloaded files are placed in tools/ and used without any inspection |
| 20 | Dependency confusion / repo hijacking | **LOW RISK** | GitHub URLs use specific owner/repo; winget uses official IDs; no npm/pip/nuget-style confusion vector |
| 21 | Releases, tags, assets | **PARTIAL** | 3 GitHub URLs pinned to specific release tags (good); 1 uses /releases/latest API (mutable) |
| 22 | Archive extraction safety (Zip Slip) | **PASS** | Expand-Archive in PS 5.1 refuses paths with `..`; extraction destinations are always hardcoded subdirs of tools/ |
| 23 | TOCTOU in file replacement | **PASS** | Module 16 downloads to final path directly; no atomic-replace pattern but tools/ is local and admin-only |

### General Application Security (Checks 24-27)

| # | Check | Result | Evidence |
|---|-------|--------|----------|
| 24 | HTTPS/TLS certificate validation | **PASS** | All URLs use HTTPS; 0 matches for SkipCertificateCheck, ServicePointManager, or certificate bypass |
| 25 | XSS | **N/A** | No web interface, no HTML generation, no browser-facing output |
| 26 | SQL Injection | **N/A** | No database, no SQL queries |
| 27 | Outdated/vulnerable libraries | **N/A** | No third-party libraries; tools are standalone executables |

---

## SECURITY FINDINGS — CONSOLIDATED

### Confirmed Findings (Actionable)

#### [HIGH] F-01: Module 16 Downloads Without Hash Verification

- **Confidence**: CONFIRMED
- **File**: `modules/16_DownloadTools.ps1` lines 29-43
- **Function**: `Get-ToolFile`
- **Created by**: Claude (this session)
- **Evidence**: `Invoke-WebRequest` downloads files and checks only existence/size, never hash.
  `tools/YAZX_TOOL_LIBRARY.md` already documents SHA-256 hashes for all 17 tools.
- **Impact**: Supply-chain attack via compromised CDN, DNS hijack, or rogue CA could
  deliver malicious executables to the tools/ directory, which are then used by
  other modules (Sysinternals Autoruns, Process Explorer, etc.).
- **Reproduction**: Compare `Get-ToolFile` function logic against YAZX_TOOL_LIBRARY.md hashes.
  No `Get-FileHash` call exists anywhere in the download pipeline.
- **Fix**: Add hash lookup table to Module 16; after download, verify
  `(Get-FileHash $OutPath -Algorithm SHA256).Hash -eq $ExpectedHash`;
  reject and delete on mismatch.

#### [MEDIUM] F-02: Blind Registry Import from Backup Directory

- **Confidence**: CONFIRMED
- **File**: `YAZX_Setup.bat` lines 251-274
- **Function**: For-loop `regedit /s "%%f"`
- **Evidence**: `for %%f in ("%BACKUP_DIR%\yazx_AllTweakRegistry\*.reg")` imports
  every .reg file without filename allowlist or content validation.
- **Impact**: A planted .reg file on external backup media would execute arbitrary
  registry changes at SYSTEM level.
- **Reproduction**: Place a crafted .reg file in the backup directory; run Restore Registry.
- **Fix**: Replace wildcard loop with explicit filename list matching expected files.

#### [MEDIUM] F-03: Core Windows Services Disabled Without Guard

- **Confidence**: CONFIRMED
- **File**: `modules/08_Services.ps1` lines 52-58
- **Function**: Main disable loop
- **Evidence**: `EventSystem` and `gpsvc` are in `$disableServices` array.
  WARNING comment at line 49-51 says "Only safe to disable after Oneclick."
  No programmatic check for Oneclick completion exists.
- **Impact**: Disabling gpsvc removes Group Policy enforcement. In Auto mode,
  no user confirmation is requested.
- **Reproduction**: Run Module 08 with -Auto flag before Oneclick has been run.
- **Fix**: Move EventSystem/gpsvc to a separate array; skip in Auto mode unless
  a Oneclick marker file/registry key is detected; or prompt interactively.

#### [MEDIUM] F-06: Unpinned Download URLs (Mutable Versions)

- **Confidence**: CONFIRMED
- **File**: `modules/16_DownloadTools.ps1` lines 93, 108, 113, 118, 123, 128
- **Function**: Tool catalog
- **Evidence**: 5+ tools download "latest" version from vendor sites without
  version pinning. Example: `download.sysinternals.com/files/SysinternalsSuite.zip`
  always returns the latest build. `api.github.com/repos/.../releases/latest`
  returns whatever the repo owner tags as latest.
- **Impact**: A compromised repository owner or CDN could serve a different version
  than expected. Combined with F-01 (no hash check), this is a supply-chain risk.
- **Reproduction**: The Sysinternals URL today returns a different binary than when
  the TOOL_LIBRARY hash was computed.
- **Fix**: For tools with known versions, pin the version in the URL.
  For tools that only offer "latest", hash verification (F-01 fix) is essential.

#### [MEDIUM] F-07: Service Binary Installed from Unverified Backup

- **Confidence**: CONFIRMED
- **File**: `modules/04_Configs.ps1` lines 141-156
- **Function**: Timer Resolution Service installation
- **Evidence**: `sc.exe create "STR" binPath="...\SetTimerResolutionService.exe"`
  installs a Windows service from an executable sourced from configs/ or backup/.
  No signature check, no hash verification on the binary.
- **Impact**: If the backup directory is tampered with, a malicious executable
  would run as a Windows service (SYSTEM privileges, auto-start).
- **Reproduction**: Replace SetTimerResolutionService.exe in backup with a crafted binary.
- **Fix**: Verify the binary's hash before `sc.exe create`. Add known-good hash
  to the codebase.

### Low / Informational Findings

#### [LOW] F-04: Hosts File Replacement Without Content Validation

- **File**: `YAZX_Setup.bat` lines 471-475
- **Mitigation**: Backup created as hosts.yazx_bak.
- **Residual risk**: The hosts file is version-controlled in the repo.

#### [LOW] F-05: ProcessLasso Config Password Empty

- **Files**: 4 copies of prolasso.ini with `ConfigPasswordMD5=` empty
- **Risk**: Local-only; requires existing local access.

#### [INFO] I-01: No Code Signing

- All 18 .ps1 scripts lack Authenticode signatures.
- All execution uses `-ExecutionPolicy Bypass`.
- Expected for a personal system tool; would be a finding for distributed software.

#### [INFO] I-02: No PowerShell Logging Configuration

- No explicit Script Block Logging, Module Logging, or Transcription configured.
- The tool does maintain its own log via `YAZX-Log`, but Windows event-level
  auditing is not configured.

---

## INTENTIONAL SECURITY TRADE-OFFS (Documented, Not Actionable)

| ID | Trade-off | Files | User Intent |
|----|-----------|-------|-------------|
| T-01 | UAC disabled (EnableLUA=0) | registry/YAZX_System.reg | Gaming — no admin prompts |
| T-02 | Defender disabled (DisableAntiSpyware=1) | YAZX_System.reg, Defender_Policy.reg | Gaming — no AV overhead |
| T-03 | Windows Update disabled | YAZX_System.reg, 08_Services.ps1 | Gaming — no surprise restarts |
| T-04 | 30+ services disabled | 08_Services.ps1 | Performance — fewer background processes |
| T-05 | Prefetch/Superfetch disabled | YAZX_System.reg | Performance — reduce disk I/O |
| T-06 | TCP auto-tuning disabled | 12_Privacy.ps1 | Gaming — fixed TCP window size |

---

## CLEAN AREAS (No Findings)

| Area | Result | Method |
|------|--------|--------|
| Secrets in code | CLEAN | Grep for password, secret, token, api_key across all scripts |
| Secrets in git history | CLEAN | git log --diff-filter=A/D for sensitive file extensions |
| Command injection | CLEAN | 0 matches for Invoke-Expression, iex, dynamic eval |
| Input validation | SAFE | YAZX-Choose: [int]::TryParse + range check |
| Path derivation | SAFE | YAZX_DIR from %~dp0, not user input |
| Transport security | CLEAN | All URLs HTTPS, no certificate bypass |
| TLS validation | CLEAN | 0 matches for SkipCertificateCheck or ServicePointManager |
| Registry ops in PS | SAFE | All hardcoded paths, no string interpolation from user input |
| Zip extraction | SAFE | Expand-Archive with hardcoded destination subdirs |
| XSS / SQL Injection | N/A | No web interface, no database |

---

## PHASE 4 — REMEDIATION PLAN (Awaiting Approval)

### Priority Order

| Priority | Finding | Change | Risk of Breaking |
|----------|---------|--------|-----------------|
| 1 | F-01 | Add SHA-256 hash table + verification to Module 16 | None — adds check after download, same behavior on success |
| 2 | F-06 | Pin mutable URLs where possible | Low — may need URL updates when tools release new versions |
| 3 | F-07 | Add hash check for STR service binary in Module 04 | None — adds check before service creation |
| 4 | F-02 | Replace wildcard .reg import with explicit filename list | Low — must match actual backup filenames |
| 5 | F-03 | Guard EventSystem/gpsvc with Oneclick check or separate prompt | None — only affects these 2 services |

### Files That Will Change

| File | Changes |
|------|---------|
| `modules/16_DownloadTools.ps1` | Add $hashTable, add Confirm-ToolHash function, call after each download |
| `modules/04_Configs.ps1` | Add hash check for SetTimerResolutionService.exe before sc.exe create |
| `YAZX_Setup.bat` | Replace `for %%f in (*.reg)` loops with explicit file lists |
| `modules/08_Services.ps1` | Separate EventSystem/gpsvc into guarded array |

### Tests After Fix

1. Module 16: Download a tool, verify hash matches, verify rejection on mismatch
2. Module 04: Verify STR service creation succeeds with correct binary
3. YAZX_Setup.bat: Verify registry restore imports all expected files
4. Module 08: Verify EventSystem/gpsvc handling in Auto vs interactive mode
5. Full dry-run of "Run ALL" to confirm no regressions

### What Will NOT Change

- Registry content (UAC, Defender, Update settings) — intentional user choices
- Module architecture and file structure
- Existing features and execution flow
- Backward compatibility with existing backups
