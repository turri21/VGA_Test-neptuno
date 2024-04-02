`default_nettype none
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name:    vga_test 
//
//////////////////////////////////////////////////////////////////////////////////
module nepturri_top(
			input clk,
			input rstn,
			output vga_hs,
			output vga_vs,
			output [VGA_BITS-1:0] vga_r,
			output [VGA_BITS-1:0] vga_g,
			output [VGA_BITS-1:0] vga_b,
			input key1,                        //button key1
			output led
);

`ifdef VGA_8BIT
localparam VGA_BITS = 8;
`else
localparam VGA_BITS = 6;
`endif
//-----------------------------------------------------------//
// Horizontal scan parameter settings 1024*768 60Hz VGA
//-----------------------------------------------------------//
parameter LinePeriod =1344;            //Number of row cycles
parameter H_SyncPulse=136;             //Horizontal sync pulse（Sync a）
parameter H_BackPorch=160;             //Display trailing edge（Back porch b）
parameter H_ActivePix=1024;            //Show time series（Display interval c）
parameter H_FrontPorch=24;             //Show leading edge（Front porch d）
parameter Hde_start=296;
parameter Hde_end=1320;

//-----------------------------------------------------------//
// Vertical scan parameter settings 1024*768 60Hz VGA
//-----------------------------------------------------------//
parameter FramePeriod =806;           //Column period number
parameter V_SyncPulse=6;              //Column sync pulse（Sync o）
parameter V_BackPorch=29;             //Display trailing edge（Back porch p）
parameter V_ActivePix=768;            //Show time series（Display interval q）
parameter V_FrontPorch=3;             //Show leading edge（Front porch r）
parameter Vde_start=35;
parameter Vde_end=803;

//-----------------------------------------------------------//
// Horizontal scan parameter settings 800*600 VGA
//-----------------------------------------------------------//
//parameter LinePeriod =1056;           //Number of row cycles
//parameter H_SyncPulse=128;            //Horizontal sync pulse（Sync a）
//parameter H_BackPorch=88;             //Display trailing edge（Back porch b）
//parameter H_ActivePix=800;            //Show time series（Display interval c）
//parameter H_FrontPorch=40;            //Show leading edge（Front porch d）

//-----------------------------------------------------------//
// Vertical scan parameter settings 800*600 VGA
//-----------------------------------------------------------//
//parameter FramePeriod =628;           //Column period number
//parameter V_SyncPulse=4;              //Column sync pulse（Sync o）
//parameter V_BackPorch=23;             //Display trailing edge（Back porch p）
//parameter V_ActivePix=600;            //Show time series（Display interval q）
//parameter V_FrontPorch=1;             //Show leading edge（Front porch r）


  reg[10 : 0] x_cnt;
  reg[9 : 0]  y_cnt;
  reg[15 : 0] grid_data_1;
  reg[15 : 0] grid_data_2;
  reg[15 : 0] bar_data;
  reg[3 : 0] vga_dis_mode;
  reg[5 : 0]  vga_r_reg;
  reg[5 : 0]  vga_g_reg;
  reg[5 : 0]  vga_b_reg;  
  reg hsync_r;
  reg vsync_r; 
  reg hsync_de;
  reg vsync_de;
  
  reg [19:0] key1_counter;                 //Key detection register
  reg [31:0] auto_change_counter;          // Counter for automatic pattern change
  
  wire vga_clk; 
  wire [12:0]  bar_interval;
  
assign	bar_interval 	= H_ActivePix[15: 3];         //Color bar width=H_ActivePix/8
  
//----------------------------------------------------------------
////////// Horizontal scan count
//----------------------------------------------------------------
always @ (posedge vga_clk)
       if(~rstn)    x_cnt <= 1;
       else if(x_cnt == LinePeriod) x_cnt <= 1;
       else x_cnt <= x_cnt+ 1;
		 
//----------------------------------------------------------------
//////// Horizontal scanning signals hsync, hsync_de are generated
//----------------------------------------------------------------
always @ (posedge vga_clk)
   begin
       if(~rstn) hsync_r <= 1'b1;
       else if(x_cnt == 1) hsync_r <= 1'b0;            //Generate hsync signal
       else if(x_cnt == H_SyncPulse) hsync_r <= 1'b1;
		 
		 		 
	    if(1'b0) hsync_de <= 1'b0;
       else if(x_cnt == Hde_start) hsync_de <= 1'b1;    //Generate hsync_de signal
       else if(x_cnt == Hde_end) hsync_de <= 1'b0;	
	end

//----------------------------------------------------------------
////////// Vertical scan count
//----------------------------------------------------------------
always @ (posedge vga_clk)
       if(~rstn) y_cnt <= 1;
       else if(y_cnt == FramePeriod) y_cnt <= 1;
       else if(x_cnt == LinePeriod) y_cnt <= y_cnt+1;

//----------------------------------------------------------------
////////// Vertical scanning signals vsync, vsync_de are generated
//----------------------------------------------------------------
always @ (posedge vga_clk)
  begin
       if(~rstn) vsync_r <= 1'b1;
       else if(y_cnt == 1) vsync_r <= 1'b0;    //Generate vsync signal
       else if(y_cnt == V_SyncPulse) vsync_r <= 1'b1;
		 
	    if(~rstn) vsync_de <= 1'b0;
       else if(y_cnt == Vde_start) vsync_de <= 1'b1;    //Generate vsync_de signal
       else if(y_cnt == Vde_end) vsync_de <= 1'b0;	 
  end
		 

//----------------------------------------------------------------
////////// Grid test image generation
//----------------------------------------------------------------
 always @(negedge vga_clk)   
   begin
     if ((x_cnt[4]==1'b1) ^ (y_cnt[4]==1'b1))            //Produce small grid images
			    grid_data_1<= 16'h0000;
	  else
			    grid_data_1<= 16'hffff;
				 
	  if ((x_cnt[6]==1'b1) ^ (y_cnt[6]==1'b1))            //Produce large grid images
			    grid_data_2<=16'h0000;
	  else
				 grid_data_2<=16'hffff; 
   
	end
	
//----------------------------------------------------------------
////////// Color bar test image generation
//----------------------------------------------------------------
 always @(negedge vga_clk)   
   begin
     if (x_cnt==Hde_start)            
			    bar_data<= 16'hf800;              //Red color bar
	  else if (x_cnt==Hde_start + bar_interval)
			    bar_data<= 16'h07e0;              //Green color bar				 
	  else if (x_cnt==Hde_start + bar_interval*2)            
			    bar_data<=16'h001f;               //Blue color bar
	  else if (x_cnt==Hde_start + bar_interval*3)         
			    bar_data<=16'hf81f;               //Purple color bar
	  else if (x_cnt==Hde_start + bar_interval*4)           
			    bar_data<=16'hffe0;               //Yellow color bar
	  else if (x_cnt==Hde_start + bar_interval*5)            
			    bar_data<=16'h07ff;               //Cyan color bar
	  else if (x_cnt==Hde_start + bar_interval*6)             
			    bar_data<=16'hffff;               //White color bar
	  else if (x_cnt==Hde_start + bar_interval*7)            
			    bar_data<=16'hfc00;               //Orange color bar
	  else if (x_cnt==Hde_start + bar_interval*8)              
			    bar_data<=16'h0000;               //Rest black
   
	end
	
//----------------------------------------------------------------
////////// VGA Image selection output
//----------------------------------------------------------------
 //LCD Data signal selection
 always @(negedge vga_clk)  
    if(~rstn) begin 
	    vga_r_reg<=0; 
	    vga_g_reg<=0;
	    vga_b_reg<=0;		 
	end
   else
     case(vga_dis_mode)
         4'b0000:begin
			        vga_r_reg<=0;                        //VGA Display all black
                 vga_g_reg<=0;
                 vga_b_reg<=0;
			end
			4'b0001:begin
			        vga_r_reg<=5'b11111;                 //VGA Display all white
                 vga_g_reg<=6'b111111;
                 vga_b_reg<=5'b11111;
			end
			4'b0010:begin
			        vga_r_reg<=5'b11111;                 //VGA Display all red
                 vga_g_reg<=0;
                 vga_b_reg<=0;  
         end			  
	      4'b0011:begin
			        vga_r_reg<=0;                        //VGA Display all green
                 vga_g_reg<=6'b111111;
                 vga_b_reg<=0; 
         end					  
         4'b0100:begin     
			        vga_r_reg<=0;                        //VGA Display all blue
                 vga_g_reg<=0;
                 vga_b_reg<=5'b11111;
			end
         4'b0101:begin     
			        vga_r_reg<=grid_data_1[15:11];       // VGA Display square 1
                 vga_g_reg<=grid_data_1[10:5];
                 vga_b_reg<=grid_data_1[4:0];
         end					  
         4'b0110:begin     
			        vga_r_reg<=grid_data_2[15:11];       // VGA Display square 2
                 vga_g_reg<=grid_data_2[10:5];
                 vga_b_reg<=grid_data_2[4:0];
			end
		   4'b0111:begin     
			        vga_r_reg<=x_cnt[6:2];               //VGA Display horizontal gradient color
                 vga_g_reg<=x_cnt[6:1];
                 vga_b_reg<=x_cnt[6:2];
			end
		   4'b1000:begin     
			        vga_r_reg<=y_cnt[6:2];               //VGA Display vertical gradient color
                 vga_g_reg<=y_cnt[6:1];
                 vga_b_reg<=y_cnt[6:2];
			end
		   4'b1001:begin     
			        vga_r_reg<=x_cnt[6:2];               //VGA Display red horizontal gradient color
                 vga_g_reg<=0;
                 vga_b_reg<=0;
			end
		   4'b1010:begin     
			        vga_r_reg<=0;                        //VGA Display green horizontal gradient color
                 vga_g_reg<=x_cnt[6:1];
                 vga_b_reg<=0;
			end
		   4'b1011:begin     
			        vga_r_reg<=0;                        //VGA Display blue horizontal gradient color
                 vga_g_reg<=0;
                 vga_b_reg<=x_cnt[6:2];			
			end
		   4'b1100:begin     
			        vga_r_reg<=bar_data[15:11];          //VGA Display color bars
                 vga_g_reg<=bar_data[10:5];
                 vga_b_reg<=bar_data[4:0];			
			end
		   default:begin
			        vga_r_reg<=5'b11111;                 //VGA Display all white
                 vga_g_reg<=6'b111111;
                 vga_b_reg<=5'b11111;
			end					  
         endcase
	

  assign vga_hs = hsync_r;
  assign vga_vs = vsync_r;  
  assign vga_r = (hsync_de & vsync_de)?vga_r_reg:5'b00000;
  assign vga_g = (hsync_de & vsync_de)?vga_g_reg:6'b000000;
  assign vga_b = (hsync_de & vsync_de)?vga_b_reg:5'b00000;
  
 //Generate 65Mhz VGA Clock 
   pll pll_inst
  (
   .inclk0(clk),               
   .c0(vga_clk),               // 65.0Mhz for 1024x768(60hz)
   .areset(~rstn),              
   .locked()
	);              

/*
  //Button handler	
  always @(posedge vga_clk)
  begin
    if(~rstn) begin 
	    vga_dis_mode<=4'b0000; 
		 key1_counter<=0;	 
	 end	
	 else begin
	    if (key1==1'b1)                               //If the button is not pressed, the register is 0
	       key1_counter<=0;
	    else if ((key1==1'b0)& (key1_counter<=20'd90_000))      //If the button is pressed and pressed for less than 1ms, count (9M*0.1=900_000)    
          key1_counter<=key1_counter+1'b1;
  	  
       if (key1_counter==20'd89_999)                //Once the button is active, change the display mode
		    begin
		      if(vga_dis_mode==4'b1101)
			      vga_dis_mode<=4'b0000;
			   else
			      vga_dis_mode<=vga_dis_mode+1'b1; 
          end	
     end		
  end	
*/
// Automatic pattern change after a few seconds
always @(posedge vga_clk or negedge rstn)
begin
    if (~rstn)
        auto_change_counter <= 0;
    else if (auto_change_counter == 120000000) // a few seconds
    begin
        auto_change_counter <= 0;
        if (vga_dis_mode == 4'b1101)
            vga_dis_mode <= 4'b0000;
        else
            vga_dis_mode <= vga_dis_mode + 1'b1;
    end
    else
        auto_change_counter <= auto_change_counter + 1;
end  

endmodule
