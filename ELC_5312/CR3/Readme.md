CR3 Instruction:
Textbook: FPGA Prototyping by SystemVerilog Examples by Pong P. Chu

11.9.4:
A blinking-LED core can turn LEDs on and off at specific rates. The core has a four-bit output signal connected to four discrete LEDs. It has four 16-bit registers that specify the values of the individual blinking intervals in milliseconds. With the blinking-LED core, the processor only needs to write the registers. The basic
  design and verification procedure is as follows:
    • Design the blinking circuit for one LED and duplicate it four times.
    • Determine the register map and derive the wrapping circuit.
    • Derive the HDL code.
    • Derive the device driver.
    • Expand the vanilla MMIO subsystem to include a blinking-LED core in slot 4.
    • Modify the vanilla FPro system to connect the LED signal to the blinking-LED core and synthesize the new system.
• Derive a testing program and verify its operation.
Demonstration link:https://www.youtube.com/shorts/79ofNPuz-AI?si=VT83tii8tfFnE7AO

