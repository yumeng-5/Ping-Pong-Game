module paddle #( 

parameter HRES = 1280,
parameter VRES = 720,


parameter PADDLE_W = 200,
parameter PADDLE_H = 20,
parameter COLOR = 24'h EFE62E,
parameter SPEED = 1
)




    (
        input pixel_clk,
        input rst,
        input fsync, 
        
        input signed [11:0] hpos, 
        input signed [11:0] vpos, 
        
        
        input right, 
        input left, 
        output [7:0] pixel [0:2] , 
        
        output active 
        
        
    );
    
    localparam VEL = 16; 
    
    /* NOTE: Put means the paddle is not moving */
    localparam PUT = 2'b00;
    localparam LEFT = 2'b01;
    localparam RIGHT = 2'b10;
    
    
    reg [0 : 2] right_ff  , left_ff ; 
    
    reg signed [ 11 : 0 ] lhpos; 
    reg signed [ 11 : 0 ] rhpos; 
    reg signed [ 11 : 0 ] tvpos; 
    reg signed [ 11 : 0 ] bvpos; 
    
    
    reg [ 1 : 0 ] dir; 
    
    reg register_right, register_left ; 
    
    
    always @(posedge pixel_clk) 
    
    begin 
        if(rst) begin 
            dir <= PUT ; 
            register_right <= 1'b0; 
            register_left <= 1'b0;
        end else begin 
            if (fsync) begin 
                if (register_right) begin 
                    dir <= RIGHT ; 
                    register_right <= 1'b0;
                    register_left  <= 1'b0;
                end else if (register_left) begin 
                    dir <= LEFT ; 
                    register_right <= 1'b0;
                    register_left  <= 1'b0;
                end else begin 
                    dir <= PUT ; 
                    register_right <= 1'b0;
                    register_left  <= 1'b0;
                end 
                
                
            end else begin 
                if (1'b1) begin 
                
                    // if (right_ff [2] ) begin 
                    //     register_right <= 1'b1; 
                    //     register_left <= 1'b0;
                    // end else if (left_ff [ 2 ] ) begin 
                    //     register_left <= 1'b1; 
                    //     register_right <= 1'b0;
                    // end 
                    if (left_ff[2]) begin 
                        register_left <= 1'b1; 
                        register_right <= 1'b0;
                    end else if (right_ff[2] ) begin 
                        register_left <= 1'b0; 
                        register_right <= 1'b1;
                    end 

                    else begin
                        register_right <= 1'b0;
                        register_left  <= 1'b0 ;
                    end
               end 
           end 
       end 
       
       right_ff <= {right, right_ff [ 0 : 1 ] } ; 
       left_ff <= {left, left_ff [ 0 : 1 ] } ; 
       
end                     


always @ (posedge pixel_clk) 
begin 

    /* Insert your code for calculating the position of the paddle */

    if (rst) begin 
        /* Insert values to reset here */
        lhpos <= HRES/2 - PADDLE_W/2;
        rhpos <= HRES/2 + PADDLE_W/2;

        tvpos <= 0;
        bvpos <= 0 + PADDLE_H;

    end else begin 
        if (fsync) begin
        /* The below code should only consider directions LEFT and RIGHT. Base this code off the code in Object.sv */
         /* The first paddle should be located at the top of the screen */
            if (dir == RIGHT) begin 
               // ....
               lhpos <= lhpos + SPEED;
               rhpos <= rhpos + SPEED;
           end 
            else if (dir == LEFT) begin
                lhpos <= lhpos - SPEED;
                rhpos <= rhpos - SPEED;
            end
            else if (dir == PUT) begin
                lhpos <= lhpos;
                rhpos  <= rhpos;
            end
            else begin
                lhpos <= lhpos;
                rhpos  <= rhpos;
            end
           
           // ....
       end 
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