Purpose:
  - Understand how to use combination between PL and PS to control the LED.
  - Understand how to use verilog to do hardware synthesis using Xillin VIVADO.

  Prompt:
  - When BTN0 is pressed, LD0 turns on.
  - When BTN1 is pressed, LD1 turns on.
  - When BTN2 is pressed, LD2 turns on.
  - When BTN3 is pressed, LD3 turns on.

Terms:
  - Pipeline
        - CPU can only execute one instruction at time. A fast CPU with large memory can efficiently execute multiple instructions concurrently or simultaneously. This method is called pipelining.

    
  - Multi-threading
        - Similar concept to pipeline where a system can handle mutiple requests

    
  - Hardware Synthesis
        - When coding FPGA, the code will define interconnection of these small building blocks inside the FPGA.
        - This allows support of parallelism in the architecture.
        - This can even synthesis CPUs, micro-controllers inside the FPGA itself.
    
  - Programmable Logic
        - FPGA consists of large number of small blocks. These blocks interconnect with each other to perform complex operations in parallel. The code is converted into a bitstream file wwhich defines the interconnection of the building blocks.
        - Can synthesis different digital logic blocks such as latches, flip-flops, multiplexers, registers. AND/OR/NAND gates.
    
  - Accelerators/Overlays
        - This happens in FPGA logic (PL). A code is written which then get synthesized into hardware. This process ir called accelerators or overlays.
       
  - Arithmetic Logic Unit(ALU)
        - This happens in the Processing System (PS). To do an ALU, you need to save some variable in the memory or register. All the instructions are executed line by line in a sequential fashion.
    
  - Multiplexer/data selector
        - Can select one data to output. This is when there are multiple inputs. It is useful for data bus.

    
  - Processing System
        - This system consist of algorithm written in C++/C/Python.
        - The down side for PS is that insutrctions can only be execute one at a time. This may bottle neck the power of parallelism of PL.



Instructions for Lab 2:
  1. Install Vivado the Board Files.
  2. Download board configuration files like Pynq Z2 hboard files and XDC constraints file
         - Directory for board files: <Xilinx installation directory>\Vivado\<version>\data\boards\board_files
  3. Create and configure project on VIVADO.
  4. Create required module to blink LEDS.
  5. Modify LED controllers.
  6. Create Block Design.
  7. Synthesis Time.
  8. Connect module inputs/outputs with FPGA pins.
  9. Generate Bitstream and program the FPGA.
  10. Program device and test visually.

Challenge:

    - I want you do is change the color of the RGB pin after every clock tick. Now 125MHz is very fast. So first you need to implement a Clock Divider Module to slow down the clock that you can visualize with you eye. Try somewhere near 1–10Hz.

   Then I want you to write a module similar to what we wrote, that will take the slow clock from the Clock Divider and the button SW0 as input.

    - If SW0 is ON (Upper position), Change the color of RGB after every clock tick.
    - If SW1 is ON (Upper Position), Set the RGB to default value (reset value)
HINT: Use RTL diagram block.

  
