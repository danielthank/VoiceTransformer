module raiseFreq(clk,rst,fft1_data,fft1_valid,freq1,fft1_fin,
    fft2_data,fft2_valid,freq2,fft2_fin,raise_valid,raise_fin,
    raise_data,freq_out);

input clk;
input rst;
input reg fft1_valid,fft1_fin;
input reg [127:0] fft1_data;
input reg [5:0] freq1;
input reg fft2_valid,fft2_fin;
input reg [127:0] fft2_data;
input reg [5:0] freq2;
output reg raise_valid,raise_fin;
output reg [127:0] raise_data;
output reg [5:0] freq_out;



endmodule

