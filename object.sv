`timescale 1ns/1ps

module object #( 

    // Image resolution
    parameter HRES = 1280,
    parameter VRES = 720,

    // Object Color
    parameter COLOR = 24'h 00FF90,

    // Paddle Height
    parameter PADDLE_H = 20
) (
    input pixel_clk,
    input rst,
    input fsync, 
    
    // Paddle location
    input signed [11:0] hpos, 
    input signed [11:0] vpos, 
    
    output [7:0] pixel [0:2] , 
    output active  
);
    
    localparam OBJ_SIZE = 50; 
    localparam [1:0] DOWN_RIGHT = 2'b00; 
    localparam [1:0] DOWN_LEFT  = 2'b01; 
    localparam [1:0] UP_RIGHT   = 2'b10; 
    localparam [1:0] UP_LEFT    = 2'b11;
    
    // Velocity of ball, 1 pixels per clock cycle
    localparam VEL = 1;
    
    // Paddle location in horizontal/vertical format
    reg        [1 : 0] dir;   // direction of object
    reg signed [11: 0] lhpos; // left   horizontal position 
    reg signed [11: 0] rhpos; // right  horizonat  position 
    reg signed [11: 0] tvpos; // top    vertical   position 
    reg signed [11: 0] bvpos; // bottom vertical   position

    // 用于定义�?机的�?始方�?�
    reg [1:0] lfsr;
    
    // 更新方�?�
    always @(posedge pixel_clk) begin
        
        // ------ RST ------ //
        if (rst) begin
            case (lfsr)
                2'b00: dir <= DOWN_RIGHT;
                2'b01: dir <= DOWN_LEFT;
                2'b10: dir <= UP_RIGHT;
                2'b11: dir <= UP_LEFT;
                default: dir <= DOWN_RIGHT;
            endcase
        end

        // ------ direction ------ //
        else if (fsync) begin 
            // 更新伪�?机数�?�?
            lfsr <= {lfsr[0], lfsr[1] ^ lfsr[0]};
            
            case (dir)
                DOWN_RIGHT: begin
                    if (bvpos == VRES - 1 - PADDLE_H) begin
                        dir <= UP_RIGHT;
                    end
                    else if (rhpos == HRES - 1) begin
                        dir <= DOWN_LEFT;
                    end
                end

                DOWN_LEFT: begin
                    if (bvpos == VRES - 1 - PADDLE_H) begin
                        dir <= UP_LEFT;
                    end
                    else if (lhpos == 0) begin
                        dir <= DOWN_RIGHT;
                    end
                end

                UP_RIGHT: begin
                    if (tvpos == PADDLE_H) begin
                        dir <= DOWN_RIGHT;
                    end
                    else if (rhpos == HRES - 1) begin
                        dir <= UP_LEFT;
                    end
                end

                UP_LEFT: begin
                    if (tvpos == PADDLE_H) begin
                        dir <= DOWN_LEFT;
                    end
                    else if (lhpos == 0) begin
                        dir <= UP_RIGHT;
                    end
                end
            endcase
        end

    end
   
    // 更新�?置
    always @(posedge pixel_clk) begin 
        
        // ------ RST ------ //
        if(rst) begin
            lhpos <= HRES/2 - OBJ_SIZE/2;
            rhpos <= HRES/2 + OBJ_SIZE/2 - 1;
            tvpos <= VRES/2 - OBJ_SIZE/2;
            bvpos <= VRES/2 + OBJ_SIZE/2 - 1;
        end

        // ------ position ------ //
        else if (fsync) begin
            case (dir)
                DOWN_RIGHT: begin
                    if ((rhpos + VEL) <= (HRES-1) && (bvpos + VEL) <= VRES - PADDLE_H) begin
                        lhpos <= lhpos + VEL; 
                        rhpos <= rhpos + VEL; 
                        tvpos <= tvpos + VEL; 
                        bvpos <= bvpos + VEL; 
                    end
                end
                
                DOWN_LEFT: begin
                    if ((lhpos - VEL) >= 0 && (bvpos + VEL) <= VRES - PADDLE_H) begin
                        lhpos <= lhpos - VEL; 
                        rhpos <= rhpos - VEL; 
                        tvpos <= tvpos + VEL; 
                        bvpos <= bvpos + VEL; 
                    end
                end
                
                UP_RIGHT: begin
                    if ((rhpos + VEL) <= (HRES-1) && (tvpos - VEL) >= PADDLE_H - 1) begin
                        lhpos <= lhpos + VEL; 
                        rhpos <= rhpos + VEL; 
                        tvpos <= tvpos - VEL; 
                        bvpos <= bvpos - VEL; 
                    end
                end
                
                UP_LEFT: begin
                    if ((lhpos - VEL) >= 0 && (tvpos - VEL) >= PADDLE_H - 1) begin
                        lhpos <= lhpos - VEL; 
                        rhpos <= rhpos - VEL; 
                        tvpos <= tvpos - VEL; 
                        bvpos <= bvpos - VEL; 
                    end
                end
            endcase
        end

    end
                                    
    /* Active calculates whether the current pixel being updated by the HDMI controller is within the bounds of the ball's */
    /* Simple Example: If the ball is located at position 0,0 and vpos and rpos = 0, active will be high, placing a green pixel */
    assign active = (hpos >= lhpos && hpos <= rhpos && vpos >= tvpos && vpos <= bvpos ) ? 1'b1 : 1'b0 ; 
    
    /* If active is high, set the RGB values for neon green */
    assign pixel [ 2 ] = (active) ? COLOR [ 23 : 16 ] : 8 'h00; //red 
    assign pixel [ 1 ] = (active) ? COLOR [ 15 : 8 ] : 8 'h00; //green 
    assign pixel [ 0 ] = (active) ? COLOR [ 7 : 0 ] : 8 'h00; //blue 
    
endmodule