`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/24/2025 12:14:35 PM
// Design Name: 
// Module Name: psRandom
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


module psRandom(
    input [7:0] seed,
    input [31:0] index,
    output [7:0] result
    );
    
    wire [7:0] stage1, stage2, data_in;
    assign data_in = seed ^ index[3:0] ^ index[7:4] ^ index[11:8] ^ index[15:12];
    // XOR-Shift Logic: a = a ^ (a << 3); a = a ^ (a >> 5); a = a ^ (a << 2);
    assign stage1   = data_in ^ (data_in << 3);
    assign stage2   = stage1  ^ (stage1  >> 5);
    assign result = (stage2  ^ (stage2  << 2));
endmodule
