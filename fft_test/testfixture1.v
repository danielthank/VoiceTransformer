`timescale 1ns/10ps
`define CYCLE     10.0                // Modify your clock period here
`define End_CYCLE  3000      // Modify cycle times once your design need more cycle times!

`define fft_fail_limit 48

module testfixture1;

reg   clk ;
reg   reset ;
reg  fft_en;
wire fir_valid;
wire fin;
reg [15:0] fir_d; // 8 integer + 8 fraction
wire [31:0] fft_d;
wire [3:0] freq;
wire [15:0] fft_real = fft_d[31:16];
wire [15:0] fft_imag = fft_d[15:0];
reg en;

reg [15:0] fir_mem [0:1023];
initial $readmemh("FFT_in.dat", fir_mem);

reg [15:0] fftr_mem [0:1023];
initial $readmemh("Golden1_FFT_real.dat", fftr_mem);
reg [15:0] ffti_mem [0:1023];
initial $readmemh("Golden1_FFT_imag.dat", ffti_mem);

integer i, j ,k, l,count;
integer fft_fail;

fft DUT(.clk(clk),.rst(reset),.fir_data(fir_d),.fir_valid(fft_en),.fft_data(fft_d),.fft_valid(fft_valid),.freq(freq),.fft_fin(fin));

/*
* fir_data: input of fft
* fir_valid: input enable
* fft_data: output of fft
* fft_valid: ?
* freq: ?
* fin: ?
*/


initial begin
    $dumpfile("FAS.vcd");
    $dumpvars;
end

initial begin
    #0;
    clk         = 1'b0;
    reset       = 1'b0; 
    i = 0;   
    j = 0;  
    k = 0;
    l = 0;
    fft_fail = 0;  
    count=0;
end

always begin #(`CYCLE/2) clk = ~clk; end

initial begin
    en = 0;
    #(`CYCLE*0.5)   reset = 1'b1; 
    #(`CYCLE*2); #0.5;   reset = 1'b0; en = 1;
end

// data input & ready
always@(negedge clk ) begin
    if (en) begin
        if (i >= 1024 )
            fir_d <= 0;
        else begin
            fir_d <= fir_mem[i];
            i <= i + 1;
        end
    end
    fft_en<=en;
    if(fin)
        count=count+1;
    if(count >=64)begin
        $display("-----------------------------------------------------");
        $display("-------------End of sim ----------------------------");
        $finish;	   
    end   
end




// Terminate the simulation, FAIL
initial  begin
    #(`CYCLE * `End_CYCLE);
    $display("-----------------------------------------------------");
    $display("-------------End of time ----------------------------");
    $finish;
end
endmodule
