`timescale 1ns / 1ps
`include "defines.v"

module regfile(
    input wire clk,
    input wire rst,
    input wire we,
    input wire[`RegAddrBus] waddr,
    input wire[`RegBus] wdata,
    input wire re1,re2,
    input wire[`RegAddrBus] raddr1,raddr2,
    output reg[`RegBus] rdata1,rdata2
    );
    
    reg[`RegBus] regs[0:`RegNum-1];    //32 32-bit general registers
    
always@(posedge clk) begin             //Write register(Sequential logic)
    if(rst == `RstDisable)
        if((we == `WriteEnable) && (waddr != `RegNumLog2'h0))  //Write prohibited in $0
            regs[waddr] <= wdata;
    end
    
always@(*) begin                       //Read register1(combinational logic)
    if(rst == `RstEnable)
        rdata1 <= `ZeroWord;
    else if(raddr1 == `RegNumLog2'h0)  //Read $0
        rdata1 <= `ZeroWord;
    else if((raddr1 == waddr) && (we == `WriteEnable) && (re1 == `ReadEnable))  //Read and write the same register
        rdata1 <= wdata;
    else if(re1 == `ReadEnable)
        rdata1 <= regs[raddr1];
    else
        rdata1 <= `ZeroWord;
    end
    
always@(*) begin                       //Read register2(combinational logic)
    if(rst == `RstEnable)
        rdata2 <= `ZeroWord;
    else if(raddr2 == `RegNumLog2'h0)  //Read $0
        rdata2 <= `ZeroWord;
    else if((raddr2 == waddr) && (we == `WriteEnable) && (re2 == `ReadEnable))  //Read and write the same register
        rdata2 <= wdata;
    else if(re2 == `ReadEnable)
        rdata2 <= regs[raddr2];
    else
        rdata2 <= `ZeroWord;
    end
    
endmodule
