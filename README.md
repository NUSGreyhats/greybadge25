# greybadge25
GreyCTF 2025 Badge (Greymecha Army)

## Repository Structure
```
.
├── firmware
│   ├── circuitpython_frozen_leaky.uf2  # CircuitPython firmware to flash
│   ├── ecp5                            # FPGA-related files                   
│   └── rp2350
│       ├── art                         # Greycat animation files (thanks shuqing!)
│       ├── filesystem                  # Filesystem to copy into CircuitPython (includes challenges)
│       ├── solutions                   # Solution scripts
│       └── src_chall                   # Raw challenge files for reference
├── hardware
│   ├── artwork                         # Artwork used on the PCB (thanks shuqing!)
│   ├── fpga_placement.svg              # High level reference for how the FPGA pins were used
│   ├── greybadge_pcb                   # KICAD files
│   ├── JLCPCB.kicad_dru
│   └── kicad_libraries
└── README.md
```

## Firmware Set Up Guide
1. Plug in PCB, you should see the filesystem `RPI_RP2`.
2. Copy `circuitpython_frozen_leaky_uf2` found in `/firmware` into the `RPI_RP2` filesystem.
3. This should restart the badge and you should see a new filesystem `CIRCUITPYTHON`.
4. Copy the **contents inside** of `/firmware/rp2350/filesystem` into `CIRCUITPYTHON` file system.
5. Your badge is set up!

## Hardware Ordering Guide
Refer to `Prototype 3 Order` under Releases.

Feel free to update the BOM to remove the oscillator for the FPGA as it is expensive and not strictly necessary.

Ordering on JLCPCB:
1. Upload the GERBER into the order page.
2. For the PCB Fab options, we recommend mostly using the defaults, but keep the following options in mind:
  - Finishing: HASL (HASL is fine, though we recommend ENIG for higher quantities as the extra cost scales well and is better for BGA soldering.)
  - To customize the main PCB colour, update the soldermask colour.
  - To have it assembled, tick the option below. You would likely want to choose to assemble both sides, which requires the standard assembly (not economic assembly).
3. Select the BOM/CPL if you chose to have it assembled.

There are several things you will need to order separately (and solder on).
1. Screen: [Taobao Link](https://item.taobao.com/item.htm?id=784228754299), choose the 焊接12P option.
2. Battery: You can either use a LIPO with JST-PH connector or solder 3x AA batteries.
  - LiPo Battery: [Taobao Link](https://item.taobao.com/item.htm?id=695205775685) We chose the 603040-750mAh option. If you want to have the plug rather than soldering the battery, contact the seller to install the 2.0-2P 反向公插 header (2.0mm pitch, 2 pin, reverse-orientation), which is essentially JST-PH, on the battery.
  - AA Battery Holder: [Taobao Link](https://detail.tmall.com/item.htm?id=533054527075).
  - 90 Degree Pinout Headers (or just solder wires)
