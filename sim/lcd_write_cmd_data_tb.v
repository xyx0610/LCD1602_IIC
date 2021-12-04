`timescale 1ns/1ns //仿真单位为1ns，精度为1ns

module lcd_write_cmd_data_tb();

	reg clk;
	reg rst_n;
	reg ena;
	reg [7:0]data;
	reg cmd_data;
	wire sda;
	wire scl;
	wire done;
	wire sda_dir;
	
	reg sda_in;
	
	assign sda = sda_dir ? 1'bz : sda_in;
	
	lcd_write_cmd_data lcd_write_cmd_data_inst(
		.clk(clk),
		.rst_n(rst_n),
		.ena(ena),
		.data(data),
		.cmd_data(cmd_data),
		.sda(sda),
		.scl(scl),
		.sda_dir(sda_dir),
		.done(done)
	);
	
	initial begin
		#0 	clk = 0;
				rst_n = 0;
				data = 8'b11010100;
				ena = 1;
				cmd_data = 0;
				sda_in = 1;
			
		#20	rst_n = 1;
		
		#2000 sda_in = 0;
	end
	
	always #5 clk = ~clk;

endmodule
