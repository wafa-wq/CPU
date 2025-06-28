//**********Global macro definition**********
`define RstEnable 1'b1         //Reset signal is valid
`define RstDisable 1'b0       //Invalid reset signal
`define ZeroWord 32'h00000000
`define ChipEnable 1'b1        //Chip enable
`define ChipDisable 1'b0       //Chip disable
`define WriteEnable 1'b1       //Enable writing
`define WriteDisable 1'b0      //Prohibit writing
`define ReadEnable 1'b1        //Enable reading
`define ReadDisable 1'b0       //Prohibit reading

`define Stop 1'b1              //pipeline pause
`define NoStop 1'b0            //pipeline resume, or not pause

//**********Instruction**********
`define InstValid 1'b0         //Instruction valid
`define InstInvalid 1'b1       //Instruction invalid
`define EXE_NOP 6'b000000
`define EXE_ORI 6'b001101      //ori OP

`define EXE_SPECIAL_INST 6'b000000  //R_type instrution
`define EXE_AND 6'b100100      //and func
`define EXE_OR 6'b100101       //or func
`define EXE_XOR 6'b100110      //xor func
`define EXE_NOR 6'b100111      //nor func
`define EXE_ANDI 6'b001100     //andi OP
`define EXE_XORI 6'b001110     //xori OP
`define EXE_LUI 6'b001111      //lui OP

`define EXE_SLL 6'b000000      //sll func
`define EXE_SLLV 6'b000100     //sllv func
`define EXE_SRL 6'b000010      //srl func
`define EXE_SRLV 6'b000110     //srlv func
`define EXE_SRA 6'b000011      //sra func
`define EXE_SRAV 6'b000111     //srav func

`define EXE_MOVZ 6'b001010      //movz func
`define EXE_MOVN 6'b001011      //movn func
`define EXE_MFHI 6'b010000      //mfhi func
`define EXE_MTHI 6'b010001      //mthi func
`define EXE_MFLO 6'b010010      //mflo func
`define EXE_MTLO 6'b010011      //mtlo func

`define EXE_SPECIAL2_INST 6'b011100      //R_type2 instrution
`define EXE_SLT 6'b101010       //slt func
`define EXE_SLTU 6'b101011      //sltu func
`define EXE_SLTI 6'b001010      //slti func
`define EXE_SLTIU 6'b001011     //sltiu func
`define EXE_ADD 6'b100000       //add func
`define EXE_ADDU 6'b100001      //addu func
`define EXE_SUB 6'b100010       //sub func
`define EXE_SUBU 6'b100011      //subu func
`define EXE_ADDI 6'b001000      //addi func
`define EXE_ADDIU 6'b001001     //addiu func
`define EXE_CLZ 6'b100000       //clz func
`define EXE_CLO 6'b100001       //clo func
`define EXE_MULT 6'b011000      //mult func
`define EXE_MULTU 6'b011001     //multu func
`define EXE_MUL 6'b000010       //mul func

`define EXE_MADD 6'b000000       //madd func
`define EXE_MADDU 6'b000001      //maddu func
`define EXE_MSUB 6'b000100       //msub func
`define EXE_MSUBU 6'b000101      //msubu func

`define EXE_DIV 6'b011010        //div func
`define EXE_DIVU 6'b011011       //divu func

`define EXE_JR 6'b001000         //jr func
`define EXE_JALR 6'b001001       //jalr func
`define EXE_J 6'b000010          //j op
`define EXE_JAL 6'b000011        //jal op

`define EXE_BEQ 6'b000100        //beq or b op
`define EXE_BGTZ 6'b000111       //bgtz op
`define EXE_BLEZ 6'b000110       //blez op
`define EXE_BNE 6'b000101        //bne op

`define EXE_REGIMM_INST 6'b000001       //I-type2 instrution
`define EXE_BGEZ 5'b00001        //bgez rt
`define EXE_BGEZAL 5'b10001      //bgezal or bal rt
`define EXE_BLTZ 5'b00000        //bltz rt
`define EXE_BLTZAL 5'b10000      //bltzal rt

`define EXE_LB 6'b100000         //lb op
`define EXE_LBU 6'b100100        //lbu op
`define EXE_LH 6'b100001         //lh op
`define EXE_LHU 6'b100101        //lhu op
`define EXE_LW 6'b100011         //lw op
`define EXE_LWL 6'b100010        //lwl op
`define EXE_LWR 6'b100110        //lwr op
`define EXE_SB 6'b101000         //sb op
`define EXE_SH 6'b101001         //sh op
`define EXE_SW 6'b101011         //sw op
`define EXE_SWL 6'b101010        //swl op
`define EXE_SWR 6'b101110        //swr op

//**********ALU**********
//AluOp
`define AluOpBus 7:0           //signal aluop_o width
`define EXE_NOP_OP 8'b00000000
`define EXE_OR_OP 8'b00100101  //可随意更改，不重复

`define EXE_AND_OP 8'b00100100
`define EXE_XOR_OP 8'b00100110
`define EXE_NOR_OP 8'B00100111
`define EXE_SLL_OP 8'b01111100
`define EXE_SRL_OP 8'b00000010
`define EXE_SRA_OP 8'b00000011

`define EXE_MOVZ_OP 8'b00001010
`define EXE_MOVN_OP 8'b00001011
`define EXE_MFHI_OP 8'b00010000
`define EXE_MTHI_OP 8'b00010001
`define EXE_MFLO_OP 8'b00010010
`define EXE_MTLO_OP 8'b00010011

`define EXE_SLT_OP 8'b00101010
`define EXE_SLTU_OP 8'b00101011
`define EXE_ADD_OP 8'b00100000
`define EXE_ADDU_OP 8'b00100001
`define EXE_SUB_OP 8'b00100010
`define EXE_SUBU_OP 8'b00100011
`define EXE_CLZ_OP 8'b10110000
`define EXE_CLO_OP 8'b10110001
`define EXE_MULT_OP 8'b00011000
`define EXE_MULTU_OP 8'b00011001
`define EXE_MUL_OP 8'b10101001

`define EXE_MADD_OP 8'b10100110
`define EXE_MADDU_OP 8'b10101000
`define EXE_MSUB_OP 8'b10101010
`define EXE_MSUBU_OP 8'b10101011

`define EXE_DIV_OP 6'b00011010
`define EXE_DIVU_OP 6'b00011011

`define EXE_LB_OP 8'b11100000
`define EXE_LBU_OP 8'b11100100
`define EXE_LH_OP 8'b11100001
`define EXE_LHU_OP 8'b11100101
`define EXE_LW_OP 8'b11100011
`define EXE_LWL_OP 8'b11100010
`define EXE_LWR_OP 8'b11100110
`define EXE_SB_OP 8'b11101000
`define EXE_SH_OP 8'b11101001
`define EXE_SW_OP 8'b11101011
`define EXE_SWL_OP 8'b11101010
`define EXE_SWR_OP 8'b11101110

//AluSel
`define AluSelBus 2:0          //signal alusel_o width alu输出控制
`define EXE_RES_NOP 3'b000
`define EXE_RES_LOGIC 3'b001   //可随意更改，不重复
`define EXE_RES_SHIFT 3'B010
`define EXE_RES_MOVE 3'B011
`define EXE_RES_ARITHMETIC 3'B100
`define EXE_RES_MUL 3'B101
`define EXE_RES_JUMP_BRANCH 3'B110

//**********DIV**********
//FSM
`define DivFree 2'b00
`define DivByZero 2'b01
`define DivOn 2'b10
`define DivEnd 2'b11

//Control
`define DivResultReady 1'b1
`define DivResultNotReady 1'b0
`define DivStart 1'b1
`define DivStop 1'b0

//**********Instruction memory:ROM**********
`define InstAddrBus 31:0       //Address bus width
`define InstBus 31:0           //Data bus width
`define InstMemNum 1024        //1024*32(4KB)
`define InstMemNumLog2 10      //Number of address lines

//**********Data memory:DM**********
`define DataAddrBus 31:0       //Address bus width
`define DataBus 31:0           //Data bus width
`define DataMemNum 1024        //1024*32(4KB)
`define DataMemNumLog2 10      //Number of address lines
`define ByteWidth 7:0          //Byte width

//**********General register:Regfile**********
`define RegAddrBus 4:0         //Address bus width
`define RegBus 31:0            //Data bus width
`define RegNum 32              //Number of general registers
`define RegNumLog2 5           //Address bits of general register
`define NOPRegAddr 5'b00000

`define DoubleRegBus 63:0

//**********branch**********
`define Branch 1'b1
`define NotBranch 1'b0

`define InDelaySlot 1'b1
`define NotInDelaySlot 1'b0