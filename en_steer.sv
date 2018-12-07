module en_steer(clk,rst_n,tmr_full,lft_ld, rght_ld,clr_tmr,en_steer,rider_off);

  input clk;				// 50MHz clock
  input rst_n;				// Active low asynch reset
  input tmr_full;			// asserted when timer reaches 1.3 sec
  wire sum_gt_min;			// asserted when left and right load cells together exceed min rider weight
  //wire sum_lt_min;
  /////////////////////////////////////////////////////////////////////////////
  // HEY BUDDY...you are a moron.  sum_gt_min would simply be ~sum_lt_min. Why
  // have both signals coming to this unit??  ANSWER: What if we had a rider
  // (a child) who's weigth was right at the threshold of MIN_RIDER_WEIGHT?
  // We would enable steering and then disable steering then enable it again,
  // ...  We would make that child crash(children are light and flexible and 
  // resilient so we don't care about them, but it might damage our Segway).
  // We can solve this issue by adding hysteresis.  So sum_gt_min is asserted
  // when the sum of the load cells exceeds MIN_RIDER_WEIGHT + HYSTERESIS and
  // sum_lt_min is asserted when the sum of the load cells is less than
  // MIN_RIDER_WEIGHT - HYSTERESIS.  Now we have noise rejection for a rider
  // who's wieght is right at the threshold.  This hysteresis trick is as old
  // as the hills, but very handy...remember it.
  //////////////////////////////////////////////////////////////////////////// 

  input [11:0] lft_ld; // load form left cell
  input [11:0] rght_ld; // load from right cell
  
  wire [11:0] diff;		// difference of left and right loads
  wire diff_gt_1_4;		// asserted if load cell difference exceeds 1/4 sum (rider not situated)
  wire diff_gt_15_16;		// asserted if load cell difference is great (rider stepping off)
  output logic clr_tmr;		// clears the 1.3sec timer
  output logic en_steer;	// enables steering (goes to balance_cntrl)
  output logic rider_off;	// pulses high for one clock on transition back to initial state

  localparam MIN_RIDER_WEIGHT = 12'h200;

  //assign statements
  assign diff = lft_ld - rght_ld;
  assign diff_gt_1_4 = diff[11] ? ((~diff + 1) > (lft_ld + rght_ld)/4 ? 1 : 0) : diff > (lft_ld + rght_ld)/4 ? 1 : 0;
  assign diff_gt_15_16 = diff[11] ? ((~diff + 1) > (lft_ld + rght_ld)*15/16 ? 1 : 0) : diff > (lft_ld + rght_ld)*15/16 ? 1 : 0;
  assign sum_gt_min = (lft_ld + rght_ld) > MIN_RIDER_WEIGHT ? 1 : 0;
  //assign sum_lt_min = (lft_ld + rght_ld) < MIN_RIDER_WEIGHT ? 1 : 0;
  
  // You fill out the rest...use good SM coding practices ///
  typedef enum reg [1:0] {START, STEER, WAIT} state_t;
  state_t state, nxt_state; 	
  
  // infer state ffs //
  always_ff @(posedge clk, negedge rst_n) 
    if (!rst_n)    
	state <= START;
    else    
	state <= nxt_state;
  
  always_comb begin
    ///// default outputs /////
    en_steer = 0;
    rider_off = 0;
    clr_tmr = 0;
    nxt_state = START;
    case (state)
      STEER : if (diff_gt_15_16 && sum_gt_min) begin
	en_steer = 0;
	clr_tmr = 1;
	nxt_state = WAIT;
      end else if(sum_gt_min && !(diff_gt_15_16)) begin
	en_steer = 1;
	rider_off = 0;
	nxt_state = STEER;
      end else begin
	en_steer = 0;
	clr_tmr = 1;
	rider_off = 1;
	nxt_state = START;

      end

      WAIT : if(!sum_gt_min) begin
	en_steer = 0;
	clr_tmr = 1;
	rider_off = 1;
	nxt_state = START;
      end else if(diff_gt_1_4) begin
	en_steer = 0;
	clr_tmr = 1;
	rider_off = 0;
	nxt_state = WAIT;
      end else if(tmr_full) begin
	en_steer = 1;
	rider_off = 0;
	nxt_state = STEER;
      end else begin
	nxt_state = WAIT;
      end 


    ///// START /////
    START : if (sum_gt_min) begin
	en_steer = 0;
	clr_tmr = 1;
	nxt_state = WAIT;
    end else begin
	//en_steer = 0;
	nxt_state = START;
    end
    
    ////// default /////
    default :
      nxt_state = START;
   
    endcase
  end
    
  
endmodule
