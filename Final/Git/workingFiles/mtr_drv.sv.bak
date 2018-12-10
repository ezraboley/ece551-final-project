module mtr_drv(clk, rst_n, lft_spd, lft_rev, PWM_rev_lft, PWM_frwrd_lft, rght_spd, rgt_rev, PWM_rev_rght, PWM_frwrd_rght);

input clk, rst_n, lft_rev, rght_rev;
input [10:0] lft_spd, rght_spd;
output PWM_rev_lft, PWM_frwrd_lft, PWM_rev_rght, PWM_frwrd_rght;

//create wires for pwm outputs
wire PWM_rght_out, PWM_lft_out;


//instatntiate pwm to drive right motor
PWM11 RGHT_DRV(.clk(clk), .rst_n(rst_n), .duty(rght_spd), .PWM_sig(PWM_rght_out));

PWM11 LFT_DRV(.clk(clk), .rst_n(rst_n), .duty(lft_spd), .PWM_sig(PWM_lft_out));


//assign the outputs as high only if the respectvie pwm is high and appropriate rev sig

assign PWM_frwrd_rght = PWM_rght_out && !(rght_rev);
assign PWM_rev_rght = PWM_rght_out && rght_rev;
assign PWM_frwrd_lft = PWM_lft_out && !(lft_rev);
assign PWM_rev_lft = PWM_lft_out && lft_rev;


endmodule
