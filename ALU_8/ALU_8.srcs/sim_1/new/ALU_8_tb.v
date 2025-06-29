`timescale 1ns / 1ps

module ALU_8_tb;
reg [7:0] A;
reg [7:0] B;
//reg Cin;
reg [2:0] ALUop;
wire [7:0] Result;
wire Cout;
wire OF,SF,ZF,CF;
ALU_8 uut(A,B,ALUop,Result,Cout,OF,SF,ZF,CF);
initial
begin
    #10 A=95;B=38;ALUop=3'b000;//Result=133(SIGNED:95+38=-123),Cout=0,OSZC=1100
    #10 A=95;B=38;ALUop=3'b001;//Result=57(SIGNED:95-38=57),Cout=1,OSZC=0000
    #10 A=255;B=1;ALUop=3'b000;//Result=0(SIGNED:-1+1=0),Cout=1,OSZC=0011
    #10 A=169;B=154;ALUop=3'b000;//Result=67(SIGNED:-187+-102=67),Cout=1,OSZC=1001
    #10 A=169;B=154;ALUop=3'b001;//Result=15(SIGNED:-187--102=15),Cout=1,OSZC=0000
    #10 A=8'b10110101;B=8'b10001100;ALUop=3'b100;//Result=10000100,Cout=0,OSZC=0000
    #10 A=8'b10110101;B=8'b10001100;ALUop=3'b100;//Result=10000100,Cout=0,OSZC=0000
    #10 A=8'b10110101;B=8'b10001100;ALUop=3'b101;//Result=10111101,Cout=0,OSZC=0000
    #10 A=8'b10110101;B=8'b10001100;ALUop=3'b110;//Result=01001010,Cout=0,OSZC=0000
    #10 A=8'b10110101;B=8'b10001100;ALUop=3'b111;//Result=00111001,Cout=0,OSZCF=0000
    #10 $finish;
end
endmodule
