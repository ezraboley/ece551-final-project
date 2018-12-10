/*task rstDUT_n;
    rst_n = 0;
    @(posedge clk);
    @(negedge clk);
    rst_n = 1;
    @(posedge clk);
endtask*/

task RST_DUT_n;
    RST_n = 0;
    @(posedge clk);
    @(negedge clk);
    RST_n = 1;
    @(posedge clk);
endtask

function void debug (string name, integer expected, integer actual);
    $display("SIGNAL NAME: %s  |  EXPECTED VALUE: %h  |  ACTUAL VALUE: %h", name, expected, actual);
endfunction

/*
task sign_extend;
    parameter IN_SIZE = 0;
    parameter OUT_SIZE = 0;
    input [IN_SIZE - 1 : 0] in_sig;
    output [OUT_SIZE - 1: 0] out_sig;
     
    begin
        out_sig = {(OUT_SIZE - IN_SIZE){in_sig[IN_SIZE - 1]}, in_sig};
    end
endtask

task init_digital_core;
    
        clk = 0;
        pwr_up = 0;
        MISO = 0;
        INT = 0;
        lft_ld = 12'h000;
        rght_ld = 12'h00;
        batt = 12'h000;
   
endtask 

task inputSPI_cmd(command);
	input[15:0] command;
	cmd = command;
	@(posedge clk);
	wrt = 1;
	@(posedge clk);
	wrt = 0;
	@(posedge clk);
	while(!done) @(posedge clk);
endtask

task inputUART(in);
	input[7:0] in;
	tx_data = in;
	tmrt = 1;
	@(posedge clk);
	tmrt = 0;
	@(posedge clk);
endtask
*/

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
	
