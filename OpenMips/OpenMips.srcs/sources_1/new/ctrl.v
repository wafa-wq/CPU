`timescale 1ns / 1ps
`include "defines.v"

module ctrl(
    input wire rst,
    input wire stallreq_from_id,
    input wire stallreq_from_ex,
    
    output reg[5:0] stall  //stall[0]--PC,stall[1]--IF,stall[2]--ID,stall[3]--EX,stall[4]--MEM,stall[5]--WB
    );
    
always@(*) begin
    if(rst == `RstEnable)
        stall <= 6'b000000;
    else if(stallreq_from_ex == `Stop)
        stall <= 6'b001111;  //pulse EX,ID,IF,PC
    else if(stallreq_from_id == `Stop)
        stall <= 6'b000111;  //pulse ID,IF,PC
    else 
        stall <= 6'b000000;
    end
    
endmodule
