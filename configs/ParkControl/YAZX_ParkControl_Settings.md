# YAZX ParkControl — Power Plan Processor Settings
# Extracted from TTCH ULTIMATE PERFORMANCE power plan
# GUID: fd7463fc-d008-4a42-9497-1007fc9baaf0

## Current Power Plan Settings (from PowerPlan_Full_Query.txt)

### Processor Power Management
- Minimum processor state: 100% AC / 5% DC
- Maximum processor state: 100% AC / 100% DC
- System cooling policy: Active

### Core Parking (ParkControl manages these)
- Core Parking should be DISABLED (0%) for gaming
- ParkControl provides GUI for these hidden settings:
  - Processor performance core parking min cores: 100% (all cores active)
  - Processor performance core parking max cores: 100%
  - Processor performance core parking concurrency threshold: 100%
  - Processor performance core parking increase policy: Rocket
  - Processor performance core parking decrease policy: Single core
  - Processor idle demote threshold: 100%
  - Processor idle promote threshold: 100%

### Heterogeneous Thread Policy (NEW — from YAZX research)
- Setting: Prefer performant processors (value 4)
- Effect: Windows schedules threads to P-cores first
- Apply via: powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR SCHEDPOLICY 4

### ParkControl Pro Settings
- Bitsum Highest Performance plan is an alternative
- ParkControl can dynamically switch plans per-app
- For LTSC with static gaming use: keep TTCH ULTIMATE PERFORMANCE

## Post-Format Steps
1. Install ParkControl (from Bitsum, same installer as Process Lasso)
2. Set power plan to TTCH ULTIMATE PERFORMANCE (import via YAZX_Setup.bat)
3. Verify core parking is disabled (ParkControl GUI shows green = unparked)
4. Apply heterogeneous thread policy via Module 14 (14_NewTweaks.ps1)
5. Verify with: powercfg /qh SCHEME_CURRENT SUB_PROCESSOR SCHEDPOLICY

## Notes
- ParkControl is bundled with Process Lasso Pro
- Free version has limited functionality
- The power plan export (.pow) requires admin — use text query as reference
- Core parking settings are hidden in standard Windows power options
