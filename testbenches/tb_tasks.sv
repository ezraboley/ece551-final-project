
task RST_DUT_n;
    RST_n = 0;
    @(posedge clk);
    @(negedge clk);
    RST_n = 1;
    @(posedge clk);
endtask

function void check (string name, integer expected, integer actual);
    if(actual != expected) begin
        $display("*ERROR - SIGNAL NAME: %s  |  EXPECTED VALUE: %h  |  ACTUAL VALUE: %h", name, expected, actual);
        $stop();
    end
endfunction

function void check_range (string name, integer min, integer max, integer actual);
    if(actual < min || actual > max) begin
         $display("*ERROR - SIGNAL NAME: %s  |  RANGE MIN: %h  |  RANGE MAX: %h  |  ACTUAL VALUE: %h", name, min, max, actual);
	 $stop();
    end
endfunction

task init_Segway;
	clk = 0;
	RST_n = 0;
	cmd = 0;
	send_cmd = 0;
	rider_lean = 0;
	ld_cell_lft = 0;
	ld_cell_rght = 0;
	batt_V = 0;
endtask

task send_s;
	@(posedge clk);
	cmd = 8'h73;
	@(posedge clk);
	send_cmd = 1;
	@(posedge clk);
	send_cmd = 0;
	@(posedge clk);
	@(posedge cmd_sent);
endtask

task send_g;
	@(posedge clk);
	cmd = 8'h67;
	@(posedge clk);
	send_cmd = 1;
	@(posedge clk);
	send_cmd = 0;
	@(posedge clk);
	@(posedge cmd_sent);
endtask

task clock;
	input integer num;
	repeat(num)@(posedge clk);
	@(negedge clk);
endtask

