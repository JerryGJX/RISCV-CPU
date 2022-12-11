`include "riscv/src/definition.v"

module decoder (
    input wire clk,
    input wire rst,
    input wire rdy,
    input wire rollback,


    //from ifetch
    input wire              inst_enable,
    input wire [`INST_TYPE] inst,
    input wire [`ADDR_TYPE] inst_pc,
    input wire              inst_pred_jump,


    //to issue
    output reg                 issue_enable,
    //controlled by ifetch
    output reg [ `OPENUM_TYPE] issue_openum,
    output reg [`REG_POS_TYPE] issue_rd,
    output reg [   `DATA_TYPE] issue_rs1_val,
    output reg [`ROB_POS_TYPE] issue_rs1_rob_pos,
    output reg [   `DATA_TYPE] issue_rs2_val,
    output reg [`ROB_POS_TYPE] issue_rs2_rob_pos,
    output reg [    `IMM_TYPE] issue_imm,
    output reg [   `ADDR_TYPE] issue_pc,
    output reg                 issue_pred_jump,
    output reg                 issue_ready_inst,
    //for load
    output reg [`ROB_POS_TYPE] issue_rob_pos,

    //with regfile
    output reg [`REG_POS_TYPE] reg_rs1_pos,
    output reg [`REG_POS_TYPE] reg_rs2_pos,
    input  reg [   `DATA_TYPE] reg_rs1_val,
    input  reg [`ROB_POS_TYPE] reg_rs1_rob_pos,
    input  reg [   `DATA_TYPE] reg_rs2_val,
    input  reg [`ROB_POS_TYPE] reg_rs2_rob_pos,

    //with rob
    output reg [`ROB_POS_TYPE] rob_rs1_pos,
    input  reg                 rob_rs1_ready,
    input  reg [   `DATA_TYPE] rob_rs1_val,
    output reg [`ROB_POS_TYPE] rob_rs2_pos,
    input  reg                 rob_rs2_ready,
    input  reg [   `DATA_TYPE] rob_rs2_val,
    input  reg [`ROB_POS_TYPE] next_rob_pos,

    //with alu
    input wire                 alu_result_ready,
    input wire [`ROB_POS_TYPE] alu_result_rob_pos,
    input wire [   `DATA_TYPE] alu_result_val,

    //with lsb
    input wire                 lsb_load_result_ready,
    input wire [`ROB_POS_TYPE] lsb_load_result_rob_pos,
    input wire [   `DATA_TYPE] lsb_load_result_val,

    //out control
    output reg rs_enable,
    output reg lsb_enable
);

  assign reg_rs1_pos = inst[`RS1_RANGE];
  assign reg_rs2_pos = inst[`RS2_RANGE];
  assign rob_rs1_pos = reg_rs1_rob_pos;
  assign rob_rs2_pos = reg_rs2_rob_pos;

  always @(*) begin
    if (rst || !inst_enable || rollback) begin
      issue_enable = `FALSE;
      rs_enable = `FALSE;
      lsb_enable = `FALSE;
    end else if (!rdy) begin
      ;
    end else begin
      issue_enable = `TRUE;
      issue_rob_pos = next_rob_pos;
      issue_rs1_rob_pos = 0;
      if (reg_rs1_rob_pos == 0) begin
        issue_rs1_val = reg_rs1_val;
      end else if (rob_rs1_ready) begin
        issue_rs1_val = rob_rs1_val;
      end else if (alu_result_ready && alu_result_rob_pos == reg_rs1_rob_pos) begin
        issue_rs1_val = alu_result_val;
      end else if (lsb_load_result_ready && lsb_load_result_rob_pos == reg_rs1_rob_pos) begin
        issue_rs1_val = lsb_load_result_val;
      end else begin
        issue_rs1_val = 0;
        issue_rs1_rob_pos = reg_rs1_rob_pos;
      end

      issue_rs2_rob_pos = 0;
      if (reg_rs2_rob_pos == 0) begin
        issue_rs2_val = reg_rs2_val;
      end else if (rob_rs2_ready) begin
        issue_rs2_val = rob_rs2_val;
      end else if (alu_result_ready && alu_result_rob_pos == reg_rs2_rob_pos) begin
        issue_rs2_val = alu_result_val;
      end else if (lsb_load_result_ready && lsb_load_result_rob_pos == reg_rs2_rob_pos) begin
        issue_rs2_val = lsb_load_result_val;
      end else begin
        issue_rs2_val = 0;
        issue_rs2_rob_pos = reg_rs2_rob_pos;
      end

      rs_enable = `FALSE;
      lsb_enable = `FALSE;
      issue_ready_inst = `FALSE;
      issue_rd = inst[`RD_RANGE];

      case (inst[`OPCODE_RANGE])

        `OPCODE_RC: begin
          rs_enable = `TRUE;
          case (inst[`FUNC3_RANGE])
            `FUNC3_ADD_SUB: begin
              case (inst[`FUNC7_RANGE])
                `FUNC7_ADD: begin
                  issue_openum = `OPENUM_ADD;
                end
                `FUNC7_SUB: begin
                  issue_openum = `OPENUM_SUB;
                end
                default;
              endcase
            end
            `FUNC3_XOR: begin
              issue_openum = `OPENUM_XOR;
            end
            `FUNC3_OR: begin
              issue_openum = `OPENUM_OR;
            end
            `FUNC3_AND: begin
              issue_openum = `OPENUM_AND;
            end
            `FUNC3_SLL: begin
              issue_openum = `OPENUM_SLL;
            end
            `FUNC3_SRL_SRA: begin
              case (inst[`FUNC7_RANGE])
                `FUNC7_SRL: begin
                  issue_openum = `OPENUM_SRL;
                end
                `FUNC7_SRA: begin
                  issue_openum = `OPENUM_SRA;
                end
                default;
              endcase
            end
            `FUNC3_SLT: begin
              issue_openum = `OPENUM_SLT;
            end
            `FUNC3_SLTU: begin
              issue_openum = `OPENUM_SLTU;
            end
            default;
          endcase
        end

        `OPCODE_RI: begin
          rs_enable = `TRUE;
          issue_rs2_rob_pos = 0;
          issue_rs2_val = 0;
          issue_imm = {{21{inst[31]}}, inst[30:20]};
          case (inst[`FUNC3_RANGE])
            `FUNC3_ADDI: begin
              issue_openum = `OPENUM_ADDI;
            end
            `FUNC3_XORI: begin
              issue_openum = `OPENUM_XORI;
            end
            `FUNC3_ORI: begin
              issue_openum = `OPENUM_ORI;
            end
            `FUNC3_ANDI: begin
              issue_openum = `OPENUM_ANDI;
            end
            `FUNC3_SLLI: begin
              issue_openum = `OPENUM_SLLI;
            end
            `FUNC3_SRLI_SRAI: begin
              case (inst[`FUNC7_RANGE])
                `FUNC7_SRLI: begin
                  issue_openum = `OPENUM_SRLI;
                end
                `FUNC7_SRAI: begin
                  issue_openum = `OPENUM_SRAI;
                end
                default;
              endcase
            end
            `FUNC3_SLTI: begin
              issue_openum = `OPENUM_SLTI;
            end
            `FUNC3_SLTIU: begin
              issue_openum = `OPENUM_SLTIU;
            end
            default;
          endcase
        end

        `OPCODE_LD: begin
          lsb_enable = `TRUE;
          issue_rs2_rob_pos = 0;
          issue_rs2_val = 0;
          issue_imm = {{21{inst[31]}}, inst[30:20]};
          case (inst[`FUNC3_RANGE])
            `FUNC3_LB: begin
              issue_openum = `OPENUM_LB;
            end
            `FUNC3_LH: begin
              issue_openum = `OPENUM_LH;
            end
            `FUNC3_LW: begin
              issue_openum = `OPENUM_LW;
            end
            `FUNC3_LBU: begin
              issue_openum = `OPENUM_LBU;
            end
            `FUNC3_LHU: begin
              issue_openum = `OPENUM_LHU;
            end
            default;
          endcase
        end

        `OPCODE_ST: begin
          lsb_enable = `TRUE;
          issue_rd = 0;
          issue_ready_inst = `TRUE;
          issue_imm = {{21{inst[31]}}, inst[30:25], inst[11:7]};
          case (inst[`FUNC3_RANGE])
            `FUNC3_SB: begin
              issue_openum = `OPENUM_SB;
            end
            `FUNC3_SH: begin
              issue_openum = `OPENUM_SH;
            end
            `FUNC3_SW: begin
              issue_openum = `OPENUM_SW;
            end
            default;
          endcase
        end

        `OPCODE_BR: begin
          rs_enable = `TRUE;
          issue_rd  = 0;
          issue_imm = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
          case (inst[`FUNC3_RANGE])
            `FUNC3_BEQ: begin
              issue_openum = `OPENUM_BEQ;
            end
            `FUNC3_BNE: begin
              issue_openum = `OPENUM_BNE;
            end
            `FUNC3_BLT: begin
              issue_openum = `OPENUM_BLT;
            end
            `FUNC3_BGE: begin
              issue_openum = `OPENUM_BGE;
            end
            `FUNC3_BLTU: begin
              issue_openum = `OPENUM_BLTU;
            end
            `FUNC3_BGEU: begin
              issue_openum = `OPENUM_BGEU;
            end
            default;
          endcase
        end

        `OPCODE_JAL: begin
          rs_enable = `TRUE;
          issue_rs1_rob_pos = 0;
          issue_rs1_val = 0;
          issue_rs2_rob_pos = 0;
          issue_rs2_val = 0;
          issue_imm = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
          issue_openum = `OPENUM_JAL;
        end

        `OPCODE_JALR: begin
          rs_enable = `TRUE;
          issue_rs2_rob_pos = 0;
          issue_rs2_val = 0;
          issue_imm = {{21{inst[31]}}, inst[30:20]};
          issue_openum = `OPENUM_JALR;
        end

        `OPCODE_LUI: begin
          rs_enable = `TRUE;
          issue_rs1_rob_pos = 0;
          issue_rs1_val = 0;
          issue_rs2_rob_pos = 0;
          issue_rs2_val = 0;
          issue_imm = {inst[31:12], 12'b0};
          issue_openum = `OPENUM_LUI;
        end
        
        `OPCODE_AUIPC: begin
          rs_enable = `TRUE;
          issue_rs1_rob_pos = 0;
          issue_rs1_val = 0;
          issue_rs2_rob_pos = 0;
          issue_rs2_val = 0;
          issue_imm = {inst[31:12], 12'b0};
          issue_openum = `OPENUM_AUIPC;
        end
        default;
      endcase
    end
  end




endmodule
