`timescale 1ns / 1ps
`include "defines.v"

module inst_rom(
    input wire ce,
    input wire[`InstAddrBus] addr,
    output reg[`InstBus] inst
    );
    
reg[`InstBus] inst_mem[0:`InstMemNum-1];  //1k*32=4KB
//0-1023(32bits).Addressing by word,not by byte!

initial
$readmemh("D:/OpenMips/OpenMips.srcs/sources_1/new/inst_rom.txt",inst_mem);  //Load Storage

always@(*) begin
    if(ce == `ChipDisable)
        inst <= `ZeroWord;
    else
        inst <= inst_mem[addr[`InstMemNumLog2+1:2]];  //addr[11:2].addr/4=inst_mem address
    end
    
endmodule
