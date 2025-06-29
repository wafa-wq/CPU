

module divider_1_tb();

    // Inputs
    reg clk;
    reg [16:1] IN;
    reg X_button;
    reg Y_button;
    reg rst;
    
    // Outputs
    wire [8:1] Q, R;
    wire [7:0] an;
    wire [6:0] sseg;
    
    // Instantiate the Unit Under Test (UUT)
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
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end
    
    // Test cases
    initial begin
        // Initialize Inputs
        IN = 0;
        X_button = 0;
        Y_button = 0;
        rst = 1;
        
        // Wait 100ns for global reset to finish
        #100;
        rst = 0;
        
        // Test case 1: Normal division (100/5)
        #10;
        IN = 100;
        X_button = 1;
        #10;
        X_button = 0;
        #10;
        IN = 5;
        Y_button = 1;
        #10;
        Y_button = 0;
        #100;
        
        // Check results
        if (Q == 20 && R == 0)
            $display("Test 1 Passed: 100/5 = %d remainder %d", Q, R);
        else
            $display("Test 1 Failed: Expected 20 remainder 0, got %d remainder %d", Q, R);
        
        // Test case 2: Division with remainder (17/5)
        #100;
        IN = 17;
        X_button = 1;
        #10;
        X_button = 0;
        #10;
        IN = 5;
        Y_button = 1;
        #10;
        Y_button = 0;
        #100;
        
        // Check results
        if (Q == 3 && R == 2)
            $display("Test 2 Passed: 17/5 = %d remainder %d", Q, R);
        else
            $display("Test 2 Failed: Expected 3 remainder 2, got %d remainder %d", Q, R);
        
        // Test case 3: Division by zero (should trigger error)
        #100;
        IN = 100;
        X_button = 1;
        #10;
        X_button = 0;
        #10;
        IN = 0;
        Y_button = 1;
        #10;
        Y_button = 0;
        #100;
        
        // Check error display
        $display("Test 3: Division by zero - should display ERROR");
        
        // Test case 4: Overflow case (255/1)
        #100;
        IN = 255;
        X_button = 1;
        #10;
        X_button = 0;
        #10;
        IN = 1;
        Y_button = 1;
        #10;
        Y_button = 0;
        #100;
        
        // Check overflow display
        $display("Test 4: Overflow case - should display OVERFLOW");
        
        // Test case 5: Reset test
        #100;
        rst = 1;
        #10;
        rst = 0;
        #100;
        
        $display("Test 5: Reset test - all outputs should be cleared");
        
        // End simulation
        #100;
        $finish;
    end
    
    // Monitor changes
    initial begin
        $monitor("Time = %t, IN = %d, X = %b, Y = %b, rst = %b, Q = %d, R = %d, OF = %b, Error = %b", 
                 $time, IN, X_button, Y_button, rst, Q, R, uut.OF_tmp, uut.Er_tmp);
    end
    
endmodule