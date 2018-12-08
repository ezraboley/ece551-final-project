module UART_rcv(RX, clk, rst_n, clr_rdy, rx_data, rdy);
	output reg[7:0] rx_data;
	output reg rdy;
	input RX, clk, rst_n, clr_rdy;
	typedef enum {IDLE, RECEIVE} state_t;
	state_t state, nxt_state;
	localparam BAUD = 12'hA2C;
	reg[3:0] cnt;
	reg[8:0] rx_shft_reg;
	reg[11:0] baud_cnt;
	reg receive, ff_rx, start, set_rdy, shift, q;

	assign shift = (baud_cnt == 0); //Data should only be shifted after the baud cycle is over
	assign rx_data = rx_shft_reg[7:0];
	
	//Flop to handle state transitions
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n) state <= IDLE;
		else state <= nxt_state;
	end

	//Combinational block to handle state transition logic and outputs
	always_comb begin
		start = 0;
		receive = 0;
		set_rdy = 0;
		case(state)
			IDLE : 
				if (ff_rx == 0) begin
					start = 1;
					receive = 1;				
					nxt_state = RECEIVE;
				end
				else nxt_state = state;
			RECEIVE :
				if (cnt >= 10) begin
					set_rdy = 1;
					nxt_state = IDLE;
				end
				else if (cnt < 10) begin
					receive= 1;
					nxt_state = state;
				end
				else nxt_state = IDLE;
			default nxt_state = IDLE;
		endcase
	end

	//Flop to handle ready bit set and clear
	always @(posedge clk, negedge rst_n) begin
		if (!rst_n) rdy <= 0;
		else begin
			if (start | clr_rdy) rdy <= 0;
			else if (set_rdy) rdy <= 1;
			else rdy <= rdy;
		end
	end

	//Flop to keep track of received bits
	always @(posedge clk) begin
		if (start) cnt <= 0;		
		else if (shift) cnt <= cnt + 1;
		else cnt <= cnt;
	end

	//Flop to count baud rate
	always @(posedge clk) begin
		if (start) baud_cnt <= BAUD/2;
		else if (shift) baud_cnt <= BAUD;  
		else if (receive) baud_cnt <= baud_cnt - 1;
		else baud_cnt <= baud_cnt;
	end

	//Flop to handle shifting of rx data value
	always @(posedge clk) begin
		if (shift) rx_shft_reg <= {ff_rx,rx_shft_reg[8:1]};	
		else rx_shft_reg <= rx_shft_reg;
	end

	//Double flop for metastability
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n) q <= 0;
		else if(preset) q <= 1;
		else begin
			q <= RX;
		end
		ff_rx <= q;
	end

endmodule
