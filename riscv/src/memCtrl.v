`ifndef macro_memCtrl
`define macro_memCtrl
`include "definition.v"
module memCtrl (
    input wire clk,
    input wire rst,
    input wire rdy,
    input wire clr,

    input  wire [ 7:0] mem_to_mc_din,   // data input bus
    output reg  [ 7:0] mc_to_mem_dout,  // data output bus
    output reg  [31:0] mc_to_mem_addr,  // address bus (only 17:0 is used)
    output reg         mc_to_mem_wr,    // write/read signal (1 for write)
    input  wire        io_buffer_full,
    // 1 if uart buffer is full

    //with IF
    input  wire              if_to_mc_enable,
    input  wire [`ADDR_TYPE] if_to_mc_pc,
    output reg               mc_to_if_done,
    output reg  [`DATA_TYPE] mc_to_if_result,

    //with lsb
    input  wire              lsb_to_mc_enable,
    input  wire              lsb_to_mc_wr,
    input  wire [`ADDR_TYPE] lsb_to_mc_addr,
    input  wire [  `LS_TYPE] lsb_to_mc_type,
    input  wire [`DATA_TYPE] lsb_to_mc_st_val,
    output reg               mc_to_lsb_done,
    output reg  [`DATA_TYPE] mc_to_lsb_ld_val

);

  localparam IDLE = 3'b000,
WAIT_FOR_FIRST_BYTE = 3'b100,//for load, get the first byte; for store, put the first byte to the buffer
  WAIT_FOR_SECOND_BYTE = 3'b101, WAIT_FOR_THIRD_BYTE = 3'b110, WAIT_FOR_FOURTH_BYTE = 3'b111;

  reg last_lsb = `FALSE;
  reg [2:0] ls_step;  //0:idle, 1:wait for first byte and so on
  wire [2:0] ls_last_step = lsb_to_mc_type;  //use ls type to secure the matching of the last step
  reg [2:0] if_step;
  wire [2:0] if_last_step = WAIT_FOR_FOURTH_BYTE;
  reg [`DATA_TYPE] mem_result;

  always @(*) begin
    if (ls_step != IDLE && if_step == IDLE) begin
      mc_to_mem_addr = lsb_to_mc_addr + {{30{1'b0}}, ls_step[1:0]};
      if (lsb_to_mc_wr == `MEM_READ) begin  //load
        case (ls_step)
          WAIT_FOR_FIRST_BYTE: mem_result[7:0] = mem_to_mc_din;
          WAIT_FOR_SECOND_BYTE: mem_result[15:8] = mem_to_mc_din;
          WAIT_FOR_THIRD_BYTE: mem_result[23:16] = mem_to_mc_din;
          WAIT_FOR_FOURTH_BYTE: mem_result[31:24] = mem_to_mc_din;
          default: ;
        endcase
      end else begin  //store
        case (ls_step)
          WAIT_FOR_FIRST_BYTE: mc_to_mem_dout = lsb_to_mc_st_val[7:0];
          WAIT_FOR_SECOND_BYTE: mc_to_mem_dout = lsb_to_mc_st_val[15:8];
          WAIT_FOR_THIRD_BYTE: mc_to_mem_dout = lsb_to_mc_st_val[23:16];
          WAIT_FOR_FOURTH_BYTE: mc_to_mem_dout = lsb_to_mc_st_val[31:24];
          default: ;
        endcase
      end
    end else if (ls_step == IDLE && if_step != IDLE) begin
      mc_to_mem_addr = if_to_mc_pc + {{30{1'b0}}, if_step[1:0]};
      case (ls_step)
        WAIT_FOR_FIRST_BYTE: mem_result[7:0] = mem_to_mc_din;
        WAIT_FOR_SECOND_BYTE: mem_result[15:8] = mem_to_mc_din;
        WAIT_FOR_THIRD_BYTE: mem_result[23:16] = mem_to_mc_din;
        WAIT_FOR_FOURTH_BYTE: mem_result[31:24] = mem_to_mc_din;
        default: ;
      endcase
    end else begin
      mc_to_mem_addr = 0;
      mem_result = 0;
    end
  end


  always @(posedge clk) begin
    if (rst || clr) begin
      if_step        <= IDLE;
      ls_step        <= IDLE;
      mc_to_mem_wr   <= `MEM_READ;
      //   mc_to_mem_addr <= 0;
      mc_to_lsb_done <= `FALSE;
      mc_to_if_done  <= `FALSE;
    end else if (!rdy) begin
      if_step      <= IDLE;
      ls_step      <= IDLE;
      mc_to_mem_wr <= `MEM_READ;
      //   mc_to_mem_addr <= 0;
    end else begin
      mc_to_mem_wr     <= 0;
      mc_to_if_done    <= `FALSE;
      mc_to_if_result  <= 0;
      mc_to_lsb_done   <= `FALSE;
      mc_to_lsb_ld_val <= 0;

      if (if_step == IDLE && ls_step == IDLE) begin  //mem idle
        if (!clr) begin
          if (last_lsb && if_to_mc_enable) begin
            if_step      <= WAIT_FOR_FIRST_BYTE;
            mc_to_mem_wr <= `MEM_READ;
          end else if (lsb_to_mc_enable) begin
            ls_step      <= WAIT_FOR_FIRST_BYTE;
            mc_to_mem_wr <= lsb_to_mc_wr;
          end
        end
      end else if (if_step != IDLE && ls_step == IDLE) begin
        mc_to_mem_wr <= `MEM_READ;  //important
        if (if_step != if_last_step) begin
          case (if_step)
            WAIT_FOR_FIRST_BYTE: if_step <= WAIT_FOR_SECOND_BYTE;
            WAIT_FOR_SECOND_BYTE: if_step <= WAIT_FOR_THIRD_BYTE;
            WAIT_FOR_THIRD_BYTE: if_step <= WAIT_FOR_FOURTH_BYTE;
            WAIT_FOR_FOURTH_BYTE: if_step <= IDLE;
            default: ;
          endcase
        end else begin
          if_step <= IDLE;
          mc_to_if_result <= mem_result;
          mc_to_if_done <= `TRUE;
        end
      end else if (if_step == IDLE && ls_step != IDLE) begin
        if (clr && lsb_to_mc_wr == `MEM_READ) begin
          ls_step <= IDLE;
        end else begin
          mc_to_mem_wr <= lsb_to_mc_wr;
          if (ls_step != ls_last_step) begin
            case (ls_step)
              WAIT_FOR_FIRST_BYTE: ls_step <= WAIT_FOR_SECOND_BYTE;
              WAIT_FOR_SECOND_BYTE: ls_step <= WAIT_FOR_THIRD_BYTE;
              WAIT_FOR_THIRD_BYTE: ls_step <= WAIT_FOR_FOURTH_BYTE;
              WAIT_FOR_FOURTH_BYTE: ls_step <= IDLE;
              default: ;
            endcase
          end else begin
            ls_step <= IDLE;
            if (lsb_to_mc_wr == `MEM_READ) begin
              mc_to_lsb_ld_val <= mem_result;
              mc_to_lsb_done   <= `TRUE;
            end else begin  //store
              mc_to_lsb_done <= `TRUE;
            end
          end
        end
      end else begin

      end
    end
  end







endmodule
`endif
