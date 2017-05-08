module top(
    rst,
    // i2c
    sclk,
    sdat,
    // adc and dac
    mclk,
    bclk,
    adclrc,
    daclrc,
    adcdat,
    dacdat,
    // channel
    channel
);

input rst;
input mclk; // 12.288MHz
input bclk; // 3.072MHz
input adclrc; // 8kHz
input daclrc; // 8kHz
input adcdat;
input [1:0] channel;

output sclk;
output sdat;
output dacdat;
wire i2c_finish;
wire [15:0] audio_raw;
wire audio_raw_en;

reg [2:0] state_r, state_w;
reg [15:0] audio_r, audio_w;
reg audio_ready_r, audio_ready_w;
reg [1:0] counter_r, counter_w;

i2c_init i2c_init_0(.clk_n(mclk), .rst(rst), .sclk(sclk), .sdat(sdat), .finish(i2c_finish));
i2s_read i2s_read_0(.clk_p(bclk), .rst(i2c_finish), .adclrc(adclrc), .adcdat(adcdat), .data(audio_raw), .data_en(audio_raw_en));
i2s_write i2s_write_0(.clk_n(bclk), .rst(i2c_finish), .daclrc(daclrc), .dacdat(dacdat), .data(audio_r), .data_en(audio_ready_r));

localparam [2:0]
    STATE_INIT=3'd0,
    STATE_GET_AUDIO=3'd1,
    STATE_PROCESS=3'd2,
    STATE_PLAY_AUDIO=3'd3,
    STATE_STOP=3'd4,
    STATE_FINISH=3'd5;

always @(*) begin
    state_w = state_r;
    audio_w = audio_r;
    audio_ready_w = audio_ready_r;
    case (state_r)
        STATE_INIT: begin
            if (i2c_finish == 1'b1) begin
                state_w = STATE_GET_AUDIO;
            end
        end
        STATE_GET_AUDIO: begin
            if (audio_raw_en) begin
                audio_w = audio_raw;
                state_w = STATE_PLAY_AUDIO; 
                audio_ready_w = 1'b1;
                counter_w = 0;
            end
        end
        STATE_PLAY_AUDIO: begin
            if (counter_r == 2'd3) begin
                state_w = STATE_GET_AUDIO;
                audio_ready_w = 1'b0;
            end
            counter_w = counter_r + 1;
        end
    endcase
end

always @(posedge mclk or negedge rst) begin
    if (rst == 1'b0) begin
        state_r <= STATE_INIT;
        audio_r <= 15'd0;
        audio_ready_r <= 1'b0;
        counter_r <= 2'd0;
    end
    else begin
        state_r <= state_w;
        audio_r <= audio_w;
        audio_ready_r <= audio_ready_w;
        counter_r <= counter_w;
    end
end

endmodule


