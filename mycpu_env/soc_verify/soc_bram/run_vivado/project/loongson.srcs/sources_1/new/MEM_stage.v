`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/03/04 08:37:42
// Design Name: 
// Module Name: MEM_stage
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`include "mycpu.vh"

module mem_stage(
    input                          clk           ,
    input                          reset         ,
    //allowin
    input                          ws_allowin    ,
    output                         ms_allowin    ,
    //from es
    input                          es_to_ms_valid,
    input  [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus  ,
    //to ws
    output                         ms_to_ws_valid,
    output [`MS_TO_WS_BUS_WD -1:0] ms_to_ws_bus  ,
    
    //from data-sram
    input  [31                 :0] data_sram_rdata,
    output [ 4:0] ms_to_ds_dest,
    output [31:0] ms_to_ds_result
);

reg         ms_valid;
wire        ms_ready_go;

reg [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus_r;
wire        ms_res_from_mem;
wire        ms_gr_we;
wire [ 4:0] ms_dest;
wire [31:0] ms_alu_result;
wire [31:0] ms_pc;
wire [ 2:0] ms_load_op_type;
wire [ 1:0] ms_addr_low2;

wire [31:0] mem_result;
wire [31:0] ms_final_result;
wire [ 7:0] mem_byte;
wire [15:0] mem_half;
wire [31:0] load_result;


assign {ms_res_from_mem,
        ms_gr_we       ,
        ms_dest        ,
        ms_alu_result  ,
        ms_pc          ,
        ms_load_op_type,
        ms_addr_low2
       } = es_to_ms_bus_r;


assign ms_to_ws_bus = {ms_gr_we       ,  //69:69
                       ms_dest        ,  //68:64
                       ms_final_result,  //63:32
                       ms_pc             //31:0
                      };

assign ms_to_ds_dest   = ms_dest & {5{ms_valid && ms_gr_we}};
assign ms_to_ds_result = ms_final_result;
assign ms_ready_go     = 1'b1;
assign ms_allowin     = !ms_valid || ms_ready_go && ws_allowin;
assign ms_to_ws_valid = ms_valid && ms_ready_go;
always @(posedge clk) begin
    if (reset) begin
        ms_valid <= 1'b0;
    end
    else if (ms_allowin) begin
        ms_valid <= es_to_ms_valid;
    end

    if (es_to_ms_valid && ms_allowin) begin
        es_to_ms_bus_r  <= es_to_ms_bus;
    end
end

assign mem_result = data_sram_rdata;
assign mem_byte   = (ms_addr_low2 == 2'b00) ? mem_result[ 7: 0] :
                    (ms_addr_low2 == 2'b01) ? mem_result[15: 8] :
                    (ms_addr_low2 == 2'b10) ? mem_result[23:16] :
                                              mem_result[31:24];
assign mem_half   = ms_addr_low2[1] ? mem_result[31:16] : mem_result[15:0];

assign load_result = (ms_load_op_type == 3'b001) ? mem_result                 :
                     (ms_load_op_type == 3'b010) ? {{24{mem_byte[7]}}, mem_byte} :
                     (ms_load_op_type == 3'b011) ? {{16{mem_half[15]}}, mem_half} :
                     (ms_load_op_type == 3'b100) ? {24'b0, mem_byte}           :
                     (ms_load_op_type == 3'b101) ? {16'b0, mem_half}           :
                                                    mem_result;

assign ms_final_result = ms_res_from_mem ? load_result : ms_alu_result;


endmodule

