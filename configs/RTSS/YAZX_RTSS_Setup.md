# YAZX RTSS (RivaTuner Statistics Server) — Setup Guide
# Current state: NOT separately installed (only RTSSSetup.exe in Afterburner Redist)
# MSI Afterburner installs RTSS automatically when selected during install

## Why RTSS Matters for Gaming
- Frame limiter with SCANLINE sync (superior to V-Sync for input lag)
- OSD (On-Screen Display) for monitoring FPS, frametime, temps
- Works with CapFrameX for frame time analysis
- Frame limiter adds only ~1 frame of input lag (vs 2-3 for V-Sync)

## Post-Format Installation
1. Install MSI Afterburner (includes RTSS installer in Redist folder)
2. During Afterburner install, check "RivaTuner Statistics Server"
3. OR install RTSS standalone from guru3d.com

## Recommended RTSS Settings

### Global Profile
- Framerate limit: 0 (use per-game limits)
- On-Screen Display support: ON
- Application detection level: High
- Stealth mode: OFF (unless anti-cheat conflicts)

### Per-Game Frame Limiting
- Competitive (Valorant, CS2): Cap at monitor refresh - 3 (e.g., 141 for 144Hz)
- Story games: Cap at monitor refresh rate or desired FPS
- Use SCANLINE sync for tear-free without V-Sync input lag

### OSD Layout
- Show: FPS, Frametime, GPU Temp, GPU Usage, CPU Temp
- Position: Top-left (default)
- Font size: Small (OSD shadow ON for readability)
- Toggle hotkey: Set to convenient key (e.g., F12)

### Advanced Settings
- Enable Frametime overlay graph: YES (for stutter detection)
- Framerate limit method: Front Edge (lowest input lag)

## Config File Location
- Settings: %ProgramFiles(x86)%\RivaTuner Statistics Server\Profiles\
- Global config: %ProgramFiles(x86)%\RivaTuner Statistics Server\RTSS.cfg

## Integration with YAZX Tools
- CapFrameX reads RTSS data for benchmarking
- HWiNFO provides additional sensor data to OSD
- MSI Afterburner OSD uses RTSS as backend
- Process Lasso can trigger RTSS profile switches

## Notes
- RTSS must run as admin for some games
- Some anti-cheat systems may flag RTSS — check game compatibility
- SCANLINE sync number: use values between -1 and -20 for optimal results
- Current system has NO RTSS config to preserve — this is a fresh setup guide
