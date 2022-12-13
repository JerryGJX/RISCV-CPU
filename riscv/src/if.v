`ifndef mqacro_if
`define macro_if
`include "definition.v"

module iFetch (
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire rs_next_full,
    input wire lsb_next_full,
    input wire rob_next_full,


    //with mem ctrl
    output reg               mem_ctrl_enable,
    output reg  [`ADDR_TYPE] mem_ctrl_pc,
    input  wire              mem_result_ready,
    input  wire [`INST_TYPE] mem_result_inst,

    //with rob, handle pc fix
    input wire rob_set_pc_ready,
    input wire [`ADDR_TYPE] rob_set_pc,
    input wire rob_br_commit,
    input wire rob_br_jump,


    //to decoder
    output reg                 inst_rdy,
    output reg [ `OPENUM_TYPE] inst_openum,
    output reg [`REG_POS_TYPE] inst_rd,
    output reg [`REG_POS_TYPE] inst_rs1,
    output reg [`REG_POS_TYPE] inst_rs2,
    output reg [   `DATA_TYPE] inst_imm,
    output reg [   `ADDR_TYPE] inst_pc,
    output reg                 inst_pred_jump,
    output reg                 ready_inst,
    output reg                 lsb_enable,
    output reg                 rs_enable
);

  parameter STATUS_IDLE = 0, STATUS_FETCH = 1;

  integer i;

  reg [`STATUS_TYPE] status;
  //pc
  reg [`ADDR_TYPE] pc;

  //direct mapping iCache
  `define ICACHE_SIZE 256
  `define INDEX_RANGE 9:2
  `define TAG_RANGE 31:10

  reg valid[`ICACHE_SIZE - 1:0];
  reg [`TAG_RANGE] tag_store[`ICACHE_SIZE - 1:0];
  reg [`INST_TYPE] inst_store[`ICACHE_SIZE - 1:0];

  wire hit = valid[pc[`INDEX_RANGE]] && (tag_store[pc[`INDEX_RANGE]] == pc[`TAG_RANGE]);

  wire [`INST_TYPE] hit_inst_val = (hit) ? inst_store[pc[`INDEX_RANGE]] : `BLANK_INST;

  //predictor
  reg [`ADDR_TYPE] pred_pc;
  reg pred_jump;

  //local
  reg [`OPENUM_TYPE] local_inst_openum;
  reg [`REG_POS_TYPE] local_inst_rd;
  reg [`REG_POS_TYPE] local_inst_rs1;
  reg [`REG_POS_TYPE] local_inst_rs2;
  reg [`DATA_TYPE] local_inst_imm;
  reg local_ready_inst;
  reg local_lsb_enable;
  reg local_rs_enable;

  reg local_rs_dispatch_enable;
  reg local_lsb_dispatch_enable;
  reg local_issue_enable;



  //decode
  always @(*) begin
    local_lsb_enable          = `FALSE;
    local_rs_enable           = `FALSE;
    local_rs_dispatch_enable  = `FALSE;
    local_lsb_dispatch_enable = `FALSE;
    local_issue_enable        = `FALSE;

    local_inst_rd             = hit_inst_val[`RD_RANGE];
    local_inst_rs1            = hit_inst_val[`RS1_RANGE];
    local_inst_rs2            = hit_inst_val[`RS2_RANGE];

    case (hit_inst_val[`OPCODE_RANGE])
      `OPCODE_RC: begin
        local_rs_enable = `TRUE;
        case (hit_inst_val[`FUNC3_RANGE])
          `FUNC3_ADD_SUB: begin
            case (hit_inst_val[`FUNC7_RANGE])
              `FUNC7_ADD: begin
                local_inst_openum = `OPENUM_ADD;
              end
              `FUNC7_SUB: begin
                local_inst_openum = `OPENUM_SUB;
              end
              default;
            endcase
          end
          `FUNC3_XOR: begin
            local_inst_openum = `OPENUM_XOR;
          end
          `FUNC3_OR: begin
            local_inst_openum = `OPENUM_OR;
          end
          `FUNC3_AND: begin
            local_inst_openum = `OPENUM_AND;
          end
          `FUNC3_SLL: begin
            local_inst_openum = `OPENUM_SLL;
          end
          `FUNC3_SRL_SRA: begin
            case (hit_inst_val[`FUNC7_RANGE])
              `FUNC7_SRL: begin
                local_inst_openum = `OPENUM_SRL;
              end
              `FUNC7_SRA: begin
                local_inst_openum = `OPENUM_SRA;
              end
              default;
            endcase
          end
          `FUNC3_SLT: begin
            local_inst_openum = `OPENUM_SLT;
          end
          `FUNC3_SLTU: begin
            local_inst_openum = `OPENUM_SLTU;
          end
          default;
        endcase
      end

      `OPCODE_RI: begin
        local_rs_enable = `TRUE;
        local_inst_imm  = {{21{hit_inst_val[31]}}, hit_inst_val[30:20]};
        case (hit_inst_val[`FUNC3_RANGE])
          `FUNC3_ADDI: begin
            local_inst_openum = `OPENUM_ADDI;
          end
          `FUNC3_XORI: begin
            local_inst_openum = `OPENUM_XORI;
          end
          `FUNC3_ORI: begin
            local_inst_openum = `OPENUM_ORI;
          end
          `FUNC3_ANDI: begin
            local_inst_openum = `OPENUM_ANDI;
          end
          `FUNC3_SLLI: begin
            local_inst_openum = `OPENUM_SLLI;
          end
          `FUNC3_SRLI_SRAI: begin
            case (hit_inst_val[`FUNC7_RANGE])
              `FUNC7_SRLI: begin
                local_inst_openum = `OPENUM_SRLI;
              end
              `FUNC7_SRAI: begin
                local_inst_openum = `OPENUM_SRAI;
              end
              default;
            endcase
          end
          `FUNC3_SLTI: begin
            local_inst_openum = `OPENUM_SLTI;
          end
          `FUNC3_SLTIU: begin
            local_inst_openum = `OPENUM_SLTIU;
          end
          default;
        endcase
      end

      `OPCODE_LD: begin
        local_lsb_enable = `TRUE;
        local_inst_imm   = {{21{hit_inst_val[31]}}, hit_inst_val[30:20]};
        case (hit_inst_val[`FUNC3_RANGE])
          `FUNC3_LB: begin
            local_inst_openum = `OPENUM_LB;
          end
          `FUNC3_LH: begin
            local_inst_openum = `OPENUM_LH;
          end
          `FUNC3_LW: begin
            local_inst_openum = `OPENUM_LW;
          end
          `FUNC3_LBU: begin
            local_inst_openum = `OPENUM_LBU;
          end
          `FUNC3_LHU: begin
            local_inst_openum = `OPENUM_LHU;
          end
          default;
        endcase
      end

      `OPCODE_ST: begin
        local_lsb_enable = `TRUE;
        local_inst_rd = 0;
        local_ready_inst = `TRUE;
        local_inst_imm = {{21{hit_inst_val[31]}}, hit_inst_val[30:25], hit_inst_val[11:7]};
        case (hit_inst_val[`FUNC3_RANGE])
          `FUNC3_SB: begin
            local_inst_openum = `OPENUM_SB;
          end
          `FUNC3_SH: begin
            local_inst_openum = `OPENUM_SH;
          end
          `FUNC3_SW: begin
            local_inst_openum = `OPENUM_SW;
          end
          default;
        endcase
      end

      `OPCODE_BR: begin
        local_rs_enable = `TRUE;
        local_inst_rd = 0;
        local_inst_imm = {
          {20{hit_inst_val[31]}}, hit_inst_val[7], hit_inst_val[30:25], hit_inst_val[11:8], 1'b0
        };
        case (hit_inst_val[`FUNC3_RANGE])
          `FUNC3_BEQ: begin
            local_inst_openum = `OPENUM_BEQ;
          end
          `FUNC3_BNE: begin
            local_inst_openum = `OPENUM_BNE;
          end
          `FUNC3_BLT: begin
            local_inst_openum = `OPENUM_BLT;
          end
          `FUNC3_BGE: begin
            local_inst_openum = `OPENUM_BGE;
          end
          `FUNC3_BLTU: begin
            local_inst_openum = `OPENUM_BLTU;
          end
          `FUNC3_BGEU: begin
            local_inst_openum = `OPENUM_BGEU;
          end
          default;
        endcase
      end

      `OPCODE_JAL: begin
        local_rs_enable = `TRUE;
        local_inst_imm = {
          {12{hit_inst_val[31]}}, hit_inst_val[19:12], hit_inst_val[20], hit_inst_val[30:21], 1'b0
        };
        local_inst_openum = `OPENUM_JAL;
      end

      `OPCODE_JALR: begin
        local_rs_enable   = `TRUE;
        local_inst_imm    = {{21{hit_inst_val[31]}}, hit_inst_val[30:20]};
        local_inst_openum = `OPENUM_JALR;
      end

      `OPCODE_LUI: begin
        local_rs_enable   = `TRUE;
        local_inst_imm    = {hit_inst_val[31:12], 12'b0};
        local_inst_openum = `OPENUM_LUI;
      end

      `OPCODE_AUIPC: begin
        local_rs_enable   = `TRUE;
        local_inst_imm    = {hit_inst_val[31:12], 12'b0};
        local_inst_openum = `OPENUM_AUIPC;
      end
      default;
    endcase

    local_lsb_dispatch_enable = (!lsb_next_full) && local_lsb_enable;
    local_rs_dispatch_enable = (!rs_next_full) && local_rs_enable;
    local_issue_enable        = (local_lsb_dispatch_enable||local_rs_dispatch_enable)&& (!rob_next_full);
  end



  always @(posedge clk) begin
    if (rst) begin
      pc              <= `BLANK_ADDR;
      mem_ctrl_pc     <= `BLANK_ADDR;
      mem_ctrl_enable <= `FALSE;
      status          <= STATUS_IDLE;
      inst_rdy        <= `FALSE;
      for (i = 0; i < `ICACHE_SIZE; i = i + 1) begin
        valid[i]      <= `FALSE;
        tag_store[i]  <= 0;
        inst_store[i] <= `BLANK_INST;
      end
    end else if (!rdy) begin
      ;
    end else begin
      if (rob_set_pc_ready) begin
        inst_rdy <= `FALSE;
        pc       <= rob_set_pc;
      end else begin
        if (hit && local_issue_enable) begin
          inst_rdy       <= `TRUE;
          inst_openum    <= local_inst_openum;
          inst_rd        <= local_inst_rd;
          inst_rs1       <= local_inst_rs1;
          inst_rs2       <= local_inst_rs2;
          inst_imm       <= local_inst_imm;
          ready_inst     <= local_ready_inst;
          lsb_enable     <= local_lsb_dispatch_enable;
          rs_enable      <= local_rs_dispatch_enable;
          inst_pc        <= pc;
          pc             <= pred_pc;
          inst_pred_jump <= pred_jump;
        end else begin
          inst_rdy <= `FALSE;
        end
      end

        if (status == `STATUS_IDLE)

    end
  end


endmodule

`endif
