`timescale 1ns / 1ps
`include "defines.v"

module div(
    input wire rst,
    input wire clk,
    input wire start_i,
    input wire [`RegBus] opdata1_i,
    input wire [`RegBus] opdata2_i,
    input wire signed_div_i,
    input wire annul_i,
    output reg [`DoubleRegBus] result_o,
    output reg ready_o
    );

    // 状态机定义
    reg [1:0] state;
    
    // 内部信号
    wire [32:0] div_temp;
    reg [64:0] dividend;   // 被除数
    reg [`RegBus] divisor;    // 除数
    reg [`RegBus] temp_op1;
    reg [`RegBus] temp_op2;
    reg [5:0] count;          // 迭代计数器（32次）
    
    assign div_temp = {1'b0,dividend[63:32]} - {1'b0,divisor};

    // 状态转移逻辑
    always @(posedge clk) begin
        if (rst == `RstEnable) begin
            state <= `DivFree;
            ready_o <= `DivResultNotReady;
            result_o <= `DivResultNotReady;
        end else begin
            case (state)
                `DivFree: begin
                    if (start_i && !annul_i)begin
                        if(opdata2_i == `ZeroWord)
                            state <= `DivByZero;
                        else begin
                            state <= `DivOn;
                            count <= 6'b000000;
                            temp_op1 <= (signed_div_i && opdata1_i[31])? (~opdata1_i + 1) :opdata1_i;
                            temp_op2 <= (signed_div_i && opdata2_i[31])? (~opdata2_i + 1) :opdata2_i;
                            dividend <= {`ZeroWord,`ZeroWord};
                            dividend[32:1] <= temp_op1;
                            divisor <= temp_op2;
                            end
                        end
                    else begin
                        ready_o <= `DivResultNotReady;
                        result_o <= {`ZeroWord,`ZeroWord};
                        end
                    end
                
                `DivOn: begin
                    if (!annul_i) begin
                        if (count != 6'd32) begin
                            dividend <= (div_temp[32] == 1'b1)? {dividend[63:0],1'b0} 
                                                              : {div_temp[31:0],dividend[31:0],1'b1};
                            count <= count + 1;
                            end
                        else begin
                            if((signed_div_i == 1'b1) && ((opdata1_i[31] ^ opdata2_i[31]) == 1'b1))
                                dividend[31:0] <= (~dividend[31:0] + 1);
                            if((signed_div_i == 1'b1) && ((opdata1_i[31] ^ dividend[64]) == 1'b1))
                                dividend[63:33] <= (~dividend[63:33] + 1);
                            state <= `DivEnd;
                            count<=6'b000000;
                            end
                        end
                        else
                            state <= `DivFree;
                    end
                
                `DivEnd: begin
                    result_o <= {dividend[64:33],dividend[31:0]};
                    ready_o <= `DivResultReady;
                    if(start_i == `DivStop) begin
                        state <= `DivFree;
                        ready_o <= `DivResultNotReady;
                        result_o <= {`ZeroWord,`ZeroWord};
                        end
                    end
                
                `DivByZero: begin
                    dividend <= {`ZeroWord,`ZeroWord};
                    state <= `DivEnd;
                    end
                
                default: 
                    state <= `DivFree;
            endcase
        end
    end

endmodule