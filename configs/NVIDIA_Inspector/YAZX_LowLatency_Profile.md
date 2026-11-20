# YAZX NVIDIA Profile Inspector — Low Latency Reference
# STATUS: Reference only. Do NOT modify Global Profile without testing.
# Apply per-game profiles only. Global Profile changes affect ALL applications.

## Important: Pre-Rendered Frames vs Low Latency Mode

These two settings interact and can CONFLICT:

| Setting | DRS ID | Values |
|---------|--------|--------|
| Low Latency Mode | 0x00000094 | 0=Off, 1=On, 2=Ultra |
| Max Pre-Rendered Frames | 0x00060057 | 1-4 (app default varies) |

When Low Latency Mode = Ultra (2):
- The driver OVERRIDES Pre-Rendered Frames to 1 internally
- Setting Pre-Rendered Frames = 1 manually is REDUNDANT
- Setting Pre-Rendered Frames to a different value creates a CONFLICT
  where the driver behavior is undefined

CORRECT approach:
- Use Low Latency Mode = Ultra ALONE (it implies Pre-Rendered = 1)
- OR use Pre-Rendered Frames = 1 with Low Latency Mode = Off/On
- Do NOT set both Ultra + explicit Pre-Rendered value

## Global Profile — DO NOT CHANGE without reason

The Global Profile affects every application including desktop, browsers,
and productivity apps. Changes should be minimal:

| Setting | DRS ID | Recommended Global | Reason |
|---------|--------|--------------------|--------|
| Power Management | 0x00000016 | Prefer Max Performance | Prevents GPU downclocking |
| Shader Cache Size | 0x00000061 | Unlimited | Prevents shader stutter |
| Threaded Optimization | 0x000000E2 | Auto | Let driver decide |
| Texture Filtering Quality | 0x000000CE | Quality (default) | No reason to lower globally |
| VSync | 0x000000A1 | Use App Setting | Per-game decision |

ONLY Power Management and Shader Cache are worth changing globally.
Everything else stays at default or Application Controlled.

## Per-Game Profile: Competitive (Template)

Create this as a SEPARATE profile in NVIDIA Profile Inspector.
Apply to specific game executables only.

| Setting | DRS ID | Value | Notes |
|---------|--------|-------|-------|
| Low Latency Mode | 0x00000094 | Ultra (2) | Implies Pre-Rendered=1 |
| Power Management | 0x00000016 | Prefer Max Performance | |
| VSync | 0x000000A1 | Off | Use RTSS limiter instead |
| Triple Buffering | 0x00000020 | Off | Only with VSync |
| Threaded Optimization | 0x000000E2 | Auto | |

## Per-Game Profile: Rocket League

Create as its own profile. Executable: RocketLeague.exe

| Setting | DRS ID | Value | Notes |
|---------|--------|-------|-------|
| Low Latency Mode | 0x00000094 | Ultra (2) | |
| Power Management | 0x00000016 | Prefer Max Performance | |
| VSync | 0x000000A1 | Off | |
| Threaded Optimization | 0x000000E2 | Auto | |

Note: Rocket League supports NVIDIA Reflex natively. When Reflex is
enabled in-game, Low Latency Mode is automatically managed by the
game engine. Setting Ultra in the driver may be redundant or conflict.
Test with Reflex On vs. Driver Ultra to determine which gives lower
latency on your setup.

## Per-Game Profile: Single-Player / Story Games

| Setting | DRS ID | Value | Notes |
|---------|--------|-------|-------|
| Low Latency Mode | 0x00000094 | On (1) | Less aggressive, stable FPS |
| Power Management | 0x00000016 | Prefer Max Performance | |
| VSync | 0x000000A1 | Use App Setting | |
| Threaded Optimization | 0x000000E2 | Auto | |

## Driver Compatibility
- These DRS IDs are valid for driver 500.xx+ (confirmed for 610.88)
- NVIDIA Profile Inspector version 2.4+ recommended
- After driver update, re-verify profiles are intact

## How to Apply
1. Install NVIDIA driver (NVCleanstall for clean install)
2. Open NVIDIA Profile Inspector
3. The existing Performances.nip or QuakedV2.nip is the base — do NOT delete it
4. Create new per-game profiles for competitive games
5. Modify Global Profile ONLY for Power Management and Shader Cache
6. Export as YAZX_Profiles.nip for backup

## Existing Profile Files
- Performances.nip: Current NVIDIA profile (from tweaker/user)
- QuakedV2.nip: Alternative profile
- These are preserved in exports. Load whichever was active as the base.
