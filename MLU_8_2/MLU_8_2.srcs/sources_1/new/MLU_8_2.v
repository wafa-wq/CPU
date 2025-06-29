`timescale 1ns / 1ps

module MUL_8_2(
    input [8:1] X,
    input [8:1] Y,
    output reg [16:1] Result,
    input reset
);

reg [16:1] Result_tmp;
reg [8:1] Y_tmp;
reg [11:1] P_tmp;
reg [11:1] X_yuan;
reg [11:1] X_bu;
reg [11:1] X_twobu;
reg [11:1] X_fubu;
reg C;
integer i;

always @*
begin

    P_tmp = 11'b0;
    Y_tmp = Y;
    X_yuan = {3'b0, X};
    X_bu = X_yuan;
    X_twobu = X_yuan << 1;
    X_fubu = ~X_yuan + 1'b1;
    C = 0;

    for (i = 1; i <= 4; i = i + 1) // 循环迭代4次
    begin
        case ({Y_tmp[2], Y_tmp[1], C})
            3'b000: begin
            end
            3'b001: begin
                P_tmp = P_tmp + X_yuan;
                C = 0;
            end
            3'b010: begin
                P_tmp = P_tmp + X_yuan;
                C = 0;
            end
            3'b011: begin
                P_tmp = P_tmp + X_twobu;
                C = 0;
            end
            3'b100: begin
                P_tmp = P_tmp + X_twobu;
                C = 0;
            end
            3'b101: begin
                P_tmp = P_tmp + X_fubu;
                C = 1;
            end
            3'b110: begin
                P_tmp = P_tmp + X_fubu;
                C = 1;
            end
            3'b111: begin
                P_tmp = P_tmp ;
                C = 1;
            end       
        endcase
        Y_tmp={P_tmp[2:1],Y_tmp[8:3]};
        if(P_tmp[11]==1)
            P_tmp={2'b11,P_tmp[11:3]};
        else
            P_tmp={2'b00,P_tmp[11:3]};
    end
    
    if (C == 1) 
    begin
        P_tmp = P_tmp + X_yuan; // 如果C=1，则再加上X_yuan
    end
end

always@*
begin
    if (reset == 1)
    begin
         Result=16'b0;
    end
    else
    begin
        Result = {P_tmp[8:1], Y_tmp[8:1]};
    end
end

endmodule

