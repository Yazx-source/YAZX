# YAZX Equalizer APO — Post-Format Setup Guide
# Current state: Minimal config (only mic.txt include)

## Step 1: Device Selection
After installing Equalizer APO:
1. Run Configurator.exe from the EQ APO install directory
2. Select the PRIMARY playback device (likely "Headphones" or "Speakers")
3. Check "Troubleshooting: Install as SFX/EFX" if needed
4. Reboot

## Step 2: Config Structure
Create these files in C:\Program Files\EqualizerAPO\config\:

### config.txt (main config)
```
# YAZX Equalizer APO Configuration
# Include mic processing
Include: mic.txt

# Include headphone EQ (uncomment when configured)
# Include: headphone_eq.txt

# Include game audio profile (uncomment when configured)
# Include: game_audio.txt
```

### mic.txt (preserved from current system)
```
Device: Capture
# Microphone processing
# Add filters as needed
```

## Step 3: Low-Latency Audio Settings
In Windows Sound Properties > Playback Device > Advanced:
- Default Format: 48000 Hz, 24 bit (or match your DAC)
- Check: "Allow applications to take exclusive control"
- Check: "Give exclusive mode applications priority"
- Uncheck: "Enable audio enhancements" (if not using EQ APO)

## Step 4: MMCSS Audio (already in YAZX)
These are set by YAZX_Gaming.reg:
- SystemResponsiveness = 0
- Games\GPU Priority = 8
- Games\Priority = 6
- Games\Scheduling Category = High
- Pro Audio\Priority = 1
- Pro Audio\Scheduling Category = High

## Notes
- EQ APO adds ~1-2ms latency when active
- For pure gaming, the minimal config (mic.txt only) is optimal
- Only add EQ profiles if you actively use headphone correction or effects
- VST plugins directory is empty — populate post-format if needed
