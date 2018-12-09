module en_steer_tb();
	reg clk, rst_n, nxt;
	reg [11:0] lft_ld, rght_ld;
	wire en_steer, rider_off;

	en_steer  #(.fast_sim(1)) iDUT (.clk(clk), .rst_n(rst_n), .lft_ld(lft_ld), .rght_ld(rght_ld), .en_steer(en_steer), .rider_off(rider_off));

	localparam MIN_RIDER_WEIGHT = 12'h200;

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
		repeat(20)@(posedge clk);
		lft_ld = 12'h201; 
		rght_ld = 0;
		repeat(10)@(posedge clk);
		lft_ld = 12'h0A4;

		fork begin : timeout2
			repeat(35000) @(posedge clk);
			$display("Timeout waiting for rider_off signal");
			$stop();
		end
		begin
			@(posedge rider_off);
			disable timeout2;
		end
		join

		if(en_steer) begin
			$display("Error, en_steer should NOT be asserted here.");
			$stop();
		end 
		if(!rider_off) begin
			$display("Error, rider_off should be asserted here.");
			$stop();
		end

		$display("Tests passed.");
		$stop();	
	end

	always #5 clk = ~clk;

endmodule
