module UART_tx_tb();
	
	reg tx, done, trmt, rst_n, clk;
	reg[7:0] data;
	reg[9:0] check;
	reg[3:0] i;
	reg[12:0] j;
	localparam BAUD = 12'hA2C; //Given baud rate

	UART_tx iDUT(.TX(tx), .tx_done(done), .clk(clk), .rst_n(rst_n), .trmt(trmt), .tx_data(data));

	always  begin
		clk = 0;
		rst_n = 0;
		repeat(2)@(posedge clk);
		rst_n = 1;
		@(posedge clk);
		data = 8'h6A; //Set a test value for data
		trmt = 1;
		@(posedge clk) //Make sure trmt value is only high for one clock edge
		trmt = 0;
		@(posedge clk);
		@(posedge done) $quit(); //Stop running testbench once bit has been fully transmitted
        $quit();
	end
	
	always #10 clk = ~clk;

endmodule
