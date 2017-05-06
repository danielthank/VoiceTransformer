`timescale 1ns/100ps

module test_i2c;

reg clk, rst;
wire sclk, sdat, finish;

i2c_init i2c_init_0(.clk_n(clk), .rst(rst), .sclk(sclk), .sdat(sdat), .finish(finish));

always #4 clk = ~clk;

initial begin
    $dumpfile("i2c_init.vcd");
    $dumpvars;
    clk = 1'b1;
    rst = 1'b1;
    #4 rst = 1'b0;
    #8 rst = 1'b1;

    #10000 $finish;
end

always @(posedge finish) begin
    #10 $finish;
end

endmodule
