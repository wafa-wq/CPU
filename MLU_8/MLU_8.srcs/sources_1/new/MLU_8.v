`timescale 1ns / 1ps

module MUL_8(
    input [8:1] X,          // 被乘数，8位输入
    input [8:1] Y,          // 乘数，8位输入
    output reg [16:1] Result, // 16位乘积输出
    input reset             // 复位信号，高电平有效
);

reg [8:1] Y_tmp;           // 乘数临时寄存器，用于移位操作
reg [8:1] P_tmp;           // 部分积寄存器，存储中间累加结果
reg C;                     // 进位标志
integer i;                 // 循环计数器

// 组合逻辑块：执行乘法运算
always @ *
begin
    P_tmp = 8'b0;          // 初始部分积清零
    Y_tmp = Y;             // 加载乘数Y到临时寄存器
    C = 1'b0;              // 初始进位清零

    // 8次循环，逐位处理乘数Y的每一位
    for (i = 1; i <= 8; i = i + 1) 
    begin
        // 若当前乘数位为1，将被乘数X加到部分积
        if (Y_tmp[1] == 1) 
        begin
            // 将X与当前部分积和进位相加，结果更新到{C, P_tmp}
            // {C, P_tmp} 为9位，加上{1'b0, X}（扩展为9位），结果存回
            {C, P_tmp} = {C, P_tmp} + {1'b0, X};
        end

        // 右移乘数寄存器Y_tmp：将部分积的最低位移入Y_tmp的最高位
        Y_tmp = {P_tmp[1], Y_tmp[8:2]}; // Y_tmp右移1位，高位由P_tmp[1]填充

        // 右移部分积和进位，为处理下一位做准备
        {C, P_tmp} = {C, P_tmp} >> 1;  // 整体右移1位，高位补0
    end  
end

// 组合逻辑块：处理复位并输出最终结果
always @ *
begin
    if (reset == 1)
    begin
        Result = 16'b0;    // 复位时结果清零
    end
    else
    begin
        // 将部分积的高8位（P_tmp）与移位后的Y_tmp组合为16位结果
        // 经过8次移位后，P_tmp存储乘积的高8位，Y_tmp存储低8位
        Result = {P_tmp[8:1], Y_tmp[8:1]};
    end
end

endmodule