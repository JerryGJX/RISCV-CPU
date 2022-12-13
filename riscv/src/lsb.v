`ifndef macro_lsb
`define macro_lsb

`include "definition.v"

module lsb (
    input wire clk,
    input wire rst,
    input wire rdy,
    input wire rollback,

    //from issue
    input wire                      issue_enable,
    input wire [      `OPENUM_TYPE] issue_openum,
    input wire [`ROB_WRAP_POS_TYPE] issue_rob_pos,
    input wire [        `DATA_TYPE] issue_rs1_val,
    input wire [`ROB_WRAP_POS_TYPE] issue_rs1_rob_pos,
    input wire [        `DATA_TYPE] issue_rs2_val,
    input wire [`ROB_WRAP_POS_TYPE] issue_rs2_rob_pos,
    input wire [        `DATA_TYPE] issue_imm,

    //with memCtrl
    input  wire              memCtrl_load_store_finish,
    input  wire [`DATA_TYPE] memCtrl_load_val,
    output reg               memCtrl_enable,
    output reg               memCtrl_wr,
    output reg  [  `LS_TYPE] memCtrl_ls_type,
    output reg  [`ADDR_TYPE] memCtrl_addr,
    output reg  [`DATA_TYPE] memCtrl_store_val,

    //with rob
    input wire                      rob_store_commit,
    input wire [`ROB_WRAP_POS_TYPE] rob_store_rob_pos,

    //lsb broadcast
    output wire                      broadcast_next_full,
    output reg                       broadcast_result_ready,
    output reg  [`ROB_WRAP_POS_TYPE] broadcast_result_rob_pos,
    output reg  [        `DATA_TYPE] broadcast_result_val,

    //receive ALU broadcast
    input wire                      alu_result_ready,
    input wire [`ROB_WRAP_POS_TYPE] alu_result_rob_pos,
    input wire [        `DATA_TYPE] alu_result_val,

    //receive LSB broadcast
    input wire                      lsb_load_result_ready,
    input wire [`ROB_WRAP_POS_TYPE] lsb_load_result_rob_pos,
    input wire [        `DATA_TYPE] lsb_load_result_val

);


  reg                      busy       [`LSB_SIZE - 1:0];
  reg [      `OPENUM_TYPE] openum     [`LSB_SIZE - 1:0];
  reg [`ROB_WRAP_POS_TYPE] rob_pos    [`LSB_SIZE - 1:0];
  reg [        `DATA_TYPE] rs1_val    [`LSB_SIZE - 1:0];
  reg [`ROB_WRAP_POS_TYPE] rs1_rob_pos[`LSB_SIZE - 1:0];
  reg [        `DATA_TYPE] rs2_val    [`LSB_SIZE - 1:0];
  reg [`ROB_WRAP_POS_TYPE] rs2_rob_pos[`LSB_SIZE - 1:0];
  reg [        `DATA_TYPE] imm        [`LSB_SIZE - 1:0];
  reg                      commit     [`LSB_SIZE - 1:0];

  `define LSB_STATUS_TYPE 1:0
  `define IDLE 1'b0
  `define WAIT 1'b1

  reg [`LSB_POS_TYPE] loop_head;
  reg [`LSB_POS_TYPE] loop_tail;
  reg [    `NUM_TYPE] ele_num;
  reg [    `NUM_TYPE] next_ele_num;
  reg [    `NUM_TYPE] commit_ele_num;
  //reg [    `NUM_TYPE] next_commit_ele_num;

  reg                 head_status;

  assign broadcast_next_full = (next_ele_num == `LSB_SIZE);

  wire head_pop = (head_status == `WAIT) && memCtrl_load_store_finish;

  wire head_excutable = commit_ele_num!=0 &&commit[loop_head] && (head_status == `IDLE || head_pop);

  always @(*) begin
    if (rst || rollback) next_ele_num = 0;
    else next_ele_num = ele_num - (head_pop ? 32'd1 : 32'd0) + (issue_enable ? 32'd1 : 32'd0);
  end


  integer i;

  always @(posedge clk) begin
    if (rst || (rollback && commit_ele_num == 0)) begin
      ele_num <= 0;
      commit_ele_num <= 0;
      loop_head <= 0;
      loop_tail <= 0;
      head_status <= `IDLE;
      for (i = 0; i < `LSB_SIZE; i = i + 1) begin
        busy[i] <= `FALSE;
        openum[i] <= `OPENUM_NOP;
        rob_pos[i] <= 0;
        rs1_val[i] <= 0;
        rs1_rob_pos[i] <= 0;
        rs2_val[i] <= 0;
        rs2_rob_pos[i] <= 0;
        imm[i] <= 0;
        commit[i] <= `FALSE;
      end
    end else if (rollback) begin
      loop_tail <= loop_head + commit_ele_num[`LSB_POS_TYPE];

      for (i = 0; i < `LSB_SIZE; i = i + 1) begin
        if (!commit[i]) begin
          busy[i] <= `FALSE;
          openum[i] <= `OPENUM_NOP;
          rob_pos[i] <= 0;
          rs1_val[i] <= 0;
          rs1_rob_pos[i] <= 0;
          rs2_val[i] <= 0;
          rs2_rob_pos[i] <= 0;
          imm[i] <= 0;
          commit[i] <= `FALSE;
        end
      end
      if (head_status == `WAIT) begin

      end



      ele_num <= commit_ele_num;
    end
  end


endmodule
`endif
