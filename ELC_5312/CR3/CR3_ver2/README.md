Version 2 updates:
- Added UART to indicate the rates of each of the 4 LEDs
- Hard removed GPO slot 2 to prevent collision in the bus
- Update RTL block design to reflect the removal of slot 2 GPO
- The UART interface is used to help troubleshoot and verify that the 4 LEDs are operating independently
- Decode issue corrected by updating the read and write addresses in the chu_blink4_mmio.sv code.
    - Decode full 5-bit word offset instead of 3 bits [4:2], which caused a lot of collisions.
