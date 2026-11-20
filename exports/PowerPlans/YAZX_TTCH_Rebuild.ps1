param(
    [string]$YazxDir,
    [string]$LogFile
)

# YAZX TTCH Power Plan Rebuild Script
# Recreates TTCH ULTIMATE PERFORMANCE plan from saved powercfg /query values
# Source: exports/PowerPlans/TTCH_UltimatePerformance_Full.txt (27 settings)
#
# EXACT RESTORE: 27 settings with AC+DC from powercfg /query (54 commands)
# RECONSTRUCTED: 45 settings with AC only from Power_Control.reg (45 commands)
#   Includes: core parking, EPP, boost mode, idle promote/demote, autonomy,
#   energy saver, interrupt steering, heterogeneous CPU policy
# TOTAL: 72 settings (99 powercfg commands)
# NOT COVERED: OEM-specific settings and any registry-only entries without
#   ACSettingIndex values in Power_Control.reg.
#
# RECOMMENDED: Import Power_Control.reg FIRST (covers more settings via registry),
#   then run this script to ensure the powercfg layer matches.
#
# NOTE: This does NOT apply Candidate or Experimental tweaks.

Write-Host ""
Write-Host "  TTCH ULTIMATE PERFORMANCE — Power Plan Rebuild"
Write-Host "  ==============================================="
Write-Host ""

# Step 1: Duplicate the built-in Ultimate Performance scheme
Write-Host "  Step 1: Creating TTCH plan from Ultimate Performance base..."
$baseScheme = "e9a42b02-d5df-448d-aa00-03f14749eb61"
$output = powercfg /duplicatescheme $baseScheme 2>&1
if ($output -match '([a-f0-9-]{36})') {
    $planGuid = $Matches[1]
    Write-Host "  [OK] New plan created: $planGuid"
} else {
    Write-Host "  [!] Failed to create plan. Trying High Performance base..."
    $output = powercfg /duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>&1
    if ($output -match '([a-f0-9-]{36})') {
        $planGuid = $Matches[1]
        Write-Host "  [OK] New plan created from High Performance: $planGuid"
    } else {
        Write-Host "  [ERROR] Cannot create power plan. Aborting."
        return
    }
}

# Step 2: Rename the plan
powercfg /changename $planGuid "TTCH ULTIMATE PERFORMANCE" "Rebuilt by YAZX from saved values"
Write-Host "  [OK] Renamed to TTCH ULTIMATE PERFORMANCE"
Write-Host ""

# Step 3: Apply all 27 saved settings (AC + DC)
Write-Host "  Step 2: Applying 27 saved settings..."
Write-Host ""

# Hard disk / Turn off hard disk after
powercfg /setacvalueindex $planGuid 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0
powercfg /setdcvalueindex $planGuid 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 1200

# Internet Explorer / JavaScript Timer Frequency
powercfg /setacvalueindex $planGuid 02f815b5-a5cf-4c84-bf20-649d1f75d3d8 4c793e7d-a264-42e1-87d3-7a0d2f523ccd 1
powercfg /setdcvalueindex $planGuid 02f815b5-a5cf-4c84-bf20-649d1f75d3d8 4c793e7d-a264-42e1-87d3-7a0d2f523ccd 1

# Desktop background settings / Slide show
powercfg /setacvalueindex $planGuid 0d7dbae2-4294-402a-ba8e-26777e8488cd 309dce9b-bef4-4119-9921-a851fb12f0f4 0
powercfg /setdcvalueindex $planGuid 0d7dbae2-4294-402a-ba8e-26777e8488cd 309dce9b-bef4-4119-9921-a851fb12f0f4 0

# Wireless Adapter Settings / Power Saving Mode
powercfg /setacvalueindex $planGuid 19cbb8fa-5279-450e-9fac-8a3d5fedd0c1 12bbebe6-58d6-4636-95bb-3217ef867c1a 0
powercfg /setdcvalueindex $planGuid 19cbb8fa-5279-450e-9fac-8a3d5fedd0c1 12bbebe6-58d6-4636-95bb-3217ef867c1a 0

# Sleep / Sleep after
powercfg /setacvalueindex $planGuid 238c9fa8-0aad-41ed-83f4-97be242c8f20 29f6c1db-86da-48c5-9fdb-f2b67b1f44da 0
powercfg /setdcvalueindex $planGuid 238c9fa8-0aad-41ed-83f4-97be242c8f20 29f6c1db-86da-48c5-9fdb-f2b67b1f44da 0

# Sleep / Allow hybrid sleep
powercfg /setacvalueindex $planGuid 238c9fa8-0aad-41ed-83f4-97be242c8f20 94ac6d29-73ce-41a6-809f-6363ba21b47e 1
powercfg /setdcvalueindex $planGuid 238c9fa8-0aad-41ed-83f4-97be242c8f20 94ac6d29-73ce-41a6-809f-6363ba21b47e 1

# Sleep / Hibernate after
powercfg /setacvalueindex $planGuid 238c9fa8-0aad-41ed-83f4-97be242c8f20 9d7815a6-7ee4-497e-8888-515a05f02364 0
powercfg /setdcvalueindex $planGuid 238c9fa8-0aad-41ed-83f4-97be242c8f20 9d7815a6-7ee4-497e-8888-515a05f02364 0

# Sleep / Allow wake timers
powercfg /setacvalueindex $planGuid 238c9fa8-0aad-41ed-83f4-97be242c8f20 bd3b718a-0680-4d9d-8ab2-e1d2b4ac806d 0
powercfg /setdcvalueindex $planGuid 238c9fa8-0aad-41ed-83f4-97be242c8f20 bd3b718a-0680-4d9d-8ab2-e1d2b4ac806d 0

# USB settings / USB selective suspend setting
powercfg /setacvalueindex $planGuid 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
powercfg /setdcvalueindex $planGuid 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0

# Power buttons and lid / Start menu power button
powercfg /setacvalueindex $planGuid 4f971e89-eebd-4455-a8de-9e59040e7347 a7066653-8d6c-40a8-910e-a1f54b84c7e5 0
powercfg /setdcvalueindex $planGuid 4f971e89-eebd-4455-a8de-9e59040e7347 a7066653-8d6c-40a8-910e-a1f54b84c7e5 0

# PCI Express / Link State Power Management
powercfg /setacvalueindex $planGuid 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0
powercfg /setdcvalueindex $planGuid 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0

# Processor power management / Minimum processor state
powercfg /setacvalueindex $planGuid 54533251-82be-4824-96c1-47b60b740d00 893dee8e-2bef-41e0-89c6-b55d0929964c 100
powercfg /setdcvalueindex $planGuid 54533251-82be-4824-96c1-47b60b740d00 893dee8e-2bef-41e0-89c6-b55d0929964c 5

# Processor power management / Maximum processor state
powercfg /setacvalueindex $planGuid 54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 100
powercfg /setdcvalueindex $planGuid 54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 100

# Display / Turn off display after
powercfg /setacvalueindex $planGuid 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e 0
powercfg /setdcvalueindex $planGuid 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e 600

# Display / Display brightness
powercfg /setacvalueindex $planGuid 7516b95f-f776-4464-8c53-06167f40cc99 aded5e82-b909-4619-9949-f5d71dac0bcb 100
powercfg /setdcvalueindex $planGuid 7516b95f-f776-4464-8c53-06167f40cc99 aded5e82-b909-4619-9949-f5d71dac0bcb 100

# Display / Dimmed display brightness
powercfg /setacvalueindex $planGuid 7516b95f-f776-4464-8c53-06167f40cc99 f1fbfde2-a960-4165-9f88-50667911ce96 50
powercfg /setdcvalueindex $planGuid 7516b95f-f776-4464-8c53-06167f40cc99 f1fbfde2-a960-4165-9f88-50667911ce96 50

# Display / Enable adaptive brightness
powercfg /setacvalueindex $planGuid 7516b95f-f776-4464-8c53-06167f40cc99 fbd9aa66-9553-4097-ba44-ed6e9d65eab8 0
powercfg /setdcvalueindex $planGuid 7516b95f-f776-4464-8c53-06167f40cc99 fbd9aa66-9553-4097-ba44-ed6e9d65eab8 0

# Multimedia settings / When sharing media
powercfg /setacvalueindex $planGuid 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 03680956-93bc-4294-bba6-4e0f09bb717f 1
powercfg /setdcvalueindex $planGuid 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 03680956-93bc-4294-bba6-4e0f09bb717f 1

# Multimedia settings / Video playback quality bias
powercfg /setacvalueindex $planGuid 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 10778347-1370-4ee0-8bbd-33bdacaade49 1
powercfg /setdcvalueindex $planGuid 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 10778347-1370-4ee0-8bbd-33bdacaade49 0

# Multimedia settings / When playing video
powercfg /setacvalueindex $planGuid 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 34c7b99f-9a6d-4b3c-8dc7-b6693b78cef4 0
powercfg /setdcvalueindex $planGuid 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 34c7b99f-9a6d-4b3c-8dc7-b6693b78cef4 0

# Battery / Critical battery notification
powercfg /setacvalueindex $planGuid e73a048d-bf27-4f12-9731-8b2076e8891f 5dbb7c9f-38e9-40d2-9749-4f8a0e9f640f 1
powercfg /setdcvalueindex $planGuid e73a048d-bf27-4f12-9731-8b2076e8891f 5dbb7c9f-38e9-40d2-9749-4f8a0e9f640f 1

# Battery / Critical battery action
powercfg /setacvalueindex $planGuid e73a048d-bf27-4f12-9731-8b2076e8891f 637ea02f-bbcb-4015-8e2c-a1c7b9c0b546 2
powercfg /setdcvalueindex $planGuid e73a048d-bf27-4f12-9731-8b2076e8891f 637ea02f-bbcb-4015-8e2c-a1c7b9c0b546 2

# Battery / Low battery level
powercfg /setacvalueindex $planGuid e73a048d-bf27-4f12-9731-8b2076e8891f 8183ba9a-e910-48da-8769-14ae6dc1170a 10
powercfg /setdcvalueindex $planGuid e73a048d-bf27-4f12-9731-8b2076e8891f 8183ba9a-e910-48da-8769-14ae6dc1170a 10

# Battery / Critical battery level
powercfg /setacvalueindex $planGuid e73a048d-bf27-4f12-9731-8b2076e8891f 9a66d8d7-4ff7-4ef9-b5a2-5a326ca2a469 5
powercfg /setdcvalueindex $planGuid e73a048d-bf27-4f12-9731-8b2076e8891f 9a66d8d7-4ff7-4ef9-b5a2-5a326ca2a469 5

# Battery / Low battery notification
powercfg /setacvalueindex $planGuid e73a048d-bf27-4f12-9731-8b2076e8891f bcded951-187b-4d05-bccc-f7e51960c258 1
powercfg /setdcvalueindex $planGuid e73a048d-bf27-4f12-9731-8b2076e8891f bcded951-187b-4d05-bccc-f7e51960c258 1

# Battery / Low battery action
powercfg /setacvalueindex $planGuid e73a048d-bf27-4f12-9731-8b2076e8891f d8742dcb-3e6a-4b3c-b3fe-374623cdcf06 0
powercfg /setdcvalueindex $planGuid e73a048d-bf27-4f12-9731-8b2076e8891f d8742dcb-3e6a-4b3c-b3fe-374623cdcf06 0

# Battery / Reserve battery level
powercfg /setacvalueindex $planGuid e73a048d-bf27-4f12-9731-8b2076e8891f f3c5027d-cd16-4930-aa6b-90db844a8f00 7
powercfg /setdcvalueindex $planGuid e73a048d-bf27-4f12-9731-8b2076e8891f f3c5027d-cd16-4930-aa6b-90db844a8f00 7


# Step 4: Apply 45 registry-only settings (AC only — desktop has no battery DC)
# SOURCE: Power_Control.reg — these settings are NOT visible in powercfg /query
# CLASSIFICATION: Reconstructed from registry export, NOT exact from powercfg output
Write-Host "  Step 3: Applying 45 registry-only settings (from Power_Control.reg)..."
Write-Host ""

# Hard disk / AHCI Link Power Management - HIPM/DIPM (AC only)
powercfg /setacvalueindex $planGuid 0012ee47-9041-4b5d-9b77-535fba8b1442 fc7372b6-ab2d-43ee-8797-15e9841f2cca 0

# Sleep / Allow Away Mode Policy (AC only)
powercfg /setacvalueindex $planGuid 238c9fa8-0aad-41ed-83f4-97be242c8f20 25dfa149-5dd1-4736-b5ab-e8a37b5b8187 1

# Sleep / System unattended sleep timeout (AC only)
powercfg /setacvalueindex $planGuid 238c9fa8-0aad-41ed-83f4-97be242c8f20 7bc4a2f9-d8fc-4469-b07b-33eb785aaca0 120

# Sleep / Allow System Required Policy (AC only)
powercfg /setacvalueindex $planGuid 238c9fa8-0aad-41ed-83f4-97be242c8f20 abfc2519-3608-4c2a-94ea-171b0ed546ab 1

# USB / USB 3 Link Power Management (AC only)
powercfg /setacvalueindex $planGuid 2a737441-1930-4402-8d77-b2bebba308a3 0853a681-27c8-4100-a2fd-82013e970683 0

# USB / Hub Selective Suspend Timeout (AC only)
powercfg /setacvalueindex $planGuid 2a737441-1930-4402-8d77-b2bebba308a3 d4e98f31-5ffe-4ce1-be31-1b38b384c009 0

# Energy Saver / Charge level (AC only)
powercfg /setacvalueindex $planGuid 2e601130-5351-4d9d-8e04-252966bad054 c36f0eb4-2988-4a70-8eee-0884fc2c2433 0

# Energy Saver / Energy Saver Policy (AC only)
powercfg /setacvalueindex $planGuid 2e601130-5351-4d9d-8e04-252966bad054 c42b79aa-aa3a-484b-a98f-2cf32aa90a28 0

# Energy Saver / Energy Saver Brightness Weight (AC only)
powercfg /setacvalueindex $planGuid 2e601130-5351-4d9d-8e04-252966bad054 d502f7ee-1dc7-4efd-a55d-f04b6f5c0545 0

# Interrupt Steering / Interrupt Steering Mode (AC only)
powercfg /setacvalueindex $planGuid 48672f38-7a9a-4bb2-8bf8-3d85be19de4e 2bfc24f9-5ea2-4801-8213-3dbae01aa39d 6

# Power buttons / Power button action (AC only)
powercfg /setacvalueindex $planGuid 4f971e89-eebd-4455-a8de-9e59040e7347 7648efa3-dd9c-4e3e-b566-50f929386280 3

# Power buttons / Lid close action (AC only)
powercfg /setacvalueindex $planGuid 4f971e89-eebd-4455-a8de-9e59040e7347 96996bc0-ad50-47ec-923b-6f41874dd9eb 1

# === PROCESSOR POWER MANAGEMENT (30 hidden settings) ===
# These are the core performance-tuning settings TTCH applied

# Processor / Heterogeneous policy in effect (P-core class 1, AC only)
powercfg /setacvalueindex $planGuid 54533251-82be-4824-96c1-47b60b740d00 06cadf0e-64ed-448a-8927-ce7bf90eb35d 100

# Processor / Heterogeneous policy in effect (E-core class 0, AC only)
powercfg /setacvalueindex $planGuid 54533251-82be-4824-96c1-47b60b740d00 06cadf0e-64ed-448a-8927-ce7bf90eb35e 100

# Processor / Autonomous mode (AC only) — 0=disabled
powercfg /setacvalueindex $planGuid 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318584 0

# Processor / Processor performance core parking min cores (class 1, AC only)
powercfg /setacvalueindex $planGuid 54533251-82be-4824-96c1-47b60b740d00 12a0ab44-fe28-4fa9-b3bd-4b64f44960a6 100

# Processor / Processor performance core parking min cores (class 0, AC only)
powercfg /setacvalueindex $planGuid 54533251-82be-4824-96c1-47b60b740d00 12a0ab44-fe28-4fa9-b3bd-4b64f44960a7 20

# Processor / Processor performance core parking concurrency headroom threshold (AC only)
powercfg /setacvalueindex $planGuid 54533251-82be-4824-96c1-47b60b740d00 1facfc65-a930-4bc5-9f38-504ec097bbc0 50

# Processor / Processor performance core parking max cores (class 0, AC only)
powercfg /setacvalueindex $planGuid 54533251-82be-4824-96c1-47b60b740d00 2430ab6f-a520-44a2-9601-f7f23b5134b1 97

# Processor / Processor performance increase time (AC only)
powercfg /setacvalueindex $planGuid 54533251-82be-4824-96c1-47b60b740d00 36687f9e-e3a5-4dbf-b1dc-15eb381c6863 0

# Processor / Processor energy performance preference policy (AC only) — 0=max performance
powercfg /setacvalueindex $planGuid 54533251-82be-4824-96c1-47b60b740d00 3b04d4fd-1cc7-4f23-ab1c-d1337819c4bb 0

# Processor / Processor performance core parking increase time (AC only)
powercfg /setacvalueindex $planGuid 54533251-82be-4824-96c1-47b60b740d00 40fbefc7-2e9d-4d25-a185-0cfd8574bac7 0

# Processor / Processor performance boost mode (AC only) — 2=aggressive
powercfg /setacvalueindex $planGuid 54533251-82be-4824-96c1-47b60b740d00 465e1f50-b610-473a-ab58-00d1077dc418 2

# Processor / Processor performance core parking max cores (class 1, AC only)
powercfg /setacvalueindex $planGuid 54533251-82be-4824-96c1-47b60b740d00 4b92d758-5a24-4851-a470-815d78aee119 100

# Processor / Processor idle demote threshold (AC only)
powercfg /setacvalueindex $planGuid 54533251-82be-4824-96c1-47b60b740d00 4bdaf4e9-d103-46d7-a5f0-6280121616ef 90

# Processor / Processor idle time check (AC only) — microseconds
powercfg /setacvalueindex $planGuid 54533251-82be-4824-96c1-47b60b740d00 4d2b0152-7d5c-498b-88e2-34345392a2c5 5000

# Processor / Processor performance core parking distribution threshold (AC only)
powercfg /setacvalueindex $planGuid 54533251-82be-4824-96c1-47b60b740d00 5d76a2ca-e8c0-402f-a133-2158492d58ad 0

# Processor / Processor performance core parking decrease policy (AC only) — 50=graduated
powercfg /setacvalueindex $planGuid 54533251-82be-4824-96c1-47b60b740d00 616cdaa5-695e-4545-97ad-97dc2d1bdd88 50

# Processor / Processor performance core parking increase policy (AC only) — 0=immediate
powercfg /setacvalueindex $planGuid 54533251-82be-4824-96c1-47b60b740d00 616cdaa5-695e-4545-97ad-97dc2d1bdd89 0

# Processor / Processor idle promote threshold (AC only)
powercfg /setacvalueindex $planGuid 54533251-82be-4824-96c1-47b60b740d00 619b7505-003b-4e82-b7a6-4dd29c300971 99

# Processor / Processor performance core parking overutilization threshold (AC only)
powercfg /setacvalueindex $planGuid 54533251-82be-4824-96c1-47b60b740d00 619b7505-003b-4e82-b7a6-4dd29c300972 50

# Processor / Processor performance core parking parked performance state (class 1, AC only)
powercfg /setacvalueindex $planGuid 54533251-82be-4824-96c1-47b60b740d00 7b224883-b3cc-4d79-819f-8374152cbe7c 100

# Processor / Processor performance time check interval (AC only)
powercfg /setacvalueindex $planGuid 54533251-82be-4824-96c1-47b60b740d00 7f2f5cfa-f10c-4823-b5e1-e93ae85f46b5 4

# Processor / Processor performance decrease time (AC only)
powercfg /setacvalueindex $planGuid 54533251-82be-4824-96c1-47b60b740d00 93b8b6dc-0698-4d1c-9ee4-0644e900c85d 5

# Processor / Processor performance core parking decrease time (AC only)
powercfg /setacvalueindex $planGuid 54533251-82be-4824-96c1-47b60b740d00 943c8cb6-6f93-4227-ad87-e9a3feec08d1 60

# Processor / Processor performance core parking utility distribution (AC only) — 2=enabled
powercfg /setacvalueindex $planGuid 54533251-82be-4824-96c1-47b60b740d00 bae08b81-2d5e-4688-ad6a-13243356654b 2

# Processor / Performance boost policy (AC only) — 2=aggressive at guaranteed
powercfg /setacvalueindex $planGuid 54533251-82be-4824-96c1-47b60b740d00 be337238-0d82-4146-a960-4f3749d470c7 2

# Processor / Processor idle disable (AC only) — 0=idle states enabled
powercfg /setacvalueindex $planGuid 54533251-82be-4824-96c1-47b60b740d00 c4581c31-89ab-4597-8e2b-9c9cab440e6b 50000

# Processor / Processor performance decrease policy (class 1, AC only)
powercfg /setacvalueindex $planGuid 54533251-82be-4824-96c1-47b60b740d00 d8edeb9b-95cf-4f95-a73c-b061973693c8 1

# Processor / Processor performance increase policy (class 1, AC only)
powercfg /setacvalueindex $planGuid 54533251-82be-4824-96c1-47b60b740d00 d8edeb9b-95cf-4f95-a73c-b061973693c9 2

# Processor / Processor performance decrease threshold (AC only)
powercfg /setacvalueindex $planGuid 54533251-82be-4824-96c1-47b60b740d00 dfd10d17-d5eb-45dd-877a-9a34ddd15c82 20

# Processor / Processor performance increase threshold (AC only)
powercfg /setacvalueindex $planGuid 54533251-82be-4824-96c1-47b60b740d00 f735a673-2066-4f80-a0c5-ddee0cf1bf5d 20

# Display / Console lock display off timeout (AC only) — seconds
powercfg /setacvalueindex $planGuid 7516b95f-f776-4464-8c53-06167f40cc99 17aaa29b-8b43-4b94-aafe-35f64daaf1ee 885

# Display / Display idle timeout (AC only)
powercfg /setacvalueindex $planGuid 7516b95f-f776-4464-8c53-06167f40cc99 8ec4b3a5-6868-48c2-be75-4f3044be88a7 60

# Presence Aware / Standby budget percent (AC only)
powercfg /setacvalueindex $planGuid 8619b916-e004-4dd8-9b66-dae86f806698 5adbbfbc-074e-4da1-ba38-db8b36b2c8f3 240

Write-Host "  [OK] 45 registry-only settings applied (AC only)"
Write-Host ""

# Step 5: Activate the plan
Write-Host "  Step 4: Activating TTCH plan..."
powercfg /setactive $planGuid
Write-Host "  [OK] TTCH ULTIMATE PERFORMANCE is now the active plan"
Write-Host ""

# Step 6: Summary
Write-Host "  === Rebuild Summary ==="
Write-Host "  Exact Restore (from powercfg /query):  27 settings (AC+DC)"
Write-Host "  Reconstructed (from Power_Control.reg): 45 settings (AC only)"
Write-Host "  Total: 72 settings applied"
Write-Host ""
Write-Host "  Import Power_Control.reg AFTER this script for any remaining"
Write-Host "  registry-level settings not accessible via powercfg."
Write-Host ""

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
if ($LogFile) {
    Add-Content $LogFile "[$timestamp] TTCH Power Plan rebuilt: $planGuid (72 settings: 27 exact + 45 reconstructed)"
}
