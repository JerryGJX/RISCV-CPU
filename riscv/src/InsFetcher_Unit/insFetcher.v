`include "definition.v"


module insFetcher(
    input wire clk,
    input wire rst,
    input wire rdy,

    //full signal
    input wire full_flag,

    //from iCache
    input wire in_from_iCache_hit,
    input wire [`INSTRUCTION_TYPE ] in_from_iCache_ins,
    //to iCache
    output wire out_to_iCache_valid,
    output wire [`ADDRESS_TYPE ] out_to_iCache_addr,

    //from_predictor
    input wire in_from_predictor_valid,
    input wire [`ADDRESS_TYPE ] in_from_predictor_addr,
    //to_predictor
    output wire out_to_predictor_valid,
    output wire [`ADDRESS_TYPE ] out_to_predictor_addr,

    //to predictor
    output wire out_to_predictor_valid,
    output wire [`ADDRESS_TYPE ] out_to_predictor_addr,
    //from predictor
    input wire in_from_predictor_valid,
    input wire if_jump,
    input wire [`ADDRESS_TYPE ] in_from_predictor_jump_imm,

    //to issue
    output wire out_to_dispatcher_valid,
    output wire [`INSTRUCTION_TYPE ] out_to_dispatcher_ins

);

    reg [`ADDRESS_TYPE ] PC;

    always @(posedge clk) begin
        if (rst) begin
            PC <= 0;
            out_to_iCache_valid <= 0;
            out_to_iCache_addr <= `BLANK_ADDR;
        end
        else if(rdy) begin //CPU pending
        end
        else begin
            if(in_from_iCache_hit && full_flag != `FALSE ) begin
                PC <= PC + (if_jump ? in_from_predictor_jump_imm : NEXT_PC );
                out_to_dispatcher_valid <= ENABLE;
                out_to_dispatcher_ins <= in_from_iCache_ins;
            end
            else begin
                out_to_dispatcher_valid <= DISABLE;
            end
        end
    end


endmodule : insFetcher