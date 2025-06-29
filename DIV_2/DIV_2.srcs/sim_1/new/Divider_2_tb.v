`timescale 1ns / 1ps

module divider_2_tb();
    
    // 输入信号
    reg clk;
    reg [16:1] IN;
    reg X_button, Y_button;
    reg rst;
    
    // 输出信号
    wire [8:1] Q, R;
    wire [7:0] an;
    wire [6:0] sseg;
    
    // 实例化被测模块
    top uut (
        .clk(clk),
        .IN(IN),
        .X_button(X_button),
        .Y_button(Y_button),
        .rst(rst),
        .Q(Q),
        .R(R),
        .an(an),
        .sseg(sseg)
    );
    
    // 时钟生成
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz时钟
    end
    
    // 测试过程
    initial begin
        // 初始化输入
        IN = 0;
        X_button = 0;
        Y_button = 0;
        rst = 1;
        
        // 复位
        #20;
        rst = 0;
        
        // 测试用例1: 正常除法 200/8 = 25余0
        $display("Test Case 1: 200 / 8 = 25 rem 0");
        IN = 200;
        X_button = 1;
        #10;
        X_button = 0;
        IN = 8;
        Y_button = 1;
        #10;
        Y_button = 0;
        #100;
        $display("Q = %d, R = %d, OF = %b, Error = %b", Q, R, uut.OF_tmp, uut.Er_tmp);
        
        // 测试用例2: 正常除法 123/10 = 12余3
        $display("\nTest Case 2: 123 / 10 = 12 rem 3");
        IN = 123;
        X_button = 1;
        #10;
        X_button = 0;
        IN = 10;
        Y_button = 1;
        #10;
        Y_button = 0;
        #100;
        $display("Q = %d, R = %d, OF = %b, Error = %b", Q, R, uut.OF_tmp, uut.Er_tmp);
        
        // 测试用例3: 除数为零错误
        $display("\nTest Case 3: Divide by zero error");
        IN = 100;
        X_button = 1;
        #10;
        X_button = 0;
        IN = 0;
        Y_button = 1;
        #10;
        Y_button = 0;
        #100;
        $display("Q = %d, R = %d, OF = %b, Error = %b", Q, R, uut.OF_tmp, uut.Er_tmp);
        // 检查显示模块是否显示"ERROR"
        #100;
        
        // 复位
        rst = 1;
        #20;
        rst = 0;
        
        // 测试用例4: 溢出情况 (300/1 = 300 > 255)
        $display("\nTest Case 4: Overflow case (300/1)");
        IN = 300;
        X_button = 1;
        #10;
        X_button = 0;
        IN = 1;
        Y_button = 1;
        #10;
        Y_button = 0;
        #100;
        $display("Q = %d, R = %d, OF = %b, Error = %b", Q, R, uut.OF_tmp, uut.Er_tmp);
        // 检查显示模块是否显示"OVERFLOW"
        #100;
        
        // 测试用例5: 边界情况 (255/1 = 255)
        $display("\nTest Case 5: Boundary case (255/1)");
        IN = 255;
        X_button = 1;
        #10;
        X_button = 0;
        IN = 1;
        Y_button = 1;
        #10;
        Y_button = 0;
        #100;
        $display("Q = %d, R = %d, OF = %b, Error = %b", Q, R, uut.OF_tmp, uut.Er_tmp);
        
        // 结束仿真
        #100;
        $display("\nSimulation completed");
        $finish;
    end
    
    // 监视数码管显示
    always @(posedge clk) begin
        if (an != 8'b11111111) begin
            case(sseg)
                7'b0110000: $display("Display: E");
                7'b0001000: $display("Display: R");
                7'b0000001: $display("Display: O");
                7'b1110001: $display("Display: L");
                7'b0111000: $display("Display: F");
                7'b1000001: $display("Display: U/V/W");
                default: $display("Display: Unknown segment");
            endcase
        end
    end
endmodule