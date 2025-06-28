`timescale 1ns / 1ps
`include "defines.v"

module pc_reg(
    input wire clk,
    input wire rst,
    output reg[`InstAddrBus] pc,
    output reg ce,
    
    //pipeline pluse
    input wire[5:0] stall,  //stall[0]--PC
    
    //branch
    input wire branch_flag_i,
    input wire[`RegBus] branch_target_address_i
    );
    
always@(posedge clk) begin
    if(rst == `RstEnable)
        ce <= `ChipDisable;
    else
        ce <= `ChipEnable;
    end
    
always@(posedge clk) begin
    if(ce == `ChipDisable)
        pc <= `ZeroWord;
    else if(stall[0] == `NoStop)  //if stall[0]=`Stop,pc hold
        if(branch_flag_i == `Branch)
            pc <= branch_target_address_i;
        else
            pc <= pc + 4'h4;
    end
    
endmodule
