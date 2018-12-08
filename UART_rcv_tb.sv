module UART_rcv_tb();

reg RX, clk, rst_n, clr_rdy;
reg rdy;
reg [7:0] rx_data;

UART_rcv iDUT(.RX(RX), .clk(clk), .rst_n(rst_n), .clr_rdy(clr_rdy), .rx_data(rx_data), .rdy(rdy));


logic tx_done;	// Outputs
logic trmt; 
logic [7:0] tx_data;	// Inputs to UART_TX

UART_tx test_tx(.TX(RX), 
	.tx_done(tx_done), 
	.trmt(trmt), 
	.tx_data(tx_data), 
	.rst_n(rst_n), 
	.clk(clk));

initial begin
	clk = 0;
	clr_rdy = 0;
	rst_n = 0;
	@(posedge clk);
	rst_n = 1;
	@(posedge clk);
	tx_data = 8'h6A;
	trmt = 1;
	@(posedge clk);
	trmt = 0;
	@(posedge clk);
	@(posedge rdy);
	if (tx_data != rx_data) begin
		$display("RX_DATA should equal %h, but is instead %h", tx_data, rx_data);
		//$stop();
	end 
	// Test the manual clear ready signal
	clr_rdy = 1;
	@(posedge clk);
	clr_rdy = 0;
	@(posedge clk);
	if (rdy == 1) begin 
		$display("Shouldnt be ready anymore");
		$stop();
	end
	@(posedge clk);
	tx_data = 8'h37;
	trmt = 1;
	@(posedge clk);
	trmt = 0;
	@(posedge clk);
	while(!rdy) @(posedge clk);
	if (tx_data != rx_data) begin
		$display("RX_DATA should equal %h, but is instead %h", tx_data, rx_data);
		$stop();
	end
	$display("SUCCESS!");
	$quit();	
end

always #5 clk = ~clk;

endmodule
