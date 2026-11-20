# YAZX IRQControl — Interrupt Affinity Reference
# STATUS: Reference guide only. No affinity assignments are final.
# All assignments below are THEORETICAL and must be verified against
# the actual post-format interrupt topology before applying.

## CPU Core Map (i5-13400F — to be verified with IRQControl)
- Cores 0-5: P-cores (Performance) — Threads 0-11 (HyperThreaded)
- Cores 6-9: E-cores (Efficiency) — Threads 12-15 (single-threaded)
- This map is based on Intel specs. IRQControl will show the actual
  APIC IDs and processor numbers after format.

## PART 1: Theory — General Principles

These are general interrupt affinity principles. They are NOT ready-to-apply
settings. The actual optimal configuration depends on:
- The real interrupt distribution reported by IRQControl post-format
- Which devices share interrupt lines
- Driver versions and their interrupt behavior
- Workload characteristics

### Principle 1: Separate high-frequency interrupt sources
Devices that generate many interrupts per second (GPU, NIC, USB HID)
should ideally not share the same core, to avoid contention.

### Principle 2: Consider the scheduler
On hybrid CPUs, Windows assigns threads to cores based on QoS and
the heterogeneous thread policy. Forcing interrupt affinity to specific
cores can conflict with the scheduler's decisions if not done carefully.

### Principle 3: MSI Mode is prerequisite
Message Signaled Interrupts must be enabled before setting affinity.
Without MSI, devices share legacy IRQ lines and affinity cannot be
set per-device. Module 10 (MSIMode) handles this.

### Principle 4: Measure before and after
Any affinity change should be benchmarked with LatencyMon (DPC/ISR
latency) and CapFrameX (frame time consistency). If metrics don't
improve, revert.

## PART 2: Post-Format Procedure

### Step 1: Gather actual data
After format and driver installation, run IRQControl and record:
1. Which devices have MSI enabled (green checkmark)
2. Current interrupt-to-processor mapping
3. Interrupt frequency per device (use LatencyMon "Drivers" tab)
4. APIC topology (verify P-core and E-core thread numbering)

### Step 2: Identify candidates
Devices worth adjusting affinity for:
- GPU (highest interrupt rate during gaming)
- Network adapter (latency-sensitive for online games)
- USB XHCI controller (input device polling)
- Audio controller (needs consistent timing)
- NVMe/SATA controllers (storage I/O)

### Step 3: Plan assignments based on actual data
Using the gathered data, plan assignments following these guidelines:
- Do NOT put two high-frequency interrupt sources on the same core
- Leave at least 2 P-cores with no forced interrupt affinity for game threads
- E-cores are suitable for lower-priority devices (SATA, system timers)
- Document every assignment with the actual device instance path and
  current vs. new processor number

### Step 4: Apply and verify
- Apply one device at a time in IRQControl
- Run LatencyMon after each change
- If DPC latency increases, revert that specific change
- Document final working configuration

## PART 3: Example Layout (THEORETICAL — NOT TESTED)

This is an EXAMPLE of how assignments MIGHT look. It is not a
recommendation. Actual device instance paths, interrupt frequencies,
and core availability will differ after format.

| Device | Example Core | Rationale |
|--------|-------------|-----------|
| GPU | A free P-core | Highest interrupt frequency |
| NIC | Different P-core | Avoids contention with GPU |
| USB XHCI | Different P-core | Input latency sensitive |
| Audio | P-core or E-core | Consistent but not ultra-low latency |
| NVMe | P-core | Game asset loading |
| SATA | E-core | Secondary storage, lower priority |
| System timers | E-core | Background/system |

## Notes
- IRQControl (from Bitsum) persists settings across reboots
- If you have Process Lasso Pro, IRQControl is included
- Always create a system restore point before making changes
- The tweaker's existing MSI Mode settings will carry over via Module 10
