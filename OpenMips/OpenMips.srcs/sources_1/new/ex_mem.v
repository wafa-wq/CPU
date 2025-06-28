`timescale 1ns / 1ps
`include "defines.v"

module ex_mem(
    input wire clk,
    input wire rst,
    
    input wire[`RegAddrBus] ex_wd,
    input wire ex_wreg,
    input wire[`RegBus] ex_wdata,
    
    input wire ex_whilo,
    input wire[`RegBus] ex_hi,ex_lo,
    
    output reg mem_whilo,
    output reg[`RegBus] mem_hi,mem_lo,
    
    output reg[`RegAddrBus] mem_wd,
    output reg mem_wreg,
    output reg[`RegBus] mem_wdata,
    
    //pipeline pluse
    input wire[5:0] stall,  //stall[3]--EX, stall[4]--MEM*/
    
    //madd
    input wire[`DoubleRegBus] hilo_i,  //store mult temp result about madd
    input wire[1:0]cnt_i,  //store the number of ex-clock
    output reg[`DoubleRegBus] hilo_o,
    output reg[1:0]cnt_o,
    
    //load_store
    input wire[`AluOpBus] ex_aluop,
    input wire[`RegBus] ex_mem_addr,
    input wire[`RegBus] ex_reg2,
    output reg[`AluOpBus] mem_aluop,
    output reg[`RegBus] mem_mem_addr,
    output reg[`RegBus] mem_reg2
    );
    
always@(posedge clk) begin
    if(rst == `RstEnable) begin
        mem_wd <= `NOPRegAddr;
        mem_wreg <= `WriteDisable;
        mem_wdata <= `ZeroWord;
        mem_hi <= `ZeroWord;
        mem_lo <= `ZeroWord;
        mem_whilo <= `WriteDisable;
        hilo_o <= {`ZeroWord,`ZeroWord};
        cnt_o <= 2'b00;
        
        mem_aluop <= `EXE_NOP_OP;
        mem_mem_addr <= `ZeroWord;
        mem_reg2 <= `ZeroWord;
        end
    else if(stall[3] == `Stop && stall[4] == `NoStop)begin  //pulse EX.In the next cycle,nop instruction-->MEM
        mem_wd <= `NOPRegAddr;
        mem_wreg <= `WriteDisable;
        mem_wdata <= `ZeroWord;
        mem_hi <= `ZeroWord;
        mem_lo <= `ZeroWord;
        mem_whilo <= `WriteDisable;
        hilo_o <= hilo_i;
        cnt_o <= cnt_i;
        
        mem_aluop <= `EXE_NOP_OP;
        mem_mem_addr <= `ZeroWord;
        mem_reg2 <= `ZeroWord;
        end
    else if(stall[3] == `NoStop)begin  //normal,updata.if stall[4:3]=11,hold MEM signals
        mem_wd <= ex_wd;
        mem_wreg <= ex_wreg;
        mem_wdata <= ex_wdata;
        mem_hi <= ex_hi;
        mem_lo <= ex_lo;
        mem_whilo <= ex_whilo;
        hilo_o <= {`ZeroWord,`ZeroWord};
        cnt_o <= 2'b00;
        
        mem_aluop <= ex_aluop;
        mem_mem_addr <= ex_mem_addr;
        mem_reg2 <= ex_reg2;
        end
    else begin  //stall[4:3]=11,hold other MEM signals
        hilo_o <= hilo_i;
        cnt_o <= cnt_i;
        end
    end
    
endmodule
