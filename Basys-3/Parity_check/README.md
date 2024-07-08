Lab referenced from: https://www.instructables.com/Sequence-Detector-Using-Digilent-Basys-3-FPGA-Boar/

Purpose: To apply the concept of parity checking by building a finite state machine as a sequence detector.

Instroduction: The Basys 3 FPGA board with use the 7 segments display for this experiment. When the binary 10010 is detected, LED0 will be on. When there an odd is detected, LED1 will be on.

Required Hardwares: Basys 3 by Xilinx

Terms:
  1. Mealy FSM - finite state machine where the output depends on present state and current input symbol.
               - Fewer states as outputs are tied to transitions.
               - Faster response to input changes due to output updates.
               - more complexes due to state-input cases.
  2. Moore FSM - state machine where the output depends only on the present state.
  3. Pseudo Random Binary Sequence (PRBS) - this method is to generate random pattern.  

Instructions:
  1. Create finite state machine with total of 5 states.
  2. Create a transition table
  3. Create a block diagram with top module and its sub-modules.
  4. Create clock divider to create 2 clocks to drive PRBS, FSM, Enable, and Display.
       - Use Global buffer clock, Xilinx primitive for Low Skew Clock as this clock has high fanout. (output drives a lot of inputs).
       - Reference from https://www.instructables.com/id/How-to-use-Verilog-and-Basys-3-to-do-stop-watch/
  6. Model FSM by Verilog
  7. Create Enable Digit Logic
  8. Create Display Logic
  9. Create PRBS(Pseudo Random Binary Sequence) and check parity
  10. Create your own constraint file using Basys 3 pin out schemetics https://digilent.com/reference/_media/basys3/basys3_sch.pdf
        - Use timing constraint documents
        - Use IO constraiunt documents
  11. Syntheis, implement and generate bitstream
  12. Program bitstream file to Basys 3
        - Refer to basic 3 bit counter example with verilog on Basys 3. https://www.instructables.com/How-to-use-Verilog-and-Basys-3-to-do-3-bit-binary-/



Other references:
  1. https://www.geeksforgeeks.org/mealy-and-moore-machines-in-toc/
