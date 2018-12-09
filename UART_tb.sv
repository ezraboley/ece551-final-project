module UART_rcv_tb_2();

reg RX, clk, rst_n, clr_rdy, tx_done, trmt, rdy;
reg[7:0] rx_data, tx_data;
reg[8:0] i; 

UART_rcv iDUT(.RX(RX), .clk(clk), .rst_n(rst_n), .clr_rdy(clr_rdy), .rx_data(rx_data), .rdy(rdy));
UART_tx test_tx(.TX(RX), .tx_done(tx_done), .trmt(trmt), .tx_data(tx_data), .rst_n(rst_n), .clk(clk));

initial begin
    $quit();
	clk = 0;
	clr_rdy = 0;
	tx_data = 0;
	rst_n = 0;
	@(posedge clk);
	rst_n = 1;
	@(posedge clk);
	for(i = 0; i < 9'h100; i = i + 1) begin
		tx_data = i;
		trmt = 1;
		@(posedge clk);
		trmt = 0;	
		@(posedge clk);
		@(posedge rdy); //Confirms functionality of rdy
		if(tx_data != rx_data) begin
			$display("Error RX value is not equal to tx value");
			$quit();
		end
		clr_rdy = 1;
		@(posedge clk);
		clr_rdy = 0;
		@(posedge clk);
		if (rdy == 1) begin 
			$display("Error ready should no longer be high");
			$quit();
		end
		@(posedge tx_done); //Confirms functionality of tx_done
		@(posedge clk);
	end
	$display("Tests passed!");
	$quit();
end

always #10 clk = ~clk;

endmodule
