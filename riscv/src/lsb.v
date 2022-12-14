`ifndef macro_lsb
`define macro_lsb

`include "definition.v"

module lsb (
    input wire clk,
    input wire rst,
    input wire rdy,
    input wire clr,

    //from issue
    input wire                      issue_to_lsb_enable,
    input wire [      `OPENUM_TYPE] issue_to_lsb_openum,
    input wire [`ROB_WRAP_POS_TYPE] issue_to_lsb_rob_pos,
    input wire [        `DATA_TYPE] issue_to_lsb_rs1_val,
    input wire [`ROB_WRAP_POS_TYPE] issue_to_lsb_rs1_rob_pos,
    input wire [        `DATA_TYPE] issue_to_lsb_rs2_val,
    input wire [`ROB_WRAP_POS_TYPE] issue_to_lsb_rs2_rob_pos,
    input wire [        `DATA_TYPE] issue_to_lsb_imm,

    //with memCtrl
    input  wire              mc_to_lsb_ls_done,
    input  wire [`DATA_TYPE] mc_to_lsb_ld_val,
    output reg               lsb_to_mc_enable,
    output reg               lsb_to_mc_wr,
    output reg  [  `LS_TYPE] lsb_to_mc_ls_type,
    output reg  [`ADDR_TYPE] lsb_to_mc_addr,
    output reg  [`DATA_TYPE] lsb_to_mc_st_val,

    //with rob
    input wire                      rob_to_lsb_st_commit,
    input wire [`ROB_WRAP_POS_TYPE] rob_to_lsb_st_rob_pos,

    //lsb broadcast
    output wire                      lsb_broadcast_next_full,
    output reg                       lsb_broadcast_result_ready,
    output reg  [`ROB_WRAP_POS_TYPE] lsb_broadcast_result_rob_pos,
    output reg  [        `DATA_TYPE] lsb_broadcast_result_val,

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

  parameter STATUS_IDLE = 0, STATUS_WAIT = 1;


  reg [`LSB_POS_TYPE] loop_head;
  reg [`LSB_POS_TYPE] loop_tail;
  reg [    `NUM_TYPE] ele_num;
  reg [    `NUM_TYPE] next_ele_num;
  reg [    `NUM_TYPE] commit_ele_num;
  //reg [    `NUM_TYPE] next_commit_ele_num;

  reg [ `STATUS_TYPE] head_status;

  assign lsb_broadcast_next_full = (next_ele_num == `LSB_SIZE);

  wire [`ADDR_TYPE] head_addr = rs1_val[loop_head] + imm[loop_head];
  wire head_load_type = (openum[loop_head] == `OPENUM_LB) || (openum[loop_head] == `OPENUM_LH) || (openum[loop_head] == `OPENUM_LW) || (openum[loop_head] == `OPENUM_LBU) || (openum[loop_head] == `OPENUM_LHU);
  wire head_pop = (head_status == STATUS_WAIT) && mc_to_lsb_ls_done;
  wire head_excutable = ele_num != 0 && rs1_rob_pos[loop_head] == 0 && rs2_rob_pos[loop_head] == 0 && ((head_load_type && !clr)|| commit[loop_head]);

  always @(*) begin
    if (rst) next_ele_num = 0;
    else if (clr) next_ele_num = commit_ele_num - (head_pop ? 32'd1 : 32'd0);
    else
      next_ele_num = ele_num - (head_pop ? 32'd1 : 32'd0) + (issue_to_lsb_enable ? 32'd1 : 32'd0);
  end


  integer i;

  always @(posedge clk) begin
    if (rst || (clr && commit_ele_num == 0)) begin
      ele_num <= 0;
      commit_ele_num <= 0;
      loop_head <= 0;
      loop_tail <= 0;
      head_status <= STATUS_IDLE;
      for (i = 0; i < `LSB_SIZE; i = i + 1) begin
        busy[i]        <= `FALSE;
        openum[i]      <= `OPENUM_NOP;
        rob_pos[i]     <= 0;
        rs1_val[i]     <= 0;
        rs1_rob_pos[i] <= 0;
        rs2_val[i]     <= 0;
        rs2_rob_pos[i] <= 0;
        imm[i]         <= 0;
        commit[i]      <= `FALSE;
      end
    end else if (!rdy) begin
      ;
    end else if (clr) begin
      loop_tail <= loop_head + commit_ele_num[`LSB_POS_TYPE];

      if (head_status == STATUS_WAIT && mc_to_lsb_ls_done) begin//there will not be a committed load at head pos
        busy[loop_head]   <= `FALSE;
        commit[loop_head] <= `FALSE;
        loop_head         <= loop_head + 1;
        ele_num           <= commit_ele_num - 1;
        commit_ele_num    <= commit_ele_num - 1;
        head_status       <= STATUS_IDLE;
      end else begin
        ele_num        <= commit_ele_num;
        commit_ele_num <= commit_ele_num;
      end

      for (i = 0; i < `LSB_SIZE; i = i + 1) begin
        if (!commit[i]) begin
          busy[i]        <= `FALSE;
          openum[i]      <= `OPENUM_NOP;
          rob_pos[i]     <= 0;
          rs1_val[i]     <= 0;
          rs1_rob_pos[i] <= 0;
          rs2_val[i]     <= 0;
          rs2_rob_pos[i] <= 0;
          imm[i]         <= 0;
          commit[i]      <= `FALSE;
        end
      end
    end else begin
      if (head_status == STATUS_WAIT) begin
        if (mc_to_lsb_ls_done) begin
          busy[loop_head]   <= `FALSE;
          commit[loop_head] <= `FALSE;
          loop_head         <= loop_head + 1;
          ele_num           <= ele_num - 1;
          commit_ele_num    <= commit_ele_num - 1;
          head_status       <= STATUS_IDLE;

          if (head_load_type) begin
            lsb_broadcast_result_ready   <= `TRUE;
            lsb_broadcast_result_rob_pos <= rob_pos[loop_head];
            case (openum[loop_head])
              `OPENUM_LB:
              lsb_broadcast_result_val <= {{24{mc_to_lsb_ld_val[7]}}, mc_to_lsb_ld_val[7:0]};
              `OPENUM_LBU: lsb_broadcast_result_val <= {24'b0, mc_to_lsb_ld_val[7:0]};
              `OPENUM_LH:
              lsb_broadcast_result_val <= {{16{mc_to_lsb_ld_val[15]}}, mc_to_lsb_ld_val[15:0]};
              `OPENUM_LHU: lsb_broadcast_result_val <= {16'b0, mc_to_lsb_ld_val[15:0]};
              `OPENUM_LW: lsb_broadcast_result_val <= mc_to_lsb_ld_val;
              default;
            endcase
          end
        end
      end else begin
        lsb_to_mc_enable <= `FALSE;
        if (head_excutable) begin
          lsb_to_mc_enable <= `TRUE;
          lsb_to_mc_addr   <= head_addr;
          case (openum[loop_head])
            `OPENUM_SB, `OPENUM_LB, `OPENUM_LBU: lsb_to_mc_ls_type <= 3'd1;
            `OPENUM_SH, `OPENUM_LH, `OPENUM_LHU: lsb_to_mc_ls_type <= 3'd2;
            `OPENUM_SW, `OPENUM_LW:              lsb_to_mc_ls_type <= 3'd4;
            default;
          endcase

          if (head_load_type) lsb_to_mc_wr <= `MEM_READ;
          else begin
            lsb_to_mc_wr <= `MEM_WRITE;
            lsb_to_mc_st_val <= rs2_val[loop_head];
          end

          head_status <= STATUS_WAIT;
        end
      end

      if (issue_to_lsb_enable) begin
        busy[loop_tail]        <= `TRUE;
        openum[loop_tail]      <= issue_to_lsb_openum;
        rob_pos[loop_tail]     <= issue_to_lsb_rob_pos;
        rs1_val[loop_tail]     <= issue_to_lsb_rs1_val;
        rs1_rob_pos[loop_tail] <= issue_to_lsb_rs1_rob_pos;
        rs2_val[loop_tail]     <= issue_to_lsb_rs2_val;
        rs2_rob_pos[loop_tail] <= issue_to_lsb_rs2_rob_pos;
        imm[loop_tail]         <= issue_to_lsb_imm;
        commit[loop_tail]      <= `FALSE;
        loop_tail              <= loop_tail + 1;
        ele_num                <= ele_num + 1;
      end



      if (rob_to_lsb_st_commit) begin
        for (i = 0; i < `LSB_SIZE; i = i + 1) begin
          if (busy[i] && rob_pos[i] == rob_to_lsb_st_rob_pos && commit[i] == `FALSE) begin
            commit[i] <= `TRUE;
            commit_ele_num <= commit_ele_num + 1;
          end
        end
      end

      //deal with broadcast
      if (alu_result_ready) begin
        for (i = 0; i < `LSB_SIZE; i = i + 1) begin
          if (busy[i] && rs1_rob_pos[i] == alu_result_rob_pos) begin
            rs1_val[i] <= alu_result_val;
            rs1_rob_pos[i] <= 0;
          end
          if (busy[i] && rs2_rob_pos[i] == alu_result_rob_pos) begin
            rs2_val[i] <= alu_result_val;
            rs2_rob_pos[i] <= 0;
          end
        end
      end

      if (lsb_load_result_ready) begin
        for (i = 0; i < `LSB_SIZE; i = i + 1) begin
          if (busy[i] && rs1_rob_pos[i] == lsb_load_result_rob_pos) begin
            rs1_val[i] <= lsb_load_result_val;
            rs1_rob_pos[i] <= 0;
          end
          if (busy[i] && rs2_rob_pos[i] == lsb_load_result_rob_pos) begin
            rs2_val[i] <= lsb_load_result_val;
            rs2_rob_pos[i] <= 0;
          end
        end
      end






    end
  end


endmodule
`endif