`include "riscv/src/definition.v"

module decoder (
    input wire clk,
    input wire rst,
    input wire rdy,
    input wire clr,


    //from ifetch
    input wire                inst_enable,
    input wire [  `INST_TYPE] inst_val,
    input wire [`OPENUM_TYPE] inst_openum,
    input wire [  `ADDR_TYPE] inst_pc,
    input wire                inst_pred_jump,
    input wire                inst_lsb_enable,
    input wire                inst_rs_enable,


    //issue
    output reg                      issue_enable,
    //controlled by ifetch
    output reg [      `OPENUM_TYPE] issue_openum,
    output reg [     `REG_POS_TYPE] issue_rd,
    output reg [        `DATA_TYPE] issue_rs1_val,
    output reg [`ROB_WRAP_POS_TYPE] issue_rs1_rob_pos,
    output reg [        `DATA_TYPE] issue_rs2_val,
    output reg [`ROB_WRAP_POS_TYPE] issue_rs2_rob_pos,
    output reg [        `DATA_TYPE] issue_imm,
    output reg [        `ADDR_TYPE] issue_pc,
    output reg                      issue_pred_jump,
    output reg                      issue_ready_inst,
    //for load
    output reg [`ROB_WRAP_POS_TYPE] issue_rob_pos,

    //with regfile
    output reg [`REG_POS_TYPE] reg_rs1_pos,
    output reg [`REG_POS_TYPE] reg_rs2_pos,
    input  reg [   `DATA_TYPE] reg_rs1_val,
    input  reg [`ROB_WRAP_POS_TYPE] reg_rs1_rob_pos,
    input  reg [   `DATA_TYPE] reg_rs2_val,
    input  reg [`ROB_WRAP_POS_TYPE] reg_rs2_rob_pos,

    //with rob
    output reg [`ROB_WRAP_POS_TYPE] rob_rs1_pos,
    input  reg                      rob_rs1_ready,
    input  reg [        `DATA_TYPE] rob_rs1_val,
    output reg [`ROB_WRAP_POS_TYPE] rob_rs2_pos,
    input  reg                      rob_rs2_ready,
    input  reg [        `DATA_TYPE] rob_rs2_val,
    input  reg [`ROB_WRAP_POS_TYPE] next_rob_pos,

    //with alu
    input wire                      alu_result_ready,
    input wire [`ROB_WRAP_POS_TYPE] alu_result_rob_pos,
    input wire [        `DATA_TYPE] alu_result_val,

    //with lsb
    input wire                      lsb_load_result_ready,
    input wire [`ROB_WRAP_POS_TYPE] lsb_load_result_rob_pos,
    input wire [        `DATA_TYPE] lsb_load_result_val,

    //out control
    output reg rs_enable,
    output reg lsb_enable
);

  assign reg_rs1_pos = inst_val[`RS1_RANGE];
  assign reg_rs2_pos = inst_val[`RS2_RANGE];
  assign rob_rs1_pos = reg_rs1_rob_pos;
  assign rob_rs2_pos = reg_rs2_rob_pos;

  always @(*) begin
    if (rst || !inst_enable || clr) begin
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


      issue_openum = inst_openum;
      rs_enable = inst_rs_enable;
      lsb_enable = inst_lsb_enable;
      issue_ready_inst = `FALSE;
      issue_rd = inst_val[`RD_RANGE];

      case (inst_val[`OPCODE_RANGE])

        `OPCODE_RC: begin
        end

        `OPCODE_RI: begin
          issue_rs2_rob_pos = 0;
          issue_rs2_val = 0;
          issue_imm = {{21{inst_val[31]}}, inst_val[30:20]};

        end

        `OPCODE_LD: begin
          issue_rs2_rob_pos = 0;
          issue_rs2_val = 0;
          issue_imm = {{21{inst_val[31]}}, inst_val[30:20]};
        end

        `OPCODE_ST: begin
          issue_rd = 0;
          issue_ready_inst = `TRUE;
          issue_imm = {{21{inst_val[31]}}, inst_val[30:25], inst_val[11:7]};
        end

        `OPCODE_BR: begin
          issue_rd  = 0;
          issue_imm = {{20{inst_val[31]}}, inst_val[7], inst_val[30:25], inst_val[11:8], 1'b0};
        end

        `OPCODE_JAL: begin
          issue_rs1_rob_pos = 0;
          issue_rs1_val = 0;
          issue_rs2_rob_pos = 0;
          issue_rs2_val = 0;
          issue_imm = {{12{inst_val[31]}}, inst_val[19:12], inst_val[20], inst_val[30:21], 1'b0};
        end

        `OPCODE_JALR: begin
          issue_rs2_rob_pos = 0;
          issue_rs2_val = 0;
          issue_imm = {{21{inst_val[31]}}, inst_val[30:20]};
        end

        `OPCODE_LUI: begin
          issue_rs1_rob_pos = 0;
          issue_rs1_val = 0;
          issue_rs2_rob_pos = 0;
          issue_rs2_val = 0;
          issue_imm = {inst_val[31:12], 12'b0};
        end

        `OPCODE_AUIPC: begin
          issue_rs1_rob_pos = 0;
          issue_rs1_val = 0;
          issue_rs2_rob_pos = 0;
          issue_rs2_val = 0;
          issue_imm = {inst_val[31:12], 12'b0};
        end
        default;
      endcase
    end
  end




endmodule
