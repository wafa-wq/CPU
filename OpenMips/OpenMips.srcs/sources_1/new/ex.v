`timescale 1ns / 1ps
`include "defines.v"

module ex(
    input wire rst,
    input wire[`AluOpBus] aluop_i,
    input wire[`AluSelBus] alusel_i,
    input wire[`RegBus] reg1_i,reg2_i,
    input wire[`RegAddrBus] wd_i,
    input wire wreg_i,
    
    input wire[`RegBus] hi_i,lo_i,
    
    //test data dependent--WB
    input wire wb_whilo_i,  //write HILO enbale
    input wire[`RegBus] wb_hi_i,wb_lo_i,  //data
    
    //test data dependent--MEM
    input wire mem_whilo_i,  //write HILO enbale
    input wire[`RegBus] mem_hi_i,mem_lo_i,  //data
    
    output reg whilo_o,
    output reg[`RegBus] hi_o,lo_o,
    
    output reg[`RegAddrBus] wd_o,
    output reg wreg_o,
    output reg[`RegBus] wdata_o,
    
    //request pulse pipeline
    output reg stallreq,
    
    //madd
    input wire[`DoubleRegBus] hilo_temp_i,  //mult result at 1st ex-clock
    input wire[1:0]cnt_i,  //current ex-clock,2'b00(1st ex-clock),2'b01(2nd ex-clock)
    output reg[`DoubleRegBus] hilo_temp_o,  //mult result at 1st ex-clock
    output reg[1:0]cnt_o,  //next ex-clock
    
    //div
    input wire[`DoubleRegBus] div_result_i,
    input wire div_ready_i,
    output reg div_start_o,
    output reg[`RegBus] div_opdata1_o,
    output reg[`RegBus] div_opdata2_o,
    output reg signed_div_o,
    
    //branch
    input wire is_in_delayslot_i,
    input wire[`RegBus] link_address_i,
    
    //load_store
    input wire[`RegBus] inst_i,
    output wire[`AluOpBus] aluop_o,
    output wire[`RegBus] mem_addr_o,
    output wire[`RegBus] reg2_o
    );
    
    reg[`RegBus] logicout;  //Save logical operation results
    reg[`RegBus] shiftres;  //Save shift operation results
    reg[`RegBus] moveres;   //Save move operation results
    
    reg[`RegBus] hi,lo;  //Save Lastest hi/lo Values
    
    wire ov_sum;                    //overflow flag
    wire reg1_lt_reg2;              //reg1 < reg2 flag
    wire reg1_ltu_reg2;
    wire[`RegBus] reg2_i_mux;       //reg2 value
    wire[`RegBus] result_sum;       //add,subu,slt result
    wire[`RegBus] opdata1_mult;     //multiplicand(x)
    wire[`RegBus] opdata2_mult;     //multiplier(y)
    wire[`DoubleRegBus] hilo_temp;  //mult result temp
    reg[`DoubleRegBus] mulres;     //mult result
    reg[`RegBus] arithmeticres;    //Save srithmetic operation results
    
    reg[`DoubleRegBus] hilo_temp1;  //{hi,lo} + hilo_temp results, used by madd
    reg stallreq_for_madd_msub;  //request pipeline pluse triggered by madd
    
//load_store
assign aluop_o = aluop_i;
assign reg2_o = reg2_i;
assign mem_addr_o = reg1_i + {{16{inst_i[15]}},inst_i[15:0]};
    
//Logical operation
always@(*) begin  //Operation based on operator type of alu--aluop
    if(rst == `RstEnable)
        logicout <= `ZeroWord;
    else
        case(aluop_i)
            `EXE_OR_OP:
                logicout <= reg1_i | reg2_i;
            `EXE_AND_OP:
                logicout <= reg1_i & reg2_i;
            `EXE_XOR_OP:
                logicout <= reg1_i ^ reg2_i;
            `EXE_NOR_OP:
                logicout <= ~(reg1_i | reg2_i);
            default:
                logicout <= `ZeroWord;
            endcase
    end
    
//Shift operation
always@(*) begin
    if(rst == `RstEnable)
        shiftres <= `ZeroWord;
    else
        case(aluop_i)
            `EXE_SRL_OP:
                shiftres <= reg2_i >> reg1_i[4:0];
            `EXE_SRA_OP:
                shiftres <= ({32{reg2_i[31]}})<<(6'd32 - {1'b0,reg1_i[4:0]}) | reg2_i >> reg1_i[4:0];
            `EXE_SLL_OP:
                shiftres <= reg2_i << reg1_i[4:0];
            default:
                shiftres <= `ZeroWord;
            endcase
        end
        
//Move operation
always@(*) begin  //mfhi,mflo,movz,movn
    if(rst == `RstEnable)
        shiftres <= `ZeroWord;
    else
        case(aluop_i)
            `EXE_MFHI_OP:
                moveres <= hi;
            `EXE_MFLO_OP:
                moveres <= lo;
            `EXE_MOVZ_OP:
                moveres <= reg1_i;
            `EXE_MOVN_OP:
                moveres <= reg1_i;
            default:
                moveres <= `ZeroWord;
            endcase
        end
   
//signal value,write HILO 
always@(*) begin  //mthi,mtlo
    if(rst == `RstEnable)begin
        whilo_o <= `WriteDisable;
        hi_o <= `ZeroWord;
        lo_o <= `ZeroWord;
        end
    else if(aluop_i == `EXE_MULT_OP)begin
        whilo_o <= `WriteEnable;
        hi_o <= mulres[63:32];
        lo_o <= mulres[31:0];
        end
    else if(aluop_i == `EXE_MULTU_OP)begin
        whilo_o <= `WriteEnable;
        hi_o <= mulres[63:32];
        lo_o <= mulres[31:0];
        end
    else if(aluop_i == `EXE_MTLO_OP)begin
        whilo_o <= `WriteEnable;
        hi_o <= hi;      //hold
        lo_o <= reg1_i;  //write hi
        end
    else if(aluop_i == `EXE_MADD_OP)begin
        whilo_o <= `WriteEnable;
        hi_o <= hilo_temp1[63:32];
        lo_o <= hilo_temp1[31:0];
        end
    else if(aluop_i == `EXE_MADDU_OP)begin
        whilo_o <= `WriteEnable;
        hi_o <= hilo_temp1[63:32];
        lo_o <= hilo_temp1[31:0];
        end
    else if(aluop_i == `EXE_MSUB_OP)begin
        whilo_o <= `WriteEnable;
        hi_o <= hilo_temp1[63:32];
        lo_o <= hilo_temp1[31:0];
        end
    else if(aluop_i == `EXE_MSUBU_OP)begin
        whilo_o <= `WriteEnable;
        hi_o <= hilo_temp1[63:32];
        lo_o <= hilo_temp1[31:0];
        end
    else if(aluop_i == `EXE_MTHI_OP)begin
        whilo_o <= `WriteEnable;
        hi_o <= reg1_i;
        lo_o <= lo;
        end
    else if(aluop_i == `EXE_DIV_OP || `EXE_DIVU_OP)begin
        whilo_o <= `WriteEnable;
        hi_o <= div_result_i[63:32];
        lo_o <= div_result_i[31:0];
        end
    else begin
        whilo_o <= `WriteDisable;
        hi_o <= `ZeroWord;
        lo_o <= `ZeroWord;
        end
    end
    
//solve data dependent, get lastest HI/LO value
always@(*) begin
    if(rst == `RstEnable)begin
        hi <= `ZeroWord;
        lo <= `ZeroWord;
        end
    else if(mem_whilo_i == `WriteEnable)begin
        hi <= mem_hi_i;
        lo <= mem_lo_i;
        end
    else if(wb_whilo_i == `WriteEnable)begin
        hi <= wb_hi_i;
        lo <= wb_lo_i;
        end
    else begin
        hi <= hi_i;
        lo <= lo_i;
        end
    end
    
//Arithmetic operation

assign reg2_i_mux = ((aluop_i == `EXE_SUBU_OP)||(aluop_i == `EXE_SUB_OP)||(aluop_i == `EXE_SLT_OP)||(aluop_i == `EXE_SLTU_OP))?
                    (~reg2_i)+1:reg2_i;   //if(subu or slt) then -reg2,else reg2
                    
assign result_sum = reg1_i + reg2_i_mux;  //results:add,subu,slt

assign ov_sum = (!reg1_i[31] && !reg2_i_mux[31] && result_sum[31])||
                (reg1_i[31] && reg2_i_mux[31] && !result_sum[31]);  //used by add
                
assign reg1_lt_reg2 = (reg1_i[31] && !reg2_i_mux[31])||
                      (!reg1_i[31] && !reg2_i_mux[31] && result_sum[31])||
                      (reg1_i[31] && reg2_i_mux[31] && !result_sum[31]);  //used by slt
                      
assign reg1_ltu_reg2 = reg1_i < reg2_i;

always@(*)begin  //arithmeticres value
    if(rst == `RstEnable) begin
        arithmeticres <= `ZeroWord;
        end
    else
        case(aluop_i)
            `EXE_SLT_OP:
                arithmeticres <= reg1_lt_reg2;
            `EXE_SLTU_OP:
                arithmeticres <= reg1_ltu_reg2;
            `EXE_ADD_OP,`EXE_ADDU_OP,`EXE_SUB_OP,`EXE_SUBU_OP:
                arithmeticres <= result_sum;
            `EXE_MUL_OP:
                arithmeticres <= reg1_i * reg2_i;
            `EXE_CLZ_OP:
                if(reg1_i[31])arithmeticres <= 0; else if(reg1_i[30])arithmeticres <= 1; else if(reg1_i[29])arithmeticres <= 2; else if(reg1_i[28])arithmeticres <= 3;
                else if(reg1_i[27])arithmeticres <= 4; else if(reg1_i[26])arithmeticres <= 5; else if(reg1_i[25])arithmeticres <= 6; else if(reg1_i[24])arithmeticres <= 7;
                else if(reg1_i[23])arithmeticres <= 8; else if(reg1_i[22])arithmeticres <= 9; else if(reg1_i[21])arithmeticres <= 10; else if(reg1_i[20])arithmeticres <= 11;
                else if(reg1_i[19])arithmeticres <= 12; else if(reg1_i[18])arithmeticres <= 13; else if(reg1_i[17])arithmeticres <= 14; else if(reg1_i[16])arithmeticres <= 15;
                else if(reg1_i[15])arithmeticres <= 16; else if(reg1_i[14])arithmeticres <= 17; else if(reg1_i[13])arithmeticres <= 18; else if(reg1_i[12])arithmeticres <= 19;
                else if(reg1_i[11])arithmeticres <= 20; else if(reg1_i[10])arithmeticres <= 21; else if(reg1_i[9])arithmeticres <= 22; else if(reg1_i[8])arithmeticres <= 23;
                else if(reg1_i[7])arithmeticres <= 24; else if(reg1_i[6])arithmeticres <= 25; else if(reg1_i[5])arithmeticres <= 26; else if(reg1_i[4])arithmeticres <= 27;
                else if(reg1_i[3])arithmeticres <= 28; else if(reg1_i[2])arithmeticres <= 29; else if(reg1_i[1])arithmeticres <= 30; else if(reg1_i[0])arithmeticres <= 31;
                else arithmeticres <= 32;
            `EXE_CLO_OP:
                if(!reg1_i[31])arithmeticres <= 0; else if(!reg1_i[30])arithmeticres <= 1; else if(!reg1_i[29])arithmeticres <= 2; else if(!reg1_i[28])arithmeticres <= 3;
                else if(!reg1_i[27])arithmeticres <= 4; else if(!reg1_i[26])arithmeticres <= 5; else if(!reg1_i[25])arithmeticres <= 6; else if(!reg1_i[24])arithmeticres <= 7;
                else if(!reg1_i[23])arithmeticres <= 8; else if(!reg1_i[22])arithmeticres <= 9; else if(!reg1_i[21])arithmeticres <= 10; else if(!reg1_i[20])arithmeticres <= 11;
                else if(!reg1_i[19])arithmeticres <= 12; else if(!reg1_i[18])arithmeticres <= 13; else if(!reg1_i[17])arithmeticres <= 14; else if(!reg1_i[16])arithmeticres <= 15;
                else if(!reg1_i[15])arithmeticres <= 16; else if(!reg1_i[14])arithmeticres <= 17; else if(!reg1_i[13])arithmeticres <= 18; else if(!reg1_i[12])arithmeticres <= 19;
                else if(!reg1_i[11])arithmeticres <= 20; else if(!reg1_i[10])arithmeticres <= 21; else if(!reg1_i[9])arithmeticres <= 22; else if(!reg1_i[8])arithmeticres <= 23;
                else if(!reg1_i[7])arithmeticres <= 24; else if(!reg1_i[6])arithmeticres <= 25; else if(!reg1_i[5])arithmeticres <= 26; else if(!reg1_i[4])arithmeticres <= 27;
                else if(!reg1_i[3])arithmeticres <= 28; else if(!reg1_i[2])arithmeticres <= 29; else if(!reg1_i[1])arithmeticres <= 30; else if(!reg1_i[0])arithmeticres <= 31;
                else arithmeticres <= 32;
        endcase
    end
    
//Mult operation

assign opdata1_mult = ((aluop_i == `EXE_MUL_OP) || (aluop_i == `EXE_MULT_OP) || (aluop_i == `EXE_MADD_OP) || (aluop_i == `EXE_MSUB_OP)) && (reg1_i[31] == 1'b1)?(~reg1_i + 1):reg1_i;
assign opdata2_mult = ((aluop_i == `EXE_MUL_OP) || (aluop_i == `EXE_MULT_OP) || (aluop_i == `EXE_MADD_OP) || (aluop_i == `EXE_MSUB_OP)) && (reg2_i[31] == 1'b1)?(~reg2_i + 1):reg2_i;
assign hilo_temp = opdata1_mult * opdata2_mult;  //"*" in Verilog is unsigned mult

always@(*)begin
    if(rst == `RstEnable)
        mulres <= {`ZeroWord,`ZeroWord};
    else if(((aluop_i == `EXE_MUL_OP) || (aluop_i == `EXE_MULT_OP) || (aluop_i == `EXE_MADD_OP) || (aluop_i == `EXE_MSUB_OP)) && (reg1_i[31]^reg2_i[31] == 1'b1))
        mulres <= ~hilo_temp + 1;
    else
        mulres <= hilo_temp;
    end
    
//2 ex_clock--madd operation,one-hot code
always@(*)begin
    if(rst == `RstEnable)begin
        hilo_temp_o <= {`ZeroWord,`ZeroWord};
        cnt_o <= 2'b00;
        stallreq_for_madd_msub <= `NoStop;
        end
    else
        case(aluop_i)
            `EXE_MADD_OP:begin
                if(cnt_i == 2'b00)begin
                    hilo_temp_o <= mulres;
                    cnt_o <= 2'b01;
                    hilo_temp1<= {`ZeroWord,`ZeroWord};
                    stallreq_for_madd_msub <= `Stop;
                    end
                else if(cnt_i == 2'b01)begin
                    hilo_temp_o <= {`ZeroWord,`ZeroWord};
                    cnt_o <= 2'b10;
                    hilo_temp1<= hilo_temp_i + {hi,lo};
                    stallreq_for_madd_msub <= `NoStop;
                    end
                end
                
            `EXE_MADDU_OP:begin
                if(cnt_i == 2'b00)begin
                    hilo_temp_o <= mulres;
                    cnt_o <= 2'b01;
                    hilo_temp1<= {`ZeroWord,`ZeroWord};
                    stallreq_for_madd_msub <= `Stop;
                    end
                else if(cnt_i == 2'b01)begin
                    hilo_temp_o <= {`ZeroWord,`ZeroWord};
                    cnt_o <= 2'b10;
                    hilo_temp1<= hilo_temp_i + {hi,lo};
                    stallreq_for_madd_msub <= `NoStop;
                    end
                end
                
            `EXE_MSUB_OP:begin
                if(cnt_i == 2'b00)begin
                    hilo_temp_o <= mulres;
                    cnt_o <= 2'b01;
                    hilo_temp1<= {`ZeroWord,`ZeroWord};
                    stallreq_for_madd_msub <= `Stop;
                    end
                else if(cnt_i == 2'b01)begin
                    hilo_temp_o <= {`ZeroWord,`ZeroWord};
                    cnt_o <= 2'b10;
                    hilo_temp1<= {hi,lo} - hilo_temp_i;
                    stallreq_for_madd_msub <= `NoStop;
                    end
                end
                
            `EXE_MSUBU_OP:begin
                if(cnt_i == 2'b00)begin
                    hilo_temp_o <= mulres;
                    cnt_o <= 2'b01;
                    hilo_temp1<= {`ZeroWord,`ZeroWord};
                    stallreq_for_madd_msub <= `Stop;
                    end
                else if(cnt_i == 2'b01)begin
                    hilo_temp_o <= {`ZeroWord,`ZeroWord};
                    cnt_o <= 2'b10;
                    hilo_temp1<= {hi,lo} - hilo_temp_i;
                    stallreq_for_madd_msub <= `NoStop;
                    end
                end
                
            default:begin
                hilo_temp_o <= {`ZeroWord,`ZeroWord};
                cnt_o <= 2'b00;
                stallreq_for_madd_msub <= `NoStop;
                end
            endcase
    end

//Div operation
always@(*)begin
    if(rst == `RstEnable) begin
        stallreq <= `NoStop;
        div_start_o <= 1'b0;
        div_opdata1_o <= `ZeroWord;
        div_opdata2_o <= `ZeroWord;
        signed_div_o <= 1'b0;
        end
        else begin
            stallreq <= `NoStop;
            div_opdata1_o <= `ZeroWord;
            div_opdata2_o <= `ZeroWord;
            div_start_o <= `DivStop;
            signed_div_o <= 1'b0;
            
        case(aluop_i)
            `EXE_DIV_OP:begin
                if(div_ready_i == `DivResultNotReady)begin
                    div_opdata1_o <= reg1_i;
                    div_opdata2_o <= reg2_i;
                    div_start_o <= `DivStart;
                    signed_div_o <= 1'b1;
                    stallreq <= `Stop;
                    end
                else if(div_ready_i == `DivResultReady)begin
                    div_opdata1_o <= reg1_i;
                    div_opdata2_o <= reg2_i;
                    div_start_o <= `DivStop;
                    signed_div_o <= 1'b1;
                    stallreq <= `NoStop;
                    end
                else begin
                    div_opdata1_o <= `ZeroWord;
                    div_opdata2_o <= `ZeroWord;
                    div_start_o <= `DivStop;
                    signed_div_o <= 1'b0;
                    stallreq <= `Stop;
                    end
                end
            `EXE_DIVU_OP:begin
                if(div_ready_i == `DivResultNotReady)begin
                    div_opdata1_o <= reg1_i;
                    div_opdata2_o <= reg2_i;
                    div_start_o <= `DivStart;
                    signed_div_o <= 1'b0;
                    stallreq <= `Stop;
                    end
                else if(div_ready_i == `DivResultReady)begin
                    div_opdata1_o <= reg1_i;
                    div_opdata2_o <= reg2_i;
                    div_start_o <= `DivStop;
                    signed_div_o <= 1'b0;
                    stallreq <= `NoStop;
                    end
                else begin
                    div_opdata1_o <= `ZeroWord;
                    div_opdata2_o <= `ZeroWord;
                    div_start_o <= `DivStop;
                    signed_div_o <= 1'b0;
                    stallreq <= `Stop;
                    end
                end
                
                default:begin
                    end
                endcase
            end
    end

//pulse pipeline 
always@(*)begin
    stallreq = stallreq_for_madd_msub;
    end
    
//result output
always@(*) begin  //Select the result output according to alusel
    wd_o <= wd_i;
    wreg_o <= (aluop_i == `EXE_ADD_OP) && (ov_sum == 1'b1)?
              `WriteDisable:wreg_i;
    case(alusel_i)
        `EXE_RES_LOGIC:
            wdata_o <= logicout;
        `EXE_RES_SHIFT:
            wdata_o <= shiftres;
        `EXE_RES_MOVE:
            wdata_o <= moveres;
        `EXE_RES_ARITHMETIC:
            wdata_o <= arithmeticres;
        `EXE_RES_JUMP_BRANCH:
            wdata_o <= link_address_i;
        default:
            wdata_o <= `ZeroWord;
        endcase
    end
    
endmodule
