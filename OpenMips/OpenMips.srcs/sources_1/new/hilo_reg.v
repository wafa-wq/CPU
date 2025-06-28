`timescale 1ns / 1ps
`include "defines.v"

module hilo_reg(
    input wire clk,
    input wire rst,
    
    input wire we,
    input wire[`RegBus] hi_i,lo_i,  //32bits
    
    output reg[`RegBus] hi_o,lo_o  //32bits
    );
    
always@(posedge clk)begin
    if(rst == `RstEnable)begin
        hi_o <= `ZeroWord;
        lo_o <= `ZeroWord;
        end
    else if(we == `WriteEnable)begin
        hi_o <= hi_i;
        lo_o <= lo_i;
        end
    end
    
endmodule
