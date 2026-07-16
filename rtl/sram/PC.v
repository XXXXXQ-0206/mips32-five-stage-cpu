`timescale 1ns / 1ps


module PC(clk,rst,en,PC,Adel,PCF);
    input clk;
    input rst;
    input en;
    input [31:0] PC;
    output reg Adel;
    output reg [31:0] PCF=0;

    always @(posedge clk or posedge rst) 
    begin
        if(rst)
        begin
            PCF <= 32'hbfc00000;
            Adel <= 1'b0;
        end
        else if(en)
        begin
            PCF <= PC;
            Adel <= PC[1] | PC[0];
        end
    end
endmodule
