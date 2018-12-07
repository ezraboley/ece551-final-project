module en_steer_tb();
	reg clk,r rst_n, tmr_full, nxt;
	reg [11:0] lft_ld, rght_ld, batt;
	wire clr_tmr, en_steer, rider_off, SS_n, SCLK, MOSI, MISO;

	en_steer iDUT(.clk(clk), .rst_n(rst_n), .tmr_full(tmr_full), .lft_ld(lft_ld), .rght_ld(rght_ld), .clr_tmr(clr_tmr), .en_steer(en_steer), .rider_off(rider_off));
	A2D_intf a2d(.clk(clk), .rst_n(rst_n), .nxt(nxt), .lft_ld(lft_ld), .rght_ld(rght_ld), .batt(batt), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO));

	initial clk = 0;


	always #5 clk = ~clk;
endmodule
