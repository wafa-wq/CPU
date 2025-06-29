`timescale 1ns / 1ps

module adder_8(
    input [7:0]A,
    input [7:0]B,
    input Cin,
    output reg[7:0]Sum,
    output reg Cout,OF,SF,ZF,CF
    );
    
reg [7:0]sum;
reg [8:0]cout;
integer i;
always@*
    begin
    cout[0] = Cin;  //初始进位为输入的进位
    for(i = 0;i < 8;i = i + 1)
        begin
            cout[i+1] = A[i] & B[i] | A[i] & cout[i] | B[i] & cout[i];  //计算下一位的进位
            sum = A[i] ^ B[i] ^ cout[i];  //计算当前位的和
        end
    Sum = sum;  //计算Sum
    Cout = cout[8];  //计算Cout 
    OF = cout[8] ^ cout[7];  //计算OF
    SF = sum[7];  //计算SF
    ZF = ~|sum;  //计算ZF
    CF = cout[0] ^ cout[8];  //计算CF
    end
endmodule
