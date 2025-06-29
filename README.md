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
│   ├── fpga_placement.svg              # High level reference for how the FPGA pins are used.
│   ├── greybadge_pcb                   # KICAD and production files can be found here
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
TBD