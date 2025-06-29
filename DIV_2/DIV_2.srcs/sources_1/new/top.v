`timescale 1ns / 1ps
module top(
    input wire clk,
    input wire[16:1] IN,
    input wire X_button,Y_button,
    input wire rst,
    
    output [8:1]Q,R,
    output [7:0]an,
    output [6:0]sseg
    );
    
    wire OF_tmp;
    wire Er_tmp;
    
    divider_2 uu1(
        .IN(IN),
        .X_button(X_button),
        .Y_button(Y_button),
        .rst(rst),
        
        .Q(Q),
        .R(R),
        .OF(OF_tmp),
        .Error(Er_tmp)
    );
    display uu2(
        .clk(clk),
        .OF(OF_tmp),
        .Er(Er_tmp),
        .rst(rst),
        
        .an(an),
        .sseg(sseg)
    );
endmodule
