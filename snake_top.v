`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/28/2025 02:07:01 PM
// Design Name: 
// Module Name: snake_top
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


module snake_top(
    input clk, reset,
    input up,down,left,right,
    output h_sync,v_sync,
    output [11:0] rgb
    );
    
    localparam debounceTimer = 25_000;
    reg [18:0] counter [3:0];
    reg [3:0] btnState, btnState_prv, btnStable;
    reg [3:0] btnOut;
    
    always@(posedge clk, reset)
    begin
        if(reset)
        begin
            btnState <= 4'b0;
            btnState_prv <= 4'b0;
            btnStable <= 4'b0;
        end else begin
            btnState <= {up,down,left,right};
            btnState_prv <= btnState;
        end
    end
    
    always@(posedge clk , reset)begin
        if(btnState_prv[0] != btnState[0])
            if(counter[0]>=debounceTimer)begin
                btnStable[0] <= btnState_prv[0];
                counter[0] <= 0;
            end else
                counter[0] <= counter[0] + 1;
        else
            counter[0] <= 0;
        if(btnState_prv[1] != btnState[1])
            if(counter[1]>=debounceTimer)begin
                btnStable[1] <= btnState_prv[1];
                counter[1] <= 0;
            end else
                counter[1] <= counter[1] + 1;
        else
            counter[1] <= 0;
        if(btnState_prv[2] != btnState[2])
            if(counter[2]>=debounceTimer)begin
                btnStable[2] <= btnState_prv[2];
                counter[2] <= 0;
            end else
                counter[2] <= counter[2] + 1;
        else
            counter[2] <= 0;
        if(btnState_prv[3] != btnState[3])
            if(counter[3]>=debounceTimer)begin
                btnStable[3] <= btnState_prv[3];
                counter[3] <= 0;
            end else
                counter[3] <= counter[3] + 1;
        else
            counter[3] <= 0;
        btnOut <= btnStable;
    end
    
    display dips (clk, reset, btnOut[0], btnOut[1], btnOut[2], btnOut[3], h_sync, v_sync, rgb);
    
endmodule
