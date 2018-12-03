module inertial_integrator(ptch, AZ, ptch_rt, vld, rst_n, clk);
   	input clk, rst_n, vld;
 	input [15:0] ptch_rt, AZ;
    	output reg [15:0] ptch;
	reg [26:0] ptch_int, fusion_ptch_offset;

	localparam PTCH_RT_OFFSET = 16'h03C2;

	always @(posedge clk) begin
		if(vld) ptch_rt_comp = ptch_rt - PTCH_RT_OFFSET;
	end

	always@(posedge clk) begin
		if(vld) ptch_int <= ptch_int - {{11{ptch_rt_comp[15]}},ptch_rt_comp} + fusion_ptch_offset;
	end


	always_comb begin
		ptch_acc_product = AZ_comp * $signed(327);
		ptch_acc = {{3{ptch_acc_product[25]}}, ptch_acc_product[25:13]};
		fusion_ptch_offset = (ptch_acc > ptch) ? 512 : -512;
	end

	assign ptch = ptch_int[26:11]

endmodule
