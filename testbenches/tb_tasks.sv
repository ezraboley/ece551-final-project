task rstDUT_n;
    rst_n = 0;
    @(posedge clk);
    @(negedge clk);
    rst_n = 1;
    @(posedge clk);
endtask

task debug;
    parameter BUS_SIZE = 1;
    input string name;
    input [BUS_SIZE : 0] expected;
    input [BUS_SIZE : 0] actual;
    $display("SIGNAL NAME: %s  |  EXPECTED VALUE: %h  |  ACTUAL VALUE: %h", name, expected, actual);
endtask

task sign_extend;
    parameter IN_SIZE = 0;
    parameter OUT_SIZE = 0;
    input [IN_SIZE - 1 : 0] in_sig;
    output [OUT_SIZE - 1: 0] out_sig;
     
    initial begin
        out_sig = {(OUT_SIZE - IN_SIZE){in_sig[IN_SIZE - 1]}, in_sig};
    end
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
