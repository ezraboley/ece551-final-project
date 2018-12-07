module balance_cntrl(clk,rst_n,vld,ptch,ld_cell_diff,lft_spd,lft_rev, rght_spd,rght_rev,rider_off, en_steer);
								
  input clk,rst_n;
  input vld;						// tells when a new valid inertial reading ready
  input signed [15:0] ptch;			// actual pitch measured
  input signed [11:0] ld_cell_diff;	// lft_ld - rght_ld from steer_en block
  input rider_off;					// High when weight on load cells indicates no rider
  input en_steer;
  output [10:0] lft_spd;			// 11-bit unsigned speed at which to run left motor
  output lft_rev;					// direction to run left motor (1==>reverse)
  output [10:0] rght_spd;			// 11-bit unsigned speed at which to run right motor
  output rght_rev;					// direction to run right motor (1==>reverse)
  
  ////////////////////////////////////
  // Define needed registers below //
  //////////////////////////////////
  reg signed [17:0] integrator;
  reg [9:0] ptch_err_mid;
  reg [9:0] prev_ptch_err;

  ///////////////////////////////////////////
  // Define needed internal signals below //
  /////////////////////////////////////////
  wire [9:0] ptch_err_sat;
  wire signed [14:0] ptch_P_term;
  wire signed [17:0] ptch_err_sat_ext;
  wire [17:0] accum_out;
  wire [17:0] integrator_in;
  wire ov;
  wire [9:0] ptch_err_mid_in, prev_ptch_err_in;
  wire signed [9:0] ptch_D_diff;
  wire signed [6:0] ptch_D_diff_sat;
  wire signed [12:0] ptch_D_term;
  wire [15:0] ld_cell_diff_ext, P_ext, I_ext, D_ext, PID_cntrl, lft_torque, rght_torque;
  wire [15:0] lft_torque_abs, rght_torque_abs;
  wire signed [15:0] lft_shaped, rght_shaped;
  wire [15:0] lft_shaped_abs, rght_shaped_abs;
  
  /////////////////////////////////////////////
  // local params for increased flexibility //
  ///////////////////////////////////////////
  localparam P_COEFF = 5'h0E;
  localparam D_COEFF = 6'h14;				// D coefficient in PID control = +20 
    
  localparam LOW_TORQUE_BAND = 8'h46;	// LOW_TORQUE_BAND = 5*P_COEFF
  localparam GAIN_MULTIPLIER = 6'h0F;	// GAIN_MULTIPLIER = 1 + (MIN_DUTY/LOW_TORQUE_BAND)
  localparam MIN_DUTY = 15'h03D4;		// minimum duty cycle (stiffen motor and get it ready)
  
  //// You fill in the rest ////
  // P Term
  assign ptch_err_sat = ptch[15] ? (&ptch[14:9] ? ptch[9:0] : 10'h200) : (|ptch[14:9] ? 10'h1FF : ptch[9:0]);
  assign ptch_P_term = ($signed(ptch_err_sat))*($signed(P_COEFF));
  // I term
  assign ptch_err_sat_ext = {{8{ptch_err_sat[9]}}, ptch_err_sat};
  assign accum_out = ptch_err_sat_ext + integrator;
  assign ov = (ptch_err_sat_ext[17] == integrator[17]) && (integrator[17] != accum_out[17]);
  assign integrator_in = rider_off ? 18'h00000 : (vld && !ov ? accum_out : integrator);
  
  always_ff@(posedge clk, negedge rst_n) begin
    if(!rst_n)
      integrator <= 18'h00000;
    else
      integrator <= integrator_in;
  end

  // D Term
  assign ptch_err_mid_in = vld ? ptch_err_sat : ptch_err_mid;
  assign prev_ptch_err_in = vld ? ptch_err_mid : prev_ptch_err;
  
  always_ff@(posedge clk, negedge rst_n) begin
    if(!rst_n)
      ptch_err_mid <= 10'h000;
    else
      ptch_err_mid <= ptch_err_mid_in;
  end
  
  always_ff@(posedge clk, negedge rst_n) begin
    if(!rst_n)
      prev_ptch_err <= 10'h000;
    else
      prev_ptch_err <= prev_ptch_err_in;
  end
  
  assign ptch_D_diff = ptch_err_sat - prev_ptch_err;
  assign ptch_D_diff_sat = ptch_D_diff[9] ? (&ptch_D_diff[8:6] ? ptch_D_diff[6:0] : 7'h40) : (|ptch_D_diff[8:6] ? 7'h7F : ptch_D_diff[6:0]);
  assign ptch_D_term = ptch_D_diff_sat*($signed(D_COEFF));
  
  // PID MATH //
  //sign extend all relevant P,I,D, and ld_cell_diff
  assign ld_cell_diff_ext = {{7{ld_cell_diff[11]}}, ld_cell_diff[11:3]};
  assign P_ext = {ptch_P_term[14], ptch_P_term};
  assign I_ext = {{4{integrator[17]}}, integrator[17:6]};
  assign D_ext = {{3{ptch_D_term[12]}}, ptch_D_term};
  assign PID_cntrl = P_ext + I_ext + D_ext;
  //assign outputs for left and right torque
  assign lft_torque = en_steer ? PID_cntrl - ld_cell_diff_ext : PID_cntrl;
  assign rght_torque = en_steer ? PID_cntrl + ld_cell_diff_ext : PID_cntrl;
  
  // SHAPING TORQUE FROM DUTY //
  // left and right abs
  assign lft_torque_abs = lft_torque[15] ? (~lft_torque + 1) : lft_torque;
  assign rght_torque_abs = rght_torque[15] ? (~rght_torque + 1) : rght_torque;
  // left shaped
  assign lft_shaped = (lft_torque_abs > LOW_TORQUE_BAND) ? (lft_torque[15] ? lft_torque - MIN_DUTY : lft_torque + MIN_DUTY) : $signed(lft_torque)*$signed(GAIN_MULTIPLIER);
  // right shaped
  assign rght_shaped = (rght_torque_abs > LOW_TORQUE_BAND) ? (rght_torque[15] ? rght_torque - MIN_DUTY : rght_torque + MIN_DUTY) : $signed(rght_torque)*$signed(GAIN_MULTIPLIER);
  //assign revs
  assign lft_rev = lft_shaped[15];
  assign rght_rev = rght_shaped[15];
  // assign speeds
  assign lft_shaped_abs = lft_shaped[15] ? (~lft_shaped + 1) : lft_shaped;
  assign rght_shaped_abs = rght_shaped[15] ? (~rght_shaped + 1) : rght_shaped;
  assign lft_spd = |lft_shaped_abs[15:11] ? 11'h7FF : lft_shaped_abs[10:0];
  assign rght_spd = |rght_shaped_abs[15:11] ? 11'h7FF : rght_shaped_abs[10:0];

endmodule 
