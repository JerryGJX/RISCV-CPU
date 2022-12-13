`ifndef macro_memCtrl
`define macro_memCtrl
`include "definition.v"
module memCtrl (
    input wire clk,
    input wire rst,
    input wire rdy,
    input wire clr,

    input  wire [ 7:0] mem_din,   // data input bus
    output reg  [ 7:0] mem_dout,  // data output bus
    output reg  [31:0] mem_a,     // address bus (only 17:0 is used)
    output reg         mem_wr,    // write/read signal (1 for write)

    input wire io_buffer_full,
    // 1 if uart buffer is full

    //with IF
    input wire if_enable,
    input wire if_pc,
    output reg if_done,
    output reg [`DATA_TYPE] if_result,

    //with lsb
    input wire lsb_enable,
    input wire lsb_wr,
    input wire [`ADDR_TYPE] lsb_addr,
    input wire [`LS_TYPE] lsb_type,
    input wire [`DATA_TYPE] lsb_st_val,
    output reg lsb_done,
    output reg [`DATA_TYPE] lsb_ld_val
);











endmodule
`endif
