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
reg audio_ready_r, audio_ready_w;
reg [2:0] counter_r, counter_w;
reg [3:0] counter_12_r, counter_12_w;
reg [5:0] counter_64_r, counter_64_w;
reg [4:0] counter_32_r, counter_32_w;
reg [6:0] transmit_idx_r, transmit_idx_w;
reg [15:0] buffer_r[0:79], buffer_w[0:79]; 
reg [15:0] tofft_pre_r, tofft_pre_w;
reg [15:0] tofft_next_r, tofft_next_w;
reg transmitting_w, transmitting_r;

i2c_init i2c_init_0(.clk_n(mclk), .rst(rst), .sclk(sclk), .sdat(sdat), .finish(i2c_finish));
i2s_read i2s_read_0(.clk_p(bclk), .rst(i2c_finish), .adclrc(adclrc), .adcdat(adcdat), .data(audio_raw), .data_en(audio_raw_en));
i2s_write i2s_write_0(.clk_n(bclk), .rst(i2c_finish), .daclrc(daclrc), .dacdat(dacdat), .data(buffer_r[79]));

localparam [2:0]
    STATE_INIT=3'd0,
    STATE_GET_AUDIO=3'd1,
    STATE_GET_AUDIO_WAIT=3'd2,
    STATE_PROCESS=3'd3,
    STATE_PLAY_AUDIO=3'd4,
    STATE_STOP=3'd5,
    STATE_FINISH=3'd6;

integer i;

always @(*) begin
    state_w = state_r;
    audio_ready_w = audio_ready_r;
    counter_w = counter_r;
    counter_64_w = counter_64_r;
    counter_12_w = counter_12_r;
    counter_32_w = counter_32_r;
    tofft_pre_w = tofft_pre_r;
    tofft_next_w = tofft_next_r;
    transmitting_w = transmitting_r;
    transmit_idx_w = transmit_idx_r;
    for (i=0; i<80; i=i+1) begin
        buffer_w[i] = buffer_r[i];
    end
    case (state_r)
        STATE_INIT: begin
            if (i2c_finish == 1'b1) begin
                state_w = STATE_GET_AUDIO;
            end
        end
        STATE_GET_AUDIO: begin
            if (audio_raw_en) begin
                counter_w = 3'd0;
                state_w = STATE_GET_AUDIO_WAIT;
                for (i=0; i<79; i=i+1) begin
                    buffer_w[i] = buffer_r[i+1];
                end
                buffer_w[79] = audio_raw;
                counter_12_w = counter_12_r + 1;
                if (counter_12_w == 4'd12) begin
                    counter_12_w = 4'd0;
                    counter_32_w = 5'd0;
                    counter_64_w = 6'd0;
                    transmitting_w = 1'b1;
                    transmit_idx_w = 6'd0;
                end
            end
        end
        STATE_GET_AUDIO_WAIT: begin
            if (counter_r == 3'd5) begin
                state_w = STATE_GET_AUDIO;
            end
            counter_w = counter_r + 1;
        end
    endcase
    if (transmitting_r) begin
        tofft_pre_w = buffer_r[transmit_idx_r];
        tofft_next_w = buffer_r[transmit_idx_r+16];
        if (counter_32_r == 5'd31) begin
            if (counter_64_r == 6'd63) begin
                transmitting_w = 1'b0;
                tofft_pre_w = 16'd0;
                tofft_next_w = 16'd0;
            end
            if (~(state_r == STATE_GET_AUDIO && audio_raw_en)) begin
                transmit_idx_w = transmit_idx_r + 1;
            end
            counter_64_w = counter_64_r + 1;
        end
        counter_32_w = counter_32_r + 1;
    end
end

always @(posedge mclk or negedge rst) begin
    if (rst == 1'b0) begin
        state_r <= STATE_INIT;
        audio_ready_r <= 1'b0;
        counter_r <= 3'd0;
        counter_12_r <= 4'd0;
        counter_64_r <= 6'd0;
        counter_32_r <= 5'd0;
        transmitting_r <= 1'd0;
        transmit_idx_r <= 7'd0;
        tofft_pre_r <= 16'd0;
        tofft_next_r <= 16'd0;
        for (i=0; i<80; i=i+1) begin
            buffer_r[i] <= 16'd0;
        end
    end
    else begin
        state_r <= state_w;
        audio_ready_r <= audio_ready_w;
        counter_r <= counter_w;
        counter_12_r <= counter_12_w;
        counter_64_r <= counter_64_w;
        counter_32_r <= counter_32_w;
        transmitting_r <= transmitting_w;
        transmit_idx_r <= transmit_idx_w;
        tofft_pre_r <= tofft_pre_w;
        tofft_next_r <= tofft_next_w;
        for (i=0; i<80; i=i+1) begin
            buffer_r[i] <= buffer_w[i];
        end
    end
end

endmodule


