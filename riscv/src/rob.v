`ifndef macro_rob
`define macro_rob
`include "definition.v"

module rob (
    input wire clk,
    input wire rst,
    input wire rdy,

    output wire next_loop_full,

    //false predict & rst
    //check
    output reg rollback,
    output reg [`ADDR_TYPE] target_pc,


    //issue to rob
    input wire                 issue_enable,
    input wire [   `ADDR_TYPE] issue_pc,
    input wire [`REG_POS_TYPE] issue_rd,
    input wire [ `OPENUM_TYPE] issue_op_enum,
    input wire                 jump_flag,
    input wire                 issue_ready,
    //from predictor,if jump, the flag is positive

    //commit
    output reg [`ROB_POS_TYPE] commit_rob_pos,

    //rob to register
    output reg                 reg_commit_enable,
    output reg [`REG_POS_TYPE] reg_pos,
    output reg [   `DATA_TYPE] reg_val,

    //rob to lsb
    output reg                  store_commit_enable,
    //lsb to rob
    input  wire                 lsb_load_ready,
    input  wire [`ROB_POS_TYPE] lsb_load_rob_pos,
    input  wire [   `DATA_TYPE] lsb_load_val,

    //rob to predictor
    output reg br_commit_enable,
    output reg br_jump,
    //output reg [`ADDR_TYPE] br_pc,

    //alu to rob, alu broadcast
    input wire                 alu_result_ready,
    input wire [`ROB_POS_TYPE] alu_result_rob_pos,
    input wire [   `DATA_TYPE] alu_result_val,
    input wire                 alu_result_jump,
    input wire [   `ADDR_TYPE] alu_result_pc,

    //decoder to rob
    input  wire [`ROB_POS_TYPE] rs1_pos,
    input  wire [`ROB_POS_TYPE] rs2_pos,
    output wire                 rs1_ready,
    output wire                 rs2_ready,
    output wire [   `DATA_TYPE] rs1_val,
    output wire [   `DATA_TYPE] rs2_val,
    output wire [`ROB_POS_TYPE] next_rob_pos

    //todo

);
  reg                 ready    [`ROB_SIZE-1:0];
  reg [`REG_POS_TYPE] rd       [`ROB_SIZE-1:0];
  reg [   `DATA_TYPE] val      [`ROB_SIZE-1:0];
  reg [   `ADDR_TYPE] pc       [`ROB_SIZE-1:0];
  reg [ `OPENUM_TYPE] opEnum   [`ROB_SIZE-1:0];
  reg                 pred_jump[`ROB_SIZE-1:0];
  reg                 real_jump[`ROB_SIZE-1:0];
  reg [   `ADDR_TYPE] dest_pc  [`ROB_SIZE-1:0];

  reg [`ROB_POS_TYPE] loop_head, loop_tail;  //[loop_head,loop_tail)
  reg [`NUM_TYPE] ele_num;

  wire commit_enable = (ele_num > 0) && (ready[loop_head] == `TRUE);

  //   wire [`ROB_POS_TYPE] next_head = loop_head + (if_commit ? 4'b1 : 4'b0);
  //   wire [`ROB_POS_TYPE] next_tail = loop_tail + (issue_ready ? 4'b1 : 4'b0);
  wire [`NUM_TYPE] next_num = ele_num + (issue_ready ? 32'b1 : 32'b0) - (commit_enable ? 32'b1 : 32'b0);

  assign next_loop_full = (next_num == `ROB_SIZE);

  //form decoder
  assign rs1_ready = ready[rs1_pos];
  assign rs2_ready = ready[rs2_pos];
  assign rs1_val = val[rs1_pos];
  assign rs2_val = val[rs2_pos];

  always @(posedge clk) begin
    if (rst || rollback) begin
      loop_head <= 0;
      loop_tail <= 0;
      ele_num   <= 0;
      rollback  <= 0;
      target_pc <= 0;
      for (integer i = 0; i < `ROB_SIZE; i += 1) begin
        ready[i]     <= 0;
        rd[i]        <= 0;
        val[i]       <= 0;
        pc[i]        <= 0;
        opEnum[i]    <= 0;
        pred_jump[i] <= 0;
        //may be empty
        real_jump[i] <= 0;
        dest_pc[i]   <= 0;
      end
      reg_commit_enable   <= 0;
      store_commit_enable <= 0;
      br_commit_enable    <= 0;
    end else if (!rdy) begin
      ;
    end else begin
      ele_num <= next_num;
      if (issue_enable) begin
        ready[loop_tail]     <= issue_ready;
        rd[loop_tail]        <= issue_rd;
        opEnum[loop_tail]    <= issue_op_enum;
        pc[loop_tail]        <= issue_pc;
        pred_jump[loop_tail] <= jump_flag;
        loop_tail            <= loop_tail + 1;
      end

      if (lsb_load_ready) begin
        ready[lsb_load_rob_pos] <= `TRUE;
        val[lsb_load_rob_pos]   <= lsb_load_val;
      end

      if (alu_result_ready) begin
        ready[alu_result_rob_pos] <= `TRUE;
        val[alu_result_rob_pos] <= alu_result_val;
        real_jump[alu_result_rob_pos] <= alu_result_jump;
        dest_pc[alu_result_rob_pos] <= alu_result_pc;
      end

      reg_commit_enable <= `FALSE;
      store_commit_enable <= `FALSE;
      br_commit_enable <= `FALSE;

      if (commit_enable) begin
        commit_rob_pos <= loop_head;
        if (
        opEnum[loop_head] == `OPENUM_SB|| 
        opEnum[loop_head] == `OPENUM_SH|| 
        opEnum[loop_head] == `OPENUM_SW ) begin
          store_commit_enable <= `TRUE;
        end else if (
        opEnum[loop_head] == `OPENUM_BEQ ||
        opEnum[loop_head] == `OPENUM_BNE ||
        opEnum[loop_head] == `OPENUM_BLT ||
        opEnum[loop_head] == `OPENUM_BGE ||
        opEnum[loop_head] == `OPENUM_BLTU||
        opEnum[loop_head] == `OPENUM_BGEU||
        opEnum[loop_head] == `OPENUM_JALR ) begin
          br_commit_enable <= `TRUE;
          br_jump          <= real_jump[loop_head];
          if (pred_jump[loop_head] != real_jump[loop_head]) begin
            rollback  <= `TRUE;
            target_pc <= dest_pc[loop_head];
          end
        end
        loop_head <= loop_head + 1;
      end
    end
  end
endmodule
`endif
