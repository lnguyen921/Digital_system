`timescale 1ns / 1ps

// The purpose of this module is to control each digit. It is to decode which segment will turn on and count.
// input: clk_1hz, reset                                 
//outputs: ones, tens, thundreds, thousands
module digits(
    input clk_1Hz,
    input reset,
    output reg [3:0] ones,
    output reg [3:0] tens,
    output reg [3:0] hundreds,
    output reg [3:0] thousands
    );
    
    // ones reg control
    always @(posedge clk_1Hz or posedge reset)
        if(reset)
            ones <= 0;
        else
            if(ones == 9)
                ones <= 0;
            else
                ones <= ones + 1;
         
    // tens reg control       
    always @(posedge clk_1Hz or posedge reset)
        if(reset)
            tens <= 0;
        else
            if(ones == 9)
                if(tens == 9)
                    tens <= 0;
                else
                    tens <= tens + 1;
      
    // hundreds reg control              
    always @(posedge clk_1Hz or posedge reset)
        if(reset)
            hundreds <= 0;
        else
            if(tens == 9 && ones == 9)
                if(hundreds == 9)
                    hundreds <= 0;
                else
                    hundreds <= hundreds + 1;
     
    // thousands reg control                
    always @(posedge clk_1Hz or posedge reset)
        if(reset)
            thousands <= 0;
        else
            if(hundreds == 9 && tens == 9 && ones == 9) //Under this condition thousands register will increment by 1
                if(thousands == 9) //If thousand is = 9, thousands reg will go back to 0
                    thousands <= 0;
                else
                    thousands <= thousands + 1;
  
endmodule
