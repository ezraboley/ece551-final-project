module rst_synch(RST_n,clk,rst_n);
input RST_n,clk;
output reg rst_n;

logic q;

always_ff@(negedge clk, negedge RST_n) begin
	if(~RST_n) begin
	rst_n <= 0;
	q <= 0;
	end
	else begin
	 q <= 1'b1;
	 rst_n <= q;
	end
end

endmodule
