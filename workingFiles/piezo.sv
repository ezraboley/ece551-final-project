module piezo(clk,rst_n,norm_mode,ovr_spd,batt_low,piezo,piezo_n);
input clk, rst_n, norm_mode, ovr_spd, batt_low;
output  piezo,piezo_n;
logic [26:0]counter;
logic piezo_freq;
logic time_en;
logic freq;

always_ff@(posedge clk, negedge rst_n)begin
	if(~rst_n) begin
	counter <= 0;
	end

	//at norm_mode, beep every 2 second
	//if after 10M period
	else counter <= counter + 1;
	
end

/*always_ff@(posedge clk, negedge rst_n)begin
	if(~rst_n) piezo_freq <= 0;
	else if(time_en) piezo_freq <= freq;
	else piezo_freq <= 0;
end	*/
assign piezo_freq = time_en? freq :0;

assign freq = (norm_mode || batt_low)? counter[13] : ovr_spd? counter[12]:0;
assign time_en = norm_mode? counter[26]: 
							ovr_spd? counter[25]:
							batt_low? counter[24]: 0;


//ovr_spd has 5kHZ(10000 clk period), batt_low has 1kHz(50000 clk period)
assign piezo = (norm_mode || batt_low || ovr_spd )? piezo_freq: 0;
assign piezo_n = ~piezo;


endmodule
