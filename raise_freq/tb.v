`timescale 1ns/10ps
`define CYCLE     400.0                // Modify your clock period here
`define CYCLE_CAL     10.0                // Modify your clock period here
`define End_CYCLE  520      // Modify cycle times once your design need more cycle times!

`define fft_fail_limit 48

module tb;

reg         en;
reg         clk;
reg         clk_cal;
reg         rst;
reg [31:0]  fft1_data;
reg         fft1_valid;
reg [5:0]   freq1;
reg         fft1_fin;
reg [31:0]  fft2_data;
reg         fft2_valid;
reg [5:0]   freq2;
reg         fft2_fin;

wire raise_valid;
wire raise_fin;
wire [31:0] raise_data;
wire [5:0]  freq_out;

reg [31:0] fft1_mem [0:511];
initial $readmemh("fft_in1.dat", fft1_mem);
reg [31:0] fft2_mem [0:511];
initial $readmemh("fft_in2.dat", fft2_mem);

integer i, j ,k, l,count;

raiseFreq DUT(.clk(clk),.clk_cal(clk_cal),.rst(rst),.fft1_data(fft1_data),
    .fft1_valid(fft1_valid),.freq1(freq1),.fft1_fin(fft1_fin),
    .fft2_data(fft2_data),.fft2_valid(fft2_valid),.freq2(freq2),
    .fft2_fin(fft2_fin),.raise_valid(raise_valid),.raise_fin(raise_fin),
    .raise_data(raise_data),.freq_out(freq_out));

/*
* fir_data: input of fft
* fir_valid: input enable
* fft_data: output of fft
* fft_valid: ?
* freq: ?
* fin: ?
*/


initial begin
    $dumpfile("FAS.fsdb");
    $dumpvars;
end

initial begin
    #0;
    clk         = 1'b0;
    clk_cal     = 1'b0;
    rst       = 1'b0; 
    fft1_fin = 1;
    fft2_fin = 1;
    freq1 = 6'b0;
    freq2 = 6'b0;
    en = 0;
    i = 0;   
    j = 0;  
    k = 0;
    l = 0;
    count=0;
end

always begin #(`CYCLE/2) clk = ~clk; end
always begin #(`CYCLE_CAL/2) clk_cal = ~clk_cal; end

initial begin
    #(`CYCLE*0.5)   rst = 1'b1; 
    #(`CYCLE*2); #0.5;   rst = 1'b0; en = 1;
end

// data input & ready
always@(negedge clk ) begin
    if (en) begin
        if (i >= 512 )begin
            fft1_data <= 0;
            fft2_data <= 0;
        end
        else begin
            fft1_data <= fft1_mem[i];
            //$display(fft1_mem[i]);
            //$display("\n");
            fft2_data <= fft2_mem[i];
            i <= i + 1;
            freq1 <= i+1;
            freq2 <= i+1;
        end
    end
    fft1_valid <= en;
    fft2_valid <= en;
    if(raise_fin) begin
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
