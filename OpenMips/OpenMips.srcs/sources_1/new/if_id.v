`timescale 1ns / 1ps
`include "defines.v"

module if_id(
    input wire clk,
    input wire rst,
    input wire[`InstAddrBus] if_pc,
    input wire[`InstBus] if_inst,
    output reg[`InstAddrBus] id_pc,
    output reg[`InstBus] id_inst,
    
    //pipelien pluse
    input wire[5:0] stall  //stall[1]--IF, stall[2]--ID
    );
    
always@(posedge clk) begin
    if(rst == `RstEnable) begin
        id_pc <= `ZeroWord;
        id_inst <= `ZeroWord;
        end
    else if(stall[1] == `Stop && stall[2] == `NoStop) begin  //pulse ID.In the next cycle,nop instruction->ID
        id_pc <= `ZeroWord;
        id_inst <= `ZeroWord;
        end
    else if(stall[1] == `NoStop) begin  //normal,update.if stall[2:1]=11,hold id_pc and id_inst
        id_pc <= if_pc;
        id_inst <= if_inst;
        end
    end
    
endmodule
