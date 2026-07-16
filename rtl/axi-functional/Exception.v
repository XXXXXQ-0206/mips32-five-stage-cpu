`timescale 1ns / 1ps

`include "defines2.vh"
module Exception(rst,ExcepType,Adel,Ades,EXcCode);
    input rst;
    input [31:0] ExcepType;
    input Adel;
    input Ades;
    output reg [4:0] EXcCode;

    always@(*)
    begin
        if(rst)
            EXcCode <= `Ne;
        else begin
            if(ExcepType[4] || Adel)//读地址例外
                EXcCode <= `AdEL;
            else if(ExcepType[5] || Ades)//写地址例外
                EXcCode <= `AdES;
            else if(ExcepType[8])//系统调用
                EXcCode <= `Sys;
            else if(ExcepType[9])//断点
                EXcCode <= `Bp;
            else if(ExcepType[10])//保留指令
                EXcCode <= `RI;
            else if(ExcepType[12])//算术溢出
                EXcCode <= `Ov;
            else if(ExcepType[14])//ERET
                EXcCode <= `Eret;
            else EXcCode <= `Ne;
        end
    end
endmodule
