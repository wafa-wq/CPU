`timescale 1ns / 1ps

module display (
    input clk, rst,
    input OF, Er,
    output reg [7:0] an, 
    output reg [7:0] sseg
);
    // 分频计数器 - 约1kHz刷新率 (假设主时钟为100MHz)
    reg [16:0] refresh_counter;
    wire refresh_tick = (refresh_counter == 0);
    
    // 8位数码管状态机
    reg [2:0] digit_state;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            refresh_counter <= 0;
            digit_state <= 0;
        end
        else begin
            refresh_counter <= refresh_counter + 1;
            
            if (refresh_tick) begin
                digit_state <= digit_state + 1;
            end
        end
    end
    
    // 数码管显示逻辑
    always @(*) begin
        if (rst) begin
            an = 8'b11111111;
            sseg = 8'b00000000;
        end
        else begin
            an = 8'b11111111; // 默认关闭所有数码管
            sseg = 8'b00000000; // 默认段全灭
            
            case({OF, Er})
                2'b01, 2'b11: begin // 显示"ERROR"
                    case(digit_state)
                        0: begin an = 8'b11101111; sseg = 7'b0110000; end // E
                        1: begin an = 8'b11110111; sseg = 7'b0001000; end // R
                        2: begin an = 8'b11111011; sseg = 7'b0001000; end // R
                        3: begin an = 8'b11111101; sseg = 7'b0000001; end // O
                        4: begin an = 8'b11111110; sseg = 7'b0001000; end // R
                        default: begin an = 8'b11111111; sseg = 8'b00000000; end
                    endcase
                end
                2'b10: begin // 显示"OVERFLOW"
                    case(digit_state)
                        0: begin an = 8'b11111110; sseg = 7'b1000001; end // W->U
                        1: begin an = 8'b11111101; sseg = 7'b0000001; end // O
                        2: begin an = 8'b11111011; sseg = 7'b1110001; end // L
                        3: begin an = 8'b11110111; sseg = 7'b0111000; end // F
                        4: begin an = 8'b11101111; sseg = 7'b0001000; end // R
                        5: begin an = 8'b11011111; sseg = 7'b0110000; end // E
                        6: begin an = 8'b10111111; sseg = 7'b1000001; end // V->U
                        7: begin an = 8'b01111111; sseg = 7'b0000001; end // O
                        default: begin an = 8'b11111111; sseg = 8'b00000000; end
                    endcase
                end
                default: begin // 无显示
                    an = 8'b11111111;
                    sseg = 8'b00000000;
                end
            endcase
        end
    end
endmodule