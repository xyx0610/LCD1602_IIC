`timescale 1ns/1ns //仿真单位为1ns，精度为1ns
module lcd_init_tb();
	
	reg clk;
	reg rst_n;
	wire done_write;
	wire [7:0] data;
	wire cmd_data;
	wire ena_write;
	wire sda;
	wire scl;
	
	wire sda_dir;
	
	reg sda_in;
	
	assign sda = sda_dir ? 1'bz : sda_in;
	
	
	lcd_init lcd_init_inst(
		.clk(clk),
		.rst_n(rst_n),
		.ena(1'b1),
		.done_write(done_write),
		.ena_write(ena_write),
		.data(data),
		.cmd_data(cmd_data)
	);
	
	lcd_write_cmd_data lcd_write_cmd_data_inst(
		.clk(clk),
		.rst_n(rst_n),
		.ena(ena_write),
		.data(data),
		.cmd_data(cmd_data),
		.sda(sda),
		.scl(scl),
		.sda_dir(sda_dir),
		.done(done_write)
	);
	
	initial begin
		#0 	clk = 0;
				rst_n = 0;
				sda_in = 0;
			
		#20	rst_n = 1;
		
	end
	
	always #5 clk = ~clk;
	
endmodule