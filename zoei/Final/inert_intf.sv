module inert_intf(ptch, vld, SCLK, SS_n, MOSI, MISO, INT, clk, rst_n);
	input clk, rst_n, MISO, INT;
	output reg signed [15:0] ptch;
	output reg MOSI, SS_n, SCLK, vld;

	reg INT_ff1, INT_ff2, done, wrt, cpl, cph, cazl, cazh;
	reg [15:0] rd_data, cmd;
	reg [7:0] AZ_l, AZ_h, ptch_rt_l, ptch_rt_h;
	reg [15:0] timer;
	reg signed [15:0] ptch_rt, AZ;

	localparam EN_INT    = 16'h0D02;
	localparam SET_ACCEL = 16'h1053;
	localparam SET_GYRO  = 16'h1150;
	localparam ROUND_ON  = 16'h1460;

	localparam RD_PTCH_L = 16'hA2XX; 
	localparam RD_PTCH_H = 16'hA3XX;
	localparam RD_AZ_L   = 16'hACXX;
	localparam RD_AZ_H   = 16'hADXX;

	SPI_mstr16 spi_mstr(.clk(clk), .rst_n(rst_n), .SS_n(SS_n), .MOSI(MOSI), .MISO(MISO), .wrt(wrt), .cmd(cmd), .SCLK(SCLK), .done(done), .rd_data(rd_data));

	inertial_integrator inert_int(.clk(clk), .rst_n(rst_n), .vld(vld), .ptch_rt(ptch_rt), .AZ(AZ), .ptch(ptch));

	typedef enum {INIT1, INIT2, INIT3, INIT4, IDLE, WAIT, READ1, READ2, READ3, READ4, DONE} state_t;
	state_t state, nxt_state;

	always @(posedge clk, negedge rst_n) begin
    		if (!rst_n) timer <= 16'h0000;
   		else if (&timer) timer <= 16'h0000;
        	else timer <= timer + 1;
	end

	always_ff @(posedge clk, negedge rst_n) begin
    		if (!rst_n) state <= INIT1;
    		else state <= nxt_state;
	end

	always_comb begin
    		wrt = 0;
    		cpl = 0;
    		cph = 0;
    		cazl = 0;
    		cazh = 0;
    		cmd = 16'h0000;
    		nxt_state = INIT1;
    		vld = 0;
    		case(state) 
        		INIT1: 
			begin
            		  cmd = EN_INT;
            		  if (&timer) begin
                		wrt = 1;
                		nxt_state = INIT2;
            		  end
            		  else nxt_state = INIT1;
        		end
        	INIT2: 
		begin
            	  cmd = SET_ACCEL;
            	  if (&timer[9:0]) begin
                	wrt = 1;
                	nxt_state = INIT3;
            	  end
            	  else nxt_state = INIT2;
        	end
        	INIT3: 
		begin
           	   cmd = SET_GYRO;
            	   if (&timer[9:0]) begin
                	wrt = 1;
                	nxt_state = INIT4;
            	   end
            	   else nxt_state = INIT3;
        	end
        	INIT4: 
		begin
            	   cmd = ROUND_ON;
            	   if (&timer[9:0]) begin
                	wrt = 1;
                	nxt_state = WAIT;
            	   end
            	else nxt_state = INIT4;
        	end
		WAIT: 
		begin
	    	   if (&timer[9:0]) begin
                 	nxt_state = IDLE;
	    	   end
	    	   else nxt_state = WAIT;
		end
		IDLE: 
		begin
	    	   cmd = RD_PTCH_L;
	    	   if (INT_ff2) begin
			wrt = 1;
			nxt_state = READ1;	
	    	   end
	    	   else nxt_state = IDLE;
		end
       		READ1: 
		begin
            	   cmd = RD_PTCH_H;
            	   if (done) begin
                	wrt = 1;
                	cpl = 1;
                	nxt_state = READ2;
            	   end
            	   else nxt_state = READ1;
        	end
        	READ2: 
		begin
            	   cmd = RD_AZ_L;
            	   if (done) begin
                	wrt = 1;
                	cph = 1;
                	nxt_state = READ3;
            	   end
            	   else nxt_state = READ2;
        	end
        	READ3: 
		begin
            	   cmd = RD_AZ_H;
            	   if (done) begin
                	wrt = 1;
                	cazl = 1;
                	nxt_state = READ4;
            	   end
            	   else nxt_state = READ3;
        	end
        	READ4:
		 begin
            	   if (done) begin
                	cazh = 1;
                	nxt_state = DONE;
            	   end
            	   else nxt_state = READ4;
        	end
        	DONE: 
		begin
            	   vld = 1;
            	   nxt_state = IDLE;
        	end
    		endcase    
	end

	always @(posedge clk, negedge rst_n) begin
   		if (!rst_n) ptch_rt_l <= 0;
    		else if(cpl) ptch_rt_l <= rd_data[7:0];
    		else ptch_rt_l <= ptch_rt_l;
     
    	end

	always @(posedge clk, negedge rst_n) begin
   		if (!rst_n) ptch_rt_h <= 0;
    		else if(cph) ptch_rt_h <= rd_data[7:0];
    		else ptch_rt_h <= ptch_rt_h;
     
    	end

	always @(posedge clk, negedge rst_n) begin
   		if (!rst_n) AZ_l <= 0;
    		else if(cazl) AZ_l <= rd_data[7:0];
    		else AZ_l <= AZ_l;
     
    	end

	always @(posedge clk, negedge rst_n) begin
   		if (!rst_n) AZ_h <= 0;
    		else if(cazh) AZ_h <= rd_data[7:0];
    		else AZ_h <= AZ_h;
     
    	end

	assign ptch_rt = {ptch_rt_h,ptch_rt_l};
	assign AZ = {AZ_h,AZ_l};

	always @(posedge clk, negedge rst_n) begin
   		 if (!rst_n) begin
        		INT_ff1 <= 0;
        		INT_ff2 <= 0;
    		end
    		else begin
        		INT_ff1 <= INT;
        		INT_ff2 <= INT_ff1;
    		end
	end

endmodule
