`include "D:/OpenMips/OpenMips.srcs/sources_1/new/defines.v"
`timescale 1ns / 1ps

module openmips_min_sopc_tb(
    );
    reg CLOCK_50;
    reg rst;
    
openmips_min_sopc tb(
    .clk(CLOCK_50),.rst(rst)
    );
    
initial begin
    CLOCK_50 = 1'b0;
    forever #10 CLOCK_50 =~CLOCK_50;  //T=20ns,f=50MHz
    end
    
initial begin
    rst = `RstEnable;
    #195 rst = `RstDisable;
    #10000 $stop;
    end
    
endmodule
