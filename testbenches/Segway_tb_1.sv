module Segway_tb_1();

//// Interconnects to DUT/support defined as type wire /////
wire SS_n,SCLK,MOSI,MISO,INT;				// to inertial sensor
wire A2D_SS_n,A2D_SCLK,A2D_MOSI,A2D_MISO;	// to A2D converter
wire RX_TX;
wire PWM_rev_rght, PWM_frwrd_rght, PWM_rev_lft, PWM_frwrd_lft;
wire piezo,piezo_n;

////// Stimulus is declared as type reg ///////
reg clk, RST_n;
reg [7:0] cmd;					// command host is sending to DUT
reg send_cmd;					// asserted to initiate sending of command
reg signed [13:0] rider_lean;	// forward/backward lean (goes to SegwayModel)
// Perhaps more needed?
reg [11:0] ld_cell_lft;		// load on left segway cell
reg [11:0] ld_cell_rght;	// load on right segway cell 
reg [11:0] batt_V;		// battery voltage 


/////// declare any internal signals needed at this level //////
wire cmd_sent;
// Perhaps more needed?
//counter for rider_lean
reg [12:0] lean_counter;
reg zero;
reg [12:0] i;
////////////////////////////////////////////////////////////////
// Instantiate Physical Model of Segway with Inertial sensor //
//////////////////////////////////////////////////////////////	
SegwayModel iPHYS(.clk(clk),.RST_n(RST_n),.SS_n(SS_n),.SCLK(SCLK),
                  .MISO(MISO),.MOSI(MOSI),.INT(INT),.PWM_rev_rght(PWM_rev_rght),
				  .PWM_frwrd_rght(PWM_frwrd_rght),.PWM_rev_lft(PWM_rev_lft),
				  .PWM_frwrd_lft(PWM_frwrd_lft),.rider_lean(rider_lean));				  

/////////////////////////////////////////////////////////
// Instantiate Model of A2D for load cell and battery //
///////////////////////////////////////////////////////
/*  What is this?  You need to build some kind of wrapper around ADC128S.sv or perhaps
  around SPI_ADC128S.sv that mimics the behavior of the A2D converter on the DE0 used
  to read ld_cell_lft, ld_cell_rght and battery
  */
ADC128S adc(.clk(clk), .rst_n(RST_n), .SS_n(A2D_SS_n), .SCLK(SCLK), .MISO(A2D_MISO), .MOSI(A2D_MOSI), .ld_cell_lft(ld_cell_lft), .ld_cell_rght(ld_cell_rght), .batt_V(batt_V));

////// Instantiate DUT ////////
Segway iDUT(.clk(clk),.RST_n(RST_n),.LED(),.INERT_SS_n(SS_n),.INERT_MOSI(MOSI),
            .INERT_SCLK(SCLK),.INERT_MISO(MISO),.A2D_SS_n(A2D_SS_n),
			.A2D_MOSI(A2D_MOSI),.A2D_SCLK(A2D_SCLK),.A2D_MISO(A2D_MISO),
			.INT(INT),.PWM_rev_rght(PWM_rev_rght),.PWM_frwrd_rght(PWM_frwrd_rght),
			.PWM_rev_lft(PWM_rev_lft),.PWM_frwrd_lft(PWM_frwrd_lft),
			.piezo_n(piezo_n),.piezo(piezo),.RX(RX_TX));


	
//// Instantiate UART_tx (mimics command from BLE module) //////
//// You need something to send the 'g' for go ////////////////
UART_tx iTX(.clk(clk),.rst_n(RST_n),.TX(RX_TX),.trmt(send_cmd),.tx_data(cmd),.tx_done(cmd_sent));

always_ff@(posedge clk, negedge RST_n)begin
	if(~RST_n) lean_counter <= 0;
	else if(zero) lean_counter <= 0;
	else lean_counter <= lean_counter + 1;
	
end


initial begin
	//Initialize: perhaps you make a task that initializes everything?  
    	init_Segway;
  	RST_DUT_n;
 
//test 1: !'go' && rider_on -- not do anything
	repeat(5)clock;
	ld_cell_lft = 12'h150;
	ld_cell_rght = 12'h156;
	
	repeat(15)clock;

//test 2: send 'go' to power up the segway -- pwr_up?
//		  rider hop-up -- load on 
//		ld_cell_lft + ld_cell_rght > 12'h200

	clock;
	send_g;
	clock;
	ld_cell_lft = 12'h150;
	ld_cell_rght = 12'h156;
	repeat(5)clock;
	

//test 3: maintain balance: ld_cell_lft = ld_cell_rght, rider_lean = 0;
	ld_cell_lft = 12'h150;
	ld_cell_rght = 12'h156;
	for(i = 0; i < 5000; i= i + 1 )begin
	clock;
	rider_lean = lean_counter;
	end
	repeat(5)clock;
	zero = 1;
	repeat(3)clock;
	zero = 0 ;
	for(i = 0; i < 5000; i= i + 1 )begin
	clock;
	rider_lean = ~lean_counter + 1;
	end
	
//test 4: go left : ld_cell_lft = 12'h200,  ld_cell_rght = 12'h140
	ld_cell_lft = 12'h200;
	ld_cell_rght = 12'h140;
	rider_lean = 16'h0500;
	repeat(5)clock;
	rider_lean = 16'hF501;
	repeat(5)clock;

//test 5; go right : ld_cell_lft = 12'150, ld_cell_rght = 12'h202
// 
	ld_cell_lft = 12'h140;
	ld_cell_rght = 12'h200;
	rider_lean = 16'h0500;
	repeat(5)clock;
	rider_lean = 16'hF501;
	repeat(5)clock;
	
//teet 10: still on, no signal sent; one foot off -- disable en_steer, waiting-- rider_off =1;
	ld_cell_lft = 12'h140;
	ld_cell_rght = 12'h0;
	repeat(15)clock;
	ld_cell_lft = 12'h140;
	ld_cell_rght = 12'h145;	
	repeat(5)clock;
	
	
//test 8: send 's', check still go
	send_s;
	repeat(5)clock;

//test 9: step off, check segway stopped 
	ld_cell_lft = 12'h0;
	ld_cell_rght = 12'h0;
	repeat(5)clock;


//
//  repeat(50000) @(posedge clk);
   


/* SendCmd(8'h67);	// perhaps you have a task that sends 'g'

    .
	.	// this is the "guts" of your test
	.
	*/
 // $display("YAHOO! test passed!");
  
  $stop();
end


always
  #5 clk = ~clk;

`include "tb_tasks.sv"	// perhaps you have a separate included file that has handy tasks.

endmodule	
