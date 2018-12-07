module inertial_integrator(ptch, AZ, ptch_rt, vld, rst_n, clk);
    	input clk, rst_n, vld;
    	input signed [15:0] ptch_rt, AZ;
    	output reg signed [15:0] ptch;

	localparam PTCH_RT_OFFSET = 16'h03C2;
	localparam AZ_OFFSET = 16'hFE80;

	reg signed [26:0] ptch_int, ptch_acc_product, fusion_ptch_offset;
	reg signed [15:0] ptch_acc, ptch_rt_comp, AZ_comp;

	always @(posedge clk, negedge rst_n) begin
    		if (!rst_n) ptch_int <= 0;
        	else if (vld) ptch_int <= ptch_int - {{11{ptch_rt_comp[15]}}, ptch_rt_comp} + fusion_ptch_offset; //Sum compensated rate signal and 'leak' gyro measurement to agree with accelerometer
        	else ptch_int <= ptch_int;
	end

	always @(posedge clk, negedge rst_n) begin
    		if (!rst_n) ptch_rt_comp <= 0;
    		else if (vld) ptch_rt_comp = ptch_rt - PTCH_RT_OFFSET; //Integrate compensated signal into pitch on every valid pulse
       		else ptch_rt_comp <= ptch_rt_comp;
    	end

	always_comb begin
   		ptch_acc_product = AZ_comp * $signed(327);
    		ptch_acc = {{3{ptch_acc_product[25]}}, ptch_acc_product[25:13]}; //Pitch angle from accelerometer
	end

	assign AZ_comp = AZ - AZ_OFFSET; //Calculate pitch as seen be accelerometer
	assign fusion_ptch_offset = (ptch_acc > ptch) ? 10'd1024 : -10'd1024; //Compare accelerometer pitch and gyro pitch
	assign ptch = ptch_int[26:11];


endmodule

