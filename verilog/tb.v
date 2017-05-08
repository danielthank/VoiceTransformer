`timescale 1ns/100ps

module tb;

reg rst, mclk, bclk, lrc, adcdat;
wire [1:0] channel;
wire sclk, sdat, dacdat;
reg [15:0] audio_data [0:9];

top top_0(
    .rst(rst),
    // i2c
    .sclk(sclk),
    .sdat(sdat),
    // adc and dac
    .mclk(mclk),
    .bclk(bclk),
    .adclrc(lrc),
    .daclrc(lrc),
    .adcdat(adcdat),
    .dacdat(dacdat),
    // channel
    .channel(channel));

always #38.8 mclk = ~mclk; // 12.288MHz
always #(38.8*4) bclk = ~bclk;
always #(38.8*256) lrc = ~lrc;

initial begin
    $dumpfile("tb.vcd");
    $dumpvars;
    $readmemh("audio.dat", audio_data);
    mclk = 1'b0;
    bclk = 1'b0;
    lrc = 1'b0;
    rst = 1'b1;
    adcdat = 1'b0;
    #10 rst = 1'b0;
    #90 rst = 1'b1;
end

integer i, j;

initial begin
    # 50000
    for (i=0; i<10; i=i+1) begin
        @(negedge lrc);
        for (j=0; j<16; j=j+1) begin
            @(negedge bclk);
            adcdat = audio_data[i][15-j];
        end
        adcdat = 1'b0;
    end
    $finish;
end


endmodule
