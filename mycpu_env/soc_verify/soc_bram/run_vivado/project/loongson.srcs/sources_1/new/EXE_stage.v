`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/03/04 08:37:02
// Design Name: 
// Module Name: EXE_stage
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

module exe_stage(
    input                          clk           ,
    input                          reset         ,
    //allowin
    input                          ms_allowin    ,
    output                         es_allowin    ,
    //from ds
    input                          ds_to_es_valid,
    input  [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus  ,
    //to ms
    output                         es_to_ms_valid,
    output [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus  ,

    // data sram interface(write)
    output        data_sram_en   ,
    output [ 3:0] data_sram_we   ,
    output [31:0] data_sram_addr ,
    output [31:0] data_sram_wdata,
    output [ 4:0] es_to_ds_dest  ,
    output        es_to_ds_load_op,
    output [31:0] es_to_ds_result
);

reg         es_valid      ;
wire        es_ready_go   ;

reg  [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus_r;

wire [18:0] alu_op      ;
wire        es_load_op;
wire        src1_is_pc;
wire        src2_is_imm;
wire        src2_is_4;
wire        res_from_mem;
wire        dst_is_r1;
wire        gr_we;
wire        es_mem_we;
wire [4: 0] dest;
wire [31:0] rj_value;
wire [31:0] rkd_value;
wire [31:0] imm;
wire [31:0] es_pc;
wire [2 :0] load_op_type;
wire [1 :0] store_op_type;


assign {alu_op,
        es_load_op,
        src1_is_pc,
        src2_is_imm,
        src2_is_4,
        gr_we,
        es_mem_we,
        dest,
        imm,
        rj_value,
        rkd_value,
        es_pc,
        res_from_mem,
        load_op_type,
        store_op_type
       } = ds_to_es_bus_r;


wire [31:0] alu_src1   ;
wire [31:0] alu_src2   ;
wire [31:0] alu_result ;


// did't use in lab7
wire        es_res_from_mem;
assign es_res_from_mem = es_load_op;
assign es_to_ds_dest    = dest & {5{es_valid && gr_we}};
assign es_to_ds_load_op = res_from_mem & es_valid;
assign es_to_ds_result  = alu_result;



assign es_to_ms_bus = {res_from_mem,
                       gr_we       ,
                       dest        ,
                       alu_result  ,
                       es_pc       ,
                       load_op_type,
                       alu_result[1:0]
                      };


assign es_ready_go    = 1'b1;
assign es_allowin     = !es_valid || es_ready_go && ms_allowin;
assign es_to_ms_valid =  es_valid && es_ready_go;
always @(posedge clk) begin
    if (reset) begin
        es_valid <= 1'b0;
    end
    else if (es_allowin) begin
        es_valid <= ds_to_es_valid;
    end

    if (ds_to_es_valid && es_allowin) begin
        ds_to_es_bus_r <= ds_to_es_bus;
    end
end

assign alu_src1 = src1_is_pc  ? es_pc  : rj_value;
assign alu_src2 = src2_is_imm ? imm : rkd_value;

alu u_alu(
    .alu_op     (alu_op    ),
    .alu_src1   (alu_src1  ),
    .alu_src2   (alu_src2  ),
    .alu_result (alu_result)
    );

wire [3:0] stb_we;
wire [3:0] sth_we;

assign stb_we = 4'b0001 << alu_result[1:0];
assign sth_we = alu_result[1] ? 4'b1100 : 4'b0011;

assign data_sram_en    = 1'b1;
assign data_sram_we    = (es_mem_we && es_valid) ?
                         (store_op_type == 2'b01 ? 4'hf   :
                          store_op_type == 2'b10 ? stb_we :
                          store_op_type == 2'b11 ? sth_we : 4'h0)
                         : 4'h0;
assign data_sram_addr  = alu_result;
assign data_sram_wdata = (store_op_type == 2'b10) ? {4{rkd_value[7:0]}}  :
                         (store_op_type == 2'b11) ? {2{rkd_value[15:0]}} :
                                                      rkd_value;



endmodule

