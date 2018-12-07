module inert_intf_tb();
//inputs and outputs of blocks
reg PWM_rev_lft, PWM_frwrd_lft, PWM_rev_rght, PWM_frwrd_rght, clk, rst_n;
reg signed[13:0] rider_lean;
wire INT, SS_n, SCLK, MOSI, MISO, vld;
wire [15:0] ptch;

//instantiate modules
SegwayModel MODEL(.clk(clk), .RST_n(rst_n), .SS_n(SS_n), .SCLK(SCLK), .MISO(MISO), .MOSI(MOSI), .INT(INT), 
	.PWM_rev_rght(PWM_rev_rght), .PWM_frwrd_rght(PWM_frwrd_rght), .PWM_rev_lft(PWM_rev_lft), 
	.PWM_frwrd_lft(PWM_frwrd_lft), .rider_lean(rider_lean));

inert_intf iDUT(.clk(clk), .rst_n(rst_n), .INT(INT), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO), 
	.vld(vld), .ptch(ptch));


//run test
initial begin
  //set initial values
  PWM_rev_lft = 1'b0;
  PWM_frwrd_lft = 1'b0;
  PWM_rev_rght = 1'b0;
  PWM_frwrd_rght = 1'b0;
  rider_lean = 14'h0100;
  clk = 0;
  rst_n = 0;
  //test rst_n
  repeat(2)@(negedge clk);
  rst_n = 1;
  @(posedge clk)
  //stop sim after 20 vld readings
  @(posedge MODEL.NEMO_setup);
  repeat(500000)@(posedge clk);
  $stop;

end

//make clock
always
  #5 clk = ~clk;


endmodule
