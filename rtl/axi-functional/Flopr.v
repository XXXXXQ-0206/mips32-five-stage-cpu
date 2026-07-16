`timescale 1ns / 1ps


module Flopr #(parameter WIDTH=32)(clk,rst,Datain,Dataout);
    input clk;
    input rst;
    input [WIDTH-1:0] Datain;
    output reg [WIDTH-1:0] Dataout=0;

    always @(posedge clk or posedge rst) 
    begin
        if(rst)
            Dataout<=0;
        else Dataout<=Datain;
    end
endmodule
