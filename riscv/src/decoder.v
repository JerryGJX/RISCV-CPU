`include "riscv/src/definition.v"

module decoder (
    input wire [`INSTRUCTION_TYPE] inst,

    output reg                 is_jump,
    output reg [ `OPENUM_TYPE] openum,
    output reg [`REG_POS_TYPE] rd,
    output reg [`REG_POS_TYPE] rs1,
    output reg [`REG_POS_TYPE] rs2,
    output reg [    `IMM_TYPE] imm
);

  

endmodule
