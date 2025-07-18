`timescale 1ns / 1ps

module divider_2(
    input wire[15:0] IN,
        input wire X_button,Y_button,
        input wire rst,
        output [7:0] Q,R,
        output OF,
        output reg Error
        );
        reg [15:0] X;
        reg [7:0] Y;
        reg [8:0] R_tmp,Q_tmp,Y_tmp;
        assign Q = Q_tmp[7:0];
        assign R = R_tmp[7:0];
        assign OF = Q_tmp[8];
        integer i,j=0;
        always@(X_button,Y_button,rst)begin
            if(rst)begin//复位
                X=0;
                Y=1;
            end else if(X_button)begin//被除数与除数复用按键
                X=IN;
            end else if(Y_button)begin
                Y=IN[7:0];
            end
        end
        always@(X,Y,rst)begin
            if(rst)begin
                Q_tmp=0;
                R_tmp=0;
                Error=0;
            end else begin//用于判溢出
                Y_tmp={1'b0,Y};
                Q_tmp={X[7:0],1'b0};//自动补商0
                R_tmp={1'b0,X[15:8]};
                Error=(Y_tmp)?1'b0:1'b1;//0除错误
                
                R_tmp=R_tmp-Y_tmp;//第一次试商
                for(i=1;i<=8;i=i+1)begin
                    if(R_tmp[8]==1)begin
                        {R_tmp,Q_tmp}={R_tmp,Q_tmp}<<1;
                        R_tmp=R_tmp+Y_tmp;
                    end else begin
                        Q_tmp[0]=1;
                        {R_tmp,Q_tmp}={R_tmp,Q_tmp}<<1;
                        R_tmp=R_tmp-Y_tmp;
                    end 
                end
                if(R_tmp[8]==0)//最后一次的判断
                    Q_tmp[0]=1;
                else//最后一位的商为0时，余数恢复
                    R_tmp=R_tmp+Y_tmp;
            end            
        end
endmodule