module en_steer(clk, rst_n, lft_ld, rght_ld, en_steer, rider_off, ld_cell_diff);
  input clk;				// 50MHz clock
  input rst_n;				// Active low asynch reset
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
  
  output signed [11:0] ld_cell_diff;	// difference of left and right loads
  wire diff_gt_1_4;		// asserted if load cell difference exceeds 1/4 sum (rider not situated)
  wire diff_gt_15_16;		// asserted if load cell difference is great (rider stepping off)
  output reg en_steer;	// enables steering (goes to balance_cntrl)
  output reg rider_off;	// pulses high for one clock on transition back to initial state

  localparam MIN_RIDER_WEIGHT = 12'h200;
  parameter fast_sim = 0;
  reg clr_tmr;
  wire tmr_full;
  reg[25:0] tmr;
  wire[11:0] diff_abs;

  //assign statements
  assign ld_cell_diff = lft_ld - rght_ld;
  assign diff_abs = ld_cell_diff[11] ? (~ld_cell_diff[10:0] + 1) : ld_cell_diff[10:0]; //[10:0]
  assign diff_gt_1_4 = diff_abs > (lft_ld + rght_ld)>>2; //shift rather than /4
  assign diff_gt_15_16 = diff_abs > (lft_ld + rght_ld) - ((lft_ld + rght_ld)>>4); //shift rather than 15/6
  assign sum_gt_min = (lft_ld + rght_ld) > MIN_RIDER_WEIGHT ? 1 : 0;
  assign tmr_full = fast_sim ? &tmr[14:0] : &tmr[25:0]; 

  // You fill out the rest...use good SM coding practices ///
  typedef enum reg [1:0] {IDLE, WAIT, STEER_EN} state_t;
  state_t state, next_state; 	
  
  always@(posedge clk) begin
	if(clr_tmr) tmr <= 0;
	else tmr <= tmr + 1;
  end

  // infer state ffs //
  always_ff @(posedge clk, negedge rst_n) 
    if (!rst_n)    
	state <= IDLE;
    else    
	state <= next_state;
  
  always_comb begin
	//Define default values
	clr_tmr = 0;
	en_steer = 0;
	rider_off = 0;
	next_state = IDLE;
	case (state)
		IDLE : 	if(sum_gt_min) begin //Wait for rider to get on
			 next_state = WAIT;
			 clr_tmr = 1;
			end
			else begin
				next_state = IDLE;
				rider_off = 1;
			end
		WAIT : if(~sum_gt_min) begin //Check if rider has fallen/stepped off
			 next_state = IDLE;
			 rider_off = 1;
			end
			else if(diff_gt_1_4) begin //Wait for rider to stabilize
			 next_state = WAIT;
			 clr_tmr = 1;
			end
			else if(tmr_full) begin //Enable steering once rider is stable
			 next_state = STEER_EN;
			 en_steer = 1;
			end
			else next_state = state;
		STEER_EN : if(~sum_gt_min) begin //Check if rider has fallen/stepped off 
			 next_state = IDLE;
			 rider_off = 1;
			end
			else if(diff_gt_15_16) begin //Check if rider has gotten off
			 next_state = WAIT;
			 clr_tmr = 1;
			end
			else begin //Keep steering enabled if rider stays on
			  en_steer = 1;
			  next_state = state;
			end
		default next_state = IDLE;
	endcase
   end
 
endmodule
