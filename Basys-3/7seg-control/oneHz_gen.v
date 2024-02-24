`timescale 1ns / 1ps
// this module is to create a 1Hz clock divider
// The 1Hz divide module will control how fast the segment will display
module oneHz_gen(
    input clk_100MHz,
    input reset,
    output clk_1Hz
    );
    
    //reg [22:0] ctr_reg = 0; // 23 bits to cover 5,000,000 or 10Hz clock
    reg [25:0] ctr_reg1 = 0; //26 bits to cover 50,000,000
    reg clk_out_reg = 0;
    
    always @(posedge clk_100MHz or posedge reset)
        if(reset) begin
            ctr_reg1 <= 0;
            clk_out_reg <= 0;
        end
        else
            if(ctr_reg1 == 49999999) begin  // 100MHz / 10Hz / 2 = 5,000,000
                                               // 100MHz / 1 Hz /2 = 49,999,999
                ctr_reg1 <= 0;
                clk_out_reg <= ~clk_out_reg;
            end
            else
                ctr_reg1 <= ctr_reg1 + 1;
    
    assign clk_1Hz = clk_out_reg;
    
endmodule
