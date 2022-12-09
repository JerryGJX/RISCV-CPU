//wire status
`define TRUE 1'b1
`define FALSE 1'b0


//element type
`define INST_TYPE 31:0
`define ADDR_TYPE 31:0
`define IMM_TYPE 31:0//for imm
`define DATA_TYPE 31:0//for data
`define NUM_TYPE 31:0


//position type
`define REG_POS_TYPE 4:0//for rs1,rs2,rd
`define ROB_POS_TYPE 3:0
`define RS_POS_TYPE 3:0
`define LSB_POS_TYPE 3:0

//size of element
`define ROB_SIZE 32'd16
`define RS_SIZE 32'd16
`define REG_SIZE 32'd32
`define LSB_SIZE 32'd16


//default value
`define BLANK_INS 32'd0
`define BLANK_ADDR 32'd0
`define PC_DEFALT_STEP 32'd4



`define OPENUM_TYPE 5:0
//opEnum
`define OPENUM_ADD 6'd0
`define OPENUM_SUB 6'd1
`define OPENUM_XOR 6'd2
`define OPENUM_OR 6'd3
`define OPENUM_AND 6'd4
`define OPENUM_SLL 6'd5
`define OPENUM_SRL 6'd6
`define OPENUM_SRA 6'd7
`define OPENUM_SLT 6'd8
`define OPENUM_SLTU 6'd9
//imm[5:11]
`define OPENUM_ADDI 6'd10
`define OPENUM_XORI 6'd11
`define OPENUM_ORI 6'd12
`define OPENUM_ANDI 6'd13
`define OPENUM_SLLI 6'd14
`define OPENUM_SRLI 6'd15
`define OPENUM_SRAI 6'd16
`define OPENUM_SLTI 6'd17
`define OPENUM_SLTIU 6'd18
//load
`define OPENUM_LB 6'd19
`define OPENUM_LH 6'd20
`define OPENUM_LW 6'd21
`define OPENUM_LBU 6'd22
`define OPENUM_LHU 6'd23
//store
`define OPENUM_SB 6'd24
`define OPENUM_SH 6'd25
`define OPENUM_SW 6'd26
//branch
`define OPENUM_BEQ 6'd27
`define OPENUM_BNE 6'd28
`define OPENUM_BLT 6'd29
`define OPENUM_BGE 6'd30
`define OPENUM_BLTU 6'd31
`define OPENUM_BGEU 6'd32
//jump
`define OPENUM_JAL 6'd33
`define OPENUM_JALR 6'd34
//system
`define OPENUM_LUI 6'd35
`define OPENUM_AUIPC 6'd36

//`define OPENUM_ECALL 6'd35







