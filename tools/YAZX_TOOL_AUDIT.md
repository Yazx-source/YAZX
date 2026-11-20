# YAZX Tool Audit — Complete Status Report
# Date: 2026-11-20 (Updated after download phase)
# System: Intel i5-13400F / RTX 3060 12GB / Win11 IoT LTSC 2024
# Audited: All 17 tool subdirectories in E:\YAZX_GitHub\tools\

---

## DOWNLOADED & VERIFIED (12 tools)

### 1. Sysinternals Suite
- **Status**: DOWNLOADED and EXTRACTED
- **Source**: https://download.sysinternals.com/files/SysinternalsSuite.zip
- **Archive**: SysinternalsSuite.zip (357.33 MB)
- **SHA-256**: E7F49D1F4477E416B3051636DC44929B20AE025B46A1EE4CD8C1F1E869AF6AE6
- **Extraction**: tools/Sysinternals/extracted/ (164 files, 445.1 MB)
- **Key tools**: Process Explorer, Process Monitor, Autoruns, TCPView, RAMMap,
  Handle, PsExec, Sysmon, Coreinfo, Clockres, sigcheck

### 2. MouseTester v1.5.3
- **Status**: DOWNLOADED
- **Source**: https://github.com/microe1/MouseTester/releases/download/v1.5.3/MouseTester.v1.5.3.zip
- **File**: MouseTester_v1.5.3.zip (152.8 KB)
- **SHA-256**: D7E63DD67C8948777A43BB65D9D8F377A5E81254DA480DAAFF70E2BC121A01E1
- **Signature**: None (open-source community tool)

### 3. WinMTR v1.00 (static build)
- **Status**: DOWNLOADED
- **Source**: https://github.com/White-Tiger/WinMTR/releases/download/v1.00/WinMTR-v100-static.zip
- **File**: WinMTR-v100-static.zip (1.74 MB)
- **SHA-256**: 2DA85A22A319E87705FA846E949E28B9A23726D161816228D49AF402D55EA60E
- **Signature**: None (open-source community tool)

### 4. CapFrameX v1.9.2 (portable)
- **Status**: DOWNLOADED + CHECKSUM VERIFIED
- **Source**: https://github.com/CXWorld/CapFrameX/releases/download/v1.9.2/release_1.9.2_portable.zip
- **File**: release_1.9.2_portable.zip (72.87 MB)
- **SHA-256**: 0C3374D382ABB359439F8898BDAAA1C4E6A7CC0FDD936022C0EAD0CA213BDA08
- **Checksum**: VERIFIED against official SHA256SUMS.txt (also downloaded)
- **Signature**: None (open-source, but official checksums provided)

### 5. O&O ShutUp10++ v3.7.1143.0
- **Status**: DOWNLOADED + DIGITALLY SIGNED
- **Source**: https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe
- **File**: OOSU10.exe (81.81 MB)
- **SHA-256**: EA2790422AA81D62F22AE93E995C205D4D7A6AC9825877CF34AD4E65A8253ECE
- **Digital Signature**: VALID — O&O Software GmbH, Berlin
- **Version**: 3.7.1143.0

### 6. USBTreeView
- **Status**: DOWNLOADED
- **Source**: https://www.uwe-sieber.de/files/usbtreeview.zip
- **File**: usbtreeview.zip (910.8 KB)
- **SHA-256**: 558620110D614A0859D08550C9D0259C2CABC7D8444DC8DF43754A64380B85D4
- **Signature**: Not checked (zip archive)

### 7. ISLC v1.0.3.2 (Intelligent Standby List Cleaner)
- **Status**: DOWNLOADED
- **Source**: https://www.wagnardsoft.com/ISLC/ISLC%20v1.0.3.2.exe
- **File**: ISLC_v1.0.3.2.exe (373.6 KB)
- **SHA-256**: FC4961D4FFA095EB150B29CEB9D26A77098988C6549FE6187DBB80BFA2A6A381
- **Signature**: Not checked (publisher: Wagnardsoft)

### 8. LatencyMon
- **Status**: DOWNLOADED
- **Source**: https://www.resplendence.com/download/LatencyMon.exe
- **File**: LatencyMon.exe (3.6 MB)
- **SHA-256**: C124342DA2A844DA0699901476B27226DA1D0D30BF8E940C9F847D67D46A1157
- **Signature**: Not checked (publisher: Resplendence Software Projects)

### 9. QuickCPU
- **Status**: DOWNLOADED + DIGITALLY SIGNED
- **Source**: https://coderbag.com/assets/downloads/quickcpu/QuickCpuSetup.msi
- **File**: QuickCpuSetup.msi (35.02 MB)
- **SHA-256**: 9668D980F36087B56849D207A5ABEB709686D9167F621AB2076F8BEBE52AED6A
- **Digital Signature**: VALID — CoderBag LLC, California
- **Note**: MSI installer (not portable)

### 10. GPU-Z v2.72.0
- **Status**: DOWNLOADED + DIGITALLY SIGNED
- **Source**: TechPowerUp (2-step POST download via German mirror)
- **File**: GPU-Z.exe (12.43 MB)
- **SHA-256**: 3B15545F3EDF7F2C714A32C7EE2BEDD9823FEE7D23A20E15F2E29CD2FEE25323
- **Digital Signature**: VALID — TechPowerUp LLC, Washington
- **Version**: 2.72.0.0

### 11. ThrottleStop v9.7.3
- **Status**: DOWNLOADED
- **Source**: TechPowerUp (2-step POST download via German mirror)
- **File**: ThrottleStop.zip (1.71 MB)
- **SHA-256**: 7B5E1A650A845CDAB200BD6A7766D8F56AE458F633A6F2F3DF5A9EC72847098A
- **Signature**: Not checked (zip archive)
- **NOTE**: Limited use on LOCKED i5-13400F — no voltage/ratio changes.
  Still useful for: monitoring, C-state control, TSC frequency lock, SpeedShift.

### 12. DDU v18.1.6.3 (Display Driver Uninstaller)
- **Status**: DOWNLOADED + DIGITALLY SIGNED
- **Source**: TechPowerUp (2-step POST download via German mirror)
- **File**: DDU_v18.1.6.3.exe (1.77 MB) — Self-extracting EXE (not ZIP)
- **SHA-256**: 3D53FCC3506F4B9A55204B0C7E98F0B0E7A67ABA113856B87AC6F4F631E481A6
- **Digital Signature**: VALID — Wagnardsoft, Quebec, CA
- **Version**: 18.1.6.3

---

## REQUIRES MANUAL DOWNLOAD (4 tools)

All automated download attempts blocked by anti-bot protection (403 Forbidden).

### 13. CrystalDiskInfo 9.9.5
- **Status**: NOT DOWNLOADED — SourceForge 403
- **Tried**: SourceForge direct, CDN mirrors (netix, downloads.sourceforge.net),
  OSDN (domain down), crystalmark.info (connection dropped), GitHub (source only, no binaries)
- **Manual Download**: https://sourceforge.net/projects/crystaldiskinfo/files/9.9.5/CrystalDiskInfo9_9_5.zip/download
- **Alternative**: https://crystalmark.info/en/download/
- **Size**: ~5 MB (portable ZIP)
- **Priority**: Medium — NVMe health monitoring

### 14. CrystalDiskMark 9.0.3
- **Status**: NOT DOWNLOADED — SourceForge 403
- **Tried**: SourceForge direct, CDN mirrors, GitHub (CrystalDewWorld repo has release tag but no binary assets)
- **Manual Download**: https://sourceforge.net/projects/crystaldiskmark/files/9.0.3/CrystalDiskMark9_0_3.zip/download
- **Alternative**: https://crystalmark.info/en/download/
- **Size**: ~5 MB (portable ZIP)
- **Priority**: Medium — storage benchmark

### 15. HWiNFO (latest v8.60)
- **Status**: NOT DOWNLOADED — hwinfo.com 403
- **Tried**: hwinfo.com direct, SourceForge mirror, FossHub — all 403
- **Manual Download**: https://www.hwinfo.com/download/
- **Choose**: Portable version (no installer needed)
- **Size**: ~10 MB
- **Priority**: High — comprehensive hardware monitoring

### 16. SG TCP Optimizer
- **Status**: NOT DOWNLOADED — speedguide.net 403
- **Tried**: speedguide.net direct URL patterns — all 403
- **Manual Download**: https://www.speedguide.net/downloads.php
- **Size**: ~1 MB
- **Priority**: High — TCP/IP optimization

---

## ADDITIONAL DOWNLOADS (dependencies + standalone)

### 13. IRQControl v1.0.0.65 BETA (standalone)
- **Status**: DOWNLOADED + DIGITALLY SIGNED
- **Source**: https://dl.bitsum.com/files/beta/irqcontrolsetup64.exe
- **File**: irqcontrolsetup64.exe (1.51 MB)
- **SHA-256**: 0B3113EB359C88678310A2DFD66EBE9AB80CEED1D60EA4FB2EBCB5F5B67451D7
- **Digital Signature**: VALID — Bitsum Technologies (Bitsum LLC)
- **Version**: 1.0.0.65 BETA
- **NOTE**: IRQControl is BOTH standalone (free, from Bitsum) AND integrated
  in Process Lasso Pro. This is the standalone installer. Verified NOT present
  in Process Lasso backup (yazx_ProcessLasso has no IRQControl.exe).
- **Guide**: configs/IRQControl/YAZX_InterruptAffinity_Guide.md

### CapFrameX Dependencies (stored in tools/CapFrameX/)
- **VC++ 2015-2022 Redistributable x64**: vc_redist.x64.exe (24.45 MB)
  - SHA-256: CC0FF0EB1DC3F5188AE6300FAEF32BF5BEEBA4BDD6E8E445A9184072096B713B
  - Signed: Microsoft Corporation, v14.44.35211.0
- **.NET 10.0 Desktop Runtime x64**: windowsdesktop-runtime-10.0.0-win-x64.exe (57.43 MB)
  - SHA-256: FC0494EAF529B15F74B10D920784CC618FF0845BEBFDFD5D85D585E921157A5C
  - Signed: .NET, Microsoft Corporation

---

## SUMMARY

| Category | Count | Details |
|----------|-------|---------|
| Downloaded & Verified | 13 | Sysinternals + 12 individual tools (incl. IRQControl) |
| Requires Manual Download | 4 | CrystalDiskInfo, CrystalDiskMark, HWiNFO, SG TCP Optimizer |
| Dependencies Downloaded | 2 | CapFrameX: VC++ 2015-2022 + .NET 10 Runtime |
| **Total Accounted** | **17 tools + 2 deps** | |

### Download Statistics
- **Total download size**: ~654 MB (13 tools + 2 dependencies)
- **Digitally signed**: 5 tools (O&O ShutUp10, GPU-Z, DDU, QuickCPU, IRQControl)
- **Checksum verified against official**: 1 tool (CapFrameX)
- **SHA-256 recorded for all**: Yes

### Why 4 Tools Require Manual Download
SourceForge, hwinfo.com, and speedguide.net all use aggressive bot detection
that returns HTTP 403 to any automated HTTP client (PowerShell, curl, Python).
These sites require a real browser session with JavaScript execution,
cookie acceptance, and sometimes CAPTCHA completion. No technical workaround
exists for automated download — the user must visit the URL in a browser.

---

## Also in tools/ directory (scripts)
- YAZX_DownloadTools.ps1 — Automated download script (outdated, most URLs need updating)
- YAZX_DownloadGuide.md — Manual download guide with URLs
- YAZX_VerifyTools.ps1 — Post-install verification script
- YAZX_TOOL_AUDIT.md — This file
