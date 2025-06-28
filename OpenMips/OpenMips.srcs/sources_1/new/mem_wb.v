`timescale 1ns / 1ps
`include "defines.v"

module mem_wb(
    input wire clk,
    input wire rst,
    
    input wire[`RegAddrBus] mem_wd,
    input wire mem_wreg,
    input wire[`RegBus] mem_wdata,
    
    input wire mem_whilo,
    input wire[`RegBus] mem_hi,mem_lo,
    
    output reg wb_whilo,
    output reg[`RegBus] wb_hi,wb_lo,
    
    output reg[`RegAddrBus] wb_wd,
    output reg wb_wreg,
    output reg[`RegBus] wb_wdata,
    
    //pipeline pluse
    input wire[5:0] stall  //stall[4]--MEM, stall[5]--WB
    );
    
always@(posedge clk) begin
    if(rst == `RstEnable) begin
        wb_wd <= `NOPRegAddr;
        wb_wreg <= `WriteDisable;
        wb_wdata <= `ZeroWord;
        wb_hi <= `ZeroWord;
        wb_lo <= `ZeroWord;
        wb_whilo <= `WriteDisable;
        end
    else if(stall[4] == `Stop && stall[5] == `NoStop) begin  //pulse MEM.In the next cycle,nop instruction-->WB
        wb_wd <= `NOPRegAddr;
        wb_wreg <= `WriteDisable;
        wb_wdata <= `ZeroWord;
        wb_hi <= `ZeroWord;
        wb_lo <= `ZeroWord;
        wb_whilo <= `WriteDisable;
        end
    else if(stall[4] == `NoStop)begin  //normal,updata.if stall[5:4]=11,hold WB signals
        wb_wd <= mem_wd;
        wb_wreg <= mem_wreg;
        wb_wdata <= mem_wdata;
        wb_hi <= mem_hi;
        wb_lo <= mem_lo;
        wb_whilo <= mem_whilo;
        end
    end
    
endmodule
