`timescale 1ns / 1ps

module graphics(
    input wire clk, reset,
    input wire up, down, left, right,
    input wire [9:0] coord_x, coord_y,
    input wire active_area,
    
    output reg [11:0] rgb
    );

    reg [1:0] gameMode;
    
    integer rind = 0;
    wire [3:0] seed = 8'b11010110;
    wire [7:0] random;
    
    reg btnPress;
    reg [1:0] choice;
    wire [11:0] color;
    wire [11:0] gocolor;
    
    
    reg [3:0] bW = 10;          
    localparam UNIT = 44;          
    localparam LINE_THICK = 4;     
    wire [31:0] BOARD_SIZE = (UNIT * bW) + LINE_THICK; 
    localparam maxLen = 12*12;
    
    wire [31:0] OFFSET_Y = (480 - BOARD_SIZE) / 2; 
    wire [31:0] OFFSET_X = (640 - BOARD_SIZE) / 2; 
    integer textOff_X = 170;
    integer textOff_Y = 100;
    
    
    psRandom r4b (seed, rind, random);
    
    
    //localparam CIRCLE_COLOR     = 3'b101; // Magenta
    localparam GRID_LINE_COLOR  = 12'hFFF; // White
    localparam BOARD_BG_COLOR   = 12'h000; // Black
    localparam SNAKE_COLOR   = 12'h0F0; // Green
    localparam APPLE_COLOR   = 12'hF00; // Red
    localparam SCREEN_BG_COLOR  = 3'b000; // Black (outside the board)
    
    reg [1:0] dir; // Right Left Up Down
    
    reg [3:0] snake_x [maxLen-1:0];
    reg [3:0] snake_y [maxLen-1:0];
    reg [3:0] apple_x;
    reg [3:0] apple_y;
    reg [7:0] snakeLen;
    reg is_overlaped;

    reg [9:0] center_x, center_y;
    reg [9:0] center_x_next, center_y_next;
    
    reg [23:0] move_counter;
    wire move_tick = (move_counter == 10000000); // Adjust for speed
    
    integer n = 0;
    always @(posedge clk) begin
        if(reset) begin
            center_x <= 320;
            center_y <= 240;
            // initial pos set
            snakeLen <= 8'd0;
            snake_x[0] <= 4'd1; 
            snake_y[0] <= 4'd1; 
            dir <= 2'b00;
            apple_x <= 4'd5;
            apple_y <= 4'd2;
            gameMode <= 2'b00;
            choice <= 2'b00;
        end else begin
            move_counter <= move_counter + 1;
            if(up)begin 
                dir <= 2'b10;
                btnPress <= 1'b1;
            end
            else if(down)begin
                dir <= 2'b11;
                btnPress <= 1'b1;
            end
            else if(left)begin   
                dir <= 2'b01;
                btnPress <= 1'b1;
            end
            else if(right)begin 
                dir <= 2'b00;
                btnPress <= 1'b1;
            end
            else 
                btnPress <= 1'b0;
                
            if(move_tick) begin
                move_counter <= 0;
                if(gameMode == 2'b01) begin
                    for (n = maxLen-1; n > 0; n = n - 1) begin
                        snake_x[n] = snake_x[n-1];
                        snake_y[n] = snake_y[n-1];
                    end
                
                    case(dir)
                        2'b00: snake_x[0] = snake_x[0] + 1; 
                        2'b01: snake_x[0] = snake_x[0] - 1; 
                        2'b10: snake_y[0] = snake_y[0] - 1; 
                        2'b11: snake_y[0] = snake_y[0] + 1; 
                    endcase
                    for (n = 1; n< snakeLen+1; n = n + 1)
                    begin
                        if(snake_x[n] == snake_x[0] && snake_y[n] == snake_y[0])
                                gameMode <= 2'b10;
                    end
                    if (snake_x[0] >= bW || snake_y[0] >= bW)
                        gameMode <= 2'b10;
                end
            end
            if((apple_x == snake_x[0])&&(apple_y == snake_y[0])) begin
                
                if(~is_overlaped) begin
                    apple_x <= random[3:0]%bW;
                    apple_y <= random[7:4]%bW;
                    snakeLen <= snakeLen + 1;
                end 
                rind = rind + 1;
            end
        end
    end
    
    always@(posedge btnPress)
    begin
        if(gameMode == 2'b00)begin
            if(dir == 2'b01)begin
                if(choice != 2'd0)
                    choice <= choice - 2'b01;
            end
            if(dir == 2'b00)begin
                if(choice != 2'd2)
                    choice <= choice + 2'b01;
            end
            if(dir == 2'b10)begin
                if(choice == 2'b00)
                    bW <= 4'd6;
                else if (choice == 2'b01)
                    bW <= 4'd8;
                else 
                    bW <= 4'd10;
                gameMode <= 2'b01;
                snakeLen <= 8'd0;
                snake_x[0] <= 4'd1; 
                snake_y[0] <= 4'd1; 
                dir <= 2'b00;
                apple_x <= 4'd3;
                apple_y <= 4'd2;
            end
            dir <= 2'b01;
            
        end
        if(gameMode == 2'b10)begin
            // reset
            gameMode <= 2'b00;
            dir <= 2'b00;
            snake_x[0] <= 4'd5; 
            snake_y[0] <= 4'd5; 
            choice <= 2'b00;
            rind = rind + 12;
        end
    end
    
    // Movement logic with basic screen boundary checks
    always @(*) begin
        is_overlaped = 0;
        for (n =0; n < snakeLen+1 ; n = n+1)
        begin
            if((random[3:0]%bW == snake_x[n]) && (random[7:4]%bW == snake_y[n]))
                is_overlaped = 1;
        end 
    end

    
    wire [9:0] rel_x = coord_x - OFFSET_X;
    wire [9:0] rel_y = coord_y - OFFSET_Y;
    
    welcome_by8 rom (clk, coord_y[9:3], coord_x[9:3], choice, color);
    gameOver gorom (clk, coord_y[9:4], coord_x[9:4], gocolor);
    
    wire [3:0] grid_x = rel_x / UNIT ;
    wire [3:0] grid_y = rel_y / UNIT ;
    
    reg is_board_area;
    reg is_grid_line;
    reg is_snake;
    reg is_apple;

    always @(*) begin
        // Check if current pixel is within the board limits
        is_board_area = (coord_x >= OFFSET_X && coord_x < OFFSET_X + BOARD_SIZE) &&
                        (coord_y >= OFFSET_Y && coord_y < OFFSET_Y + BOARD_SIZE);

        // Check if current pixel is a line
        // We use % for repeating lines, and a fixed check for the final closing edge
        is_grid_line = (rel_x % UNIT < LINE_THICK) || (rel_y % UNIT < LINE_THICK) ||
                       (rel_x >= BOARD_SIZE - LINE_THICK) || (rel_y >= BOARD_SIZE - LINE_THICK);
        
        is_snake = 0;
        for (n =0; n < snakeLen+1 ; n = n+1)
        begin
            if((grid_x == snake_x[n]) && (grid_y == snake_y[n]))
                is_snake = 1;
        end
        is_apple = 0;
        if((grid_x == apple_x) && (grid_y == apple_y))
                is_apple = 1;
        
        if (!active_area) begin
            rgb = BOARD_BG_COLOR;
        // Play Mode
        end
        else if((gameMode == 2'b01))begin
            if (is_board_area) begin
                if (is_grid_line)
                    rgb = GRID_LINE_COLOR;
                else if(is_snake)
                    rgb = SNAKE_COLOR;
                else if(is_apple)
                    rgb = APPLE_COLOR;
                else
                    rgb = BOARD_BG_COLOR;
            end
            else 
                rgb = BOARD_BG_COLOR;
        // Difficulty mode
        end else if (gameMode == 2'b00)begin // Loading Screen
            rgb = color;
        end else if (gameMode == 2'b10)begin
            rgb = gocolor;
        end else begin
            rgb = SCREEN_BG_COLOR;
        end
    end

endmodule
