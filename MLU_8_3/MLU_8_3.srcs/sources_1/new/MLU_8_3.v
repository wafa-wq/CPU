`timescale 1ns / 1ps

module MLU_8_3(
    input [8:1] X,
    input [8:1] Y,
    input reset,
    output reg [16:1] Result
    );
    reg [9:1] Y_tmp;
    reg [8:1] P;
    integer i;
    
    wire [8:1] X_pos, X_neg;
    assign X_pos = X;        // X_pos = X
    assign X_neg = ~X + 1;   // X_neg = -X
    
    always @*
    begin
        if (reset == 1)
        begin
            Y_tmp = {Y,1'b0};
            P = 0;
            Result = 0;
        end
        else
        begin
            Y_tmp = {Y,1'b0};
            P = 0;
            for (i = 0; i < 8; i = i + 1)
            begin
                case (Y_tmp[2:1])
                    2'b00:
                        {P, Y_tmp} = {P[8], P, Y_tmp[9:2]};
                    2'b01:
                    begin
                        P = P + X_pos;
                        {P, Y_tmp} = {P[8], P, Y_tmp[9:2]};
                    end
                    2'b10:
                    begin
                        P = P + X_neg;
                        {P, Y_tmp} = {P[8], P, Y_tmp[9:2]};
                    end
                    2'b11:
                        {P, Y_tmp} = {P[8], P, Y_tmp[9:2]};
                endcase
            end
            Result = {P, Y_tmp[9:2]};
        end
    end
endmodule
