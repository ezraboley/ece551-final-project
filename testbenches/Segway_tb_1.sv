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
reg signed [15:0] rider_lean;	// forward/backward lean (goes to SegwayModel)
// Perhaps more needed?
reg [11:0] ld_cell_lft;		// load on left segway cell
reg [11:0] ld_cell_rght;	// load on right segway cell 
reg [11:0] batt_V;		// battery voltage 


/////// declare any internal signals needed at this level //////
wire cmd_sent;
// Perhaps more needed?
//counter for rider_lean
reg NEWTEST;
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
ADC128S adc(.clk(clk), .rst_n(RST_n), .SS_n(A2D_SS_n), .SCLK(A2D_SCLK), .MISO(A2D_MISO), .MOSI(A2D_MOSI), .ld_cell_lft(ld_cell_lft), .ld_cell_rght(ld_cell_rght), .batt_V(batt_V));

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

typedef enum {RIDER_ON, GO, LEAN, BALANCE, LEFT, RIGHT, LEFT_BACK, RIGHT_BACK, ONE_FOOT, FALL, STOP, RESTART} test_t;
test_t test;
initial begin
	//Initialize values and reset DUT
    	init_Segway;
  	RST_DUT_n;
 
//Test 1: RIDER_ON - rider steps on, but go command is NOT sent yet
	test = RIDER_ON;
	clock(50);
	ld_cell_lft = 12'h156;
	ld_cell_rght = 12'h156;
	
	clock(1500);

//Test 2: GO - send go command to power up the segway 
	test = GO;
	send_g;
	repeat(10)@(posedge iDUT.iDC.iINERT.wrt);
	clock(500);

//Test 3: LEAN - rider leans forward (extreme value to test correction) 
	rider_lean = 16'h1fff;
	clock(800000);
	rider_lean = 0;
	clock(800000);
	

//Test 4: BALANCE - gradually have rider lean forward then backward 
	test = BALANCE;
	for(i = 0; i < 500; i = i + 1)begin
		clock(100);
		rider_lean = rider_lean + 100;
	end
	clock(5);
	rider_lean = 0;
	clock(5);
	for(i = 0; i < 500; i= i + 1)begin
		clock(100);
		rider_lean = rider_lean - 100;
	end
	clock(5); 
	rider_lean = 0;
	clock(500);

//Test 5: LEFT - turn left
	test = LEFT;
	rider_lean = 16'h0A60;
	clock(350000);
	ld_cell_lft = 12'h200;
	ld_cell_rght = 12'h140;
	clock(350000);

	//Straighten out
	ld_cell_lft = 12'h200;
	ld_cell_rght = 12'h200;
	clock(350000);

//Test 6: RIGHT - turn right
	test = RIGHT;
	ld_cell_lft = 12'h140;
	ld_cell_rght = 12'h200;
	clock(350000);
	
	//Straighten out
	ld_cell_lft = 12'h200;
	ld_cell_rght = 12'h200;
	clock(350000);

//Test 7: LEFT_BACK - turn 'left' while leaning back
	test = LEFT_BACK;
	rider_lean = -16'h0A60;
	clock(350000);
	ld_cell_lft = 12'h200;
	ld_cell_rght = 12'h140;
	clock(350000);
	
	//Straighten out
	ld_cell_lft = 12'h200;
	ld_cell_rght = 12'h200;
	clock(350000);

//Test 8: RIGHT_BACK - turn 'right' while leaning back
	test = RIGHT_BACK;
	ld_cell_lft = 12'h140;
	ld_cell_rght = 12'h200;
	clock(350000);
	
	//Straighten out
	ld_cell_lft = 12'h200;
	ld_cell_rght = 12'h200;
	clock(350000);

//Test 9: ONE_FOOT - have rider on segway with only one foot
	test = ONE_FOOT;
	ld_cell_lft = 12'h240;
	ld_cell_rght = 12'h0;
	clock(350000);

	//Redistribute weight
	ld_cell_lft = 12'h140;
	ld_cell_rght = 12'h145;	
	clock(350000);
	
//Test 10: FALL - simulate rider falling off segway
	test = FALL;
	ld_cell_lft = 0;
	ld_cell_rght = 0;
	clock(35000);

//Test 11: STOP - send stop command to segway after rider has fallen off
	test = STOP;
	send_s;
	repeat(10)@(posedge iDUT.iDC.iINERT.wrt);
	clock(500);

//Test 12: RESTART - have segway power up again by sending go command
	test = RESTART;
	send_g;
	repeat(10)@(posedge iDUT.iDC.iINERT.wrt);
	clock(500);

	//Rider steps on and leans forward slightly
	ld_cell_lft = 12'h240;
	ld_cell_rght = 12'h240;
	clock(35000);
	rider_lean = 12'h0500;
	clock(350000);

  $stop();
end


always
  #10 clk = ~clk;

`include "tb_tasks.sv"	//Separate file containing tasks

endmodule	
