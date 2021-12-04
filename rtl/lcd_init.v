module lcd_init(
	input clk,						//时钟信号 1m
	input rst_n,					//复位信号
	input ena,						//模块使能信号
	input done_write,				//一个字节写完成
	output reg [7:0] data,		//需要写的数据
	output cmd_data,				//写数据还是写指令 0：指令 1：数据
	output reg ena_write			//使能写信号
);

parameter DELAY = 50;			//写完一个字节等待的时间 50us
reg [20:0] us_cnt;				//us计数器
reg us_cnt_clr;					//计数器清零信号

reg [7:0]init_cmd_data[16:0];	//初始化的命令和数据 //默认显示HelloWorld
reg [4:0]initcd_cnt;				//命令或数据计数器

initial begin
	init_cmd_data[0] = 8'h02;	//光标复位
	init_cmd_data[1] = 8'h28;	//四线操作模式
	init_cmd_data[2] = 8'h0C;	//开显示
	init_cmd_data[3] = 8'h01;	//清屏
	init_cmd_data[4] = 8'h80;	//设置显示初始位置
	init_cmd_data[5] = 8'h06;	//设置输入方式，增量
	
	//HelloWorld
	init_cmd_data[6] = 8'h48;init_cmd_data[7] = 8'h65;init_cmd_data[8] = 8'h6C;
	init_cmd_data[9] = 8'h6C;init_cmd_data[10] = 8'h6F;init_cmd_data[11] = 8'h57;
	init_cmd_data[12] = 8'h6F;init_cmd_data[13] = 8'h72;init_cmd_data[14] = 8'h6C;
	init_cmd_data[15] = 8'h64;
end

//状态说明：
//等待模块使能
//写一个字节
//等待写完成
//延时
//完成
parameter WaitEn=0,Write=1,WaitWrite=3,WaitDelay=4,Done=5;
reg[2:0] state,next_state;		//当前状态和下一个状态

//前6个为命令，后面都是数据，但是init_cnt每次都是提前加1的，所以需要等于6
assign cmd_data = (initcd_cnt<=3'd6) ? 1'b0 : 1'b1;

//1微秒计数器
always @ (posedge clk,negedge rst_n) begin
    if (!rst_n)
        us_cnt <= 21'd0;
    else if (us_cnt_clr)
        us_cnt <= 21'd0;
    else 
        us_cnt <= us_cnt + 1'b1;
end

//下一个状态确定
always @(*) begin
	if(!rst_n)
		next_state = WaitEn;//复位到初始状态
	else begin
		case(state)
			//等待模块使能
			WaitEn: next_state = ena ? Write : WaitEn;
			
			//写一个字节
			Write: next_state = WaitWrite;
			
			//等待写完成
			WaitWrite: next_state = done_write ? WaitDelay : WaitWrite;
			
			//延时
			//是否已经全部写完成，写完成进入下一个状态，否则等待延时完成继续写下一个字节
			WaitDelay: next_state = initcd_cnt==5'd16 ? Done : ((us_cnt==DELAY) ? Write : WaitDelay);
			
			//完成初始化
			Done:next_state = Done;
		endcase
	end
end

always @(posedge clk,negedge rst_n) begin
	if(!rst_n)begin
		us_cnt_clr = 1'b1;//计数器复位
		ena_write <= 1'b0;//不使能写
	end
	else begin
		case(state)
		
			//等待模块使能
			WaitEn:begin
				us_cnt_clr = 1'b1;
				ena_write <= 1'b0;
			end
			
			//写一个字节
			Write:begin
				us_cnt_clr = 1'b1;
				data <= init_cmd_data[initcd_cnt];
				ena_write <= 1'b1;//使能写模块
			end
			
			//等待写完成
			WaitWrite:begin
				ena_write <= 1'b0;
			end
			
			//延时
			WaitDelay:begin
				us_cnt_clr = 1'b0;//取消计数器复位，让计数器计数
			end
		endcase
	end
end

//状态流转
always @(posedge clk,negedge rst_n) begin
	if(!rst_n)
		state <= WaitEn;
	else
		state <= next_state;
end

//计数器计数
always @(posedge clk,negedge rst_n) begin
	if(!rst_n)begin
		initcd_cnt <= 4'd0;
	end
	else begin
		if(state ==  Write)//在写一个字节状态时计数器加1，然后立即进入下一个状态，所以这个值总会多1在使用时
			initcd_cnt <= initcd_cnt + 1'b1;
		else
			initcd_cnt <= initcd_cnt;
	end
end

endmodule