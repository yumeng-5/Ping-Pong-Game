module top ( 
    input clk125, 
    input right,
    input left, 

    input right2,
    input left2,
    
    output tmds_tx_clk_p, 
    output tmds_tx_clk_n,
    
    output [2:0] tmds_tx_data_p, 
    output [2:0] tmds_tx_data_n,
    output led_kawser 
); 
    
    localparam HRES = 1280; 
    localparam VRES = 720; 
    
    localparam PADDLE_W = 200;
    localparam PADDLE_H = 20; 
    
    localparam COLOR_OBJ = 24'h 00FF90; 
    localparam COLOR_PAD = 24'h EFE62E; 
    localparam COLOR_GMO = 24'h DD4F83; 
    
    localparam GAMEOVER_H = 200; 
    localparam GAMEOVER_VSTART = (VRES - GAMEOVER_H) >> 1 ; 

    localparam RESTART_PAUSE = 2 ;

    wire pixel_clk; 
    wire rst;
    wire active ; 
    wire fsync; 
    wire signed [11:0] hpos; 
    wire signed [11:0] vpos; 
    wire [7:0] pixel [0 : 2 ] ; 
    
    wire active_obj ; 
    reg active_passing ; 
   
    wire [7 : 0 ] pixel_obj [0:2] ;
    wire active_paddle; 
    wire active_paddle0;
    wire active_paddle2;
    wire [7 : 0 ] pixel_paddle [0:2] ;
    wire [7 : 0 ] pixel_paddle2 [0:2] ;
    wire [7 : 0 ] pixel_SB1 [0:2] ;
    wire [7 : 0 ] pixel_SB2 [0:2] ;
    wire active_SB1;
    wire active_SB2;

    reg game_over; 
    
    wire [HRES-1 : 0] bitmap ; 
    wire active_gameover ; 
    wire bitmap_on; 
    wire [7:0] pixel_gameover [0:2] ; 

    reg rst_zsp;
    
    /* Add Scoreboard Instantiation Here */
    scoreboard #(
        .H_Start   (30),
        .V_Start   (30)
    ) sb1 (
        .pixel_clk (pixel_clk),
        .rst       (rst_zsp),
        .fsync     (fsync),
        .hpos      (hpos),
        .vpos      (vpos),
        .score     (score_top),
        .pixel     (pixel_SB1),
        .active    (active_SB1)
    );

    scoreboard #(
        .H_Start   (1180),
        .V_Start   (560)
    ) sb2 (
        .pixel_clk (pixel_clk),
        .rst       (rst_zsp),
        .fsync     (fsync),
        .hpos      (hpos),
        .vpos      (vpos),
        .score     (score_bot),
        .pixel     (pixel_SB2),
        .active    (active_SB2)
    );
    
    /* Add Top Paddle Instantiation Here */
    assign active_paddle = active_paddle0 | active_paddle2;

    paddle #( 
        .HRES      (HRES     ),
        .VRES      (VRES     ),
        .PADDLE_W  (PADDLE_W ),
        .PADDLE_H  (PADDLE_H ),
        .COLOR     (COLOR_PAD),
        .SPEED     (3)
    ) paddle_inst (
        .pixel_clk (pixel_clk       ),
        .rst       (rst || game_over),
        .fsync     (fsync           ),  
        .hpos      (hpos            ), 
        .vpos      (vpos            ), 
        .right     (right           ),
        .left      (left            ), 
        .pixel     (pixel_paddle    ), 
        .active    (active_paddle0  )
    );
     
    paddle2 #( 
        .HRES      (HRES     ),
        .VRES      (VRES     ),
        .PADDLE_W  (PADDLE_W ),
        .PADDLE_H  (PADDLE_H ),
        .COLOR     (COLOR_PAD),
        .SPEED     (3)
    ) paddle2_inst (
        .pixel_clk   (pixel_clk       ),
        .rst         (rst || game_over),
        .fsync       (fsync           ),  
        .hpos        (hpos            ), 
        .vpos        (vpos            ), 
        .right       (right2          ),
        .left        (left2           ), 
        .pixel       (pixel_paddle2   ), 
        .active      (active_paddle2  )
    );
    
    // HDMIT Transmit + clock video timing 
    hdmi_transmit hdmi_transmit_inst ( 
        .clk125         (clk125), 
        .pixel          (pixel), 
        // Shared video interface to the rest of the system 
        .pixel_clk      (pixel_clk), 
        .rst            (rst),
        .active         (active),
        .fsync          (fsync),
        .hpos           (hpos),
        .vpos           (vpos), 
        .tmds_tx_clk_p  (tmds_tx_clk_p),  
        .tmds_tx_clk_n  (tmds_tx_clk_n),
        .tmds_tx_data_p (tmds_tx_data_p), 
        .tmds_tx_data_n (tmds_tx_data_n) 
    ); 
     
    // Handle Bounce 
    object #( 
        .HRES      (HRES     ),
        .VRES      (VRES     ),
        .COLOR     (COLOR_OBJ),
        .PADDLE_H  (PADDLE_H ) 
    ) object_inst (
        .pixel_clk   (pixel_clk       ),
        .rst         (rst || game_over),
        .fsync       (fsync           ),  
        .hpos        (hpos            ), 
        .vpos        (vpos            ), 
        .pixel       (pixel_obj       ), 
        .active      (active_obj      )
    );

    gameover_bitmap gameover_bitmap_inst ( 
        .clka           (pixel_clk),
        .ena            (1'b1),
        .addra          (vpos [7:0]),
        .douta          (bitmap) 
    ); 
       
    // GAME OVER Pixel active, middle of the screen 
    assign active_gameover = (game_over && vpos >= GAMEOVER_VSTART  && vpos < GAMEOVER_VSTART + GAMEOVER_H)  ? 1'b1 : 1'b0 ; 
    assign bitmap_on = (bitmap >> hpos) & 1'b1; 
    
    // RGB pixels for pop up game 
    assign pixel_gameover [2] = (active_gameover && bitmap_on) ? COLOR_GMO [23 : 16] : 8'h00; 
    assign pixel_gameover [1] = (active_gameover && bitmap_on) ? COLOR_GMO [15 : 8] : 8'h00; 
    assign pixel_gameover [0] = (active_gameover && bitmap_on) ? COLOR_GMO [7 : 0] : 8'h00; 
    
    // Display RGB pixels 
    // assign pixel [2] = game_over ? pixel_gameover [2] : pixel_obj [ 2 ] | pixel_paddle [ 2 ] | pixel_paddle2[2] | pixel_SB1[2] | pixel_SB2[2];
    // assign pixel [1] = game_over ? pixel_gameover [1] : pixel_obj [ 1 ] | pixel_paddle [ 1 ] | pixel_paddle2[1] | pixel_SB1[1] | pixel_SB2[1];
    // assign pixel [0] = game_over ? pixel_gameover [0] : pixel_obj [ 0 ] | pixel_paddle [ 0 ] | pixel_paddle2[0] | pixel_SB1[0] | pixel_SB2[0];
    assign pixel [2] = pixel_obj [2] | pixel_paddle [2] | pixel_paddle2[2] | pixel_SB1[2] | pixel_SB2[2];
    assign pixel [1] = pixel_obj [1] | pixel_paddle [1] | pixel_paddle2[1] | pixel_SB1[1] | pixel_SB2[1];
    assign pixel [0] = pixel_obj [0] | pixel_paddle [0] | pixel_paddle2[0] | pixel_SB1[0] | pixel_SB2[0];
    assign led_kawser = 1;
     
    // We need to detect gameover
    reg[3:0] score_bot, score_top;
    reg game_over_eval, evaluate;
    reg [7 : 0 ] pause ;
    reg flag_topwin, flag_botwin;
    always @(posedge pixel_clk) begin 
        if(rst) begin 
            game_over               <= 1'b0; 
            game_over_eval          <= 1'b0; 
            evaluate                <= 1'b0;
            pause                   <= 0;
            active_passing          <= 1'b0; 
        end
        else begin   
            if(evaluate == 0) begin 
                if(fsync) begin 
                    evaluate <= 1'b1; 
                end;
                pause <= 0;
                active_passing <= 1'b0; 
            end
            else begin 
                if(game_over_eval == 0) begin 
                    if((vpos == VRES - PADDLE_H && active_obj) || (vpos == PADDLE_H - 1 && active_obj)) begin
                        
                        if (vpos == PADDLE_H - 1 && active_obj) begin
                            flag_botwin <= 1;
                            flag_topwin <= 0;
                        end
                        else begin
                            flag_topwin <= 1;
                            flag_botwin <= 0;
                        end
                        
                        active_passing <= 1'b1; 
                        if (active_paddle) begin 
                            evaluate <= 1'b0;
                        end
                    end
                    else if (active_passing) begin 
                        if(~active_obj) begin 
                            game_over_eval <= 1'b1; 
                        end
                    end
                end
                else if (fsync) begin 
                    if(pause == RESTART_PAUSE) begin
                        game_over_eval <= 1'b0;
                        evaluate <= 1'b0; 
                        game_over <= 1'b0;

                        if (flag_botwin == 1) begin
                            flag_botwin <= 0;
                            if (score_bot < 9) begin
                                score_bot <= score_bot + 1;
                                rst_zsp <= 0;
                            end
                            else begin
                                score_bot <= 0;
                                score_top <= 0;
                                rst_zsp <= 1;
                            end
                        end
                        
                        if(flag_topwin == 1) begin
                            flag_topwin <= 0;
                            if (score_top < 9) begin
                                score_top <= score_top + 1;
                                rst_zsp <= 0;
                            end
                            else begin
                                score_top <= 0;
                                score_bot <= 0;
                                rst_zsp <= 1;
                            end
                        end
                    end
                    else begin 
                        pause <= pause + 1; 
                        game_over <= 1'b1; 
                    end
                end
            end 
        end 
    end

endmodule