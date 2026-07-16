`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: AXInterface - SRAM-like to AXI4 with Burst support for data channel
//////////////////////////////////////////////////////////////////////////////////

module AXInterface(
    input         clk,
    input         resetn, 

    //inst sram-like (no burst, single transfer)
    input         inst_req     ,
    input         inst_wr      ,
    input  [1 :0] inst_size    ,
    input  [31:0] inst_addr    ,
    input  [31:0] inst_wdata   ,
    output [31:0] inst_rdata   ,
    output        inst_addr_ok ,
    output        inst_data_ok ,
    
    //data sram-like (with burst)
    input         data_req     ,
    input         data_wr      ,
    input  [1 :0] data_size    ,
    input  [31:0] data_addr    ,
    input  [31:0] data_wdata   ,
    input  [3 :0] data_wstrb   ,
    input  [7 :0] data_len     ,
    output [31:0] data_rdata   ,
    output        data_addr_ok ,
    output        data_data_ok ,

    //axi
    //ar
    output [3 :0] arid         ,
    output [31:0] araddr       ,
    output [7 :0] arlen        ,
    output [2 :0] arsize       ,
    output [1 :0] arburst      ,
    output [1 :0] arlock       ,
    output [3 :0] arcache      ,
    output [2 :0] arprot       ,
    output        arvalid      ,
    input         arready      ,
    //r           
    input  [3 :0] rid          ,
    input  [31:0] rdata        ,
    input  [1 :0] rresp        ,
    input         rlast        ,
    input         rvalid       ,
    output        rready       ,
    //aw          
    output [3 :0] awid         ,
    output [31:0] awaddr       ,
    output [7 :0] awlen        ,
    output [2 :0] awsize       ,
    output [1 :0] awburst      ,
    output [1 :0] awlock       ,
    output [3 :0] awcache      ,
    output [2 :0] awprot       ,
    output        awvalid      ,
    input         awready      ,
    //w          
    output [3 :0] wid          ,
    output [31:0] wdata        ,
    output [3 :0] wstrb        ,
    output        wlast        ,
    output        wvalid       ,
    input         wready       ,
    //b           
    input  [3 :0] bid          ,
    input  [1 :0] bresp        ,
    input         bvalid       ,
    output        bready       
    );

    // 请求锁存
    reg do_req;
    reg do_req_or;      // 1:data, 0:inst
    reg do_wr_r;
    reg [1 :0] do_size_r;
    reg [31:0] do_addr_r;
    reg [7 :0] do_len_r;
    reg [3 :0] do_wstrb_r;

    // Burst传输计数
    reg [7:0] burst_cnt;
    
    // AXI地址通道状态
    reg addr_rcv;       // 地址已被接收
    reg wdata_done;     // 写数据全部发完
    
    wire data_back;     // 整个传输完成

    // 地址握手: data优先
    assign inst_addr_ok = !do_req && !data_req;
    assign data_addr_ok = !do_req;

    always @(posedge clk) begin
        if(!resetn) begin
            do_req <= 1'b0;
            do_req_or <= 1'b0;
            burst_cnt <= 8'd0;
        end
        else if(!do_req && (inst_req || data_req)) begin
            // 接受新请求
            do_req <= 1'b1;
            do_req_or <= data_req;
            do_wr_r <= data_req ? data_wr : inst_wr;
            do_size_r <= data_req ? data_size : inst_size;
            do_addr_r <= data_req ? data_addr : inst_addr;
            do_len_r <= data_req ? data_len : 8'd0;
            do_wstrb_r <= data_req ? data_wstrb : (
                inst_size == 2'd0 ? 4'b0001 << inst_addr[1:0] :
                inst_size == 2'd1 ? 4'b0011 << inst_addr[1:0] : 4'b1111);
            burst_cnt <= 8'd0;
        end
        else if(do_req) begin
            // 写burst计数
            if(do_wr_r && wvalid && wready)
                burst_cnt <= burst_cnt + 8'd1;
            // 读burst计数
            if(!do_wr_r && rvalid && rready)
                burst_cnt <= burst_cnt + 8'd1;
            // 传输完成
            if(data_back)
                do_req <= 1'b0;
        end
    end

    // 传输完成信号
    assign data_back = addr_rcv && (
        (!do_wr_r && rvalid && rready && rlast) ||  // 读完成
        (do_wr_r && bvalid && bready)               // 写响应
    );

    // 数据返回 (每拍data_ok)
    wire read_beat = do_req && !do_wr_r && rvalid && rready;
    wire write_beat = do_req && do_wr_r && wvalid && wready;
    
    assign inst_data_ok = do_req && !do_req_or && read_beat;
    assign data_data_ok = do_req && do_req_or && (read_beat || write_beat);
    assign inst_rdata = rdata;
    assign data_rdata = rdata;

    // 地址通道状态机
    always @(posedge clk) begin
        if(!resetn) begin
            addr_rcv <= 1'b0;
            wdata_done <= 1'b0;
        end
        else begin
            // 地址接收
            if(arvalid && arready)
                addr_rcv <= 1'b1;
            else if(awvalid && awready)
                addr_rcv <= 1'b1;
            else if(data_back)
                addr_rcv <= 1'b0;
            
            // 写数据发送(单次或burst最后一拍)
            if(wvalid && wready && wlast)
                wdata_done <= 1'b1;
            else if(data_back)
                wdata_done <= 1'b0;
        end
    end

    // AR通道
    assign arid    = 4'd0;
    assign araddr  = do_addr_r;
    assign arlen   = do_len_r;
    assign arsize  = {1'b0, do_size_r};
    assign arburst = (do_len_r == 8'd0) ? 2'b00 : 2'b01;  // FIXED for len=0, INCR for burst
    assign arlock  = 2'd0;
    assign arcache = 4'd0;
    assign arprot  = 3'd0;
    assign arvalid = do_req && !do_wr_r && !addr_rcv;

    // R通道
    assign rready  = 1'b1;

    // AW通道
    assign awid    = 4'd0;
    assign awaddr  = do_addr_r;
    assign awlen   = do_len_r;
    assign awsize  = {1'b0, do_size_r};
    assign awburst = (do_len_r == 8'd0) ? 2'b00 : 2'b01;
    assign awlock  = 2'd0;
    assign awcache = 4'd0;
    assign awprot  = 3'd0;
    assign awvalid = do_req && do_wr_r && !addr_rcv;

    // W通道 - wdata直接来自data_wdata，由DataCache控制
    assign wid    = 4'd0;
    assign wdata  = do_req_or ? data_wdata : inst_wdata;
    assign wstrb  = do_wstrb_r;
    assign wlast  = (burst_cnt == do_len_r);  // 最后一拍
    assign wvalid = do_req && do_wr_r && addr_rcv && !wdata_done;

    // B通道
    assign bready = 1'b1;

endmodule
