module balance_cntrl(clk,rst_n,vld,ptch,ld_cell_diff,lft_spd,lft_rev,
                     rght_spd,rght_rev,rider_off, en_steer, pwr_up);
								
  input clk, rst_n, pwr_up;
  input vld;						// Says when new reading is ready
  input signed [15:0] ptch;			// measured pitch
  input signed [11:0] ld_cell_diff;	// Diff in cell loads from en_steer
  input rider_off;					// high if the weight falls under threshold
  input en_steer;
  output [10:0] lft_spd;			// Left motor speed
  output lft_rev;					// direction left motor spins
  output [10:0] rght_spd;			// Right motor speed
  output rght_rev;					// direction right motor spins
  
  ////////////////////////////////////
  // Define needed registers below //
  //////////////////////////////////
	
	//P term
  reg signed[9:0] ptch_err_sat;
  reg signed[14:0] ptch_p_term;
	
	
	//I term
  reg signed[17:0] ptch_err_sat_ext, accum, imux1_2, imux2, iflop;
  reg signed[11:0] ptch_i_term;
  reg overflow, valid;
	
	
	//D term
  reg signed[9:0] dmux1_2, dmux2, dflop, prev_ptch_err, ptch_d_diff;
  reg signed[6:0] ptch_d_diff_sat;
  reg signed[12:0] ptch_d_term;

  
	//Math
  reg signed[15:0] pid_cntrl, rght_trq, lft_trq, sum, diff;
  reg signed[15:0] ld_cell_ext, p_ext, i_ext, d_ext;

  
	//Shaping
  reg[14:0] lft_abs, rght_abs, lft_shaped_abs, rght_shaped_abs;
  reg signed[15:0] lft_shaped, rght_shaped, lft_min, rght_min;
  reg[10:0] lft_spd, rght_spd;
  reg lft_rev, rght_rev, lft_gt, rght_gt;
   
  ///////////////////////////////////////////
  // Define needed internal signals below //
  /////////////////////////////////////////

  /////////////////////////////////////////////
  // local params for increased flexibility //
  ///////////////////////////////////////////
  localparam P_COEFF = 5'h0E;
  localparam D_COEFF = 6'h14;				// D coefficient in PID control = +20 
    
  localparam LOW_TORQUE_BAND = 8'h46;	// LOW_TORQUE_BAND = 5*P_COEFF
  localparam GAIN_MULTIPLIER = 6'h0F;	// GAIN_MULTIPLIER = 1 + (MIN_DUTY/LOW_TORQUE_BAND)
  localparam MIN_DUTY = 15'h03D4;		// minimum duty cycle (stiffen motor and get it ready)
  
  //P term
	assign ptch_err_sat = ptch[15] ? (&ptch[14:9] ? {ptch[15],ptch[8:0]} : 10'h200) : (|ptch[14:9] ? 10'h1FF : ptch[9:0]);
	assign ptch_p_term = ptch_err_sat * ($signed(P_COEFF));

  //I term
	assign ptch_err_sat_ext = {{8{ptch_err_sat[9]}},ptch_err_sat[9:0]};
	assign accum = ptch_err_sat_ext + iflop;
	
	assign overflow = (ptch_err_sat_ext[17] == iflop[17]) && (accum[17] != iflop[17]);
	assign valid = vld & ~overflow;
	
	assign imux1_2 = valid ? accum : iflop;
	assign imux2 = (rider_off || ~pwr_up) ? 18'h00000 : imux1_2;	// pwr_up
	
	always@(posedge clk, negedge rst_n) begin
		if(!rst_n) iflop <= 18'h00000;
		else iflop <= imux2;
	end
	
	assign ptch_i_term = iflop[17:6];
	
  //D term
	assign dmux1_2 = vld ? ptch_err_sat : dflop;
	
	assign ptch_d_diff = ptch_err_sat - prev_ptch_err;
	assign ptch_d_diff_sat = ptch_d_diff[9] ? (&ptch_d_diff[8:6] ? {ptch_d_diff[9],ptch_d_diff[5:0]} : 7'h40) : (|ptch_d_diff[8:6] ? 7'h3F : ptch_d_diff[6:0]);
	
	assign ptch_d_term = ptch_d_diff_sat * ($signed(D_COEFF));
	
	always@(posedge clk, negedge rst_n) begin
		if(!rst_n) dflop <= 10'h000;
		else dflop <= dmux1_2;
	end
	
	assign dmux2 = vld ? dflop : prev_ptch_err;
	
	always@(posedge clk, negedge rst_n) begin
		if(!rst_n) prev_ptch_err <= 10'h000;
		else prev_ptch_err <= dmux2;
	end

  //PID Math
	assign ld_cell_ext = {{8{ld_cell_diff[11]}},ld_cell_diff[11:3]};
	
	assign p_ext = {ptch_p_term[14],ptch_p_term[14:0]};
	assign i_ext = {{4{ptch_i_term[11]}},ptch_i_term[11:0]};
	assign d_ext = {{3{ptch_d_term[12]}},ptch_d_term[12:0]};
	assign pid_cntrl = p_ext + i_ext + d_ext;
	
	assign diff = pid_cntrl - ld_cell_ext;
	
	assign sum = pid_cntrl + ld_cell_ext;
	
	assign rght_trq = en_steer ? sum : pid_cntrl;
	assign lft_trq = en_steer ? diff : pid_cntrl;

  //Shaping torque
	assign lft_abs = lft_trq[15] ? (~lft_trq[14:0] + 1) : lft_trq[14:0];
	assign rght_abs = rght_trq[15] ? (~rght_trq[14:0] + 1) : rght_trq[14:0];
	
	assign lft_gt = lft_abs >= LOW_TORQUE_BAND;
	assign rght_gt = rght_abs >= LOW_TORQUE_BAND;
	
	assign lft_min = lft_trq[15] ? (~MIN_DUTY + 1) : MIN_DUTY;
	assign rght_min = rght_trq[15] ? (~MIN_DUTY + 1) : MIN_DUTY;
	
	assign lft_shaped = lft_gt ? (lft_trq + lft_min) : (lft_trq * ($signed(GAIN_MULTIPLIER)));
	assign rght_shaped = rght_gt ? (rght_trq + rght_min) : (rght_trq * ($signed(GAIN_MULTIPLIER)));
	
	assign lft_rev = lft_shaped[15];
	assign rght_rev = rght_shaped[15];
	
	assign lft_shaped_abs = lft_rev ? (~lft_shaped[14:0] + 1) : lft_shaped[14:0];
	assign rght_shaped_abs = rght_rev ? (~rght_shaped[14:0] + 1) : rght_shaped[14:0];
	
	assign lft_spd = |lft_shaped_abs[14:11] ? 11'h7FF : lft_shaped_abs[10:0];
	assign rght_spd = |rght_shaped_abs[14:11] ? 11'h7FF : rght_shaped_abs[10:0];




endmodule 
