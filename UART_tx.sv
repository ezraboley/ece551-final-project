module UART_tx(TX, tx_done, clk, rst_n, trmt, tx_data);
	output reg TX, tx_done;
	input trmt, clk, rst_n;
	input[7:0] tx_data;
	reg[9:0] data; //10 bit data value with start/stop bits appended
	reg[3:0] cnt;
	reg[11:0] baud_cnt; //Track baud rate
	reg shift, load, transmit, set_done, clr_done; //Flag values for state machine use
	localparam BAUD = 12'hA2C; //Given baud value (assigned constant for convenience)

	typedef enum {IDLE, TRANSMIT} state_t; 
	state_t state, next_state;

	assign TX = data[0]; //Always send least significant bit of data
	assign shift = (baud_cnt == BAUD); //Assert shift only after baud cylces

	//Flop to manage the counter value
	always@(posedge clk) begin
		if(load) cnt <= 0;
		else if(shift) cnt <= cnt + 1;
		else cnt <= cnt;
	end

	//Flop to manage baud counter value
	always@(posedge clk) begin
		if(load | shift) baud_cnt <= 0;
		else if(transmit) baud_cnt <= baud_cnt + 1;
		else baud_cnt <= baud_cnt;
	end

	//Flop that manages data value
	always@(posedge clk, negedge rst_n) begin
		if(!rst_n) data <= 0;
		else begin
			if(load) data <= {1'b1,tx_data,1'b0}; //Append start and stop values to data
			else if(shift) data <= data >> 1; //Shift data value right when shift value is asserted
			else data <= data;
		end
	end

	//Flop to control state machine
	always_ff@(posedge clk, negedge rst_n) begin
		if(!rst_n) state <= IDLE;
		else state <= next_state;
	end

	//Combinational logic to control state transitions
	always_comb begin
		clr_done = 0;
		set_done = 0;
		load = 0;
		transmit = 0;
		case(state)
			IDLE : 
				if(trmt) begin
					clr_done = 1;
					next_state = TRANSMIT;
					load = 1;
				end
				else next_state = state;
			TRANSMIT : 
				if(cnt == 10) begin //Count is full after 10 bits have been transmitted (start bit, 8 data bits, stop bit)
					set_done = 1;
					next_state = IDLE;
				end
				else begin 
					transmit = 1;
					next_state = state;
				end
			default next_state = IDLE;
				
		endcase
	end

	//Flop to control the assertion of tx_done when transmission has successfully completed
	always@(posedge clk) begin
		if(!rst_n) tx_done <= 0;
		else begin
			if(set_done) tx_done <= 1;
			else if(clr_done) tx_done <= 0;
			else tx_done <= tx_done;
		end
		
	end
endmodule
	
					
		
				
		
	
