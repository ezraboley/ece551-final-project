module Segway(clk,RST_n,LED,INERT_SS_n,INERT_MOSI,
              INERT_SCLK,INERT_MISO,A2D_SS_n,A2D_MOSI,A2D_SCLK,
			  A2D_MISO,PWM_rev_rght,PWM_frwrd_rght,PWM_rev_lft,
			  PWM_frwrd_lft,piezo_n,piezo,INT,RX);
			  
  input clk,RST_n;
  input INERT_MISO;						// Serial in from inertial sensor
  input A2D_MISO;						// Serial in from A2D
  input INT;							// Interrupt from inertial indicating data ready
  input RX;								// UART input from BLE module

  
  output [7:0] LED;						// These are the 8 LEDs on the DE0, your choice what to do
  output A2D_SS_n, INERT_SS_n;			// Slave selects to A2D and inertial sensor
  output A2D_MOSI, INERT_MOSI;			// MOSI signals to A2D and inertial sensor
  output A2D_SCLK, INERT_SCLK;			// SCLK signals to A2D and inertial sensor
  output PWM_rev_rght, PWM_frwrd_rght;  // right motor speed controls
  output PWM_rev_lft, PWM_frwrd_lft;	// left motor speed controls
  output piezo_n,piezo;					// diff drive to piezo for sound
  
  ////////////////////////////////////////////////////////////////////////
  // fast_sim is asserted to speed up fullchip simulations.  Should be //
  // passed to both balance_cntrl and to steer_en.  Should be set to  //
  // 0 when we map to the DE0-Nano.                                  //
  ////////////////////////////////////////////////////////////////////
  parameter fast_sim = 0;	// asserted to speed up simulations. 
  
  ///////////////////////////////////////////////////////////
  ////// Internal interconnecting sigals defined here //////
  /////////////////////////////////////////////////////////
  wire rst_n;                           // internal global reset that goes to all units
  wire pwr_up;				// comes from Auth_blk that turns on segway
  wire [11:0] lft_ld; 			// left load value supplied to en_steer from A2D intf
  wire [11:0] rght_ld; 			// right load value supplied to en_steer from A2D intf
  wire [11:0] batt;			// battery value supplied to en_steer from A2D intf
  wire nxt;				// tells the A2D intf to begin next conversion
  wire [10:0] lft_spd;			// speed of left motor send into motor driver
  wire rider_off;			// high when the rider is no longer on the Segway
  wire [10:0] rght_spd;			// speed of right motor send into motor driver
  wire lft_rev;				// tells motor driver which direction to drive left motor
  wire rght_rev;			// tells motor driver which direction to drive right motor
  wire en_steer;			// signal for normal operation when moving
  wire ovr_spd;				// signals that segway is moving too fast
  wire batt_low;			// signals that battery is running low
  // You will need to declare a bunch more interanl signals to hook up everything
  
  ////////////////////////////////////
   
  
  ///////////////////////////////////////////////////////
  // How you arrange the hierarchy of the top level is up to you.
  //
  // You could make a level of hierarchy called digital core
  // as shown in the block diagram in the spec.
  //
  // Or you could just instantiate all the components of the Segway
  // flat.
  //
  // Just for reference all the needed blocks (in no particular order) would be:
  //   Auth_blk
  //   inert_intf
  //   balance_cntrl
  //   steer_en
  //   mtr_drv
  //   A2D_intf
  //   piezo
  //////////////////////////////////////////////////////
  
  // assign statements for piezo inputs

  //assign batt_low = batt < 12'h800 ? 1 : 0;

  ///////////////////////////
  // Instantiate AUTH_blk //
  /////////////////////////  
  AUTH_blk iAUTH(.clk(clk), .rst_n(rst_n), .RX(RX), .pwr_up(pwr_up), .rider_off(rider_off));

  ////////////////////////////////
  // Instantiate A2D interface //
  //////////////////////////////  
  A2D_intf iAINTF(.clk(clk), .rst_n(rst_n), .nxt(nxt), .lft_ld(lft_ld), 
    .rght_ld(rght_ld), .batt(batt), .SS_n(A2D_SS_n), .SCLK(A2D_SCLK),
    .MOSI(A2D_MOSI), .MISO(A2D_MISO));

  ///////////////////////////////
  // Instantiate motor driver //
  /////////////////////////////  
  mtr_drv iMTRD(.clk(clk), .rst_n(rst_n), .lft_spd(lft_spd), 
    .lft_rev(lft_rev), .PWM_rev_lft(PWM_rev_lft), .PWM_frwrd_lft(PWM_frwrd_lft),
    .rght_spd(rght_spd), .rght_rev(rght_rev), .PWM_rev_rght(PWM_rev_rght), 
    .PWM_frwrd_rght(PWM_frwrd_rght));

  ///////////////////////////////
  // Instantiate piezo driver //
  ///////////////////////////// 
  piezo iPIZZA(.clk(clk), .rst_n(rst_n), .batt_low(batt_low), .ovr_spd(ovr_spd), 
    .norm_mode(en_steer), .piezo(piezo), .piezo_n(piezo_n));

  //////////////////////////////////
  // Instantiate balance control //
  ////////////////////////////////
  /*balance_cntrl iBCNTRL(.clk(clk), .rst_n(rst_n), .vld(vld), .ptch(ptch), 
    .ld_cell_diff(ld_cell_diff), .lft_spd(lft_spd), .lft_rev(lft_rev), 
    .rght_spd(rght_spd), .rght_rev(rght_rev), .rider_off(rider_off), 
    .en_steer(en_steer), .too_fast(ovr_spd));*/

  //////////////////////////////////
  // Instantiate steering enable //
  //////////////////////////////// 
  /*steer_en iENST(.clk(clk), .rst_n(rst_n), .tmr_full(tmr_full), .lft_ld(lft_ld),
    .rght_ld(rght_ld), .clr_tmr(clr_tmr), .en_steer(en_steer),
    .rider_off(rider_off));*/

  /////////////////////////////////////
  // Instantiate inertial interface //
  ///////////////////////////////////
  /*inert_intf iInrt(.ptch(ptch), .vld(vld), .SCLK(INERT_SCLK), .SS_n(INERT_SS_n), 
    .MOSI(INERT_MOSI), .MISO(INERT_MISO), .INT(INT), .clk(clk), .rst_n(rst_n));*/

  
  Digital_Core iDC(clk, rst_n, pwr_up, lft_ld, rght_ld, batt, nxt, INERT_SS_n, INERT_SCLK, INERT_MOSI, INERT_MISO, INT, batt_low, ovr_spd, en_steer, rght_rev, rght_spd, lft_rev, lft_spd, rider_off);
	
  /////////////////////////////////////
  // Instantiate reset synchronizer //
  ///////////////////////////////////  
  rst_synch iRST(.clk(clk),.RST_n(RST_n),.rst_n(rst_n));
  
endmodule
