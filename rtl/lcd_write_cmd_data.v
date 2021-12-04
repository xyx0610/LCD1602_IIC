module lcd_write_cmd_data(
	input clk,						//时钟信号 1m
	input rst_n,					//按键复位信号
	input [7:0]data,				//需要写的一个字节
	input cmd_data,				//写的是数据还是命令 0：命令，1：数据
	input ena,						//模块使能
	inout sda,						//iic sda
	output scl,						//iic scl
	output done,					//一个字节写完成
	output sda_dir					//sda 方向
);

parameter DELAY = 25;			//写完一个字节等待时间，EN从1到0等待一段时间让lcd执行命令
reg [20:0] us_cnt;				//us计数器
reg us_cnt_clr;					//计数器清零信号

//状态声明
parameter WaitEn=0,WriteAddr=1,WaitWA=2,WriteHE=3,WaitWHE=4,WaitCMD1=5,WriteHNE=6,WaitWHNE=7,WriteLE=8,WaitWLE=9,WaitCMD2=10,WriteLNE=11,WaitWLNE=12,Done=13;
reg[3:0] state,next_state;		//当前状态和下一个状态
reg en_write;						//使能写

wire en_iicwrite = en_write;	//iic写使能赋值
wire iic_done;						//iic写完成
reg [7:0] iic_data;				//iic写的数据

//1微秒计数器
always @ (posedge clk,negedge rst_n) begin
    if (!rst_n)
        us_cnt <= 21'd0;
    else if (us_cnt_clr)
        us_cnt <= 21'd0;
    else 
        us_cnt <= us_cnt + 1'b1;
end 

//下一个状态确认
always @(*) begin
	if(!rst_n)
		next_state = WaitEn;//复位到初始状态
	else begin
		case(state)
		
			//等待模块使能
			WaitEn: next_state = ena ? WriteAddr : WaitEn;
			
			//写lcd地址
			WriteAddr: next_state = WaitWA;
			//等待写地址完成
			WaitWA: next_state = iic_done ? WriteHE : WaitWA;
			
			//写字节的高位 此时EN为1
			WriteHE: next_state = WaitWHE;
			//等待写高位为0
			WaitWHE: next_state = iic_done ? WaitCMD1 : WaitWHE;
			
			//延时等待一段时间
			WaitCMD1: next_state = (us_cnt == DELAY) ? WriteHNE : WaitCMD1;
			
			//写字节的高位 此时EN为0
			WriteHNE: next_state = WaitWHNE;
			//等待写完成
			WaitWHNE: next_state = iic_done ? WriteLE : WaitWHNE;
			
			//写字节的低位	 此时EN为1
			WriteLE: next_state =  WaitWLE;
			//等待写完成
			WaitWLE: next_state = iic_done ? WaitCMD2 : WaitWLE;
			
			//延时等待一段时间
			WaitCMD2: next_state = (us_cnt == DELAY) ? WriteLNE : WaitCMD2;
			
			//写字节的低位	此时EN为0
			WriteLNE: next_state = WaitWLNE;
			//延时等待一段时间
			WaitWLNE: next_state = iic_done ? Done : WaitWLNE;
			
			//完成写一次数据或命令
			Done: next_state = WaitEn;
		endcase
	end
end

//状态变量赋值
always @(posedge clk,negedge rst_n) begin
	if(!rst_n)begin
		iic_data <= 8'd0;				//iic数据复位
		en_write <= 1'b0;				//iic不使能写
		us_cnt_clr <= 1'b1;			//计数器复位
	end
	else begin
		case(state)
			WaitEn:begin
				iic_data <= 8'd0;				//iic数据复位
				en_write <= 1'b0;				//iic不使能写
				us_cnt_clr <= 1'b1;			//计数器复位
			end
		
			WriteAddr:begin
				iic_data <= 8'h4E;			//写lcd地址 0x4e
				en_write <= 1'b1;				//使能iic写
			end
			WaitWA:begin
				en_write <= 1'b0;				//使能信号拉低，等待写完成
			end
			
			WriteHE:begin
				en_write <= 1'b1;				//使能iic写
				//取得数据高4位，背光 1（开） 	EN（1）	RW 0 （写）	RS（cmd_data）0：命令，1：数据
				iic_data <= (data & 8'hF0) | 8'h0C | cmd_data;
			end
			WaitWHE:begin
				en_write <= 1'b0;				//使能信号拉低，等待写完成
			end
			
			WaitCMD1:begin
				us_cnt_clr <= 1'b0;			//计数器停止复位，开始计数
			end
			
			WriteHNE:begin
				us_cnt_clr <= 1'b1;
				en_write <= 1'b1;
				//取得数据高4位，背光 1（开） 	EN（清0）	RW 0 （写）	RS（cmd_data）0：命令，1：数据
				iic_data <= ((data & 8'hF0) | 8'h0C | cmd_data) & 8'hFB ;
			end
			WaitWHNE:begin
				en_write <= 1'b0;				//使能信号拉低，等待写完成
			end
			
			WriteLE:begin
				en_write <= 1'b1;
				//取得数据低4位，背光 1（开） 	EN（1）	RW 0 （写）	RS（cmd_data）0：命令，1：数据
				iic_data <= ((data & 8'h0F)<<4) | 8'h0C | cmd_data;
			end
			WaitWLE:begin
				en_write <= 1'b0;				//使能信号拉低，等待写完成
			end
			
			WaitCMD2:begin
				us_cnt_clr <= 1'b0;			//计数器停止复位，开始计数
			end
			
			WriteLNE:begin
				en_write <= 1'b1;
				us_cnt_clr <= 1'b1;
				//取得数据低4位，背光 1（开） 	EN（清0）	RW 0 （写）	RS（cmd_data）0：命令，1：数据
				iic_data <= (((data & 8'h0F)<<4) | 8'h0C | cmd_data) & 8'hFB ;
			end
			WaitWLNE:begin
				en_write <= 1'b0;				//使能信号拉低，等待写完成
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

//写一次数据或命令完成信号输出
assign done = (state == Done);

//例化iic写模块
myiic_writebyte myiic_writebyte_inst(
	.clk(clk),
	.rst_n(rst_n),
	.en_write(en_iicwrite),
	.data(iic_data),
	.sda(sda),
	.scl(scl),
	.sda_dir(sda_dir),
	.done(iic_done)
);

endmodule