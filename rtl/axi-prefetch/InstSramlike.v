`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/06 15:02:01
// Design Name: 
// Module Name: InstSramlike
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


module InstSramlike(
    input clk,rst,
    input StallF,
    output InstStall,

    input inst_sram_en,
    input [31:0] inst_sram_addr,
    output [31:0] inst_sram_rdata,
    
    output wire inst_req,
    output wire inst_wr,
    output wire [1:0] inst_size,
    output wire [31:0] inst_addr,
    output wire [31:0] inst_wdata,
    input wire inst_addr_ok,
    input wire inst_data_ok,
    input wire [31:0] inst_rdata
    );

    reg addr_rcv;       // 地址已发送，等待数据(用于miss)
    reg do_finish;      // 本次访问已完成，等待流水线前进
    reg [31:0] data_buffer; // 数据缓存

    // 检测单周期命中: 发请求的同时收到addr_ok和data_ok
    wire inst_req_internal = inst_sram_en && ~addr_rcv && ~do_finish;
    wire instant_hit = inst_req_internal && inst_addr_ok && inst_data_ok;

    // 地址接收标志(用于miss: addr_ok但还没data_ok)
    always@(posedge clk) begin
        if(rst)
            addr_rcv <= 1'b0;
        else if(inst_data_ok)  // 数据返回，清除
            addr_rcv <= 1'b0;
        else if(inst_req_internal && inst_addr_ok && ~inst_data_ok)  // miss: 地址被接收但数据还没好
            addr_rcv <= 1'b1;
    end

    // 完成标志
    always@(posedge clk) begin
        if(rst)
            do_finish <= 1'b0;
        else if(~StallF)  // 流水线前进，清除完成标志
            do_finish <= 1'b0;
        else if(inst_data_ok)  // 收到数据(包括instant_hit和miss返回)
            do_finish <= 1'b1;
    end

    // 数据缓存
    always@(posedge clk) begin
        if(rst)
            data_buffer <= 32'b0;
        else if(inst_data_ok)
            data_buffer <= inst_rdata;
    end

    // 输出到cache
    assign inst_req = inst_req_internal;
    assign inst_wr = 1'b0;
    assign inst_size = 2'b10;
    assign inst_addr = inst_sram_addr;
    assign inst_wdata = 32'b0;

    // 关键优化: instant_hit时不产生stall
    assign InstStall = inst_sram_en && ~instant_hit && ~do_finish;
    
    // 数据输出: instant_hit时直接返回，否则从缓存读
    assign inst_sram_rdata = instant_hit ? inst_rdata : data_buffer;
endmodule
