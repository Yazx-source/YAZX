# YAZX Realtek RTL8125BG 2.5GbE — Configuration Comparison
# Two files exist: Realtek_Current.reg and Realtek_Balanced_Alt.reg
# This document clarifies every difference.

## Registry Path
Both files target: HKLM\SYSTEM\CCS\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0001
NOTE: The instance number (0001) may change after format. Verify in Device Manager.

## Property-by-Property Comparison

### Properties that DIFFER between Current and Balanced Alt

| Property | Current Value | Balanced Alt Value | Description |
|----------|--------------|-------------------|-------------|
| *IPChecksumOffloadIPv4 | 0 (Disabled) | 1 (Tx Only) | IPv4 IP checksum calculation |
| *TCPChecksumOffloadIPv4 | 0 (Disabled) | 1 (Tx Only) | IPv4 TCP checksum calculation |
| *UDPChecksumOffloadIPv4 | 0 (Disabled) | 1 (Tx Only) | IPv4 UDP checksum calculation |

Value meanings for checksum offload:
- 0 = Disabled (CPU calculates both Tx and Rx checksums)
- 1 = Tx Only (NIC calculates outgoing, CPU calculates incoming)
- 2 = Rx Only (NIC calculates incoming, CPU calculates outgoing)
- 3 = Rx & Tx (NIC calculates both directions)

### IPv4 vs IPv6 Offload Status (BOTH configs)

| Protocol | IPv4 Current | IPv4 Balanced | IPv6 Current | IPv6 Balanced |
|----------|-------------|--------------|-------------|--------------|
| TCP Checksum | 0 (Off) | 1 (Tx Only) | 3 (Rx & Tx) | 3 (Rx & Tx) |
| UDP Checksum | 0 (Off) | 1 (Tx Only) | 3 (Rx & Tx) | 3 (Rx & Tx) |
| IP Checksum | 0 (Off) | 1 (Tx Only) | N/A | N/A |

INCONSISTENCY: IPv6 checksum offloads are Rx & Tx (3) in BOTH configs,
while IPv4 is fully disabled in Current. This means:
- IPv6 traffic: NIC handles checksums (lower CPU, same latency)
- IPv4 traffic (Current): CPU handles checksums (higher CPU, theoretically lower latency)
- IPv4 traffic (Balanced): NIC handles Tx only (NIC does outgoing, CPU does incoming)

Whether this inconsistency is intentional (tweaker chose to disable IPv4
offloads only) or accidental is unknown. Most gaming traffic is IPv4.

### Properties IDENTICAL in both configs

| Property | Value | Description |
|----------|-------|-------------|
| *SpeedDuplex | 2500 | Force 2.5 Gbps Full Duplex |
| *FlowControl | 0 | Disabled (no pause frames) |
| *InterruptModeration | 0 | Disabled (immediate interrupts) |
| *LsoV2IPv4 | 0 | Large Send Offload v2 IPv4 disabled |
| *LsoV2IPv6 | 0 | Large Send Offload v2 IPv6 disabled |
| *RSS | 1 | Receive Side Scaling enabled |
| *NumRssQueues | 4 | 4 RSS queues |
| *ReceiveBuffers | 2048 | Doubled from default (1024) |
| *TransmitBuffers | 1024 | Doubled from default (512) |
| *EEE | 0 | Energy Efficient Ethernet disabled |
| AdvancedEEE | 0 | Advanced EEE disabled |
| EnableGreenEthernet | 0 | Green Ethernet disabled |
| GigaLite | 0 | GigaLite disabled |
| PowerSavingMode | 0 | Power saving disabled |
| PowerDownPll | 0 | PLL power down disabled |
| *WakeOnMagicPacket | 0 | WoL disabled |
| *WakeOnPattern | 0 | Wake on pattern disabled |
| S5WakeOnLan | 0 | S5 WoL disabled |
| *PMARPOffload | 0 | ARP offload disabled |
| *PMNSOffload | 0 | NS offload disabled |
| *JumboPacket | 1514 | Standard MTU (no jumbo frames) |
| *PriorityVlanTag | 0 | VLAN tagging disabled |

## Recommendation
- Keep Realtek_Current.reg as the ACTIVE config (preserves tweaker's choices)
- Keep Realtek_Balanced_Alt.reg as an ALTERNATIVE to test post-format
- Do NOT merge them — they represent two different tradeoff choices
- After format, install Current first, benchmark, then try Balanced to compare
- The IPv6 inconsistency should be investigated post-format with actual traffic
