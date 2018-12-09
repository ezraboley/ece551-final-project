odule A2D_Intf(lft_ld, rght_ld, batt, rd_data, MOSI, SCLK, SS_n, nxt, MISO, clk, rst_n);
	input MISO, nxt, clk, rst_n;
	output reg SCLK, SS_n, MOSI;
	output reg[11:0] lft_ld, rght_ld, batt;
	output reg[15:0] rd_data;
	reg done, update, wrt, ch0, ch4, ch5;
	reg[1:0] robin;
	reg[15:0] cmd;

	typedef enum{IDLE, CHANNEL, READ} state_t;
	state_t next_state, state;

	SPI_mstr16 spi(.rd_data(rd_data), .MOSI(MOSI), .done(done), .SCLK(SCLK), .SS_n(SS_n), .clk(clk), .rst_n(rst_n), .MISO(MISO), .wrt(wrt), .cmd(cmd));

	always@(posedge clk, negedge rst_n) begin
		if(!rst_n) state <= IDLE;
		else state <= next_state;
	end

	always@(posedge clk, negedge rst_n) begin
		if(!rst_n) robin <= 0;
		else if(update) robin <= (robin == 2) ? 0 : robin + 1;
		else robin <= robin;
	end

	always_comb begin
		if(robin == 0) cmd = {2'h0,3'h0,11'h0};
		else if(robin == 1) cmd = {2'h0, 3'h4, 11'h0};
		else if(robin == 2) cmd = {2'h0, 3'h5, 11'h0};
		else cmd = cmd[15:0];
	end

	always@(posedge clk) begin
		if(ch0) lft_ld <= rd_data[11:0];
		else lft_ld <= lft_ld;
	end

	always@(posedge clk) begin
		if(ch4) rght_ld <= rd_data[11:0];
		else rght_ld <= rght_ld; 
	end

	always@(posedge clk) begin
		if(ch5) batt <= rd_data[11:0];
		else batt <= batt; 
	end

	always_comb begin
		wrt = 0;
		update = 0;
		case(state)
			IDLE:
			begin
				if(nxt) begin
					wrt = 1;
					next_state = CHANNEL;
				end
				else next_state = state;
			end
			CHANNEL:
			begin
				if(done) next_state = READ;
				else next_state = state;
			end
			READ:
			begin
				if(done) begin
					update = 1;
					next_state = IDLE;
				end
				else next_state = state;
			end
			default: next_state <= IDLE;
		endcase
	end

	assign ch0 = (robin == 0);
	assign ch4 = (robin == 1);
	assign ch5 = (robin == 2);

endmodule

