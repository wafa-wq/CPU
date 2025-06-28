`timescale 1ns / 1ps
`include "defines.v"

module id_ex(
    input wire clk,
    input wire rst,
    
    input wire[`AluOpBus] id_aluop,
    input wire[`AluSelBus] id_alusel,
    input wire[`RegBus] id_reg1,id_reg2,
    input wire[`RegAddrBus] id_wd,  //write address
    input wire id_wreg,             //write flag
    
    output reg[`AluOpBus] ex_aluop,
    output reg[`AluSelBus] ex_alusel,
    output reg[`RegBus] ex_reg1,ex_reg2,
    output reg[`RegAddrBus] ex_wd,
    output reg ex_wreg,
    
    //pipeline pluse
    input wire[5:0] stall,  //stall[2]--ID,stall[3]--EX
    
    //branch
    input wire id_is_in_delayslot,
    input wire[`RegBus] id_link_address,
    input wire next_inst_in_delayslot_i,
    output reg ex_is_in_delayslot,
    output reg[`RegBus] ex_link_address,
    output reg is_in_delayslot_o,
    
    //load_store
    input wire[`RegBus] id_inst,
    output reg[`RegBus] ex_inst
    );
    
always@(posedge clk) begin
    if(rst == `RstEnable) begin
        ex_aluop <= `EXE_NOP_OP;    //8'b00000000
        ex_alusel <= `EXE_RES_NOP;  //3'B000
        ex_reg1 <= `ZeroWord;
        ex_reg2 <= `ZeroWord;
        ex_wd <= `NOPRegAddr;       //5'b00000
        ex_wreg <= `WriteDisable;
        ex_is_in_delayslot <= `NotInDelaySlot;
        ex_link_address <= `ZeroWord;
        is_in_delayslot_o <= `NotInDelaySlot;
        ex_inst <= `ZeroWord;
        end
    else if(stall[2] == `Stop && stall[3] == `NoStop)begin  //pulse ID.In the next cycle,nop instruction-->EX
        ex_aluop <= `EXE_NOP_OP;
        ex_alusel <= `EXE_RES_NOP;
        ex_reg1 <= `ZeroWord;
        ex_reg2 <= `ZeroWord;
        ex_wd <= `NOPRegAddr;
        ex_wreg <= `WriteDisable;
        ex_is_in_delayslot <= `NotInDelaySlot;
        ex_link_address <= `ZeroWord;
        ex_inst <= `ZeroWord;
        end
    else if(stall[2] == `NoStop)begin  //normal,updata.if stall[3:2]=11,hold EX signals
        ex_aluop <= id_aluop;
        ex_alusel <= id_alusel;
        ex_reg1 <= id_reg1;
        ex_reg2 <= id_reg2;
        ex_wd <= id_wd;
        ex_wreg <= id_wreg;
        ex_is_in_delayslot <= id_is_in_delayslot;
        ex_link_address <= id_link_address;
        is_in_delayslot_o <= next_inst_in_delayslot_i;
        ex_inst <= id_inst;
        end
    end
    
endmodule
