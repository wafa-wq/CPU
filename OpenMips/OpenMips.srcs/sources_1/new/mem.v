`timescale 1ns / 1ps
`include "defines.v"

module mem(
    input wire rst,
    
    input wire[`RegAddrBus] wd_i,
    input wire wreg_i,
    input wire[`RegBus] wdata_i,
    
    input wire whilo_i,
    input wire[`RegBus] hi_i,lo_i,
    
    output reg whilo_o,
    output reg[`RegBus] hi_o,lo_o,
    
    output reg[`RegAddrBus] wd_o,
    output reg wreg_o,
    output reg[`RegBus] wdata_o,
    
    //load_store
    input wire[`AluOpBus] aluop_i,
    input wire[`RegBus] mem_addr_i,
    input wire[`RegBus] reg2_i,
    input wire[`RegBus] mem_data_i,
    output wire mem_we_o,
    output reg[3:0] mem_sel_o,  //write mem byte select
         //1000-1st byte,0100-2nd byte,0010-3rd byte,0001-4th byte
    output reg[`RegBus] mem_addr_o,
    output reg[`RegBus] mem_data_o,
    output reg mem_ce_o
    );
    
    reg mem_we;  //1--write,0--read
    wire[`RegBus] zero32;
assign mem_we_o = mem_we;
assign zero32 = `ZeroWord;  //32'b0 wires
    
always@(*) begin
    if(rst == `RstEnable) begin
        wd_o <= `NOPRegAddr;
        wreg_o <= `WriteDisable;
        wdata_o <= `ZeroWord;
        hi_o <= `ZeroWord;
        lo_o <= `ZeroWord;
        whilo_o <= `WriteDisable;
        
        mem_addr_o <= `ZeroWord;
        mem_we <= `WriteDisable;
        mem_sel_o <= 4'b0000;  //null
        mem_data_o <= `ZeroWord;
        mem_ce_o <= `ChipDisable;
        end
    else begin
        wd_o <= wd_i;
        wreg_o <= wreg_i;
        wdata_o <= wdata_i;
        hi_o <= hi_i;
        lo_o <= lo_i;
        whilo_o <= whilo_i;
        
        mem_addr_o <= `ZeroWord;
        mem_we <= `WriteDisable;
        mem_sel_o <= 4'b1111;  //wire 4 bytes
        mem_ce_o <= `ChipDisable;
        
        case(aluop_i)
            `EXE_LB_OP:begin
                mem_addr_o <= {mem_addr_i[31:2],2'b00};  //word address
                mem_we <= `WriteDisable;  //0--read
                mem_ce_o <= `ChipEnable;  //1'b1
                case(mem_addr_i[1:0])
                    2'b00:
                        wdata_o <= {{24{mem_data_i[31]}},mem_data_i[31:24]};
                    2'b01:
                        wdata_o <= {{24{mem_data_i[23]}},mem_data_i[23:16]};
                    2'b10:
                        wdata_o <= {{24{mem_data_i[15]}},mem_data_i[15:8]};
                    2'b11:
                        wdata_o <= {{24{mem_data_i[7]}},mem_data_i[7:0]};
                    default:
                        wdata_o <= `ZeroWord;
                    endcase
                end
                
            `EXE_LBU_OP:begin
                mem_addr_o <= mem_addr_i;  //word address
                mem_we <= `WriteDisable;  //0--read
                mem_ce_o <= `ChipEnable;  //1'b1
                case(mem_addr_i[1:0])
                    2'b00:begin
                        wdata_o <= {{24{1'b0}},mem_data_i[31:24]};
                        mem_sel_o <= 4'b1000;
                        end
                    2'b01:begin
                        wdata_o <= {{24{1'b0}},mem_data_i[23:16]};
                        mem_sel_o <= 4'b0100;
                        end
                    2'b10:begin
                        wdata_o <= {{24{1'b0}},mem_data_i[15:8]};
                        mem_sel_o <= 4'b0010;
                        end
                    2'b11:begin
                        wdata_o <= {{24{1'b0}},mem_data_i[7:0]};
                        mem_sel_o <= 4'b0001;
                        end
                    default:
                        wdata_o <= `ZeroWord;
                    endcase
                end
            
            `EXE_LH_OP:begin
                mem_addr_o <= mem_addr_i;  //word address
                mem_we <= `WriteDisable;  //0--read
                mem_ce_o <= `ChipEnable;  //1'b1
                case(mem_addr_i[1:0])
                    2'b00:begin
                        wdata_o <= {{16{mem_data_i[31]}},mem_data_i[31:16]};
                        mem_sel_o <= 4'b1100;
                        end
                    2'b10:begin
                        wdata_o <= {{16{mem_data_i[15]}},mem_data_i[15:0]};
                        mem_sel_o <= 4'b0011;
                        end
                    default:
                        wdata_o <= `ZeroWord;
                    endcase
                end
            
            `EXE_LHU_OP:begin
                mem_addr_o <= mem_addr_i;  //word address
                mem_we <= `WriteDisable;  //0--read
                mem_ce_o <= `ChipEnable;  //1'b1
                case(mem_addr_i[1:0])
                    2'b00:begin
                        wdata_o <= {{16{1'b0}},mem_data_i[31:16]};
                        mem_sel_o <= 4'b1100;
                        end
                    2'b10:begin
                        wdata_o <= {{16{1'b0}},mem_data_i[15:0]};
                        mem_sel_o <= 4'b0011;
                        end
                    default:
                        wdata_o <= `ZeroWord;
                    endcase
                end
            
            `EXE_LW_OP:begin
                mem_addr_o <= {mem_addr_i[31:2],2'b00};  //word address
                mem_we <= `WriteDisable;   //0--read
                mem_sel_o <= 4'b1111;
                mem_ce_o <= `ChipEnable;   //1'b1
                wdata_o <= mem_data_i;
                end
                
            `EXE_LWL_OP:begin
                mem_addr_o <= {mem_addr_i[31:2],2'b00};  //word address
                mem_we <= `WriteDisable;  //0--read
                mem_sel_o <= 4'b1111;
                mem_ce_o <= `ChipEnable;  //1'b1
                case(mem_addr_i[1:0])
                    2'b00:
                        wdata_o <= mem_data_i;
                    2'b01:
                        wdata_o <= {mem_data_i[23:0],reg2_i[7:0]};
                    2'b10:
                        wdata_o <= {mem_data_i[15:0],reg2_i[15:0]};
                    2'b11:
                        wdata_o <= {mem_data_i[7:0],reg2_i[23:0]};
                    default:
                        wdata_o <= `ZeroWord;
                    endcase
                end
                
            `EXE_LWR_OP:begin
                mem_addr_o <= {mem_addr_i[31:2],2'b00};  //word address
                mem_we <= `WriteDisable;  //0--read
                mem_sel_o <= 4'b1111;
                mem_ce_o <= `ChipEnable;  //1'b1
                case(mem_addr_i[1:0])
                    2'b00:
                        wdata_o <= {reg2_i[31:8],mem_data_i[31:24]};
                    2'b01:
                        wdata_o <= {reg2_i[31:16],mem_data_i[31:16]};
                    2'b10:
                        wdata_o <= {reg2_i[31:24],mem_data_i[31:8]};
                    2'b11:
                        wdata_o <= mem_data_i;
                    default:
                        wdata_o <= `ZeroWord;
                    endcase
                end
            
            `EXE_SH_OP:begin
                mem_addr_o <= {mem_addr_i[31:2],2'b00};  //word address
                mem_we <= `WriteEnable;  //1--write
                mem_data_o <= {reg2_i[15:0],reg2_i[15:0]};
                mem_ce_o <= `ChipEnable;  //1'b1
                case(mem_addr_i[1:0])
                    2'b00:
                        mem_sel_o <= 4'b1100;
                    2'b10:
                        mem_sel_o <= 4'b0011;
                    default:
                        mem_sel_o <= 4'b0000;
                    endcase
                end
                
            `EXE_SB_OP:begin
                mem_addr_o <= mem_addr_i;  //word address
                mem_we <= `WriteEnable;  //1--write
                mem_data_o <= {reg2_i[7:0],reg2_i[7:0],reg2_i[7:0],reg2_i[7:0]};
                mem_ce_o <= `ChipEnable;  //1'b1
                case(mem_addr_i[1:0])
                    2'b00:
                        mem_sel_o <= 4'b1000;
                    2'b01:
                        mem_sel_o <= 4'b0100;
                    2'b10:
                        mem_sel_o <= 4'b0010;
                    2'b11:
                        mem_sel_o <= 4'b0001;
                    default:
                        mem_sel_o <= 4'b0000;
                    endcase
                end
            
            `EXE_SW_OP:begin
                mem_addr_o <= mem_addr_i;  //word address
                mem_we <= `WriteEnable;  //1--write
                mem_data_o <= reg2_i;
                mem_ce_o <= `ChipEnable;  //1'b1
                mem_sel_o <= 4'b1111;
                end
            
            `EXE_SWL_OP:begin
                mem_addr_o <= {mem_addr_i[31:2],2'b00};  //word address
                mem_we <= `WriteEnable;  //1--write
                mem_ce_o <= `ChipEnable;  //1'b1
                case(mem_addr_i[1:0])
                    2'b00:begin
                        mem_sel_o <= 4'b1111;
                        mem_data_o <= reg2_i;
                        end
                    2'b01:begin
                        mem_sel_o <= 4'b0111;
                        mem_data_o <= {zero32[7:0],reg2_i[31:8]};
                        end
                    2'b10:begin
                        mem_sel_o <= 4'b0011;
                        mem_data_o <= {zero32[15:0],reg2_i[31:16]};
                        end
                    2'b11:begin
                        mem_sel_o <= 4'b0001;
                        mem_data_o <= {zero32[23:0],reg2_i[31:24]};
                        end
                    default:
                        mem_sel_o <= 4'b0000;
                    endcase
                end
            
            `EXE_SWR_OP:begin
                mem_addr_o <= {mem_addr_i[31:2],2'b00};  //word address
                mem_we <= `WriteEnable;  //1--write
                mem_ce_o <= `ChipEnable;  //1'b1
                case(mem_addr_i[1:0])
                    2'b00:begin
                        mem_sel_o <= 4'b1000;
                        mem_data_o  <= {reg2_i[7:0],zero32[23:0]};
                        end
                    2'b01:begin
                        mem_sel_o <= 4'b1100;
                        mem_data_o  <= {reg2_i[15:0],zero32[15:0]};
                        end
                    2'b10:begin
                        mem_sel_o <= 4'b1110;
                        mem_data_o  <= {reg2_i[23:0],zero32[7:0]};
                        end
                    2'b11:begin
                        mem_sel_o <= 4'b1111;
                        mem_data_o  <= reg2_i;
                        end
                    default:
                        mem_sel_o <= 4'b0000;
                    endcase
                end
                default:begin
                end
            endcase
        end
    end
endmodule
