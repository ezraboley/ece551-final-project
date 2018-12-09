task rstDUT_n;
    rst_n = 0;
    @(posedge clk);
    @(negedge clk);
    rst_n = 1;
    @(posedge clk);
endtask

function void debug (string name, integer expected, integer actual);
    $display("SIGNAL NAME: %s  |  EXPECTED VALUE: %h  |  ACTUAL VALUE: %h", name, expected, actual);
endfunction

task sign_extend;
    parameter IN_SIZE = 0;
    parameter OUT_SIZE = 0;
    input [IN_SIZE - 1 : 0] in_sig;
    output [OUT_SIZE - 1: 0] out_sig;
     
    initial begin
        out_sig = {(OUT_SIZE - IN_SIZE){in_sig[IN_SIZE - 1]}, in_sig};
    end
endtask

task init_digital_core;
    begin
        clk = 0;
        pwr_up = 0;
        MISO = 0;
        INT = 0;
        lft_ld = 12'h000;
        rght_ld = 12'h00;
        batt = 12'h000;
    end
endtask
