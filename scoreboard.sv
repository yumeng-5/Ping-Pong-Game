`timescale 1ns/1ps

module scoreboard #(

    // Image resolution
    parameter HRES = 1280,
    parameter VRES = 720,

    // Object Color
    parameter COLOR = 24'hCC99FF,

    // Paddle Height
    parameter PADDLE_H = 20,

    // sccoreboard position
    parameter H_Start = 30,
    parameter V_Start = 30
) (
    input pixel_clk,
    input rst,
    input fsync,
   
    // Paddle location
    input signed [11:0] hpos,
    input signed [11:0] vpos,

    input [3:0] score,
   
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

    wire active1;
    assign active1 = (hpos>=H_Start+10 && hpos<=H_Start+60 && vpos>=V_Start && vpos<=V_Start+10)? segments[6]:1'b0;

    wire active2;
    assign active2 = (hpos>=H_Start && hpos<=H_Start+10 && vpos>=V_Start+10 && vpos<=V_Start+60)? segments[5]:1'b0;

    wire active3;
    assign active3 = (hpos>=H_Start+60 && hpos<=H_Start+70 && vpos>=V_Start+10 && vpos<=V_Start+60)? segments[4]:1'b0;

    wire active4;
    assign active4 = (hpos>=H_Start+10 && hpos<=H_Start+60 && vpos>=V_Start+60 && vpos<=V_Start+70)? segments[3]:1'b0;

    wire active5;
    assign active5 = (hpos>=H_Start && hpos<=H_Start+10 && vpos>=V_Start+70 && vpos<=V_Start+120)? segments[2]:1'b0;

    wire active6;
    assign active6 = (hpos>=H_Start+60 && hpos<=H_Start+70 && vpos>=V_Start+70 && vpos<=V_Start+120)? segments[1]:1'b0;

    wire active7;
    assign active7 = (hpos>=H_Start+10 && hpos<=H_Start+60 && vpos>=V_Start+120 && vpos<=V_Start+130)? segments[0]:1'b0;

    reg [6:0] segments;

    always @(*) begin
        case (score)
            4'd0: segments = 7'b1110111;
            4'd1: segments = 7'b0010010;
            4'd2: segments = 7'b1011101;
            4'd3: segments = 7'b1011011;
            4'd4: segments = 7'b0111010;
            4'd5: segments = 7'b1101011;
            4'd6: segments = 7'b1101111;
            4'd7: segments = 7'b1010010;
            4'd8: segments = 7'b1111111;
            4'd9: segments = 7'b1111011;
            default: segments = 7'b1110111;
        endcase
    end

    // always @(posedge pixel_clk) begin
    //     if (rst) begin
    //         segments <= 7'b1110111;
    //     end
    //     else begin
    //         if (fsync) begin
    //             if (score == 4'd0) begin
    //                 segments <= 7'b1110111;
    //             end
    //             else if (conditions) begin
                    
    //             end
    //         end
    //     end
    // end
                                   
    /* Active calculates whether the current pixel being updated by the HDMI controller is within the bounds of the ball's */
    /* Simple Example: If the ball is located at position 0,0 and vpos and rpos = 0, active will be high, placing a green pixel */
    assign active = |{active1,active2,active3,active4,active5,active6,active7};
   
    /* If active is high, set the RGB values for neon green */
    assign pixel [ 2 ] = (active) ? COLOR [ 23 : 16 ] : 8 'h00; //red
    assign pixel [ 1 ] = (active) ? COLOR [ 15 : 8 ] : 8 'h00; //green
    assign pixel [ 0 ] = (active) ? COLOR [ 7 : 0 ] : 8 'h00; //blue
   
endmodule