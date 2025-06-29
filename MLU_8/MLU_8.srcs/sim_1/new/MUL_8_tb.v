`timescale 1ns / 1ps

module MUL_8_tb();
reg [8:1] X;
reg [8:1] Y;
reg reset;
wire [16:1] Result;
MUL_8 uu1(X,Y,Result,reset);
initial
begin                                   //对于booth乘法（补码形式）
    reset=1;X=28;Y=4;   //Result=0      X     Y     Result
    #10 reset=0;        //Result=112    28    4     112
    #10 X=3;Y=4;        //Result=12     3     4     12 
    #10 X=12;Y=13;      //Result=156    12    13    156               
    #10 X=127;Y=127;    //Result=16129  127   127   16129 
    #10 X=182;Y=197;    //Result=35854  -74   -59   4366
    #10 X=255;Y=255;    //Result=65025  -1    -1    1
    #10 X=182;Y=69;     //Result=12558  -74   69    -5106    
    #10 reset=1;        //Result=0
    #10 $finish;
end
endmodule
