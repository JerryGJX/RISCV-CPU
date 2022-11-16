`include "definition.v"

module iCache(
    //cpu
    input wire clk,
    input wire rdy,
    input wire rst,

    //from memctrl
    input wire in_from_memCtrl_valid,
    input wire [`ADDRESS_TYPE ] in_from_memCtrl_addr,
    input wire [`INSTRUCTION_TYPE ] in_from_memCtrl_ins,
    //to memctrl
    output wire out_to_memCtrl_valid,
    output wire [`ADDRESS_TYPE ] out_to_memCtrl_addr,


    //from insFetcher
    input wire in_from_insFetcher_valid,
    input wire [`ADDRESS_TYPE ] in_from_insFetcher_addr,

    //to insFetcher
    // output wire out_to_insFetcher_valid,
    output wire out_to_insFetcher_hit,
    output wire [`INSTRUCTION_TYPE ] out_to_insFetcher_ins,
    // output wire [`ADDRESS_TYPE ] out_to_insFetcher_addr

);

    `define ICACHE_SIZE 256
    `define INDEX_RANGE 9:2
    `define TAG_RANGE 31:10

    reg valid [ICACHE_SIZE-1:0];
    reg [`TAG_RANGE ] tag [ICACHE_SIZE-1:0];
    reg [`INSTRUCTION_TYPE ] ins [ICACHE_SIZE-1:0];


    assign out_to_insFetcher_hit = valid[in_from_insFetcher_addr[`INDEX_RANGE ]]
        && tag[in_from_insFetcher_addr[`INDEX_RANGE ]] == in_from_insFetcher_addr[`TAG_RANGE ];



    always @(*) begin
        if(out_to_insFetcher_hit && in_from_insFetcher_valid) begin
            out_to_insFetcher_ins = ins[in_from_insFetcher_addr[`INDEX_RANGE ]];
            out_to_memCtrl_valid = `DISABLE ;
            out_to_memCtrl_addr = `BLANK_ADDR;
        end
        else begin
            assign out_to_insFetcher_ins = `BLANK_INS;
            assign out_to_memCtrl_valid = `ENABLE;
            assign out_to_memCtrl_addr = in_from_insFetcher_addr;
        end
        if(in_from_memCtrl_ins == `ENABLE ) begin
            ins[in_from_memCtrl_addr[`INDEX_RANGE ]] = in_from_memCtrl_ins;
            tag[in_from_memCtrl_addr[`INDEX_RANGE ]] = in_from_memCtrl_addr[`TAG_RANGE ];
            valid[in_from_memCtrl_addr[`INDEX_RANGE ]] = `ENABLE ;
        end
    end






endmodule : iCache