`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/25 21:22:19
// Design Name: 
// Module Name: ALU_8
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ALU_8(
    input [7:0]A,  //输入A
    input [7:0]B,  //输入B
    input [2:0]ALUop,  //ALU操作码
    output reg [7:0]Result,  //输出结果
    output reg Cout,  //输出进位
    output reg OF,SF,ZF,CF  //输出溢出、符号、零标志、进位
    );
    
wire [7:0]result;  //临时存储结果
reg [7:0] b;  //临时存储B
wire cout,of,sf,zf,cf;

adder_8 adder(
    A,b,ALUop[0],result,cout,of,sf,zf,cf
    );  //例化标志加法器
    
always@*
    begin
    if(ALUop[0] == 1)
        b = ~B;  //如果ALUop[0]为1，取B的补码
    else
        b = B;
    case(ALUop[2])
        1'b0:
        begin
            Result = result;
            Cout = cout;
            OF = of;
            SF = sf;
            ZF = zf;
            CF = cf;
        end
        1'b1:
        begin
            Cout = 1'b0;  //减法不产生进位
            OF = 1'b0;SF = 1'b0;ZF = 1'b0;CF = 1'b0;  //清除标志
            case(ALUop[1:0])
                2'b00:Result = A & B;  //与
                2'b01:Result = A | B;  //或
                2'b10:Result = ~A;  //非
                2'b11:Result = A ^ B;  //异或
            endcase
        end
    endcase
    end
endmodule
