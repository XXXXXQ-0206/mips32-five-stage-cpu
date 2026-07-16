`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Description: 4-way set associative data cache with 4-word cache line + AXI Burst
//////////////////////////////////////////////////////////////////////////////////

module DataCache(
    input clk,
    input rst,
    
    //cpu
    input cpu_data_req,
    input cpu_data_wr,
    input [1:0] cpu_data_size,
    input [31:0] cpu_data_addr,
    input [31:0] cpu_data_wdata,
    output [31:0] cpu_data_rdata,
    output cpu_data_addr_ok, 
    output cpu_data_data_ok,
    
    //axi (burst support)
    output        cache_data_req,
    output        cache_data_wr,
    output [1:0]  cache_data_size,
    output [31:0] cache_data_addr,
    output [31:0] cache_data_wdata,
    output [3:0]  cache_data_wstrb,
    output [7:0]  cache_data_len,     // burst length - 1
    input  [31:0] cache_data_rdata,
    input         cache_data_addr_ok,
    input         cache_data_data_ok
    );

    //Cache配置: 4路组相联, 4字/cache line, 64组 = 4KB
    parameter ASSOCIATIVITY_WIDTH = 2;                      // 4路
    parameter INDEX_WIDTH = 6;                              // 64组
    parameter OFFSET_WIDTH = 4;                             // 16字节/行 (4字)
    parameter TAG_WIDTH = 32 - INDEX_WIDTH - OFFSET_WIDTH;  // 22位tag
    parameter WORD_NUM = 4;                                 // 每行4字

    parameter ASSOCIATIVITY = 1 << ASSOCIATIVITY_WIDTH;     // 4
    parameter CACHE_DEEPTH = 1 << INDEX_WIDTH;              // 64

    // Cache存储
    reg cache_valid [CACHE_DEEPTH-1:0][ASSOCIATIVITY-1:0];
    reg cache_dirty [CACHE_DEEPTH-1:0][ASSOCIATIVITY-1:0];
    reg [TAG_WIDTH-1:0] cache_tag [CACHE_DEEPTH-1:0][ASSOCIATIVITY-1:0];
    reg [31:0] cache_block [CACHE_DEEPTH-1:0][ASSOCIATIVITY-1:0][WORD_NUM-1:0];

    // 地址解析
    wire [TAG_WIDTH-1:0] tag;
    wire [INDEX_WIDTH-1:0] index;
    wire [1:0] word_offset;
    wire [1:0] byte_offset;

    assign tag = cpu_data_addr[31:INDEX_WIDTH + OFFSET_WIDTH];
    assign index = cpu_data_addr[INDEX_WIDTH + OFFSET_WIDTH - 1:OFFSET_WIDTH];
    assign word_offset = cpu_data_addr[OFFSET_WIDTH - 1:2];
    assign byte_offset = cpu_data_addr[1:0];

    // 命中检测
    reg [ASSOCIATIVITY_WIDTH-1:0] target;
    wire [ASSOCIATIVITY-1:0] hits;
    wire hit;

    genvar i;
    generate
        for(i = 0; i < ASSOCIATIVITY; i = i + 1)
        begin: Hits
            assign hits[i] = cache_valid[index][i] && (tag == cache_tag[index][i]);
        end
    endgenerate
    
    always @(*) begin
        case(hits)
            4'b0001: target = 2'd0;
            4'b0010: target = 2'd1;
            4'b0100: target = 2'd2;
            4'b1000: target = 2'd3;
            default: target = 2'd0;
        endcase
    end
    assign hit = |hits;

    // PLRU替换策略 (4路)
    wire [ASSOCIATIVITY_WIDTH-1:0] replace_way [CACHE_DEEPTH-1:0];
    wire plru_enable [CACHE_DEEPTH-1:0];
    generate
        for(i = 0; i < CACHE_DEEPTH; i = i + 1) begin: FLRUs
            assign plru_enable[i] = (state == IDLE) && cpu_data_req && hit && (index == i);
            FLRU LRU(clk, rst, plru_enable[i], target, replace_way[i]);
        end
    endgenerate
    wire [ASSOCIATIVITY_WIDTH-1:0] replace;
    assign replace = replace_way[index];

    // 写掩码
    wire [3:0] write_mask;
    assign write_mask = (cpu_data_size == 2'b00) ? (4'b0001 << byte_offset) :
                        (cpu_data_size == 2'b01) ? (4'b0011 << byte_offset) : 4'b1111;
    wire [31:0] masks;
    assign masks = {{8{write_mask[3]}}, {8{write_mask[2]}}, {8{write_mask[1]}}, {8{write_mask[0]}}};

    // 命中时的写数据
    wire [31:0] hit_write_data;
    assign hit_write_data = (cache_block[index][target][word_offset] & ~masks) | (cpu_data_wdata & masks);

    // FSM状态
    parameter IDLE = 3'b000;
    parameter RM   = 3'b001;    // Read Miss - burst读取
    parameter WB   = 3'b010;    // Write Back - burst写回
    reg [2:0] state;

    // 保存的请求信息
    reg [TAG_WIDTH-1:0] save_tag;
    reg [INDEX_WIDTH-1:0] save_index;
    reg [1:0] save_word_offset;
    reg [1:0] save_byte_offset;
    reg save_wr;
    reg [1:0] save_size;
    reg [31:0] save_wdata;
    reg [ASSOCIATIVITY_WIDTH-1:0] save_replace;

    // Burst传输控制
    reg [1:0] word_cnt;         // 数据计数 (0-3)
    reg addr_sent;              // 地址已发送

    // 读取缓冲区
    reg [31:0] read_buffer [WORD_NUM-1:0];

    // 写回信息
    reg [31:0] wb_buffer [WORD_NUM-1:0];
    reg [TAG_WIDTH-1:0] wb_tag;

    // FSM
    always @(posedge clk) begin
        if(rst) begin
            state <= IDLE;
            word_cnt <= 2'b00;
            addr_sent <= 1'b0;
        end
        else begin
            case(state)
                IDLE: begin
                    if(cpu_data_req && !hit) begin
                        // 保存请求信息
                        save_tag <= tag;
                        save_index <= index;
                        save_word_offset <= word_offset;
                        save_byte_offset <= byte_offset;
                        save_wr <= cpu_data_wr;
                        save_size <= cpu_data_size;
                        save_wdata <= cpu_data_wdata;
                        save_replace <= replace;
                        
                        // 保存写回信息
                        wb_tag <= cache_tag[index][replace];
                        wb_buffer[0] <= cache_block[index][replace][0];
                        wb_buffer[1] <= cache_block[index][replace][1];
                        wb_buffer[2] <= cache_block[index][replace][2];
                        wb_buffer[3] <= cache_block[index][replace][3];
                        
                        word_cnt <= 2'b00;
                        addr_sent <= 1'b0;
                        
                        // 判断是否需要写回
                        if(cache_valid[index][replace] && cache_dirty[index][replace])
                            state <= WB;
                        else
                            state <= RM;
                    end
                end
                
                WB: begin
                    // Burst写回: 地址只发一次
                    if(cache_data_addr_ok)
                        addr_sent <= 1'b1;
                    
                    if(cache_data_data_ok) begin
                        if(word_cnt == 2'b11) begin
                            word_cnt <= 2'b00;
                            addr_sent <= 1'b0;
                            state <= RM;
                        end
                        else begin
                            word_cnt <= word_cnt + 1'b1;
                        end
                    end
                end
                
                RM: begin
                    // Burst读取: 地址只发一次
                    if(cache_data_addr_ok)
                        addr_sent <= 1'b1;
                    
                    if(cache_data_data_ok) begin
                        read_buffer[word_cnt] <= cache_data_rdata;
                        if(word_cnt == 2'b11) begin
                            word_cnt <= 2'b00;
                            addr_sent <= 1'b0;
                            state <= IDLE;
                        end
                        else begin
                            word_cnt <= word_cnt + 1'b1;
                        end
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end

    // 写入Cache
    wire rm_finish;
    assign rm_finish = (state == RM) && (word_cnt == 2'b11) && cache_data_data_ok;

    // 保存的写掩码
    wire [3:0] save_write_mask;
    wire [31:0] save_masks;
    assign save_write_mask = (save_size == 2'b00) ? (4'b0001 << save_byte_offset) :
                             (save_size == 2'b01) ? (4'b0011 << save_byte_offset) : 4'b1111;
    assign save_masks = {{8{save_write_mask[3]}}, {8{save_write_mask[2]}}, {8{save_write_mask[1]}}, {8{save_write_mask[0]}}};

    // 最终写入cache的数据
    wire [31:0] final_data [WORD_NUM-1:0];
    assign final_data[0] = (save_wr && (save_word_offset == 2'd0)) ? 
                           ((read_buffer[0] & ~save_masks) | (save_wdata & save_masks)) : read_buffer[0];
    assign final_data[1] = (save_wr && (save_word_offset == 2'd1)) ? 
                           ((read_buffer[1] & ~save_masks) | (save_wdata & save_masks)) : read_buffer[1];
    assign final_data[2] = (save_wr && (save_word_offset == 2'd2)) ? 
                           ((read_buffer[2] & ~save_masks) | (save_wdata & save_masks)) : read_buffer[2];
    assign final_data[3] = (save_wr && (save_word_offset == 2'd3)) ? 
                           ((cache_data_rdata & ~save_masks) | (save_wdata & save_masks)) : cache_data_rdata;

    integer j, k;
    always @(posedge clk) begin
        if(rst) begin
            for(j = 0; j < CACHE_DEEPTH; j = j + 1)
                for(k = 0; k < ASSOCIATIVITY; k = k + 1) begin
                    cache_valid[j][k] <= 1'b0;
                    cache_dirty[j][k] <= 1'b0;
                end
        end
        else if(rm_finish) begin
            cache_valid[save_index][save_replace] <= 1'b1;
            cache_dirty[save_index][save_replace] <= save_wr;
            cache_tag[save_index][save_replace] <= save_tag;
            cache_block[save_index][save_replace][0] <= final_data[0];
            cache_block[save_index][save_replace][1] <= final_data[1];
            cache_block[save_index][save_replace][2] <= final_data[2];
            cache_block[save_index][save_replace][3] <= final_data[3];
        end
        else if((state == IDLE) && cpu_data_req && cpu_data_wr && hit) begin
            cache_dirty[index][target] <= 1'b1;
            cache_block[index][target][word_offset] <= hit_write_data;
        end
    end

    // CPU接口
    assign cpu_data_addr_ok = (state == IDLE) && (hit || !cpu_data_req);
    assign cpu_data_data_ok = ((state == IDLE) && cpu_data_req && hit) || rm_finish;
    assign cpu_data_rdata = (state == IDLE) ? cache_block[index][target][word_offset] :
                            (save_word_offset == 2'b11) ? cache_data_rdata : read_buffer[save_word_offset];

    // AXI Burst接口
    wire [31:0] rm_addr;
    wire [31:0] wb_addr;
    assign rm_addr = {save_tag, save_index, 4'b0000};  // 对齐到cache line边界
    assign wb_addr = {wb_tag, save_index, 4'b0000};

    // Burst请求: 地址只发送一次
    assign cache_data_req = ((state == RM) || (state == WB)) && !addr_sent;
    assign cache_data_wr = (state == WB);
    assign cache_data_size = 2'b10;         // 每拍32位
    assign cache_data_len = 8'd3;           // burst长度=4 (len+1)
    assign cache_data_addr = (state == WB) ? wb_addr : rm_addr;
    assign cache_data_wdata = wb_buffer[word_cnt];
    assign cache_data_wstrb = 4'b1111;      // burst写时全字节有效

endmodule
