module balance_cntrl(clk, rst_n, too_fast, vld, ptch, ld_cell_diff, lft_spd, lft_rev, rght_spd, rght_rev, rider_off, en_steer, pwr_up);
								
  input clk,rst_n, pwr_up;
  input vld;						// tells when a new valid inertial reading ready
  input signed [15:0] ptch;			// actual pitch measured
  input signed [11:0] ld_cell_diff;	// lft_ld - rght_ld from steer_en block
  input rider_off;					// High when weight on load cells indicates no rider
  input en_steer;
  output [10:0] lft_spd;			// 11-bit unsigned speed at which to run left motor
  output lft_rev;					// direction to run left motor (1==>reverse)
  output [10:0] rght_spd;			// 11-bit unsigned speed at which to run right motor
  output rght_rev;					// direction to run right motor (1==>reverse)
  output too_fast;

  ////////////////////////////////////
  // Define needed registers below //
  //////////////////////////////////
	//P term regs
  wire signed[9:0] ptch_err_sat;
  wire signed[14:0] ptch_p_term;
  reg signed[14:0] ptch_p_ff;
	//I term regs
  wire signed[17:0] ptch_err_sat_ext, accum, imux1, imux2;
  reg signed [17:0] iflop;
  wire signed[11:0] ptch_i_term;
  wire overflow, valid;
	//D term regs
  wire signed[9:0] dmux1, dmux2, ptch_d_diff;
  reg signed[9:0] dflop, prev_ptch_err;
  wire signed[6:0] ptch_d_diff_sat;
  wire signed[12:0] ptch_d_term;
  reg signed[12:0] ptch_d_ff;

	//Math regs
  wire signed[15:0] pid_cntrl, rght_trq, lft_trq, sum, diff;
  wire signed[15:0] ld_cell_ext, p_ext, i_ext, d_ext;
  reg signed[15:0] rght_trq_ff, lft_trq_ff;

	//Shaping regs
  wire[14:0] lft_abs, rght_abs, lft_shaped_abs, rght_shaped_abs;
  wire signed[15:0] lft_shaped, rght_shaped, lft_min, rght_min;
  wire unsigned[10:0] lft_spd, rght_spd;
  wire lft_rev, rght_rev, lft_gt, rght_gt;
  reg signed[15:0] lft_shaped_ff, rght_shaped_ff;
   
  ///////////////////////////////////////////
  // Define needed internal signals below //
  /////////////////////////////////////////

  /////////////////////////////////////////////
  // local params for increased flexibility //
  ///////////////////////////////////////////
  localparam P_COEFF = 5'h0E;
  localparam D_COEFF = 6'h14;				// D coefficient in PID control = +20
  localparam SPEED_THRESH = 1536;
  localparam LOW_TORQUE_BAND = 8'h46;	// LOW_TORQUE_BAND = 5*P_COEFF
  localparam GAIN_MULTIPLIER = 6'h0F;	// GAIN_MULTIPLIER = 1 + (MIN_DUTY/LOW_TORQUE_BAND)
  localparam MIN_DUTY = 15'h03D4;		// minimum duty cycle (stiffen motor and get it ready)
  
  parameter fast_sim = 0;
  
  assign too_fast = lft_spd > SPEED_THRESH || rght_spd > SPEED_THRESH ? 1 : 0;

  //P term
	assign ptch_err_sat = ptch[15] ? (&ptch[14:9] ? {ptch[15],ptch[8:0]} : 10'h200) : (|ptch[14:9] ? 10'h1FF : ptch[9:0]); //10 bit saturation of ptch
	assign ptch_p_term = ptch_err_sat<<<4 - ptch_err_sat - ptch_err_sat;
	always@(posedge clk, negedge rst_n) begin
		if(!rst_n) ptch_p_ff <= 0;
		else ptch_p_ff <= ptch_p_term;
	end

  //I term
	assign ptch_err_sat_ext = {{8{ptch_err_sat[9]}},ptch_err_sat[9:0]}; //Sign extend saturated ptch value
	assign accum = ptch_err_sat_ext + iflop;
	assign overflow = (ptch_err_sat_ext[17] == iflop[17]) && (accum[17] != iflop[17]) ? 1 : 0; //Check if accumulator has overflow
	assign valid = vld && ~overflow ? 1 : 0; //Verify that accumulated value is valid
	assign imux1 = valid ? accum : iflop;
	assign imux2 = (rider_off || ~pwr_up) ? 18'h00000 : imux1;
	always@(posedge clk, negedge rst_n) begin
		if(!rst_n) iflop <= 18'h00000;
		else iflop <= imux2;
	end
	assign ptch_i_term = iflop[17:6];

  //D term
	assign dmux1 = vld ? ptch_err_sat : dflop;
	assign ptch_d_diff = ptch_err_sat - prev_ptch_err;
	assign ptch_d_diff_sat = ptch_d_diff[9] ? (&ptch_d_diff[8:6] ? {ptch_d_diff[9],ptch_d_diff[5:0]} : 7'h40) : (|ptch_d_diff[8:6] ? 7'h3F : ptch_d_diff[6:0]); // 7 bit saturation of ptch_D_diff
	assign ptch_d_term = ptch_d_diff_sat * ($signed(D_COEFF));
	always@(posedge clk, negedge rst_n) begin
		if(!rst_n) ptch_d_ff <= 0;
		else ptch_d_ff <= ptch_d_term;
	end
	always@(posedge clk, negedge rst_n) begin
		if(!rst_n) dflop <= 10'h000;
		else dflop <= dmux1;
	end
	assign dmux2 = vld ? dflop : prev_ptch_err;
	always@(posedge clk, negedge rst_n) begin //Flop that stores previous ptch_err
		if(!rst_n) prev_ptch_err <= 10'h000;
		else prev_ptch_err <= dmux2;
	end

  //PID Math
	assign ld_cell_ext = {{8{ld_cell_diff[11]}},ld_cell_diff[11:3]};
	assign p_ext = {ptch_p_ff[14],ptch_p_ff[14:0]};
	assign i_ext = fast_sim ? iflop[17:2] : {{4{ptch_i_term[11]}},ptch_i_term[11:0]};
	assign d_ext = {{3{ptch_d_ff[12]}},ptch_d_ff[12:0]};
	assign pid_cntrl = p_ext + i_ext + d_ext; //Sum of all PID terms (sign extended)
	assign diff = pid_cntrl - ld_cell_ext;
	assign sum = pid_cntrl + ld_cell_ext;
	assign rght_trq = en_steer ? sum : pid_cntrl;
	always@(posedge clk, negedge rst_n) begin
		if(!rst_n) rght_trq_ff <= 0;
		else rght_trq_ff <= rght_trq;
	end
	assign lft_trq = en_steer ? diff : pid_cntrl;
	always@(posedge clk, negedge rst_n) begin
		if(!rst_n) lft_trq_ff <= 0;
		else lft_trq_ff <= lft_trq;
	end

  //Shaping torque
	assign lft_abs = lft_trq_ff[15] ? (~lft_trq_ff[14:0] + 1) : lft_trq_ff[14:0]; //Absolute value of lft_trq
	assign rght_abs = rght_trq_ff[15] ? (~rght_trq_ff[14:0] + 1) : rght_trq_ff[14:0]; //Absolute value of rght_trq
	assign lft_gt = lft_abs >= LOW_TORQUE_BAND ? 1 : 0; //Magnitude compare
	assign rght_gt = rght_abs >= LOW_TORQUE_BAND ? 1 : 0; //Magnitude compare
	assign lft_min = lft_trq_ff[15] ? (~MIN_DUTY + 1) : MIN_DUTY; //Based on sign of lft_trq, change sign of MIN_duty to follow addition/subtraction
	assign rght_min = rght_trq_ff[15] ? (~MIN_DUTY + 1) : MIN_DUTY; //Based on sign of rght_trq, change sign of MIN_duty to follow addition/subtraction
	assign lft_shaped = lft_gt ? (lft_trq_ff + lft_min) : (lft_trq_ff<<<4) - lft_trq_ff;
	always@(posedge clk, negedge rst_n) begin
		if(!rst_n) lft_shaped_ff <= 0;
		else lft_shaped_ff <= lft_shaped;
	end
	assign rght_shaped = rght_gt ? (rght_trq_ff + rght_min) : (rght_trq_ff<<<4) - rght_trq_ff;
	always@(posedge clk, negedge rst_n) begin
		if(!rst_n) rght_shaped_ff <= 0;
		else rght_shaped_ff <= rght_shaped;
	end
	assign lft_rev = lft_shaped_ff[15];
	assign rght_rev = rght_shaped_ff[15];
	assign lft_shaped_abs = lft_rev ? (~lft_shaped_ff[14:0] + 1) : lft_shaped_ff[14:0]; //Absolute value of lft_shaped
	assign rght_shaped_abs = rght_rev ? (~rght_shaped_ff[14:0] + 1) : rght_shaped_ff[14:0]; //Absolute value of rght_shaped
	assign lft_spd = pwr_up ? (|lft_shaped_abs[14:11] ? 11'h7FF : lft_shaped_abs[10:0]) : 0; //11 bit unsigned saturation of absolute value of lft_shaped
	assign rght_spd = pwr_up ? (|rght_shaped_abs[14:11] ? 11'h7FF : rght_shaped_abs[10:0]) : 0; //11 bit unsigned saturation of absolute value of rght_shaped
	
	




endmodule 
