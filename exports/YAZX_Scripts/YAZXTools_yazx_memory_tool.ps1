# YAZX Memory Tool v4 - Fast bulk-scan + validation + full descriptions
# Free play / private lobby only, with Easy Anti-Cheat disabled

Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class Mem {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(uint access, bool inherit, int pid);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr addr, byte[] buf, int size, out IntPtr read);
    [DllImport("kernel32.dll")] public static extern bool WriteProcessMemory(IntPtr h, IntPtr addr, byte[] buf, int size, out IntPtr written);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
    [DllImport("kernel32.dll")] public static extern IntPtr CreateToolhelp32Snapshot(uint flags, int pid);
    [DllImport("kernel32.dll")] public static extern bool Module32FirstW(IntPtr h, ref MODULEENTRY32 me);
    [DllImport("kernel32.dll")] public static extern bool Module32NextW(IntPtr h, ref MODULEENTRY32 me);
    [DllImport("psapi.dll", SetLastError = true)] public static extern bool EnumProcessModulesEx(IntPtr hProcess, [Out] IntPtr[] lphModule, uint cb, out uint lpcbNeeded, uint dwFilterFlag);
    [DllImport("psapi.dll", CharSet = CharSet.Unicode)] public static extern uint GetModuleFileNameExW(IntPtr hProcess, IntPtr hModule, StringBuilder lpFilename, uint nSize);
    [DllImport("psapi.dll")] public static extern bool GetModuleInformation(IntPtr hProcess, IntPtr hModule, out MODULEINFO lpmodinfo, uint cb);

    [StructLayout(LayoutKind.Sequential)]
    public struct MODULEINFO {
        public IntPtr lpBaseOfDll;
        public uint SizeOfImage;
        public IntPtr EntryPoint;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct MODULEENTRY32 {
        public uint dwSize;
        public uint th32ModuleID;
        public uint th32ProcessID;
        public uint GlblcntUsage;
        public uint ProccntUsage;
        public IntPtr modBaseAddr;
        public uint modBaseSize;
        public IntPtr hModule;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)] public string szModule;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)] public string szExePath;
    }

    public static long GetModuleBase(int pid, string moduleName) {
        // Method 1: Toolhelp32Snapshot (fails if this process and target are different bitness - WOW64 limitation)
        const uint TH32CS_SNAPMODULE = 0x00000008;
        const uint TH32CS_SNAPMODULE32 = 0x00000010;
        IntPtr snap = CreateToolhelp32Snapshot(TH32CS_SNAPMODULE | TH32CS_SNAPMODULE32, pid);
        if (snap != IntPtr.Zero && snap.ToInt64() != -1) {
            MODULEENTRY32 me = new MODULEENTRY32();
            me.dwSize = (uint)Marshal.SizeOf(typeof(MODULEENTRY32));
            if (Module32FirstW(snap, ref me)) {
                do {
                    if (string.Equals(me.szModule, moduleName, StringComparison.OrdinalIgnoreCase)) {
                        CloseHandle(snap);
                        return me.modBaseAddr.ToInt64();
                    }
                } while (Module32NextW(snap, ref me));
            }
            CloseHandle(snap);
        }

        // Method 2: psapi.dll EnumProcessModulesEx (independent API, different failure mode)
        const uint PROCESS_QUERY_INFORMATION = 0x0400;
        const uint PROCESS_VM_READ = 0x0010;
        IntPtr hProc = OpenProcess(PROCESS_QUERY_INFORMATION | PROCESS_VM_READ, false, pid);
        if (hProc == IntPtr.Zero) return 0;
        try {
            IntPtr[] modules = new IntPtr[1024];
            uint needed;
            if (!EnumProcessModulesEx(hProc, modules, (uint)(IntPtr.Size * modules.Length), out needed, 3 /* LIST_MODULES_ALL */)) {
                return 0;
            }
            int count = (int)(needed / IntPtr.Size);
            for (int i = 0; i < count && i < modules.Length; i++) {
                StringBuilder sb = new StringBuilder(260);
                GetModuleFileNameExW(hProc, modules[i], sb, 260);
                string path = sb.ToString();
                if (path.EndsWith(moduleName, StringComparison.OrdinalIgnoreCase)) {
                    MODULEINFO info;
                    if (GetModuleInformation(hProc, modules[i], out info, (uint)Marshal.SizeOf(typeof(MODULEINFO)))) {
                        return info.lpBaseOfDll.ToInt64();
                    }
                }
            }
        } finally {
            CloseHandle(hProc);
        }
        return 0;
    }
}
"@

$PROCESS_ALL_ACCESS = 0x1F0FFF

function Get-GameHandle {
    Write-Host "[DEBUG] PowerShell bitness: $([Environment]::Is64BitProcess)" -ForegroundColor DarkGray
    Write-Host "[DEBUG] OS bitness:         $([Environment]::Is64BitOperatingSystem)" -ForegroundColor DarkGray

    $proc = Get-Process RocketLeague -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $proc) {
        Write-Host "[*] Rocket League is not running yet - waiting..." -ForegroundColor Yellow
        Write-Host "    (Press Ctrl+C to cancel)" -ForegroundColor DarkGray
        while (-not $proc) {
            Start-Sleep -Seconds 2
            $proc = Get-Process RocketLeague -ErrorAction SilentlyContinue | Select-Object -First 1
        }
        Write-Host "[+] Rocket League detected." -ForegroundColor Green
    }
    Write-Host "[DEBUG] PID found: $($proc.Id)" -ForegroundColor DarkGray
    Write-Host "[DEBUG] Process path: $($proc.Path)" -ForegroundColor DarkGray

    $h = [Mem]::OpenProcess($PROCESS_ALL_ACCESS, $false, $proc.Id)
    Write-Host "[DEBUG] OpenProcess handle: $h  (LastError: $([System.Runtime.InteropServices.Marshal]::GetLastWin32Error()))" -ForegroundColor DarkGray
    if ($h -eq [IntPtr]::Zero) {
        Write-Host "[!] Could not open process (handle is zero). Run this as Administrator." -ForegroundColor Red
        return $null
    }

    $base = [Mem]::GetModuleBase($proc.Id, "RocketLeague.exe")
    Write-Host "[DEBUG] GetModuleBase result: 0x$('{0:X}' -f $base)  (LastError: $([System.Runtime.InteropServices.Marshal]::GetLastWin32Error()))" -ForegroundColor DarkGray

    if ($base -eq 0) {
        Write-Host "[!] Both module-lookup methods failed. See [DEBUG] lines above - please copy them and send back." -ForegroundColor Red
        [Mem]::CloseHandle($h) | Out-Null
        return $null
    }
    Write-Host ("[+] Connected to PID {0}  |  Base: 0x{1:X}" -f $proc.Id, $base) -ForegroundColor Green
    return @{ Handle = $h; Base = $base }
}

# IMPORTANT: Some booleans in the SDK offset comments are PACKED into a shared
# uint32 with other flags (e.g. [bool : 0x2], [bool : 0x4] at the SAME offset).
# Writing them requires read-modify-write with bitwise OR/AND, never a raw 1/0
# write - that would corrupt sibling flags packed at the same address.
# Only [bool : 0x1] at a UNIQUE standalone offset is a true full uint32 bool.
# This tool currently only reads/writes float properties, so this does not
# affect any option in the menu today - documented here for future additions.

function Read-Bytes($h, $addr, [int]$size) {
    $buf = New-Object byte[] $size
    $read = [IntPtr]::Zero
    $ok = [Mem]::ReadProcessMemory($h, [IntPtr][int64]$addr, $buf, $size, [ref]$read)
    if (-not $ok) { return $null }
    return $buf
}
function Read-U64($h, $addr) { $b = Read-Bytes $h $addr 8; if ($b) { [BitConverter]::ToUInt64($b,0) } else { 0 } }
function Read-I32($h, $addr) { $b = Read-Bytes $h $addr 4; if ($b) { [BitConverter]::ToInt32($b,0) } else { 0 } }
function Read-F32($h, $addr) { $b = Read-Bytes $h $addr 4; if ($b) { [BitConverter]::ToSingle($b,0) } else { 0 } }
function Write-F32($h, $addr, [float]$val) {
    $buf = [BitConverter]::GetBytes([float]$val); $written = [IntPtr]::Zero
    return [Mem]::WriteProcessMemory($h, [IntPtr][int64]$addr, $buf, 4, [ref]$written)
}

# Sanity check: is this a plausible user-mode pointer? (rules out 0, tiny, or absurdly huge garbage)
function Test-ValidPointer($p) {
    # سقف عنوان أساس اللعبة نفسه كان قريباً جداً (0.03%) من سقفنا القديم —
    # نوسّعه لحد ويندوز ٦٤ بت الحقيقي (0x7FFFFFFFFFFF كان ضيقاً جداً فعلياً)
    return ($p -gt 0x10000) -and ($p -lt 0x7FFFFFFFFFFFFF)
}

# Confirmed offsets from rlsdk (ObscuritySRL)
$OFF_GOBJECTS       = 0x2493730
$OFF_GNAMES         = 0x24936e8
$OFF_STATICMESH     = 0x07d8
$OFF_BODYINSTANCE   = 0x01d8
$OFF_MASSSCALE      = 0x00dc
$OFF_DAMPINGSCALE   = 0x00e0
$OFF_GRAVFACTOR     = 0x00c8
$OFF_CONTACTFORCE   = 0x00d8
$OFF_CARINTERACTION = 0x0800
$OFF_CI_PUSHZ       = $OFF_CARINTERACTION + 0x0020
$OFF_CI_PUSHFWD     = $OFF_CARINTERACTION + 0x0024
$OFF_CI_MAXRELSPD   = $OFF_CARINTERACTION + 0x0028
$OFF_CI_RESTITUTION = $OFF_CARINTERACTION + 0x002c
$OFF_CI_FRICTION    = $OFF_CARINTERACTION + 0x0030
$OFF_OBJ_NAME       = 0x0048
$OFF_ACTOR_LOCATION = 0x0090  # Actor.Location (FVector) - verified from Engine.ts Offsets package
$OFF_ACTOR_PHYSICS  = 0x00c9  # Actor.Physics (EPhysics, 1 byte) - PHYS_RigidBody = 9
# --- New verified offsets, no live default values found anywhere online (smish.dev/RLBot wiki/web) ---
# Name+offset confirmed from SDK; only this tool reading them live gives real starting values.
$OFF_RBA_GROUNDOFFSET = 0x07a4  # RBActor_TA.GroundOffsetDistance
$OFF_WI_DEFSKINWIDTH  = 0x0840  # WorldInfo.DefaultSkinWidth - REAL engine default, confirmed from Offsets package
$OFF_RBA_GRAVSCALE    = 0x0764  # RBActor_TA.ReplicatedGravityScale
$OFF_WHEEL_SUSPSTIFF  = 0x0078  # Wheel_TA.SuspensionStiffness
$OFF_WHEEL_SUSPDCOMP  = 0x007c  # Wheel_TA.SuspensionDampingCompression
$OFF_WHEEL_SUSPDRELAX = 0x0080  # Wheel_TA.SuspensionDampingRelaxation
$OFF_OBJ_CLASS      = 0x0050
$OFF_BALL_RADIUS    = 0x0888
$OFF_PM_FRICTION    = 0x0064
$OFF_PM_RESTITUTION = 0x0068
$OFF_VEH_VEHICLESIM = 0x07e0
$OFF_VS_WHEELS      = 0x00a0
$OFF_WHEEL_CONTACT  = 0x0160
$OFF_CONTACT_HASCONTACT = 0x0000
$OFF_CONTACT_PHYSMAT     = 0x0048
$OFF_HP_FRONTAXLE   = 0x0060
$OFF_HP_BACKAXLE    = 0x0074
$OFF_HP_CHASSISSPRING = 0x0090
$OFF_CSS_MASS       = 0x0034
$OFF_WALLFRICTION   = 0x00f8   # Wheel_TA.WallFrictionCurve (TArray<FInterpCurvePointFloat>)
$SIZE_CURVEPOINT    = 0x19     # sizeof(FInterpCurvePointFloat) - confirmed from Core.ts Size comment
$OFF_POINT_OUTVAL    = 0x04
$OFF_VELOCITY        = 0x006c   # RB_BodyInstance.Velocity (FVector, read-only diagnostic)
$OFF_PAWN_MASS       = 0x0314   # Engine.Pawn.Mass (car weight - inherited by Car_TA)
$OFF_WI_GRAVITY      = 0x0620   # WorldInfo.DefaultGravityZ
$OFF_WI_GRAVSCALE    = 0x0628   # WorldInfo.RBPhysicsGravityScaling
$OFF_WI_TIMEDIL      = 0x0548   # WorldInfo.TimeDilation
$OFF_RBA_ROLLFRIC    = 0x0568   # RBActor_TA.RollingFriction (direct from Car object)
$OFF_RBA_PREWELDMASS = 0x0760   # RBActor_TA.PreWeldMass
$OFF_RBA_MAXANGSPD   = 0x0564   # RBActor_TA.MaxAngularSpeed
$OFF_RBA_MAXLINSPD   = 0x0560   # RBActor_TA.MaxLinearSpeed
$OFF_RBA_GROUNDTRACE = 0x07a0   # RBActor_TA.GroundTraceDistance
$OFF_VEH_BOOSTCOMP   = 0x0870   # Vehicle_TA.BoostComponent (pointer)
$OFF_BOOST_CURRENT   = 0x0338   # CarComponent_Boost_TA.CurrentBoostAmount
$OFF_BOOST_MAX       = 0x032c
$OFF_VEH_DODGECOMP   = 0x0878
$OFF_VEH_JUMPCOMP    = 0x0888
$OFF_DODGE_FWD       = 0x0334

$OFF_JUMP_IMPULSE    = 0x02ec
$OFF_VEH_DJUMPCOMP   = 0x0890
$OFF_DJUMP_IMPULSE   = 0x0060
$OFF_PCFG_JUMPLEAVE  = 0x01b0
   # CarComponent_Boost_TA.MaxBoostAmount

# ── Menu option definitions: value, valid range, units, description ──
$OPTIONS = @{
    "1" = @{ Name="Body weight (InstanceMassScale)"; Default=1.0; Min=0.1; Max=5.0;
             Desc="1.0 = normal weight (multiplier, not absolute). Confirmed real car mass = 180, ball mass = 30 (source: RLGym game values). 2.0 = twice as heavy. 0.5 = half weight. Needs pointer chain." }
    "2" = @{ Name="Body damping (InstanceDampingScale)"; Default=1.0; Min=0.0; Max=5.0;
             Desc="Higher = motion decays faster (feels 'sticky'/slow to react). 0 = no extra damping." }
    "3" = @{ Name="Body gravity multiplier (CustomGravityFactor)"; Default=1.0; Min=0.0; Max=5.0;
             Desc="1.0 = normal gravity for this object. 0 = floats. 2.0 = falls twice as fast." }
    "4" = @{ Name="Collision force threshold (ContactReportForceThreshold)"; Default=0.0; Min=0.0; Max=1000.0;
             Desc="Minimum impact force before the engine 'notices' a collision event. Usually 0 (always notice). Raising it can make light touches get ignored." }
    "5" = @{ Name="Ball-car friction (Friction)"; Default=0.3; Min=0.0; Max=2.0;
             Desc="Higher = ball 'grips' the car surface more (less sliding on touch)." }
    "6" = @{ Name="Ball-car restitution (Restitution)"; Default=0.6; Min=0.0; Max=2.0;
             Desc="Higher = bouncier ball off the car. Lower = more of a 'dead' touch." }
    "7" = @{ Name="Vertical push force (PushZScale)"; Default=1.0; Min=0.0; Max=3.0;
             Desc="Scales how much the car pushes the ball upward on contact." }
    "8" = @{ Name="Forward push force (PushForwardScale)"; Default=1.0; Min=0.0; Max=3.0;
             Desc="Scales how much the car pushes the ball forward on contact." }
    "9" = @{ Name="Max relative speed (MaxRelativeSpeed)"; Default=4600; Min=0; Max=10000;
             Desc="Speed cap used in the ball-car interaction calculation." }
    "10" = @{ Name="Wall friction curve (WallFrictionCurve point)"; Default=1.0; Min=0.0; Max=3.0;
             Desc="Real curve editing via direct memory - not possible with cheat set. Edits one point's OutVal (grip multiplier) in the wheel's wall-friction curve. Target the WHEEL object, not the ball." }
}

function Edit-WallFrictionCurve($h, $wheelObj) {
    $arrPtr = $wheelObj + $OFF_WALLFRICTION
    $dataPtr = Read-U64 $h $arrPtr
    $count = Read-I32 $h ($arrPtr + 8)
    if (-not (Test-ValidPointer $dataPtr) -or $count -le 0 -or $count -gt 64) {
        Write-Host "[!] Curve array did not resolve to a valid pointer/count." -ForegroundColor Red
        return
    }
    Write-Host "Curve has $count points:"
    for ($i = 0; $i -lt $count; $i++) {
        $pAddr = $dataPtr + ($i * $SIZE_CURVEPOINT)
        $inVal = Read-F32 $h $pAddr
        $outVal = Read-F32 $h ($pAddr + $OFF_POINT_OUTVAL)
        Write-Host ("  [{0}] InVal={1}  OutVal={2}" -f $i, $inVal, $outVal)
    }
    $idx = Read-Host "Which point index to edit"
    $pAddr = $dataPtr + ([int]$idx * $SIZE_CURVEPOINT)
    $cur = Read-F32 $h ($pAddr + $OFF_POINT_OUTVAL)
    Write-Host "Current OutVal: $cur"
    $new = Read-Host "New OutVal (grip multiplier)"
    $ok = Write-F32 $h ($pAddr + $OFF_POINT_OUTVAL) $new
    if ($ok) { Write-Host "[+] Curve point updated" -ForegroundColor Green }
    else { Write-Host "[!] Write failed" -ForegroundColor Red }
}

function Get-NameString($h, $base, [int]$nameIndex) {
    # CONFIRMED via live byte-level trace: the text is stored INLINE starting
    # at offset 0x18 of FNameEntry - it is NOT a separate pointer to dereference.
    # (The SDK's "[wchar_t*]" comment just marks where the string data begins.)
    $OFF_NAMEENTRY_NAME = 0x18
    $gnamesAddr = $base + $OFF_GNAMES
    $dataPtr = Read-U64 $h $gnamesAddr
    if (-not (Test-ValidPointer $dataPtr)) { return $null }
    $entryPtr = Read-U64 $h ($dataPtr + ($nameIndex * 8))
    if (-not (Test-ValidPointer $entryPtr)) { return $null }
    $raw = Read-Bytes $h ($entryPtr + $OFF_NAMEENTRY_NAME) 64
    if (-not $raw) { return $null }
    try {
        $s = [System.Text.Encoding]::Unicode.GetString($raw).Split([char]0)[0]
        if ($s -match '^[A-Za-z_][A-Za-z0-9_]{2,}$') { return $s }
    } catch {}
    return $null
}

# Fast bulk read of the whole GObjects pointer table in one syscall
function Get-ObjectTable($h, $base) {
    $gobjAddr = $base + $OFF_GOBJECTS
    $dataPtr = Read-U64 $h $gobjAddr
    $count = Read-I32 $h ($gobjAddr + 8)
    if ($dataPtr -eq 0 -or $count -le 0 -or $count -gt 500000) {
        Write-Host "    [!] GObjects layout did not match expectations." -ForegroundColor Red
        return $null
    }
    $sw2 = [System.Diagnostics.Stopwatch]::StartNew()
    Write-Host "    Reading $count object pointers in bulk..." -ForegroundColor DarkGray
    [byte[]]$bulk = Read-Bytes $h $dataPtr ($count * 8)
    if (-not $bulk) { return $null }
    $ptrs = New-Object 'UInt64[]' $count
    try {
        [System.Buffer]::BlockCopy($bulk, 0, $ptrs, 0, $bulk.Length)
    } catch {
        Write-Host "    [!] Fast copy failed, using slower fallback loop..." -ForegroundColor DarkYellow
        for ($i = 0; $i -lt $count; $i++) { $ptrs[$i] = [BitConverter]::ToUInt64($bulk, $i*8) }
    }
    Write-Host ("    Pointer table built in {0:N2}s" -f $sw2.Elapsed.TotalSeconds) -ForegroundColor DarkGray
    return $ptrs
}

function Find-ByValueSignature($h, $base) {
    $ptrs = Get-ObjectTable $h $base
    if (-not $ptrs) { return 0 }
    $target = 91.25  # BALL_RADIUS confirmed from RLGym official game values
    $checked = 0
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $lastUpdate = 0
    foreach ($objPtr in $ptrs) {
        if ($objPtr -eq 0) { continue }
        $checked++
        if ($checked - $lastUpdate -ge 10000) {
            Write-Host ("    ... {0}/{1}  [{2:N1}s]" -f $checked, $ptrs.Length, $sw.Elapsed.TotalSeconds) -ForegroundColor DarkGray
            $lastUpdate = $checked
        }
        $val = Read-F32 $h ($objPtr + $OFF_BALL_RADIUS)
        if ($val -gt ($target - 1) -and $val -lt ($target + 1)) {
            # Extra validation: does this object's pointer chain actually resolve?
            $sm = Read-U64 $h ($objPtr + $OFF_STATICMESH)
            if (-not (Test-ValidPointer $sm)) { continue }
            $bi = Read-U64 $h ($sm + $OFF_BODYINSTANCE)
            if (-not (Test-ValidPointer $bi)) { continue }
            Write-Host ("    [+] Verified ball object: radius={0:N2} @ 0x{1:X}" -f $val, $objPtr) -ForegroundColor Green
            return $objPtr
        }
    }
    Write-Host "    [!] No verified match found (checked $checked objects)." -ForegroundColor Red
    return 0
}

function List-ObjectsByClass($h, $base, [string]$classNameContains, [int]$maxResults = 20) {
    $ptrs = Get-ObjectTable $h $base
    if (-not $ptrs) { return @() }
    $results = @()
    foreach ($objPtr in $ptrs) {
        if ($objPtr -eq 0) { continue }
        $classPtr = Read-U64 $h ($objPtr + $OFF_OBJ_CLASS)
        if (-not (Test-ValidPointer $classPtr)) { continue }
        $className = Get-CachedClassName $h $base $classPtr
        if ($className -and $className -eq $classNameContains -and -not $className.StartsWith("__")) {
            $selfNameIdx = Read-I32 $h ($objPtr + $OFF_OBJ_NAME)
            $selfName = Get-NameString $h $base $selfNameIdx
            $results += [PSCustomObject]@{ Addr = $objPtr; Class = $className; Name = $selfName }
            if ($results.Count -ge $maxResults) { break }
        }
    }
    return $results
}

$Global:ClassNameCache = @{}

function Get-CachedClassName($h, $base, $classPtr) {
    if ($Global:ClassNameCache.ContainsKey($classPtr)) { return $Global:ClassNameCache[$classPtr] }
    $classNameIdx = Read-I32 $h ($classPtr + $OFF_OBJ_NAME)
    $className = Get-NameString $h $base $classNameIdx
    $Global:ClassNameCache[$classPtr] = $className
    return $className
}

function Find-ByNameVerbose($h, $base, [string]$classNameContains, [int]$timeoutSeconds = 150) {
    # Diagnostic version: prints EVERY name match found (even ones that fail
    # the live-instance check), instead of silently skipping and only
    # reporting the final count. Use this when a class "isn't found" and we
    # need to see whether it's zero matches at all, or matches that all
    # fail resolution (and why).
    $ptrs = Get-ObjectTable $h $base
    if (-not $ptrs) { return 0 }
    $checked = 0
    $matchesSeen = 0
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $lastUpdate = 0
    foreach ($objPtr in $ptrs) {
        if ($objPtr -eq 0) { continue }
        $classPtr = Read-U64 $h ($objPtr + $OFF_OBJ_CLASS)
        if (-not (Test-ValidPointer $classPtr)) { continue }
        $className = Get-CachedClassName $h $base $classPtr
        $checked++

        if ($checked - $lastUpdate -ge 5000) {
            $pct = [math]::Round(($checked / $ptrs.Length) * 100)
            Write-Host ("    ... {0}/{1} ({2}%)  [{3:N1}s elapsed]" -f $checked, $ptrs.Length, $pct, $sw.Elapsed.TotalSeconds) -ForegroundColor DarkGray
            $lastUpdate = $checked
        }
        if ($sw.Elapsed.TotalSeconds -gt $timeoutSeconds) {
            Write-Host ("    [!] Timed out after {0}s at {1}/{2} objects." -f $timeoutSeconds, $checked, $ptrs.Length) -ForegroundColor Yellow
            return 0
        }

        if ($className -and $className -eq $classNameContains -and -not $className.StartsWith("__")) {
            $matchesSeen++
            $sm = Read-U64 $h ($objPtr + $OFF_STATICMESH)
            $bi = Read-U64 $h ($sm + $OFF_BODYINSTANCE)
            $smValid = Test-ValidPointer $sm
            $biValid = Test-ValidPointer $bi
            Write-Host ("    [match #{0}] {1} @ 0x{2:X}  |  StaticMesh(0x{3:X})=0x{4:X} valid={5}  |  BodyInstance=0x{6:X} valid={7}" -f $matchesSeen, $className, $objPtr, $OFF_STATICMESH, $sm, $smValid, $bi, $biValid) -ForegroundColor Magenta
            if ($biValid) {
                Write-Host ("    [+] Found LIVE instance: {0} @ 0x{1:X}  ({2:N1}s, checked {3})" -f $className, $objPtr, $sw.Elapsed.TotalSeconds, $checked) -ForegroundColor Green
                return $objPtr
            }
        }
    }
    Write-Host ("    [!] Scanned all {0} objects in {1:N1}s - saw {2} name matches, none had a resolvable BodyInstance." -f $checked, $sw.Elapsed.TotalSeconds, $matchesSeen) -ForegroundColor DarkYellow
    return 0
}

function Find-ByName($h, $base, [string]$classNameContains, [int]$timeoutSeconds = 150) {
    # FIXED: the old CDO filter used $OFF_OBJ_FLAGS / $RF_ClassDefaultObject,
    # which were NEVER DEFINED anywhere in this script (ghost variables).
    # In PowerShell that silently evaluated to "always false", so the filter
    # never actually skipped anything - it always returned the FIRST name
    # match, which is very often the Class Default Object (static, same
    # address every run, empty/zeroed physics values) instead of the live
    # in-match instance.
    #
    # Fix: instead of guessing an unverified ObjectFlags offset, we use a
    # signal we already PROVED empirically - a live instance resolves a
    # valid StaticMesh->BodyInstance chain, a CDO does not ("Could not
    # resolve BodyInstance"). We collect every name match and skip any
    # candidate that fails this resolution.
    $ptrs = Get-ObjectTable $h $base
    if (-not $ptrs) { return 0 }
    $checked = 0
    $skippedUnresolved = 0
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $lastUpdate = 0
    foreach ($objPtr in $ptrs) {
        if ($objPtr -eq 0) { continue }
        $classPtr = Read-U64 $h ($objPtr + $OFF_OBJ_CLASS)
        if (-not (Test-ValidPointer $classPtr)) { continue }
        $className = Get-CachedClassName $h $base $classPtr
        $checked++

        if ($checked - $lastUpdate -ge 5000) {
            $pct = [math]::Round(($checked / $ptrs.Length) * 100)
            Write-Host ("    ... {0}/{1} ({2}%)  [{3:N1}s elapsed]" -f $checked, $ptrs.Length, $pct, $sw.Elapsed.TotalSeconds) -ForegroundColor DarkGray
            $lastUpdate = $checked
        }
        if ($sw.Elapsed.TotalSeconds -gt $timeoutSeconds) {
            Write-Host ("    [!] Timed out after {0}s at {1}/{2} objects - auto-falling back." -f $timeoutSeconds, $checked, $ptrs.Length) -ForegroundColor Yellow
            return 0
        }

        if ($className -and $className -eq $classNameContains -and -not $className.StartsWith("__")) {
            $sm = Read-U64 $h ($objPtr + $OFF_STATICMESH)
            $bi = Read-U64 $h ($sm + $OFF_BODYINSTANCE)
            if (-not (Test-ValidPointer $bi)) {
                $skippedUnresolved++
                continue  # likely a CDO/archetype - no live BodyInstance, keep scanning
            }
            Write-Host ("    [+] Found LIVE instance: {0} @ 0x{1:X}  ({2:N1}s, checked {3}, skipped {4} unresolved)" -f $className, $objPtr, $sw.Elapsed.TotalSeconds, $checked, $skippedUnresolved) -ForegroundColor Green
            return $objPtr
        }
    }
    Write-Host ("    [!] Scanned all {0} objects in {1:N1}s, no live-resolving match ({2} name matches skipped as unresolved)." -f $checked, $sw.Elapsed.TotalSeconds, $skippedUnresolved) -ForegroundColor DarkYellow
    return 0
}

# --- Address cache: avoid re-scanning 200k+ objects every time ---
# A found address stays valid as long as the SAME match (same session)
# is still running. We re-validate it cheaply (StaticMesh->BodyInstance
# resolves) before trusting it; a stale/dead address falls back to a
# full fresh scan automatically.
$Global:AddrCache = @{}

function Get-CachedOrScan($h, $base, [string]$cacheKey, [scriptblock]$scanFunc) {
    if ($Global:AddrCache.ContainsKey($cacheKey)) {
        $cached = $Global:AddrCache[$cacheKey]
        $sm = Read-U64 $h ($cached + $OFF_STATICMESH)
        $bi = Read-U64 $h ($sm + $OFF_BODYINSTANCE)
        if (Test-ValidPointer $bi) {
            Write-Host ("    [+] Using cached address 0x{0:X} (still live, skipped full scan)" -f $cached) -ForegroundColor Cyan
            return $cached
        }
        Write-Host "    [!] Cached address no longer live (new match?) - doing fresh scan." -ForegroundColor Yellow
        $Global:AddrCache.Remove($cacheKey)
    }
    $addr = & $scanFunc
    if ($addr -ne 0) { $Global:AddrCache[$cacheKey] = $addr }
    return $addr
}

function Find-ByNameSimple($h, $base, [string]$classNameContains, [int]$timeoutSeconds = 150) {
    # For classes with NO StaticMesh/BodyInstance chain at all (e.g. WorldInfo,
    # which is an Info actor with no mesh component - verified against the
    # real Engine.ts Offsets: WorldInfo has no StaticMesh field). Applying
    # the "must resolve BodyInstance" live-check here is a category error -
    # it would fail unconditionally regardless of whether the match is live.
    # This is plain first-name-match, same as the original pre-fix behavior.
    $ptrs = Get-ObjectTable $h $base
    if (-not $ptrs) { return 0 }
    $checked = 0
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    foreach ($objPtr in $ptrs) {
        if ($objPtr -eq 0) { continue }
        $classPtr = Read-U64 $h ($objPtr + $OFF_OBJ_CLASS)
        if (-not (Test-ValidPointer $classPtr)) { continue }
        $className = Get-CachedClassName $h $base $classPtr
        $checked++
        if ($sw.Elapsed.TotalSeconds -gt $timeoutSeconds) { return 0 }
        if ($className -and $className -eq $classNameContains -and -not $className.StartsWith("__")) {
            Write-Host ("    [+] Found: {0} @ 0x{1:X}  ({2:N1}s, checked {3})" -f $className, $objPtr, $sw.Elapsed.TotalSeconds, $checked) -ForegroundColor Green
            return $objPtr
        }
    }
    Write-Host ("    [!] Scanned all {0} objects in {1:N1}s, no match." -f $checked, $sw.Elapsed.TotalSeconds) -ForegroundColor DarkYellow
    return 0
}

function Find-ByActorPhysics($h, $base, [string]$classNameContains, [int]$timeoutSeconds = 150) {
    # Live-check via Actor.Physics == PHYS_RigidBody (9), using the verified
    # Actor.Physics offset (0x00c9). Use this for classes whose mesh component
    # never populates BodyInstance (e.g. Car_TA - confirmed empirically).
    $ptrs = Get-ObjectTable $h $base
    if (-not $ptrs) { return 0 }
    $checked = 0
    $matchesSeen = 0
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $lastUpdate = 0
    foreach ($objPtr in $ptrs) {
        if ($objPtr -eq 0) { continue }
        $classPtr = Read-U64 $h ($objPtr + $OFF_OBJ_CLASS)
        if (-not (Test-ValidPointer $classPtr)) { continue }
        $className = Get-CachedClassName $h $base $classPtr
        $checked++
        if ($checked - $lastUpdate -ge 5000) {
            $pct = [math]::Round(($checked / $ptrs.Length) * 100)
            Write-Host ("    ... {0}/{1} ({2}%)  [{3:N1}s elapsed]" -f $checked, $ptrs.Length, $pct, $sw.Elapsed.TotalSeconds) -ForegroundColor DarkGray
            $lastUpdate = $checked
        }
        if ($sw.Elapsed.TotalSeconds -gt $timeoutSeconds) { return 0 }
        if ($className -and $className -eq $classNameContains -and -not $className.StartsWith("__")) {
            $matchesSeen++
            $physByte = Read-Bytes $h ($objPtr + $OFF_ACTOR_PHYSICS) 1
            $phys = if ($null -ne $physByte) { $physByte[0] } else { -1 }
            $lx = Read-F32 $h ($objPtr + $OFF_ACTOR_LOCATION)
            Write-Host ("    [match #{0}] {1} @ 0x{2:X}  |  Physics={3}  |  Location.X={4:N1}" -f $matchesSeen, $className, $objPtr, $phys, $lx) -ForegroundColor Magenta
            if ($phys -eq 9) {
                Write-Host ("    [+] Found LIVE instance (PHYS_RigidBody): {0} @ 0x{1:X}" -f $className, $objPtr) -ForegroundColor Green
                return $objPtr
            }
        }
    }
    Write-Host ("    [!] Scanned all {0} objects in {1:N1}s - saw {2} name matches, none had Physics=PHYS_RigidBody." -f $checked, $sw.Elapsed.TotalSeconds, $matchesSeen) -ForegroundColor DarkYellow
    return 0
}

function Get-ObjectAddress($h, $base) {
    # Fully automatic now - no menu, no manual-address prompt.
    # Always tries the cache first, then name search, then value-signature.
    $addr = Get-CachedOrScan $h $base "Ball_TA" {
        Write-Host "[*] Searching by class name via GNames..." -ForegroundColor Yellow
        $a = Find-ByName $h $base "Ball_TA"
        if ($a -ne 0) { return $a }
        Write-Host "[*] Name search failed - trying value signature (ball radius ~91.25)..." -ForegroundColor Yellow
        return Find-ByValueSignature $h $base
    }
    if ($addr -eq 0) {
        Write-Host "[!] Could not locate the ball automatically." -ForegroundColor Red
    }
    return $addr
}

function Show-Menu {
    Write-Host ""
    Write-Host "=== YAZX Memory Tool v4 ===" -ForegroundColor Cyan
    foreach ($k in ($OPTIONS.Keys | Sort-Object)) {
        Write-Host "$k) $($OPTIONS[$k].Name)"
    }
    Write-Host "0) Exit"
    Write-Host "v) Read live velocity (diagnostic, read-only)"
    Write-Host "a) Show EVERYTHING for the ball in one report"
    Write-Host "m) List physical material objects (find PhysMaterialOverride targets)"
    Write-Host "d) Diagnose name resolution (fast, checks first 30 objects only)"
    Write-Host "s) Test GObjects element stride (8/16/24 bytes) to find the real one"
    Write-Host "n) Deep-diagnose GNames chain for one index, step by step"
    Write-Host "p) Read/write a PhysicalMaterial Friction+Restitution directly (ground/wall/ball surface)"
    Write-Host "x) Reverse-engineer PhysicsConfig_TA structs (SuperSonic/CarInteraction) by known-value matching"
    Write-Host "h) Find HandlingPreset_TA directly via GObjects scan (revisits an earlier 'no access path' conclusion)"
    Write-Host "j) Test JumpLeaveGroundTime read/write on the live PhysicsConfig_TA singleton (resolves the Cache-button mystery)"
}

function Test-JumpLeaveGroundTime($h, $base) {
    Write-Host "[*] Searching for the live PhysicsConfig_TA singleton..." -ForegroundColor Yellow
    $pcfg = Find-ByName $h $base "PhysicsConfig_TA"
    if ($pcfg -eq 0) { Write-Host "[!] Not found - it may not exist as a scannable GObject at all (pure config asset)."; return }
    $addr = $pcfg + $OFF_PCFG_JUMPLEAVE
    $cur = Read-F32 $h $addr
    Write-Host ("[+] Found. Current JumpLeaveGroundTime = {0}" -f $cur) -ForegroundColor Green
    $new = Read-Host "Write a test value (e.g. 1.0 - easy to feel in-game)"
    $ok = Write-F32 $h $addr $new
    $verify = Read-F32 $h $addr
    Write-Host ("Write result: {0}  |  Read-back value: {1}" -f $ok, $verify)
    if ($verify -eq [float]$new) { Write-Host "[+] Memory write succeeded - now go test in-game whether jump timing actually changed." -ForegroundColor Cyan }
}

function Find-HandlingPreset($h, $base) {
    Write-Host "[*] Searching GObjects directly for HandlingPreset_TA (no pointer chain needed)..." -ForegroundColor Yellow
    $hp = Find-ByName $h $base "HandlingPreset_TA"
    if ($hp -eq 0) { Write-Host "[!] Not found via name scan. It may not be spawned as a live GObject in this game state."; return }
    Write-Host ("[+] Found HandlingPreset_TA @ 0x{0:X}" -f $hp) -ForegroundColor Green
    Write-Host ("  FrontAxle.WheelRadius: {0}" -f (Read-F32 $h ($hp + $OFF_HP_FRONTAXLE)))
    Write-Host ("  FrontAxle.WheelWidth:  {0}" -f (Read-F32 $h ($hp + $OFF_HP_FRONTAXLE + 4)))
    Write-Host ("  BackAxle.WheelRadius:  {0}" -f (Read-F32 $h ($hp + $OFF_HP_BACKAXLE)))
    Write-Host ("  BackAxle.WheelWidth:   {0}" -f (Read-F32 $h ($hp + $OFF_HP_BACKAXLE + 4)))
    Write-Host ("  ChassisSpring.Mass:    {0}" -f (Read-F32 $h ($hp + $OFF_HP_CHASSISSPRING + $OFF_CSS_MASS)))
}

function Reverse-PhysicsConfig($h, $base) {
    Write-Host "[*] Looking for a live PhysicsConfig_TA object..." -ForegroundColor Yellow
    $pcfg = Find-ByName $h $base "PhysicsConfig_TA"
    if ($pcfg -eq 0) {
        $addrStr = Read-Host "Auto-search failed. Enter a PhysicsConfig_TA address manually (hex), or blank to cancel"
        if ([string]::IsNullOrWhiteSpace($addrStr)) { return }
        $pcfg = [Convert]::ToInt64($addrStr, 16)
    }
    Write-Host ("[+] Using PhysicsConfig_TA @ 0x{0:X}" -f $pcfg) -ForegroundColor Green

    # SuperSonicSettings: offset 0x01a0, size 0x0c (3 floats) - unknown internal layout
    Write-Host "-- SuperSonicSettings raw floats (looking for ~2200, the known SUPERSONIC_THRESHOLD) --"
    for ($i = 0; $i -lt 3; $i++) {
        $val = Read-F32 $h ($pcfg + 0x01a0 + ($i * 4))
        $match = if ([math]::Abs($val - 2200) -lt 50) { " <-- MATCH! This is likely the threshold field" } else { "" }
        Write-Host ("  [offset +0x{0:X}] = {1}{2}" -f (0x1a0 + $i*4), $val, $match)
    }

    # CarInteractionSettings: offset 0x0098, size 0x108 (huge, 66 floats) - scan for known values
    Write-Host "-- CarInteractionSettings: scanning for known reference values (2300=CarMaxSpeed, 180=CarMass, 5.5=MaxAngVel) --"
    $knownValues = @(2300, 180, 5.5, 33.3, 991.666, 650)
    for ($i = 0; $i -lt (0x108 / 4); $i++) {
        $val = Read-F32 $h ($pcfg + 0x0098 + ($i * 4))
        foreach ($kv in $knownValues) {
            if ([math]::Abs($val - $kv) -lt ([math]::Abs($kv) * 0.02 + 0.5)) {
                Write-Host ("  [offset +0x{0:X}] = {1}  <-- close to known value {2}" -f (0x98 + $i*4), $val, $kv) -ForegroundColor Green
            }
        }
    }
    Write-Host "[+] Scan complete. Any highlighted matches reveal that field's real identity." -ForegroundColor Cyan
}

function Diagnose-GNamesChain($h, $base) {
    $idx = [int](Read-Host "Enter a nameIndex to trace (e.g. 20660)")
    $gnamesAddr = $base + $OFF_GNAMES
    Write-Host ("GNames field address: 0x{0:X}" -f $gnamesAddr)
    $dataPtr = Read-U64 $h $gnamesAddr
    Write-Host ("Step 1 - GNames.Data pointer: 0x{0:X}  valid={1}" -f $dataPtr, (Test-ValidPointer $dataPtr))
    $countCheck = Read-I32 $h ($gnamesAddr + 8)
    Write-Host ("GNames.Count field: {0}" -f $countCheck)

    $entryAddr = $dataPtr + ($idx * 8)
    Write-Host ("Step 2 - entry slot address (Data + idx*8): 0x{0:X}" -f $entryAddr)
    $entryPtr = Read-U64 $h $entryAddr
    Write-Host ("Step 2 - FNameEntry* value read: 0x{0:X}  valid={1}" -f $entryPtr, (Test-ValidPointer $entryPtr))

    if (Test-ValidPointer $entryPtr) {
        # CONFIRMED structure (matches published FNameEntry layout for Rocket League):
        # Flags(int64, 0x00), Index(int32, 0x08), pad(12 bytes, 0x0C), Name(inline wchar_t[], 0x18)
        $indexField = Read-I32 $h ($entryPtr + 0x08)
        Write-Host ("Step 3 - Index field (0x08): {0}  (should match the nameIndex you entered: {1})" -f $indexField, $idx)

        $raw = Read-Bytes $h ($entryPtr + 0x18) 64
        Write-Host "Step 4 - inline text bytes at offset 0x18 (hex):"
        Write-Host (($raw | ForEach-Object { "{0:X2}" -f $_ }) -join " ")
        try {
            $s1 = [System.Text.Encoding]::Unicode.GetString($raw).Split([char]0)[0]
            Write-Host "Resolved name (UTF-16): '$s1'"
        } catch {}
    }
}

function Test-ObjectStride($h, $base) {
    $gobjAddr = $base + $OFF_GOBJECTS
    Write-Host "--- Hypothesis A: GObjects address IS the TArray header directly ---"
    $dataPtrA = Read-U64 $h $gobjAddr
    $countA = Read-I32 $h ($gobjAddr + 8)
    Write-Host ("DataPtr={0:X}  Count={1}" -f $dataPtrA, $countA)

    Write-Host "--- Hypothesis B: GObjects address holds a POINTER to the real TArray header ---"
    $indirectHeader = Read-U64 $h $gobjAddr
    if (Test-ValidPointer $indirectHeader) {
        $dataPtrB = Read-U64 $h $indirectHeader
        $countB = Read-I32 $h ($indirectHeader + 8)
        Write-Host ("Indirect header addr={0:X}  DataPtr={1:X}  Count={2}" -f $indirectHeader, $dataPtrB, $countB)
    } else {
        Write-Host "Indirect header pointer itself invalid."
    }

    $dataPtr = $dataPtrA
    Write-Host "Testing which element size + which offset within it holds the real UObject* ..."
    foreach ($stride in @(8, 16, 24)) {
        foreach ($innerOff in @(0, 4, 8)) {
            if ($innerOff -ge $stride) { continue }
            $classPtrs = @()
            $validCount = 0
            # نفحص عيّنة موزّعة عبر الجدول كامل، لا أول ٢٠ عنصر بس —
            # الكائنات الأولى غالباً دفعة ابتدائية من نفس الفئة (طبيعي)
            $sampleIndices = 0..19 | ForEach-Object { [int](($countA / 20) * $_) }
            foreach ($idx in $sampleIndices) {
                $candidateObjPtr = Read-U64 $h ($dataPtr + ($idx * $stride) + $innerOff)
                if (-not (Test-ValidPointer $candidateObjPtr)) { continue }
                $cp = Read-U64 $h ($candidateObjPtr + $OFF_OBJ_CLASS)
                if (Test-ValidPointer $cp) { $validCount++; $classPtrs += $cp }
            }
            $unique = ($classPtrs | Select-Object -Unique).Count
            if ($classPtrs.Count -gt 0) {
                Write-Host ("stride={0,2} innerOff={1}: {2} valid objs, {3} unique classPtrs" -f $stride, $innerOff, $validCount, $unique) -ForegroundColor $(if ($unique -ge 2 -and $unique -lt $validCount) {"Green"} else {"DarkGray"})
            }
        }
    }
}

function Diagnose-NameResolution($h, $base) {
    $gobjAddr = $base + $OFF_GOBJECTS
    $dataPtr = Read-U64 $h $gobjAddr
    $count = Read-I32 $h ($gobjAddr + 8)
    Write-Host "GObjects Data pointer: 0x$('{0:X}' -f $dataPtr)"
    Write-Host "GObjects Count:        $count"
    Write-Host ""
    Write-Host "Spread sample of 30 object entries (not just the first batch):"
    $sampleIdx = 0..29 | ForEach-Object { [int](($count / 30) * $_) }
    foreach ($i in $sampleIdx) {
        $objPtr = Read-U64 $h ($dataPtr + ($i * 8))
        if ($objPtr -eq 0) { Write-Host "  [$i] null"; continue }
        $classPtr = Read-U64 $h ($objPtr + $OFF_OBJ_CLASS)
        $valid = Test-ValidPointer $classPtr
        $selfNameIdx = Read-I32 $h ($objPtr + $OFF_OBJ_NAME)
        $selfName = Get-NameString $h $base $selfNameIdx
        $className = if ($valid) { Get-CachedClassName $h $base $classPtr } else { "N/A" }
        Write-Host ("  [{0}] obj=0x{1:X} classPtr=0x{2:X} validPtr={3} nameIdx={4} selfName='{5}' className='{6}'" -f $i, $objPtr, $classPtr, $valid, $selfNameIdx, $selfName, $className)
    }
}

function Show-Everything($h, $base) {
    Write-Host ""
    Write-Host "=== FULL REPORT: CAR + BALL + WORLD ===" -ForegroundColor Cyan

    # -- WORLD / GRAVITY (no per-object search needed style - WorldInfo is itself a GObjects entry) --
    Write-Host "[*] Locating WorldInfo..." -ForegroundColor Yellow
    $world = Find-ByNameSimple $h $base "WorldInfo"
    if ($world -ne 0) {
        Write-Host "-- World / Gravity --" -ForegroundColor DarkCyan
        Write-Host ("  DefaultGravityZ:        {0}" -f (Read-F32 $h ($world + $OFF_WI_GRAVITY)))
        Write-Host ("  DefaultSkinWidth:       {0}  <- القيمة الحقيقية من المحرك (WorldInfo)" -f (Read-F32 $h ($world + $OFF_WI_DEFSKINWIDTH)))
        Write-Host ("  RBPhysicsGravityScaling:{0}" -f (Read-F32 $h ($world + $OFF_WI_GRAVSCALE)))
        Write-Host ("  TimeDilation:           {0}" -f (Read-F32 $h ($world + $OFF_WI_TIMEDIL)))
    } else { Write-Host "  [!] WorldInfo not found." -ForegroundColor Red }

    # -- CAR --
    Write-Host "[*] Locating Car..." -ForegroundColor Yellow
    # NOTE: Cars use a custom vehicle physics system (VehicleSim_TA) - their
    # CarMesh component's BodyInstance is consistently null by design (verified
    # empirically: 3/3 live cars had StaticMesh valid, BodyInstance=0x0). So we
    # use Actor.Physics (verified offset) as the live-check instead.
    $car = Find-ByActorPhysics $h $base "Car_TA"
    if ($car -ne 0) {
        Write-Host "-- Car (Pawn-level) --" -ForegroundColor DarkCyan
        Write-Host ("  Weight (Pawn.Mass):     {0}" -f (Read-F32 $h ($car + $OFF_PAWN_MASS)))
        $csm = Read-U64 $h ($car + $OFF_STATICMESH)
        $cbi = Read-U64 $h ($csm + $OFF_BODYINSTANCE)
        if (Test-ValidPointer $cbi) {
            Write-Host ("  Mass Scale:             {0}" -f (Read-F32 $h ($cbi + $OFF_MASSSCALE)))
            Write-Host ("  Gravity Factor:         {0}" -f (Read-F32 $h ($cbi + $OFF_GRAVFACTOR)))
            $vx = Read-F32 $h ($cbi + $OFF_VELOCITY); $vy = Read-F32 $h ($cbi + $OFF_VELOCITY + 4); $vz = Read-F32 $h ($cbi + $OFF_VELOCITY + 8)
            $speed = [math]::Sqrt($vx*$vx + $vy*$vy + $vz*$vz)
            Write-Host ("  Velocity:               X={0:N1} Y={1:N1} Z={2:N1} (speed={3:N1})" -f $vx,$vy,$vz,$speed)
        }

        Write-Host "-- Car (RBActor-level, shared logic with Ball) --" -ForegroundColor DarkCyan
        Write-Host ("  RollingFriction:        {0}" -f (Read-F32 $h ($car + $OFF_RBA_ROLLFRIC)))
        Write-Host ("  PreWeldMass:            {0}" -f (Read-F32 $h ($car + $OFF_RBA_PREWELDMASS)))
        Write-Host ("  MaxAngularSpeed:        {0}" -f (Read-F32 $h ($car + $OFF_RBA_MAXANGSPD)))
        Write-Host ("  MaxLinearSpeed:         {0}" -f (Read-F32 $h ($car + $OFF_RBA_MAXLINSPD)))
        Write-Host ("  GroundTraceDistance:    {0}" -f (Read-F32 $h ($car + $OFF_RBA_GROUNDTRACE)))
        Write-Host ("  GroundOffsetDistance:   {0}" -f (Read-F32 $h ($car + $OFF_RBA_GROUNDOFFSET)))
        Write-Host ("  ReplicatedGravityScale: {0}" -f (Read-F32 $h ($car + $OFF_RBA_GRAVSCALE)))

        $boostComp = Read-U64 $h ($car + $OFF_VEH_BOOSTCOMP)
        if (Test-ValidPointer $boostComp) {
            Write-Host "-- Car Boost Component --" -ForegroundColor DarkCyan
            Write-Host ("  Current Boost:          {0}" -f (Read-F32 $h ($boostComp + $OFF_BOOST_CURRENT)))
            Write-Host ("  Max Boost:              {0}" -f (Read-F32 $h ($boostComp + $OFF_BOOST_MAX)))
        }

        $dodgeComp = Read-U64 $h ($car + $OFF_VEH_DODGECOMP)
        if (Test-ValidPointer $dodgeComp) {
            Write-Host "-- Car Dodge Component --" -ForegroundColor DarkCyan
            Write-Host ("  ForwardDodgeImpulse:    {0}" -f (Read-F32 $h ($dodgeComp + $OFF_DODGE_FWD)))
        }
        $jumpComp = Read-U64 $h ($car + $OFF_VEH_JUMPCOMP)
        if (Test-ValidPointer $jumpComp) {
            Write-Host "-- Car Jump Component --" -ForegroundColor DarkCyan
            Write-Host ("  JumpImpulse:            {0}" -f (Read-F32 $h ($jumpComp + $OFF_JUMP_IMPULSE)))
        }
        $djumpComp = Read-U64 $h ($car + $OFF_VEH_DJUMPCOMP)
        if (Test-ValidPointer $djumpComp) {
            Write-Host "-- Car DoubleJump Component --" -ForegroundColor DarkCyan
            Write-Host ("  DoubleJumpImpulse:      {0}" -f (Read-F32 $h ($djumpComp + $OFF_DJUMP_IMPULSE)))
        }

        $vehSim = Read-U64 $h ($car + $OFF_VEH_VEHICLESIM)
        if (Test-ValidPointer $vehSim) {
            $wheelsDataPtr = Read-U64 $h ($vehSim + $OFF_VS_WHEELS)
            $wheelsCount = Read-I32 $h ($vehSim + $OFF_VS_WHEELS + 8)
            if ((Test-ValidPointer $wheelsDataPtr) -and $wheelsCount -gt 0) {
                Write-Host ("-- All {0} Wheels Contact (live) --" -f $wheelsCount) -ForegroundColor DarkCyan
                $wheelNames = @("Front-Left","Front-Right","Back-Left","Back-Right")
                for ($wi = 0; $wi -lt $wheelsCount -and $wi -lt 4; $wi++) {
                    $wPtr = Read-U64 $h ($wheelsDataPtr + ($wi * 8))
                    if (-not (Test-ValidPointer $wPtr)) { continue }
                    $contactBase = $wPtr + $OFF_WHEEL_CONTACT
                    $hasContactFlags = Read-I32 $h ($contactBase + $OFF_CONTACT_HASCONTACT)
                    $hasContact = ($hasContactFlags -band 0x1) -ne 0
                    $physMat = Read-U64 $h ($contactBase + $OFF_CONTACT_PHYSMAT)
                    $wName = if ($wi -lt $wheelNames.Length) { $wheelNames[$wi] } else { "Wheel[$wi]" }
                    Write-Host ("  [{0}] Touching ground: {1}  |  SurfacePhysMat: 0x{2:X}" -f $wName, $hasContact, $physMat)
                    if ($wi -eq 0) {
                        Write-Host ("      SuspensionStiffness:        {0}" -f (Read-F32 $h ($wPtr + $OFF_WHEEL_SUSPSTIFF)))
                        Write-Host ("      SuspensionDampingCompression: {0}" -f (Read-F32 $h ($wPtr + $OFF_WHEEL_SUSPDCOMP)))
                        Write-Host ("      SuspensionDampingRelaxation: {0}" -f (Read-F32 $h ($wPtr + $OFF_WHEEL_SUSPDRELAX)))
                    }
                }
            }
        }
    } else { Write-Host "  [!] Car not found." -ForegroundColor Red }

    # -- BALL --
    Write-Host "[*] Locating Ball..." -ForegroundColor Yellow
    $obj = Get-CachedOrScan $h $base "Ball_TA" {
        Write-Host "[*] Trying fast value-signature search first (skips name lookups entirely)..." -ForegroundColor Yellow
        $o = Find-ByValueSignature $h $base
        if ($o -ne 0) { return $o }
        return Find-ByName $h $base "Ball_TA"
    }
    if ($obj -ne 0) {
        $sm = Read-U64 $h ($obj + $OFF_STATICMESH)
        $bi = Read-U64 $h ($sm + $OFF_BODYINSTANCE)
        Write-Host "-- Ball --" -ForegroundColor DarkCyan
        if (Test-ValidPointer $bi) {
            Write-Host ("  Mass Scale:             {0}" -f (Read-F32 $h ($bi + $OFF_MASSSCALE)))
            Write-Host ("  Damping Scale:          {0}" -f (Read-F32 $h ($bi + $OFF_DAMPINGSCALE)))
            Write-Host ("  Gravity Factor:         {0}" -f (Read-F32 $h ($bi + $OFF_GRAVFACTOR)))
            Write-Host ("  Contact Threshold:      {0}" -f (Read-F32 $h ($bi + $OFF_CONTACTFORCE)))
            $vx = Read-F32 $h ($bi + $OFF_VELOCITY); $vy = Read-F32 $h ($bi + $OFF_VELOCITY + 4); $vz = Read-F32 $h ($bi + $OFF_VELOCITY + 8)
            $speed = [math]::Sqrt($vx*$vx + $vy*$vy + $vz*$vz)
            Write-Host ("  Velocity:               X={0:N1} Y={1:N1} Z={2:N1} (speed={3:N1})" -f $vx,$vy,$vz,$speed)
        }
        Write-Host ("  CarInteraction.Friction:{0}" -f (Read-F32 $h ($obj + $OFF_CI_FRICTION)))
        Write-Host ("  CarInteraction.Restitution:{0}" -f (Read-F32 $h ($obj + $OFF_CI_RESTITUTION)))
        Write-Host ("  PushZScale:             {0}" -f (Read-F32 $h ($obj + $OFF_CI_PUSHZ)))
        Write-Host ("  PushForwardScale:       {0}" -f (Read-F32 $h ($obj + $OFF_CI_PUSHFWD)))
        Write-Host ("  MaxRelativeSpeed:       {0}" -f (Read-F32 $h ($obj + $OFF_CI_MAXRELSPD)))
    } else { Write-Host "  [!] Ball not found." -ForegroundColor Red }

    Write-Host "=========================================="
}

function Show-LocationAndPhysics($h, $obj) {
    # Independent liveness check - reads directly from the Actor base,
    # no StaticMesh->BodyInstance chain needed. Verified offsets from
    # Engine.ts Offsets package (Actor.Location, Actor.Physics).
    $lx = Read-F32 $h ($obj + $OFF_ACTOR_LOCATION)
    $ly = Read-F32 $h ($obj + $OFF_ACTOR_LOCATION + 4)
    $lz = Read-F32 $h ($obj + $OFF_ACTOR_LOCATION + 8)
    $physByte = Read-Bytes $h ($obj + $OFF_ACTOR_PHYSICS) 1
    $phys = if ($null -ne $physByte) { $physByte[0] } else { -1 }
    $physName = switch ($phys) {
        0 {"PHYS_None"}; 9 {"PHYS_RigidBody"}; 2 {"PHYS_Falling"}; default {"PHYS_$phys (other)"}
    }
    Write-Host ("Location: X={0:N1} Y={1:N1} Z={2:N1}  |  Physics={3}" -f $lx, $ly, $lz, $physName) -ForegroundColor Cyan
    if ($phys -ne 9) {
        Write-Host "  [!] Not in PHYS_RigidBody mode - physics fields (mass/friction/velocity) may be stale." -ForegroundColor Yellow
    }
}

function Show-Velocity($h, $obj) {
    $sm = Read-U64 $h ($obj + $OFF_STATICMESH)
    $bi = Read-U64 $h ($sm + $OFF_BODYINSTANCE)
    if (-not (Test-ValidPointer $bi)) { Write-Host "[!] Could not resolve BodyInstance."; return }
    $vx = Read-F32 $h ($bi + $OFF_VELOCITY)
    $vy = Read-F32 $h ($bi + $OFF_VELOCITY + 4)
    $vz = Read-F32 $h ($bi + $OFF_VELOCITY + 8)
    $speed = [math]::Sqrt($vx*$vx + $vy*$vy + $vz*$vz)
    Write-Host ("Velocity: X={0:N1} Y={1:N1} Z={2:N1}  |  Speed={3:N1} uu/s" -f $vx,$vy,$vz,$speed) -ForegroundColor Cyan
}

$conn = Get-GameHandle
if (-not $conn) { Write-Host "Press any key to exit..."; Read-Host | Out-Null; exit }
$h = $conn.Handle
$base = $conn.Base

while ($true) {
    Show-Menu
    $choice = Read-Host "Choice"
    if ($choice -eq "0") { break }
    if ($choice -eq "v") {
        $obj = Get-ObjectAddress $h $base
        if ($obj -ne 0) { Show-Velocity $h $obj; Show-LocationAndPhysics $h $obj }
        continue
    }
    if ($choice -eq "a") { Show-Everything $h $base; continue }
    if ($choice -eq "d") { Diagnose-NameResolution $h $base; continue }
    if ($choice -eq "s") { Test-ObjectStride $h $base; continue }
    if ($choice -eq "n") { Diagnose-GNamesChain $h $base; continue }
    # Confirmed real ball-surface physics constants (smish.dev reverse-engineered model):
    # mu (friction) = 0.285, C_R (restitution) = 0.6, Y (friction scale) = 2.0, A (spin transfer) = 0.0003
    if ($choice -eq "x") { Reverse-PhysicsConfig $h $base; continue }
    if ($choice -eq "h") { Find-HandlingPreset $h $base; continue }
    if ($choice -eq "j") { Test-JumpLeaveGroundTime $h $base; continue }
    if ($choice -eq "p") {
        $mats = List-ObjectsByClass $h $base "PhysicalMaterial" 30
        if ($mats.Count -eq 0) { Write-Host "[!] No PhysicalMaterial objects found."; continue }
        for ($i=0; $i -lt $mats.Count; $i++) { Write-Host ("  [{0}] 0x{1:X}  name={2}" -f $i, $mats[$i].Addr, $mats[$i].Name) }
        $pick = [int](Read-Host "Pick index")
        $pmAddr = $mats[$pick].Addr
        $fric = Read-F32 $h ($pmAddr + $OFF_PM_FRICTION)
        $rest = Read-F32 $h ($pmAddr + $OFF_PM_RESTITUTION)
        Write-Host ("Current: Friction={0}  Restitution={1}" -f $fric, $rest)
        $newF = Read-Host "New Friction (blank = skip)"
        if (-not [string]::IsNullOrWhiteSpace($newF)) { Write-F32 $h ($pmAddr + $OFF_PM_FRICTION) $newF | Out-Null }
        $newR = Read-Host "New Restitution (blank = skip)"
        if (-not [string]::IsNullOrWhiteSpace($newR)) { Write-F32 $h ($pmAddr + $OFF_PM_RESTITUTION) $newR | Out-Null }
        Write-Host "[+] Done" -ForegroundColor Green
        continue
    }
    if ($choice -eq "m") {
        $mats = List-ObjectsByClass $h $base "PhysicalMaterial" 20
        if ($mats.Count -eq 0) { Write-Host "[!] No matching objects found." }
        else { $mats | ForEach-Object { Write-Host ("  0x{0:X}  class={1}  name={2}" -f $_.Addr, $_.Class, $_.Name) } }
        continue
    }
    if (-not $OPTIONS.ContainsKey($choice)) { Write-Host "[!] Unknown option"; continue }

    $opt = $OPTIONS[$choice]
    Write-Host ""
    Write-Host "-- $($opt.Name) --" -ForegroundColor Cyan
    Write-Host "Default: $($opt.Default)   Range: $($opt.Min) to $($opt.Max)"
    Write-Host $opt.Desc

    $obj = Get-ObjectAddress $h $base
    if ($obj -eq 0) { Write-Host "[!] No valid object address - skipping."; continue }

    if ($choice -eq "10") { Edit-WallFrictionCurve $h $obj; continue }

    switch ($choice) {
        "1" { $sm = Read-U64 $h ($obj + $OFF_STATICMESH); $bi = Read-U64 $h ($sm + $OFF_BODYINSTANCE); $off = $OFF_MASSSCALE; $base2 = $bi }
        "2" { $sm = Read-U64 $h ($obj + $OFF_STATICMESH); $bi = Read-U64 $h ($sm + $OFF_BODYINSTANCE); $off = $OFF_DAMPINGSCALE; $base2 = $bi }
        "3" { $sm = Read-U64 $h ($obj + $OFF_STATICMESH); $bi = Read-U64 $h ($sm + $OFF_BODYINSTANCE); $off = $OFF_GRAVFACTOR; $base2 = $bi }
        "4" { $sm = Read-U64 $h ($obj + $OFF_STATICMESH); $bi = Read-U64 $h ($sm + $OFF_BODYINSTANCE); $off = $OFF_CONTACTFORCE; $base2 = $bi }
        "5" { $off = $OFF_CI_FRICTION; $base2 = $obj }
        "6" { $off = $OFF_CI_RESTITUTION; $base2 = $obj }
        "7" { $off = $OFF_CI_PUSHZ; $base2 = $obj }
        "8" { $off = $OFF_CI_PUSHFWD; $base2 = $obj }
        "9" { $off = $OFF_CI_MAXRELSPD; $base2 = $obj }
    }

    if (-not (Test-ValidPointer $base2)) {
        Write-Host "[!] Pointer chain did not resolve to a valid address (base2=0x$('{0:X}' -f $base2))." -ForegroundColor Red
        Write-Host "    This usually means the found object was NOT actually a real ball/car - try manual mode with a Cheat Engine address instead." -ForegroundColor Red
        continue
    }

    $cur = Read-F32 $h ($base2 + $off)
    $mid = ($opt.Min + $opt.Max) / 2
    Write-Host "Current value: $cur"
    Write-Host ("Suggestions: default={0}  midpoint={1}" -f $opt.Default, $mid) -ForegroundColor DarkCyan
    Write-Host "Type a number, 'd' for default, 'm' for midpoint, or blank to cancel."
    $new = Read-Host "New value"
    if ([string]::IsNullOrWhiteSpace($new)) { continue }
    if ($new -eq "d") { $new = $opt.Default }
    elseif ($new -eq "m") { $new = $mid }
    $ok = Write-F32 $h ($base2 + $off) $new
    if ($ok) { Write-Host "[+] Write succeeded" -ForegroundColor Green }
    else { Write-Host "[!] Write failed" -ForegroundColor Red }
}

[Mem]::CloseHandle($h) | Out-Null
Write-Host "Done."
