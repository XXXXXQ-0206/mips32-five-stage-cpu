`timescale 1ns / 1ps


module Floprc #(parameter WIDTH=32)(clk,rst,clear,Datain,Dataout);
    input clk;
    input rst;
    input clear;
    input [WIDTH-1:0] Datain;
    output reg [WIDTH-1:0] Dataout=0;

    always@(posedge clk or posedge rst)
    begin
        if(rst)
            Dataout<=0;
        else if(clear)
            Dataout<=0;
        else Dataout<=Datain;
    end 
endmodule
