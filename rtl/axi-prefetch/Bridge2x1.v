`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: Bridge2x1 - Mux cache data and conf data to wrap with burst support
//////////////////////////////////////////////////////////////////////////////////

module Bridge2x1(
    input now_dcache,

    //cache data (with burst)
    input         ram_data_req,
    input         ram_data_wr,
    input  [1 :0] ram_data_size,
    input  [31:0] ram_data_addr,
    input  [31:0] ram_data_wdata,
    input  [3 :0] ram_data_wstrb,
    input  [7 :0] ram_data_len,
    output [31:0] ram_data_rdata,
    output        ram_data_addr_ok,
    output        ram_data_data_ok,

    //conf data (no burst, len=0)
    input         conf_data_req,
    input         conf_data_wr,
    input  [1 :0] conf_data_size,
    input  [31:0] conf_data_addr,
    input  [31:0] conf_data_wdata,
    output [31:0] conf_data_rdata,
    output        conf_data_addr_ok,
    output        conf_data_data_ok,

    //wrap data (to AXI)
    output        wrap_data_req,
    output        wrap_data_wr,
    output [1 :0] wrap_data_size,
    output [31:0] wrap_data_addr,
    output [31:0] wrap_data_wdata,
    output [3 :0] wrap_data_wstrb,
    output [7 :0] wrap_data_len,
    input  [31:0] wrap_data_rdata,
    input         wrap_data_addr_ok,
    input         wrap_data_data_ok
    );

    wire no_dcache;
    
    assign no_dcache = (~now_dcache) && (~ram_data_wr);

    // 为conf计算正确的wstrb（基于size和地址低2位）
    wire [1:0] conf_byte_offset;
    wire [3:0] conf_wstrb;
    assign conf_byte_offset = conf_data_addr[1:0];
    assign conf_wstrb = (conf_data_size == 2'b00) ? (4'b0001 << conf_byte_offset) :
                        (conf_data_size == 2'b01) ? (4'b0011 << conf_byte_offset) : 4'b1111;

    //up
    assign ram_data_rdata   = (no_dcache) ? 32'b0 : wrap_data_rdata;
    assign ram_data_addr_ok = (no_dcache) ? 1'b0 : wrap_data_addr_ok;
    assign ram_data_data_ok = (no_dcache) ? 1'b0 : wrap_data_data_ok;

    assign conf_data_rdata   = (no_dcache) ? wrap_data_rdata : 32'b0;
    assign conf_data_addr_ok = (no_dcache) ? wrap_data_addr_ok : 1'b0;
    assign conf_data_data_ok = (no_dcache) ? wrap_data_data_ok : 1'b0;

    //down
    assign wrap_data_req   = (no_dcache) ? conf_data_req   : ram_data_req;
    assign wrap_data_wr    = (no_dcache) ? conf_data_wr    : ram_data_wr;
    assign wrap_data_size  = (no_dcache) ? conf_data_size  : ram_data_size;
    assign wrap_data_addr  = (no_dcache) ? conf_data_addr  : ram_data_addr;
    assign wrap_data_wdata = (no_dcache) ? conf_data_wdata : ram_data_wdata;
    assign wrap_data_wstrb = (no_dcache) ? conf_wstrb      : ram_data_wstrb;
    assign wrap_data_len   = (no_dcache) ? 8'd0            : ram_data_len;
endmodule
