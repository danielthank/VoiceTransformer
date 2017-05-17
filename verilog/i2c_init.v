module i2c_init (
    clk_n,
    rst,
    sclk,
    sdat,
    finish
);

input clk_n;
input rst;
output sclk;
output sdat;
output finish;


localparam DATA_LEN = 22;
reg [8:0] init_data [DATA_LEN-1:0];

localparam [3:0]
    STATE_IDLE=4'd0,
    STATE_START=4'd1,
    STATE_RUN_1=4'd2,
    STATE_RUN_2=4'd3,
    STATE_RUN_3=4'd4,
    STATE_ACK_1=4'd5,
    STATE_ACK_2=4'd6,
    STATE_ACK_3=4'd7,
    STATE_STOP=4'd8,
    STATE_FINISH=4'd9;

reg [4:0] data_idx_r, data_idx_w;
reg [2:0] bit_idx_r, bit_idx_w;
reg [3:0] state_r, state_w;
reg [7:0] buffer_r, buffer_w;
reg sdat_r, sdat_w;

assign sdat = sdat_w;
assign sclk = (state_r == STATE_RUN_1 || state_r == STATE_RUN_2 || state_r == STATE_ACK_1 || state_r == STATE_ACK_2) ? 1'b0 : 1'b1;
assign finish = state_r == STATE_FINISH;

always @(*) begin
    data_idx_w = data_idx_r;
    bit_idx_w = bit_idx_r;
    state_w = state_r;
    sdat_w = sdat_r;
    buffer_w = buffer_r;
    case (state_r)
        STATE_IDLE: begin
            if (bit_idx_r == 3'd1) begin
                state_w = STATE_START;
            end
            bit_idx_w = bit_idx_r + 1;
        end
        STATE_START: begin
            state_w = STATE_RUN_1;
            data_idx_w = 5'd0;
            bit_idx_w = 3'd0;
            buffer_w = init_data[0];
            sdat_w = 1'b0;
        end
        STATE_RUN_1: begin
            state_w = STATE_RUN_2;
        end
        STATE_RUN_2: begin
            state_w = STATE_RUN_3;
            sdat_w = buffer_r[7];
        end
        STATE_RUN_3: begin
            if (bit_idx_r == 3'd7) begin
                state_w = STATE_ACK_1;
            end
            else begin
                bit_idx_w = bit_idx_r+1;
                state_w = STATE_RUN_1;
            end
            buffer_w = buffer_r << 1;
        end
        STATE_ACK_1: begin
            state_w = STATE_ACK_2;
        end
        STATE_ACK_2: begin
            state_w = STATE_ACK_3;
            sdat_w = 1'bz;
        end
        STATE_ACK_3: begin
            if (data_idx_r == DATA_LEN-1) begin
                state_w = STATE_STOP;
            end
            else begin
                state_w = STATE_RUN_1;
                data_idx_w = data_idx_r + 1;
                bit_idx_w = 0;
                buffer_w = init_data[data_idx_w];
            end
            sdat_w = 1'bz;
        end
        STATE_STOP: begin
            state_w = STATE_FINISH;
            sdat_w = 1'b0;
        end
        STATE_FINISH: begin
            sdat_w = 1'b1;
        end
    endcase
end
/*
* 00110100 address
* 0000000 010010111 mute left line in
* 0000001 010010111 mute right line in
* 0000010 001111001 left headphone out
* 0000011 001111001 right headphone out
* 0000100 000010101 analog audio path
* 0000101 000000000 disable soft mute
* 0000110 000000000 disable all power down
* 0000111 000000010 slave i2s 16bit
* 0001000 000001100 adc 8k dac 8k mclk 12.288k 256fs
* 0001001 000000001 activate interface
* 0001111 000000000 reset
*/
always @(negedge clk_n or negedge rst) begin
    if (rst == 1'b0) begin
        data_idx_r <= 5'd0;
        bit_idx_r <= 3'd0;
        state_r <= STATE_IDLE;
        buffer_r <= 8'd0;
        sdat_r <= 1'b1;
    end
    else begin
        init_data[0]   <= {8'b00000000};
        init_data[1]   <= {8'b10010111};
        init_data[2]   <= {8'b00000010};
        init_data[3]   <= {8'b10010111};
        init_data[4]   <= {8'b00000100};
        init_data[5]   <= {8'b01111001};
        init_data[6]   <= {8'b00000110};
        init_data[7]   <= {8'b01111001};
        init_data[8]   <= {8'b00001000};
        init_data[9]   <= {8'b00010101};
        init_data[10]  <= {8'b00001010};
        init_data[11]  <= {8'b00000000};
        init_data[12]  <= {8'b00001100};
        init_data[13]  <= {8'b00000000};
        init_data[14]  <= {8'b00001110};
        init_data[15]  <= {8'b00000010};
        init_data[16]  <= {8'b00010000};
        init_data[17]  <= {8'b00001100};
        init_data[18]  <= {8'b00010010};
        init_data[19]  <= {8'b00000001};
        init_data[20]  <= {8'b00011110};
        init_data[21]  <= {8'b00000000};
        data_idx_r <= data_idx_w;
        bit_idx_r <= bit_idx_w;
        state_r <= state_w;
        buffer_r <= buffer_w;
        sdat_r <= sdat_w;
    end
end

endmodule
