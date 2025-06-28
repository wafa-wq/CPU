`timescale 1ns / 1ps
`include "defines.v"

module id(
    input wire rst,
    input wire[`InstAddrBus] pc_i,       //Instruction address
    input wire[`InstBus] inst_i,         //Instruction
    input wire[`RegBus] reg1_data_i,reg2_data_i,  //Read register data
    output reg reg1_read_o,reg2_read_o,  //Read register enable
    output reg[`RegAddrBus] reg1_addr_o,reg2_addr_o,  //Read register affress
    output reg[`AluOpBus] aluop_o,       //Alu operation type(8bits)
    output reg[`AluSelBus] alusel_o,     //Alu output type(3bits)
    output reg[`RegBus] reg1_o,reg2_o,   //Source operand
    output reg[`RegAddrBus] wd_o,        //Write register address
    output reg wreg_o,                   //Write register flag
    
    //Data dependent--RAW
    input wire mem_wreg_i,               //Instruction operation results in MEM
    input wire[`RegBus] mem_wdata_i,
    input wire[`RegAddrBus] mem_wd_i,
    input wire ex_wreg_i,               //Instruction operation results in EX
    input wire[`RegBus] ex_wdata_i,
    input wire[`RegAddrBus] ex_wd_i,
    
    //request pulse pipeline
    output wire stallreq,
    
    //branch
    input wire is_in_delayslot_i,
    output reg is_in_delayslot_o,
    output reg next_inst_in_delayslot_o,
    output reg branch_flag_o,
    output reg[`RegBus] branch_target_address_o,
    output reg[`RegBus] link_addr_o,
    
    //load_store
    output wire[`RegBus] inst_o,
    
    //Load-use Data dependent
    input wire[`AluOpBus] ex_aluop_i
    );

    wire[5:0] op = inst_i[31:26];  //OP
    wire[5:0] func = inst_i[5:0];  //func
    
//pulse pipeline
    reg stallreq_for_reg1_loadrelate;
    reg stallreq_for_reg2_loadrelate;
    wire pre_inst_is_load;  //Previous instruction is load-type
    
    reg[`RegBus] imm;  //Store immediate amount
    reg instvalid;     //Instruction valid flag

//for branch
wire[`RegBus] pc_plus_8;
wire[`RegBus] pc_plus_4;
wire[`RegBus] imm_sll2_signedext;
    
assign pre_inst_is_load = (ex_aluop_i == `EXE_LB_OP
                         ||ex_aluop_i == `EXE_LBU_OP
                         ||ex_aluop_i == `EXE_LH_OP
                         ||ex_aluop_i == `EXE_LHU_OP
                         ||ex_aluop_i == `EXE_LW_OP
                         ||ex_aluop_i == `EXE_LWL_OP
                         ||ex_aluop_i == `EXE_LWR_OP);
always@(*)begin
    stallreq_for_reg1_loadrelate <= `NoStop;  //restore pipeline
    if(rst == `RstDisable)
        if(pre_inst_is_load == 1'b1 && ex_wd_i == reg1_addr_o && reg1_read_o == 1'b1)
            stallreq_for_reg1_loadrelate <= `Stop;
        end
        
always@(*)begin
    stallreq_for_reg2_loadrelate <= `NoStop;
    if(rst == `RstDisable)
        if(pre_inst_is_load == 1'b1 && ex_wd_i == reg2_addr_o && reg2_read_o == 1'b1)
            stallreq_for_reg2_loadrelate <= `Stop;
        end
    
assign stallreq = stallreq_for_reg1_loadrelate | stallreq_for_reg2_loadrelate;
    
assign pc_plus_8 = pc_i + 8;
assign pc_plus_4 = pc_i + 4;
assign imm_sll2_signedext = {{14{inst_i[15]}},inst_i[15:0],2'b00};
assign inst_o = inst_i;

always@(*) begin  //Instruction decode
    if(rst == `RstEnable) begin      //1'b1
        aluop_o <= `EXE_NOP_OP;      //8'b00000000
        alusel_o <= `EXE_RES_NOP;    //3'b000
        wd_o <= `NOPRegAddr;         //5'b00000
        wreg_o <= `WriteDisable;     //1'b0
        instvalid <= `InstInvalid;   //1'b1(invalid)
        reg1_read_o <= 1'b0;         //read disable
        reg2_read_o <= 1'b0;         //read disable
        reg1_addr_o <= `NOPRegAddr;  //5'b00000
        reg2_addr_o <= `NOPRegAddr;  //5'b00000
        imm <= `ZeroWord;            //32'h00000000
        
        link_addr_o <= `ZeroWord;
        branch_flag_o <= `NotBranch;
        branch_target_address_o <= `ZeroWord;
        next_inst_in_delayslot_o <= `NotInDelaySlot;
        end
        
    else begin
        aluop_o <= `EXE_NOP_OP;        //8'b00000000
        alusel_o <= `EXE_RES_NOP;      //3'b000
        wd_o <= inst_i[15:11];         //rd(General situation)
        wreg_o <= `WriteDisable;       //1'b0
        instvalid <= `InstInvalid;     //1'b1(invalid)
        reg1_read_o <= 1'b0;           //read disable
        reg2_read_o <= 1'b0;           //read disable
        reg1_addr_o <= inst_i[25:21];  //rs
        reg2_addr_o <= inst_i[20:16];  //rt
        imm <= `ZeroWord;              //32'h00000000
        
        link_addr_o <= `ZeroWord;
        branch_flag_o <= `NotBranch;
        branch_target_address_o <= `ZeroWord;
        next_inst_in_delayslot_o <= `NotInDelaySlot;
        
        case(op)
            `EXE_SPECIAL_INST:begin    //6'b000000,R-type instruction
                case(func)  //func
                    `EXE_AND:begin     //and instruction
                        wreg_o <= `WriteEnable;      //1'b1
                        aluop_o <= `EXE_AND_OP;      //8'b00100100
                        alusel_o <= `EXE_RES_LOGIC;  //3'b001
                        reg1_read_o <= 1'b1;         //rs read enable
                        reg2_read_o <= 1'b1;         //rt read enable
                        instvalid <= `InstValid;     //1'b0(valid)
                        end
                        
                    `EXE_OR:begin     //or instruction
                        wreg_o <= `WriteEnable;      //1'b1
                        aluop_o <= `EXE_OR_OP;       //8'b00100101
                        alusel_o <= `EXE_RES_LOGIC;  //3'b001
                        reg1_read_o <= 1'b1;         //rs read enable
                        reg2_read_o <= 1'b1;         //rt read enable
                        instvalid <= `InstValid;     //1'b0(valid)
                        end
                        
                    `EXE_XOR:begin     //xor instruction
                        wreg_o <= `WriteEnable;      //1'b1
                        aluop_o <= `EXE_XOR_OP;      //8'b00100110
                        alusel_o <= `EXE_RES_LOGIC;  //3'b001
                        reg1_read_o <= 1'b1;         //rs read enable
                        reg2_read_o <= 1'b1;         //rt read enable
                        instvalid <= `InstValid;     //1'b0(valid)
                        end
                        
                    `EXE_NOR:begin     //nor instruction
                        wreg_o <= `WriteEnable;      //1'b1
                        aluop_o <= `EXE_NOR_OP;       //8'b00100111
                        alusel_o <= `EXE_RES_LOGIC;  //3'b001
                        reg1_read_o <= 1'b1;         //rs read enable
                        reg2_read_o <= 1'b1;         //rt read enable
                        instvalid <= `InstValid;     //1'b0(valid)
                        end
                        
                    `EXE_SRL:begin     //srl instruction
                        wreg_o <= `WriteEnable;      //1'b1
                        aluop_o <= `EXE_SRL_OP;      //8'b00000010
                        alusel_o <= `EXE_RES_SHIFT;  //3'b010
                        reg1_read_o <= 1'b0;         //rs read disable
                        reg2_read_o <= 1'b1;         //rt read enable
                        imm[4:0] <= inst_i[10:6];    //shamt
                        wd_o <= inst_i[15:11];       //rd
                        instvalid <= `InstValid;     //1'b0(valid)
                        end
                        
                    `EXE_SLL:begin     //sll instruction
                        wreg_o <= `WriteEnable;      //1'b1
                        aluop_o <= `EXE_SLL_OP;      //8'b00000000
                        alusel_o <= `EXE_RES_SHIFT;  //3'b010
                        reg1_read_o <= 1'b0;         //rs read disable
                        reg2_read_o <= 1'b1;         //rt read enable
                        imm[4:0] <= inst_i[10:6];    //shamt
                        wd_o <= inst_i[15:11];       //rd
                        instvalid <= `InstValid;     //1'b0(valid)
                        end
                        
                    `EXE_SRA:begin     //sra instruction
                        wreg_o <= `WriteEnable;      //1'b1
                        aluop_o <= `EXE_SRA_OP;      //8'b00000011
                        alusel_o <= `EXE_RES_SHIFT;  //3'b010
                        reg1_read_o <= 1'b0;         //rs read disable
                        reg2_read_o <= 1'b1;         //rt read enable
                        imm[4:0] <= inst_i[10:6];    //shamt
                        wd_o <= inst_i[15:11];       //rd
                        instvalid <= `InstValid;     //1'b0(valid)
                        end
                        
                    `EXE_SRAV:begin     //srav instruction
                        wreg_o <= `WriteEnable;      //1'b1
                        aluop_o <= `EXE_SRA_OP;      //8'b00000011
                        alusel_o <= `EXE_RES_SHIFT;  //3'b010
                        reg1_read_o <= 1'b1;         //rs read enable
                        reg2_read_o <= 1'b1;         //rt read enable
                        instvalid <= `InstValid;     //1'b0(valid)
                        end
                        
                    `EXE_SLLV:begin     //sllv instruction
                        wreg_o <= `WriteEnable;      //1'b1
                        aluop_o <= `EXE_SLL_OP;      //8'b01111100
                        alusel_o <= `EXE_RES_SHIFT;  //3'b010
                        reg1_read_o <= 1'b1;         //rs read enable
                        reg2_read_o <= 1'b1;         //rt read enable
                        instvalid <= `InstValid;     //1'b0(valid)
                        end
                        
                    `EXE_SRLV:begin     //srlv instruction
                        wreg_o <= `WriteEnable;      //1'b1
                        aluop_o <= `EXE_SRL_OP;      //8'b00000010
                        alusel_o <= `EXE_RES_SHIFT;  //3'b010
                        reg1_read_o <= 1'b1;         //rs read enable
                        reg2_read_o <= 1'b1;         //rt read enable
                        instvalid <= `InstValid;     //1'b0(valid)
                        end
                        
                    `EXE_MOVZ:begin     //movz instruction
                        aluop_o <= `EXE_MOVZ_OP;     //8'b00001010
                        alusel_o <= `EXE_RES_MOVE;   //3'b011
                        reg1_read_o <= 1'b1;         //rs read enable
                        reg2_read_o <= 1'b1;         //rt read enable
                        instvalid <= `InstValid;     //1'b0(valid)
                        if(reg2_o == `ZeroWord)      //if rt is zero
                            wreg_o <= `WriteEnable;  //1'b1
                        else
                            wreg_o <= `WriteDisable; //1'b0
                        end
                        
                    `EXE_MOVN:begin     //movn instruction
                        aluop_o <= `EXE_MOVN_OP;     //8'b00001011
                        alusel_o <= `EXE_RES_MOVE;   //3'b011
                        reg1_read_o <= 1'b1;         //rs read enable
                        reg2_read_o <= 1'b1;         //rt read enable
                        instvalid <= `InstValid;     //1'b0(valid)
                        if(reg2_o != `ZeroWord)      //if rt is not zero
                            wreg_o <= `WriteEnable;  //1'b1
                        else
                            wreg_o <= `WriteDisable; //1'b0
                        end
                        
                    `EXE_MFHI:begin     //mfhi instruction
                        wreg_o <= `WriteEnable;      //1'b1
                        aluop_o <= `EXE_MFHI_OP;     //8'b00010000
                        alusel_o <= `EXE_RES_MOVE;   //3'b011
                        reg1_read_o <= 1'b0;         //rs read disable
                        reg2_read_o <= 1'b0;         //rt read dusable
                        instvalid <= `InstValid;     //1'b0(valid)
                        end
                        
                    `EXE_MFLO:begin     //mflo instruction
                        wreg_o <= `WriteEnable;      //1'b1
                        aluop_o <= `EXE_MFLO_OP;     //8'b00010010
                        alusel_o <= `EXE_RES_MOVE;   //3'b011
                        reg1_read_o <= 1'b0;         //rs read disable
                        reg2_read_o <= 1'b0;         //rt read disable
                        instvalid <= `InstValid;     //1'b0(valid)
                        end
                        
                    `EXE_MTLO:begin     //mtlo instruction
                        wreg_o <= `WriteDisable;      //1'b0
                        aluop_o <= `EXE_MTLO_OP;      //8'b00010011
                        reg1_read_o <= 1'b1;         //rs read enable
                        reg2_read_o <= 1'b0;         //rt read disable
                        instvalid <= `InstValid;     //1'b0(valid)
                        end
                        
                    `EXE_MTHI:begin     //mthi instruction
                        wreg_o <= `WriteDisable;      //1'b0
                        aluop_o <= `EXE_MTHI_OP;      //8'b00010010
                        reg1_read_o <= 1'b1;         //rs read enable
                        reg2_read_o <= 1'b0;         //rt read disable
                        instvalid <= `InstValid;     //1'b0(valid)
                        end
                        
                    `EXE_SLT:begin
                        wreg_o <= `WriteEnable;
                        aluop_o <= `EXE_SLT_OP;
                        alusel_o <= `EXE_RES_ARITHMETIC;
                        reg1_read_o <= 1'b1;         //rs read enable
                        reg2_read_o <= 1'b1;         //rt read enable
                        instvalid <= `InstValid;
                        end
                        
                    `EXE_SLTU:begin
                        wreg_o <= `WriteEnable;
                        aluop_o <= `EXE_SLTU_OP;
                        alusel_o <= `EXE_RES_ARITHMETIC;
                        reg1_read_o <= 1'b1;         //rs read enable
                        reg2_read_o <= 1'b1;         //rt read enable
                        instvalid <= `InstValid;
                        end
                        
                    `EXE_ADD:begin
                        wreg_o <= `WriteEnable;
                        aluop_o <= `EXE_ADD_OP;
                        alusel_o <= `EXE_RES_ARITHMETIC;
                        reg1_read_o <= 1'b1;         //rs read enable
                        reg2_read_o <= 1'b1;         //rt read enable
                        instvalid <= `InstValid;
                        end
                        
                    `EXE_ADDU:begin
                        wreg_o <= `WriteEnable;
                        aluop_o <= `EXE_ADDU_OP;
                        alusel_o <= `EXE_RES_ARITHMETIC;
                        reg1_read_o <= 1'b1;         //rs read enable
                        reg2_read_o <= 1'b1;         //rt read enable
                        instvalid <= `InstValid;
                        end
                        
                    `EXE_SUBU:begin
                        wreg_o <= `WriteEnable;
                        aluop_o <= `EXE_SUBU_OP;
                        alusel_o <= `EXE_RES_ARITHMETIC;
                        reg1_read_o <= 1'b1;         //rs read enable
                        reg2_read_o <= 1'b1;         //rt read enable
                        instvalid <= `InstValid;
                        end
                        
                    `EXE_SUB:begin
                        wreg_o <= `WriteEnable;
                        aluop_o <= `EXE_SUB_OP;
                        alusel_o <= `EXE_RES_ARITHMETIC;
                        reg1_read_o <= 1'b1;         //rs read enable
                        reg2_read_o <= 1'b1;         //rt read enable
                        instvalid <= `InstValid;
                        end
                        
                    `EXE_MULT:begin
                        wreg_o <= `WriteDisable;
                        aluop_o <= `EXE_MULT_OP;
                        reg1_read_o <= 1'b1;         //rs read enable
                        reg2_read_o <= 1'b1;         //rt read enable
                        instvalid <= `InstValid;
                        end
                        
                    `EXE_MULTU:begin
                        wreg_o <= `WriteDisable;
                        aluop_o <= `EXE_MULTU_OP;
                        reg1_read_o <= 1'b1;         //rs read enable
                        reg2_read_o <= 1'b1;         //rt read enable
                        instvalid <= `InstValid;
                        end
                        
                    `EXE_DIV:begin
                        wreg_o <= `WriteDisable;
                        aluop_o <= `EXE_DIV_OP;
                        reg1_read_o <= 1'b1;         //rs read enable
                        reg2_read_o <= 1'b1;         //rt read enable
                        instvalid <= `InstValid;
                        end
                        
                    `EXE_DIVU:begin
                        wreg_o <= `WriteDisable;
                        aluop_o <= `EXE_DIVU_OP;
                        reg1_read_o <= 1'b1;         //rs read enable
                        reg2_read_o <= 1'b1;         //rt read enable
                        instvalid <= `InstValid;
                        end
                        
                    `EXE_JALR:begin
                        wreg_o <= `WriteEnable;
                        aluop_o <= `EXE_NOP_OP;
                        alusel_o <= `EXE_RES_JUMP_BRANCH;
                        reg1_read_o <= 1'b1;         //rs read enable
                        reg2_read_o <= 1'b0;         //rt read disable
                        wd_o <= inst_i[15:11];       //rd
                        link_addr_o <= pc_plus_8;
                        branch_flag_o <= `Branch;
                        branch_target_address_o <= reg1_o;
                        next_inst_in_delayslot_o <= `InDelaySlot;
                        instvalid <= `InstValid;
                        end
                        
                    `EXE_JR:begin
                        wreg_o <= `WriteEnable;
                        aluop_o <= `EXE_NOP_OP;
                        alusel_o <= `EXE_RES_JUMP_BRANCH;
                        reg1_read_o <= 1'b1;         //rs read enable
                        reg2_read_o <= 1'b0;         //rt read disable
                        link_addr_o <= `ZeroWord;
                        branch_flag_o <= `Branch;
                        branch_target_address_o <= reg1_o;
                        next_inst_in_delayslot_o <= `InDelaySlot;
                        instvalid <= `InstValid;
                        end

                    default:begin
                        end
                    endcase
                end
                
            `EXE_SPECIAL2_INST:begin  //6'b011100,R_type instruction
                case(func)  //func
                
                `EXE_CLZ:begin
                    wreg_o <= `WriteEnable;
                    aluop_o <= `EXE_CLZ_OP;
                    alusel_o <= `EXE_RES_ARITHMETIC;
                    reg1_read_o <= 1'b1;          //rs read enable
                    reg2_read_o <= 1'b0;          //rt read disable
                    instvalid <= `InstValid;      //1'b0(valid)
                    end
                    
                `EXE_CLO:begin
                    wreg_o <= `WriteEnable;
                    aluop_o <= `EXE_CLO_OP;
                    alusel_o <= `EXE_RES_ARITHMETIC;
                    reg1_read_o <= 1'b1;          //rs read enable
                    reg2_read_o <= 1'b0;          //rt read disable
                    instvalid <= `InstValid;      //1'b0(valid)
                    end
                    
                `EXE_MUL:begin
                    wreg_o <= `WriteEnable;
                    aluop_o <= `EXE_MUL_OP;
                    alusel_o <= `EXE_RES_ARITHMETIC;
                    reg1_read_o <= 1'b1;         //rs read enable
                    reg2_read_o <= 1'b1;         //rt read enable
                    instvalid <= `InstValid;
                    end
                
                `EXE_MADD:begin
                    wreg_o <= `WriteDisable;       //1'b0
                    aluop_o <= `EXE_MADD_OP;
                    alusel_o <= `EXE_RES_MUL;
                    reg1_read_o <= 1'b1;          //rs read enable
                    reg2_read_o <= 1'b1;          //rt read enable
                    instvalid <= `InstValid;      //1'b0(valid)
                    end
                    
                `EXE_MADDU:begin
                    wreg_o <= `WriteDisable;       //1'b0
                    aluop_o <= `EXE_MADDU_OP;
                    alusel_o <= `EXE_RES_MUL;
                    reg1_read_o <= 1'b1;          //rs read enable
                    reg2_read_o <= 1'b1;          //rt read enable
                    instvalid <= `InstValid;      //1'b0(valid)
                    end
                    
                `EXE_MSUB:begin
                    wreg_o <= `WriteDisable;       //1'b0
                    aluop_o <= `EXE_MSUB_OP;
                    alusel_o <= `EXE_RES_MUL;
                    reg1_read_o <= 1'b1;          //rs read enable
                    reg2_read_o <= 1'b1;          //rt read enable
                    instvalid <= `InstValid;      //1'b0(valid)
                    end
                    
                `EXE_MSUBU:begin
                    wreg_o <= `WriteDisable;       //1'b0
                    aluop_o <= `EXE_MSUBU_OP;
                    alusel_o <= `EXE_RES_MUL;
                    reg1_read_o <= 1'b1;          //rs read enable
                    reg2_read_o <= 1'b1;          //rt read enable
                    instvalid <= `InstValid;      //1'b0(valid)
                    end
                    
                default:begin
                    end
                endcase
            end
                
            `EXE_ORI:begin  //6'b001101
                wreg_o <= `WriteEnable;       //1'b1
                aluop_o <= `EXE_OR_OP;        //8'b00100101
                alusel_o <= `EXE_RES_LOGIC;   //3'B001
                reg1_read_o <= 1'b1;          //rs read enable
                reg2_read_o <= 1'b0;          //rt read disable
                imm <= {16'h0,inst_i[15:0]};  //zero extend(16-->32)
                wd_o <= inst_i[20:16];        //rt
                instvalid <= `InstValid;      //1'b0(valid)
                end
                
            `EXE_LUI:begin  //6'b001111
                wreg_o <= `WriteEnable;       //1'b1
                aluop_o <= `EXE_OR_OP;        //8'b00100101
                alusel_o <= `EXE_RES_LOGIC;   //3'B001
                reg1_read_o <= 1'b1;          //rs read enable
                reg2_read_o <= 1'b0;          //rt read disable
                imm <= {inst_i[15:0],16'b0};  //last extend(16-->32)
                wd_o <= inst_i[20:16];        //rt
                instvalid <= `InstValid;      //1'b0(valid)
                end
                
            `EXE_ANDI:begin  //6'b001100
                wreg_o <= `WriteEnable;       //1'b1
                aluop_o <= `EXE_AND_OP;       //8'b00100100
                alusel_o <= `EXE_RES_LOGIC;   //3'B001
                reg1_read_o <= 1'b1;          //rs read enable
                reg2_read_o <= 1'b0;          //rt read disable
                imm <= {16'b0,inst_i[15:0]};
                wd_o <= inst_i[20:16];        //rt
                instvalid <= `InstValid;      //1'b0(valid)
                end
                
            `EXE_XORI:begin  //6'b001110
                wreg_o <= `WriteEnable;       //1'b1
                aluop_o <= `EXE_XOR_OP;       //8'b00100110
                alusel_o <= `EXE_RES_LOGIC;   //3'B001
                reg1_read_o <= 1'b1;          //rs read enable
                reg2_read_o <= 1'b0;          //rt read disable
                imm <= {16'b0,inst_i[15:0]};
                wd_o <= inst_i[20:16];        //rt
                instvalid <= `InstValid;      //1'b0(valid)
                end
                
            `EXE_ADDI:begin
                wreg_o <= `WriteEnable;
                aluop_o <= `EXE_ADD_OP;
                alusel_o <= `EXE_RES_ARITHMETIC;
                reg1_read_o <= 1'b1;          //rs read enable
                reg2_read_o <= 1'b0;          //rt read disable
                imm <= {{16{inst_i[15]}},inst_i[15:0]};
                wd_o <= inst_i[20:16];        //rt
                instvalid <= `InstValid;      //1'b0(valid)
                end
            
            `EXE_ADDIU:begin
                wreg_o <= `WriteEnable;
                aluop_o <= `EXE_ADDU_OP;
                alusel_o <= `EXE_RES_ARITHMETIC;
                reg1_read_o <= 1'b1;          //rs read enable
                reg2_read_o <= 1'b0;          //rt read disable
                imm <= {{16{inst_i[15]}},inst_i[15:0]};
                wd_o <= inst_i[20:16];        //rt
                instvalid <= `InstValid;      //1'b0(valid)
                end
                
            `EXE_SLTI:begin
                wreg_o <= `WriteEnable;
                aluop_o <= `EXE_SLT_OP;
                alusel_o <= `EXE_RES_ARITHMETIC;
                reg1_read_o <= 1'b1;          //rs read enable
                reg2_read_o <= 1'b0;          //rt read disable
                imm <= {{16{inst_i[15]}},inst_i[15:0]};
                wd_o <= inst_i[20:16];        //rt
                instvalid <= `InstValid;      //1'b0(valid)
                end
                
            `EXE_SLTIU:begin
                wreg_o <= `WriteEnable;
                aluop_o <= `EXE_SLTU_OP;
                alusel_o <= `EXE_RES_ARITHMETIC;
                reg1_read_o <= 1'b1;          //rs read enable
                reg2_read_o <= 1'b0;          //rt read disable
                imm <= {{16{inst_i[15]}},inst_i[15:0]};
                wd_o <= inst_i[20:16];        //rt
                instvalid <= `InstValid;      //1'b0(valid)
                end
                
            `EXE_LB:begin
                wreg_o <= `WriteEnable;
                aluop_o <= `EXE_LB_OP;
                alusel_o <= `EXE_RES_NOP;
                reg1_read_o <= 1'b1;          //rs read enable
                reg2_read_o <= 1'b0;          //rt read disable
                wd_o <= inst_i[20:16];        //rt
                instvalid <= `InstValid;      //1'b0(valid)
                end
                
            `EXE_LBU:begin
                wreg_o <= `WriteEnable;
                aluop_o <= `EXE_LBU_OP;
                alusel_o <= `EXE_RES_NOP;
                reg1_read_o <= 1'b1;          //rs read enable
                reg2_read_o <= 1'b0;          //rt read disable
                wd_o <= inst_i[20:16];        //rt
                instvalid <= `InstValid;      //1'b0(valid)
                end
                
            `EXE_LH:begin
                wreg_o <= `WriteEnable;
                aluop_o <= `EXE_LH_OP;
                alusel_o <= `EXE_RES_NOP;
                reg1_read_o <= 1'b1;          //rs read enable
                reg2_read_o <= 1'b0;          //rt read disable
                wd_o <= inst_i[20:16];        //rt
                instvalid <= `InstValid;      //1'b0(valid)
                end
                
            `EXE_LHU:begin
                wreg_o <= `WriteEnable;
                aluop_o <= `EXE_LHU_OP;
                alusel_o <= `EXE_RES_NOP;
                reg1_read_o <= 1'b1;          //rs read enable
                reg2_read_o <= 1'b0;          //rt read disable
                wd_o <= inst_i[20:16];        //rt
                instvalid <= `InstValid;      //1'b0(valid)
                end
                
            `EXE_LW:begin
                wreg_o <= `WriteEnable;
                aluop_o <= `EXE_LW_OP;
                alusel_o <= `EXE_RES_NOP;
                reg1_read_o <= 1'b0;          //rs read disable
                reg2_read_o <= 1'b0;          //rt read disable
                wd_o <= inst_i[20:16];        //rt
                instvalid <= `InstValid;      //1'b0(valid)
                end
                            
            `EXE_LWL:begin
                wreg_o <= `WriteEnable;
                aluop_o <= `EXE_LWL_OP;
                alusel_o <= `EXE_RES_NOP;
                reg1_read_o <= 1'b1;          //rs read enable
                reg2_read_o <= 1'b1;          //rt read enable
                wd_o <= inst_i[20:16];        //rt
                instvalid <= `InstValid;      //1'b0(valid)
                end
            
            `EXE_LWR:begin
                wreg_o <= `WriteEnable;
                aluop_o <= `EXE_LWR_OP;
                alusel_o <= `EXE_RES_NOP;
                reg1_read_o <= 1'b1;          //rs read enable
                reg2_read_o <= 1'b1;          //rt read enable
                wd_o <= inst_i[20:16];        //rt
                instvalid <= `InstValid;      //1'b0(valid)
                end
                
            `EXE_SH:begin
                wreg_o <= `WriteDisable;
                aluop_o <= `EXE_SH_OP;
                alusel_o <= `EXE_RES_NOP;
                reg1_read_o <= 1'b1;          //rs read enable
                reg2_read_o <= 1'b1;          //rt read enable
                instvalid <= `InstValid;      //1'b0(valid)
                end
                
            `EXE_SB:begin
                wreg_o <= `WriteDisable;
                aluop_o <= `EXE_SB_OP;
                alusel_o <= `EXE_RES_NOP;
                reg1_read_o <= 1'b1;          //rs read enable
                reg2_read_o <= 1'b1;          //rt read enable
                instvalid <= `InstValid;      //1'b0(valid)
                end
            
            `EXE_SW:begin
                wreg_o <= `WriteDisable;
                aluop_o <= `EXE_SW_OP;
                alusel_o <= `EXE_RES_NOP;
                reg1_read_o <= 1'b1;          //rs read enable
                reg2_read_o <= 1'b1;          //rt read enable
                instvalid <= `InstValid;      //1'b0(valid)
                end
            
            `EXE_SWL:begin
                wreg_o <= `WriteDisable;
                aluop_o <= `EXE_SW_OP;
                alusel_o <= `EXE_RES_NOP;
                reg1_read_o <= 1'b1;          //rs read enable
                reg2_read_o <= 1'b1;          //rt read enable
                instvalid <= `InstValid;      //1'b0(valid)
                end
            
            `EXE_SWR:begin
                wreg_o <= `WriteDisable;
                aluop_o <= `EXE_SW_OP;
                alusel_o <= `EXE_RES_NOP;
                reg1_read_o <= 1'b1;          //rs read enable
                reg2_read_o <= 1'b1;          //rt read enable
                instvalid <= `InstValid;      //1'b0(valid)
                end
            
            `EXE_BEQ:begin
                if (inst_i[25:21] == 5'b00000 && inst_i[20:16] == 5'b00000) begin  // b 指令
                    wreg_o <= `WriteDisable;
                    aluop_o <= `EXE_NOP_OP;
                    alusel_o <= `EXE_RES_NOP;
                    reg1_read_o <= 1'b0;
                    reg2_read_o <= 1'b0;
                    branch_flag_o <= `Branch;
                    branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
                    next_inst_in_delayslot_o <= `InDelaySlot;
                    instvalid <= `InstValid;
                end else begin
                wreg_o <= `WriteDisable;
                aluop_o <= `EXE_NOP_OP;
                alusel_o <= `EXE_RES_NOP;
                reg1_read_o <= 1'b1;          //rs read enable
                reg2_read_o <= 1'b1;          //rt read disable
                if(reg1_o == reg2_o) begin
                    branch_flag_o <= `Branch;
                    branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
                    next_inst_in_delayslot_o <= `InDelaySlot;
                    end
                instvalid <= `InstValid;      //1'b0(valid)
                end
            end
                
            `EXE_BGTZ:begin
                wreg_o <= `WriteDisable;
                aluop_o <= `EXE_NOP_OP;
                alusel_o <= `EXE_RES_NOP;
                reg1_read_o <= 1'b1;          //rs read enable
                reg2_read_o <= 1'b1;          //rt read disable
                if(reg1_o[31] == 1'b0) begin
                    branch_flag_o <= `Branch;
                    branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
                    next_inst_in_delayslot_o <= `InDelaySlot;
                    end
                instvalid <= `InstValid;      //1'b0(valid)
                end
                
            `EXE_BLEZ:begin
                wreg_o <= `WriteDisable;
                aluop_o <= `EXE_NOP_OP;
                alusel_o <= `EXE_RES_NOP;
                reg1_read_o <= 1'b1;          //rs read enable
                reg2_read_o <= 1'b1;          //rt read disable
                if(reg1_o == `ZeroWord || reg1_o[31] == 1'b1) begin
                    branch_flag_o <= `Branch;
                    branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
                    next_inst_in_delayslot_o <= `InDelaySlot;
                    end
                instvalid <= `InstValid;      //1'b0(valid)
                end
                
            `EXE_BNE:begin
                wreg_o <= `WriteDisable;
                aluop_o <= `EXE_NOP_OP;
                alusel_o <= `EXE_RES_NOP;
                reg1_read_o <= 1'b1;          //rs read enable
                reg2_read_o <= 1'b1;          //rt read disable
                if(reg1_o != reg2_o) begin
                    branch_flag_o <= `Branch;
                    branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
                    next_inst_in_delayslot_o <= `InDelaySlot;
                    end
                instvalid <= `InstValid;      //1'b0(valid)
                end
                
            `EXE_REGIMM_INST:begin  //6'B000001,I-type2 instruction
                
                case(inst_i[20:16])  //rt
                    `EXE_BGEZ:begin
                        wreg_o <= `WriteDisable;
                        aluop_o <= `EXE_NOP_OP;
                        alusel_o <= `EXE_RES_NOP;
                        reg1_read_o <= 1'b1;          //rs read enable
                        reg2_read_o <= 1'b0;          //rt read disable
                        if(reg1_o == `ZeroWord || reg1_o[31] == 1'b0) begin
                            branch_flag_o <= `Branch;
                            branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
                            next_inst_in_delayslot_o <= `InDelaySlot;
                            end
                        instvalid <= `InstValid;      //1'b0(valid)
                        end
                        
                    `EXE_BLTZ:begin
                        wreg_o <= `WriteDisable;
                        aluop_o <= `EXE_NOP_OP;
                        alusel_o <= `EXE_RES_NOP;
                        reg1_read_o <= 1'b1;          //rs read enable
                        reg2_read_o <= 1'b0;          //rt read disable
                        if(reg1_o[31] == 1'b1) begin
                            branch_flag_o <= `Branch;
                            branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
                            next_inst_in_delayslot_o <= `InDelaySlot;
                            end
                        instvalid <= `InstValid;      //1'b0(valid)
                        end
                        
                    `EXE_BLTZAL:begin
                        wreg_o <= `WriteEnable;
                        aluop_o <= `EXE_NOP_OP;
                        alusel_o <= `EXE_RES_JUMP_BRANCH;
                        reg1_read_o <= 1'b1;          //rs read enable
                        reg2_read_o <= 1'b0;          //rt read disable
                        wd_o <= 5'b11111;
                        if(reg1_o[31] == 1'b1) begin
                            link_addr_o <= pc_plus_8;
                            branch_flag_o <= `Branch;
                            branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
                            next_inst_in_delayslot_o <= `InDelaySlot;
                            end
                        instvalid <= `InstValid;      //1'b0(valid)
                        end
                        
                    `EXE_BGEZAL:begin
                        if (inst_i[25:21] == 5'b00000) begin  // bal
                            wreg_o <= `WriteEnable;
                            aluop_o <= `EXE_NOP_OP;
                            alusel_o <= `EXE_RES_JUMP_BRANCH;
                            reg1_read_o <= 1'b0;
                            reg2_read_o <= 1'b0;
                            wd_o <= `RegNumLog2'd31;
                            link_addr_o <= pc_plus_8;
                            branch_flag_o <= `Branch;
                            branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
                            next_inst_in_delayslot_o <= `InDelaySlot;
                            instvalid <= `InstValid;
                        end 
                        else begin
                            wreg_o <= `WriteEnable;
                            aluop_o <= `EXE_NOP_OP;
                            alusel_o <= `EXE_RES_JUMP_BRANCH;
                            reg1_read_o <= 1'b1;          //rs read enable
                            reg2_read_o <= 1'b0;          //rt read disable
                            wd_o <= 5'b11111;
                            link_addr_o <= pc_plus_8;
                            if(reg1_o == `ZeroWord || reg1_o[31] == 1'b0) begin
                                branch_flag_o <= `Branch;
                                branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
                                next_inst_in_delayslot_o <= `InDelaySlot;
                                end
                            instvalid <= `InstValid;      //1'b0(valid)
                            end
                        end
                        
                    default:begin
                        end
                    endcase
                end
            
            `EXE_NOP:begin
                wreg_o <= `WriteDisable;
                aluop_o <= `EXE_NOP_OP;
                alusel_o <= `EXE_RES_NOP;
                reg1_read_o <= 1'b0;         //rs read disable
                reg2_read_o <= 1'b0;         //rt read disable        
                instvalid <= `InstInvalid;
                end
            
            `EXE_J:begin
                wreg_o <= `WriteEnable;
                aluop_o <= `EXE_NOP_OP;
                alusel_o <= `EXE_RES_JUMP_BRANCH;
                reg1_read_o <= 1'b0;         //rs read disable
                reg2_read_o <= 1'b0;         //rt read disable        
                branch_flag_o <= `Branch;
                branch_target_address_o <= {branch_target_address_o[31:28],inst_i[25:0],2'b00};
                next_inst_in_delayslot_o <= `InDelaySlot;
                instvalid <= `InstValid;
                end
                
            `EXE_JAL:begin
                wreg_o <= `WriteEnable;
                aluop_o <= `EXE_NOP_OP;
                alusel_o <= `EXE_RES_JUMP_BRANCH;
                reg1_read_o <= 1'b0;         //rs read disable
                reg2_read_o <= 1'b0;         //rt read disable
                wd_o <= 5'b11111;        
                link_addr_o <= pc_plus_8;
                branch_flag_o <= `Branch;
                branch_target_address_o <= {branch_target_address_o[31:28],inst_i[25:0],2'b00};
                next_inst_in_delayslot_o <= `InDelaySlot;
                instvalid <= `InstValid;
                end
            
            default:begin
                end
            endcase
        end
    end
    
always@(*) begin  //Source operand:reg1_o
    if(rst == `RstEnable)     //1'b1
        reg1_o <= `ZeroWord;  //32'h00000000
    
    //Data dependent--RAW
    else if((reg1_read_o == 1'b1) && (ex_wreg_i ==1'b1) && (ex_wd_i ==reg1_addr_o))  //C1
        reg1_o <= ex_wdata_i;
    else if((reg1_read_o == 1'b1) && (mem_wreg_i ==1'b1) && (mem_wd_i ==reg1_addr_o))  //C2
        reg1_o <= mem_wdata_i;
        
    else if(reg1_read_o ==1'b1)
        reg1_o <= reg1_data_i;
    else if(reg1_read_o ==1'b0)
        reg1_o <= imm;
    else
        reg1_o <= `ZeroWord;
    end
    
always@(*) begin  //Source operand:reg2_o
    if(rst == `RstEnable)
        reg2_o <= `ZeroWord;
    
    //Data dependent--RAW
    else if((reg2_read_o == 1'b1) && (ex_wreg_i ==1'b1) && (ex_wd_i ==reg2_addr_o))  //C1
        reg2_o <= ex_wdata_i;
    else if((reg2_read_o == 1'b1) && (mem_wreg_i ==1'b1) && (mem_wd_i ==reg2_addr_o))  //C2
        reg2_o <= mem_wdata_i;
    
    else if(reg2_read_o ==1'b1)
        reg2_o <= reg2_data_i;
    else if(reg2_read_o ==1'b0)
        reg2_o <= imm;
    else
        reg2_o <= `ZeroWord;
    end
    
always@(*)begin  //is_in_delayslot_o
    if(rst == `RstEnable)
        is_in_delayslot_o <= `NotInDelaySlot;
    else
        is_in_delayslot_o <= is_in_delayslot_i;
    end
    
endmodule
