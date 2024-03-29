module en_steer_tb();
	reg clk, rst_n, nxt;
	reg [11:0] lft_ld, rght_ld;
	wire en_steer, rider_off;

	en_steer  #(.fast_sim(1)) iDUT (.clk(clk), .rst_n(rst_n), .lft_ld(lft_ld), .rght_ld(rght_ld), .en_steer(en_steer), .rider_off(rider_off));

	initial begin
		clk = 0;
		rst_n = 0;
		nxt = 0;
		@(posedge clk);
		@(negedge clk);
		rst_n = 1;

		@(posedge clk);
		lft_ld = 12'h1A6;
		rght_ld = 12'h1A0;
		@(posedge clk);

		fork begin : timeout1
			repeat(35000) @(posedge clk);
			$display("Timeout waiting for en_steer signal");
			$stop();
		end
		begin
			@(posedge en_steer);
			disable timeout1;
		end
		join
		if(!en_steer) begin
			$display("Error, en_steer should be asserted here.");
			$stop();
		end
		if(rider_off) begin
			$display("Error, rider_off should NOT be asserted here.");
			$stop();
		end
		
		repeat(5)@(posedge clk);
		rst_n = 0;
		repeat(5)@(posedge clk);
		rst_n = 1;

		repeat(5)@(posedge clk);
		lft_ld = 12'h0A8; 
		rght_ld = 12'h100;
		repeat(2)@(posedge clk);
		
		if(iDUT.state != iDUT.IDLE) begin
			$display("Error, sum did not exceed min rider weight");
			$stop();
		end

		if(en_steer) begin
			$display("Error, en_steer should NOT be asserted here.");
			$stop();
		end 
		if(rider_off) begin
			$display("Error, rider_off should NOT be asserted here.");
			$stop();
		end

		repeat(5)@(posedge clk);
		lft_ld = 12'h2A8; 
		rght_ld = 12'h2A0;
		@(posedge clk);

		fork begin : timeout4
			repeat(35000) @(posedge clk);
			$display("Timeout waiting for en_steer signal");
			$stop();
		end
		begin
			@(posedge en_steer);
			disable timeout4;
		end
		join

		repeat(5)@(posedge clk);
		lft_ld = 12'h2A8; 
		rght_ld = 12'h012;
		repeat(2)@(posedge clk);
		if(iDUT.state != iDUT.WAIT) begin
			$display("Error, should transition to WAIT state");
			$stop();
		end
		repeat(5)@(posedge clk);
		lft_ld = 12'h012; 
		rght_ld = 12'h003;
		@(posedge clk);
		if(en_steer) begin
			$display("Error, en_steer should NOT be asserted here.");
			$stop();
		end 
		if(!rider_off) begin
			$display("Error, rider_off should be asserted here.");
			$stop();
		end

		$display("Tests passed.");	
//		$stop();
	end

	always #5 clk = ~clk;

endmodule
