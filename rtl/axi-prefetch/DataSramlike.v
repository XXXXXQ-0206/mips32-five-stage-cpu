`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/06 15:02:01
// Design Name: 
// Module Name: DataSramlike
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


module DataSramlike(
    input clk,rst,
    input StallM,
    output DataStall,

    input data_sram_en,
    input [3:0] data_sram_wen,
    input [31:0] data_sram_addr,
    input [31:0] data_sram_wdata,
    output [31:0] data_sram_rdata,

    output wire data_req,
    output wire data_wr,
    output wire [1:0] data_size,
    output wire [31:0] data_addr,
    output wire [31:0] data_wdata,
    input wire data_addr_ok,
    input wire data_data_ok,
    input wire [31:0] data_rdata
    );

    reg addr_rcv;       // 地址已发送，等待数据(用于miss)
    reg do_finish;      // 本次访问已完成，等待流水线前进
    reg [31:0] data_buffer; // 数据缓存

    // 检测单周期命中: 发请求的同时收到addr_ok和data_ok
    wire data_req_internal = data_sram_en && ~addr_rcv && ~do_finish;
    wire instant_hit = data_req_internal && data_addr_ok && data_data_ok;

    // 地址接收标志(用于miss: addr_ok但还没data_ok)
    always@(posedge clk) begin
        if(rst)
            addr_rcv <= 1'b0;
        else if(data_data_ok)  // 数据返回，清除
            addr_rcv <= 1'b0;
        else if(data_req_internal && data_addr_ok && ~data_data_ok)  // miss: 地址被接收但数据还没好
            addr_rcv <= 1'b1;
    end

    // 完成标志
    always@(posedge clk) begin
        if(rst)
            do_finish <= 1'b0;
        else if(~StallM)  // 流水线前进，清除完成标志
            do_finish <= 1'b0;
        else if(data_data_ok)  // 收到数据(包括instant_hit和miss返回)
            do_finish <= 1'b1;
    end

    // 数据缓存
    always@(posedge clk) begin
        if(rst)
            data_buffer <= 32'b0;
        else if(data_data_ok)
            data_buffer <= data_rdata;
    end

    // 输出到cache
    assign data_req = data_req_internal;
    assign data_wr = |data_sram_wen;
    assign data_size = (data_sram_wen==4'b0001 || data_sram_wen==4'b0010 || data_sram_wen==4'b0100 || data_sram_wen==4'b1000) ? 2'b00:
                       (data_sram_wen==4'b0011 || data_sram_wen==4'b1100 ) ? 2'b01 : 2'b10;
    assign data_addr = data_sram_addr;
    assign data_wdata = data_sram_wdata;

    // 关键优化: instant_hit时不产生stall
    assign DataStall = data_sram_en && ~instant_hit && ~do_finish;
    
    // 数据输出: instant_hit时直接返回，否则从缓存读
    assign data_sram_rdata = instant_hit ? data_rdata : data_buffer;
endmodule
