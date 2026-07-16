`timescale 1ns / 1ps


module Flopenrc #(parameter WIDTH=32)(clk,rst,clear,en,Datain,Dataout);
    input clk;
    input rst;
    input clear;
    input en;
    input [WIDTH-1:0] Datain;
    output reg [WIDTH-1:0] Dataout=0;

    always@(posedge clk or posedge rst)
    begin
        if(rst)
            Dataout <= 0;
        else if(clear)
            Dataout <= 0;
        else if(en)
            Dataout <= Datain;
    end

endmodule
