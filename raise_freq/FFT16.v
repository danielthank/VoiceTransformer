module fft(clk,rst,fir_data,fir_valid,fft_data,fft_valid,freq,fft_fin);
input clk;
input rst;
input fir_valid;
input [15:0] fir_data;
output reg fft_valid,fft_fin;
output reg [31:0] fft_data;
output reg [3:0] freq;
integer i;
//const define
parameter signed w0_r = 20'h10000, w0_i = 20'h00000;
parameter signed w1_r = 20'h0EC83, w1_i = 20'hF9E09;
parameter signed w2_r = 20'h0B504, w2_i = 20'hF4AFC;
parameter signed w3_r = 20'h061F7, w3_i = 20'hF137D;
parameter signed w4_r = 20'h00000, w4_i = 20'hF0000;
parameter signed w5_r = 20'hF9E09, w5_i = 20'hF137D;
parameter signed w6_r = 20'hF4AFC, w6_i = 20'hF4AFC;
parameter signed w7_r = 20'hF137D, w7_i = 20'hF9E09;
//
reg [ 3:0] count_st1;
reg      fft1_state;
reg      fft1_state_n;
reg [ 2:0] count_st2;
reg      fft2_state;
reg      fft2_state_n;
reg [ 1:0] count_st3;
reg      fft3_state;
reg      fft3_state_n;
reg [ 3:0]  count_st4;
reg      fft4_state;
reg      fft4_state_n;
reg [15:0] fft_fifo1 [7:0];
reg [23:0] fft_fifo2_r [3:0];
reg [23:0] fft_fifo2_i [3:0];
reg [15:0] fft_fifo3_r [1:0];
reg [15:0] fft_fifo3_i [1:0];
reg [15:0] fft_fifo4_r ;
reg [15:0] fft_fifo4_i ;
//coeff reg
reg signed [19:0] fft_st1_coeff_r_r;
reg signed [19:0] fft_st1_coeff_i_r;
reg rounds1_r;
reg rounds1;
reg signed [19:0] fft_st2_coeff_r_r;
//reg signed [19:0] fft_st2_coeff_i_r;
reg rounds2_r2;
reg rounds2_r;
reg rounds2;
//stagr reg
reg signed [15:0] fft_st1_out_r;
reg               fft_st1_sel_r;
reg signed [19:0] fft_st1_coeff_r;
reg signed [19:0] fft_st1_coeff_i;
reg signed [23:0] fft_st1_mr_r;
reg signed [23:0] fft_st1_mi_r;
reg               fft_st1_sel_r2;
reg               fft_st2_en_r;
reg               fft_st2_en_r2;
reg signed [19:0] fft_st2_coeff_r;
reg signed [19:0] fft_st2_coeff_i;
reg signed [23:0] fft_st2_outr_r;
reg signed [23:0] fft_st2_outi_r;
reg signed [15:0] fft_st2_mr_r;
reg signed [15:0] fft_st2_mi_r;
reg               fft_st3_en_r;
reg               fft_st3_en_r2;
reg signed [15:0] fft_st3_outr_r;
reg signed [15:0] fft_st3_outi_r;
reg               fft_st4_en_r;
reg signed [15:0] fft_st4_outr_r;
reg signed [15:0] fft_st4_outi_r;
//
wire       fft_st1_sel = (count_st1>=4'd8);
wire[15:0] fft_fifo1_out = fft_fifo1[7]; 
wire[15:0] fft_st1_add = fft_fifo1_out+fir_data;  
wire[15:0] fft_st1_sub = fft_fifo1_out-fir_data;  
wire[15:0] fft_fifo1_in = (fft_st1_sel==1'b0)?fir_data:fft_st1_sub; 
wire[15:0] fft_st1_out  = (fft_st1_sel==1'b0)?fft_fifo1_out:fft_st1_add; 
wire signed [35:0] fft_st1_mr = fft_st1_coeff_r_r* fft_st1_out_r;
wire signed [35:0] fft_st1_mi = fft_st1_coeff_i_r* fft_st1_out_r;
////
wire       fft_st2_sel = (count_st2>=4'd4);
wire[23:0] fft_fifo2_r_out = fft_fifo2_r[3];
wire[23:0] fft_fifo2_i_out = fft_fifo2_i[3];
wire[23:0] fft_st2_r_add = fft_fifo2_r_out+fft_st1_mr_r;  
wire[23:0] fft_st2_i_add = fft_fifo2_i_out+fft_st1_mi_r;
wire[23:0] fft_st2_r_sub = fft_fifo2_r_out-fft_st1_mr_r; 
wire[23:0] fft_st2_i_sub = fft_fifo2_i_out-fft_st1_mi_r; 
wire[23:0] fft_fifo2_r_in = (fft_st2_sel==1'b0)?fft_st1_mr_r:fft_st2_r_sub;
wire[23:0] fft_fifo2_i_in = (fft_st2_sel==1'b0)?fft_st1_mi_r:fft_st2_i_sub;
reg [23:0] fft_fifo2_add ;
reg [23:0] fft_fifo2_sub ;
wire[23:0] fft_st2_r_out  = (fft_st2_sel==1'b0)?fft_fifo2_add:fft_st2_r_add;
wire[23:0] fft_st2_i_out  = (fft_st2_sel==1'b0)?fft_fifo2_sub:fft_st2_i_add;
wire signed [43:0] fft_st2_mr = fft_st2_coeff_r_r* fft_st2_outr_r;
wire signed [43:0] fft_st2_mi = fft_st2_coeff_r_r* fft_st2_outi_r;
////
wire       fft_st3_sel = (count_st3>=4'd2);
wire[15:0] fft_fifo3_r_out = fft_fifo3_r[1];
wire[15:0] fft_fifo3_i_out = fft_fifo3_i[1];
wire       rounds2r_r3 =fft_st2_mr_r[15]&rounds2_r2;
wire       rounds2i_r3 =fft_st2_mi_r[15]&rounds2_r2;
wire[15:0] fft_st3_r_add = fft_fifo3_r_out+fft_st2_mr_r+rounds2r_r3;  
wire[15:0] fft_st3_i_add = fft_fifo3_i_out+fft_st2_mi_r+rounds2i_r3;
wire[15:0] fft_st3_r_sub = fft_fifo3_r_out-fft_st2_mr_r-rounds2r_r3; 
wire[15:0] fft_st3_i_sub = fft_fifo3_i_out-fft_st2_mi_r-rounds2i_r3; 
wire[15:0] fft_fifo3_r_in = (fft_st3_sel==1'b0)?fft_st2_mr_r:fft_st3_r_sub;
wire[15:0] fft_fifo3_i_in = (fft_st3_sel==1'b0)?fft_st2_mi_r:fft_st3_i_sub;
wire[15:0] fft_st3_r_out  = (fft_st3_sel==1'b0)?fft_fifo3_r_out:fft_st3_r_add;
wire[15:0] fft_st3_i_out  = (fft_st3_sel==1'b0)?fft_fifo3_i_out:fft_st3_i_add;
wire[15:0] fft_st3_r_out2 = (count_st3==2'd1)? fft_st3_i_out:fft_st3_r_out;
wire[15:0] fft_st3_i_out2 = (count_st3==2'd1)? -fft_st3_r_out:fft_st3_i_out;
//
wire       fft_st4_sel = (count_st4[0]>=1'd1);
wire[15:0] fft_fifo4_r_out = fft_fifo4_r;
wire[15:0] fft_fifo4_i_out = fft_fifo4_i;
wire[15:0] fft_st4_r_add = fft_fifo4_r_out+fft_st3_outr_r;  
wire[15:0] fft_st4_i_add = fft_fifo4_i_out+fft_st3_outi_r;
wire[15:0] fft_st4_r_sub = fft_fifo4_r_out-fft_st3_outr_r; 
wire[15:0] fft_st4_i_sub = fft_fifo4_i_out-fft_st3_outi_r; 
wire[15:0] fft_fifo4_r_in = (fft_st4_sel==1'b0)?fft_st3_outr_r:fft_st4_r_sub;
wire[15:0] fft_fifo4_i_in = (fft_st4_sel==1'b0)?fft_st3_outi_r:fft_st4_i_sub;
wire[15:0] fft_st4_r_out  = (fft_st4_sel==1'b0)?fft_fifo4_r_out:fft_st4_r_add;
wire[15:0] fft_st4_i_out  = (fft_st4_sel==1'b0)?fft_fifo4_i_out:fft_st4_i_add;
//output
reg [3:0] freq_o;
always@(posedge clk)
  if(rst)begin
    fft_data <=0;
    fft_valid<=0;
    freq<=0;
    fft_fin<=0;
  end
  else begin
   fft_data <= {fft_st4_r_out,fft_st4_i_out};
   fft_valid<= fft4_state;
   freq     <= freq_o;
   fft_fin  <= (count_st4==4'd0&fft4_state);
  end 
always@(*)
  case(count_st4)
  4'd1: freq_o = 4'd0;
  4'd2: freq_o = 4'd8;
  4'd3: freq_o = 4'd4;
  4'd4: freq_o = 4'd12;
  4'd5: freq_o = 4'd2;
  4'd6: freq_o = 4'd10;
  4'd7: freq_o = 4'd6;
  4'd8: freq_o = 4'd14;
  4'd9: freq_o = 4'd1;
  4'd10: freq_o = 4'd9;
  4'd11: freq_o = 4'd5;
  4'd12: freq_o = 4'd13;
  4'd13: freq_o = 4'd3;
  4'd14: freq_o = 4'd11;
  4'd15: freq_o = 4'd7;
  4'd0: freq_o = 4'd15;
  endcase
//FFT stage4
always@(*)
  case(fft4_state)
  1'b0: if(fft_st4_en_r==1'b1 & count_st4[0]>=1'd0) fft4_state_n=1'b1; else fft4_state_n=1'b0;
  1'b1: if(fft_st4_en_r==1'b0 & count_st4[0]==1'd0) fft4_state_n=1'b0; else fft4_state_n=1'b1;
  endcase
always@(posedge clk)
  if(rst) fft4_state <=  0;
  else    fft4_state <=  fft4_state_n;
//counter
always@(posedge clk)
  if(rst)                count_st4 <=0;
  else if(fft_st4_en_r||fft4_state) count_st4 <= count_st4+4'd1;
// shift reg 
always@(posedge clk)
  if(rst) begin
    fft_fifo4_r<=0;
    fft_fifo4_i<=0;
  end
  else begin 
    fft_fifo4_r<=fft_fifo4_r_in;
    fft_fifo4_i<=fft_fifo4_i_in;
  end

//FFT stage3
always@(*)
  case(fft3_state)
  1'b0: if(fft_st3_en_r2==1'b1 & count_st3>=4'd1) fft3_state_n=1'b1; else fft3_state_n=1'b0;
  1'b1: if(fft_st3_en_r2==1'b0 & count_st3==4'd1) fft3_state_n=1'b0; else fft3_state_n=1'b1;
  endcase
always@(posedge clk)
  if(rst) fft3_state <=  0;
  else    fft3_state <=  fft3_state_n;
//counter
always@(posedge clk)begin 
  if(rst) begin
    count_st3 <=0;
  end
  else if(fft_st3_en_r2) begin 
    count_st3 <= count_st3+2'd1;
  end 
end
// shift reg 
always@(posedge clk)begin 
  if(rst) begin
     for(i=0;i<=1;i=i+1)begin
       fft_fifo3_r[i]<=0;
       fft_fifo3_i[i]<=0;
     end
  end
  else begin 
    fft_fifo3_r[0]<=fft_fifo3_r_in;
    fft_fifo3_i[0]<=fft_fifo3_i_in;
    for(i=1;i<=1;i=i+1)begin
      fft_fifo3_r[i]<=fft_fifo3_r[i-1]; 
      fft_fifo3_i[i]<=fft_fifo3_i[i-1];
    end
  end 
end

always@(posedge clk)begin 
  if(rst) begin
   fft_st3_outr_r<=0;
   fft_st3_outi_r<=0;
    fft_st4_en_r  <=0;
   // fft_st4_en_r2 <=0;    
  end
  else begin 
   fft_st3_outr_r<=fft_st3_r_out2;
   fft_st3_outi_r<=fft_st3_i_out2;
    fft_st4_en_r  <=fft3_state;
    //fft_st4_en_r2 <=fft_st4_en_r;
 end 
end

//FFtstage2
always@(posedge clk)begin
  if(rst)begin
    fft_st2_coeff_r_r<=0;
//    fft_st2_coeff_i_r<=0;
    rounds2_r<=0;
  end
  else begin
    fft_st2_coeff_r_r<= fft_st2_coeff_r;
//    fft_st2_coeff_i_r<= fft_st2_coeff_i;
    rounds2_r<=rounds2;
  end
end
//
always@(*)
  case(fft2_state)
  1'b0: if(fft_st2_en_r2==1'b1 & count_st2>=4'd3) fft2_state_n=1'b1; else fft2_state_n=1'b0;
  1'b1: if(fft_st2_en_r2==1'b0 & count_st2==4'd3) fft2_state_n=1'b0; else fft2_state_n=1'b1;
  endcase

always@(posedge clk)
  if(rst) fft2_state <=  0;
  else    fft2_state <=  fft2_state_n;
////counter
always@(posedge clk)begin 
  if(rst) begin
    count_st2 <=0;
  end
  else if(fft_st2_en_r2||fft2_state) begin 
    count_st2 <= count_st2+3'd1;
  end 
end
// shift reg 
always@(posedge clk)begin 
  if(rst) begin
     for(i=0;i<=3;i=i+1)begin
       fft_fifo2_r[i]<=0;
       fft_fifo2_i[i]<=0;
     end
  end
  else begin 
    fft_fifo2_r[0]<=fft_fifo2_r_in;
    fft_fifo2_i[0]<=fft_fifo2_i_in;
    for(i=1;i<=3;i=i+1)begin
      fft_fifo2_r[i]<=fft_fifo2_r[i-1]; 
      fft_fifo2_i[i]<=fft_fifo2_i[i-1];
    end
  end 
end
always@(posedge clk)begin 
  if(rst) begin
   fft_st2_outr_r<=0;
   fft_st2_outi_r<=0;
    fft_st2_mr_r  <= 0;
    fft_st2_mi_r  <= 0;
    fft_st3_en_r  <=0;
    fft_st3_en_r2 <=0;
    rounds2_r2    <=0;    
  end
  else begin 
   fft_st2_outr_r<=fft_st2_r_out;
   fft_st2_outi_r<=fft_st2_i_out;
    fft_st2_mr_r  <= fft_st2_mr[39:24];
    fft_st2_mi_r  <= fft_st2_mi[39:24];
    fft_st3_en_r  <=fft2_state;
    fft_st3_en_r2 <=fft_st3_en_r;
    rounds2_r2    <=rounds2_r;
 end 
end

always@(*)begin
  rounds2 =1'b0;	
  case(count_st2)
  3'd1: begin fft_st2_coeff_r = w2_r;   rounds2 =1'b1; fft_fifo2_add = fft_fifo2_r_out+fft_fifo2_i_out;  fft_fifo2_sub = fft_fifo2_i_out-fft_fifo2_r_out; end
  3'd2: begin fft_st2_coeff_r = w0_r;   fft_fifo2_add = fft_fifo2_i_out;  fft_fifo2_sub = -fft_fifo2_r_out; end
  3'd3: begin fft_st2_coeff_r = w6_r;   rounds2 =1'b1; fft_fifo2_add = fft_fifo2_r_out-fft_fifo2_i_out;  fft_fifo2_sub = fft_fifo2_i_out+fft_fifo2_r_out;end
  default:  begin fft_st2_coeff_r = w0_r;  fft_fifo2_add = fft_fifo2_r_out;  fft_fifo2_sub = fft_fifo2_i_out;  end
  endcase
end

//FFt1stage
always@(posedge clk)begin
  if(rst)begin
    fft_st1_coeff_r_r<=0;
    fft_st1_coeff_i_r<=0;
    rounds1_r<=0;
  end
  else begin
    fft_st1_coeff_r_r<= fft_st1_coeff_r;
    fft_st1_coeff_i_r<= fft_st1_coeff_i;
    rounds1_r<=rounds1;
  end
end
always@(*)
  case(fft1_state)
  1'b0: if(fir_valid==1'b1 & count_st1>=4'd7) fft1_state_n=1'b1; else fft1_state_n=1'b0;
  1'b1: if(fir_valid==1'b0 & count_st1==4'd7) fft1_state_n=1'b0; else fft1_state_n=1'b1;
  endcase

always@(posedge clk)
  if(rst) fft1_state <=  0;
  else    fft1_state <=  fft1_state_n;
// count reg 
always@(posedge clk)begin 
  if(rst) begin
    count_st1 <=0;
  end
  else if(fir_valid||fft1_state) begin 
    count_st1 <= count_st1+4'd1;
  end 
end

// shift reg 
always@(posedge clk)begin 
  if(rst) begin
    for(i=0;i<=7;i=i+1)
	  fft_fifo1[i]<=0;
  end
  else begin 
    fft_fifo1[0]<=fft_fifo1_in;
    for(i=1;i<=7;i=i+1)
	  fft_fifo1[i]<=fft_fifo1[i-1];
  end 
end

always@(posedge clk)begin 
  if(rst) begin
    fft_st1_out_r <=0;
    fft_st1_mr_r  <=0;
    fft_st1_mi_r  <=0;
    fft_st2_en_r  <=0;
    fft_st2_en_r2 <=0;
  end
  else begin 
    fft_st1_out_r <= fft_st1_out;
    fft_st1_mr_r  <= fft_st1_mr[31:8]+(rounds1_r&fft_st1_mr[35]);
    fft_st1_mi_r  <= fft_st1_mi[31:8]+(rounds1_r&fft_st1_mi[35]);
    fft_st2_en_r  <= fft1_state;
    fft_st2_en_r2 <= fft_st2_en_r;
  end 
end

always@(*)begin
  rounds1=1'b0;	
  case(count_st1)
  4'd1:  begin fft_st1_coeff_r = w1_r;  fft_st1_coeff_i = w1_i; rounds1=1'b1; end
  4'd2: begin fft_st1_coeff_r = w2_r;  fft_st1_coeff_i = w2_i;rounds1=1'b1; end
  4'd3: begin fft_st1_coeff_r = w3_r;  fft_st1_coeff_i = w3_i;rounds1=1'b1; end
  4'd4: begin fft_st1_coeff_r = w4_r;  fft_st1_coeff_i = w4_i; end
  4'd5: begin fft_st1_coeff_r = w5_r;  fft_st1_coeff_i = w5_i;rounds1=1'b1; end
  4'd6: begin fft_st1_coeff_r = w6_r;  fft_st1_coeff_i = w6_i;rounds1=1'b1; end
  4'd7: begin fft_st1_coeff_r = w7_r;  fft_st1_coeff_i = w7_i;rounds1=1'b1; end
  default:  begin fft_st1_coeff_r = w0_r;  fft_st1_coeff_i = w0_i; end
  endcase
end

endmodule 
