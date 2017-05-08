module i2s_read(
    clk_p,
    rst,
    adclrc,
    adcdat,
    data,
    data_en
);

input clk_p;
input rst;
input adclrc;
input adcdat;

output [15:0] data;
output data_en;

localparam [2:0]
    STATE_IDLE = 3'd0,
    STATE_LEFT = 3'd1,
    STATE_LEFT_WAIT = 3'd2,
    STATE_RIGHT_WAIT = 3'd3;

reg [2:0] state_r, state_w;
reg [3:0] counter_r, counter_w;
reg [15:0] buffer_r, buffer_w;
reg data_en_r, data_en_w;

assign data = buffer_r;
assign data_en = data_en_r;

always @(*) begin
    state_w = state_r;
    counter_w = counter_r;
    buffer_w = buffer_r;
    data_en_w = data_en_r;
    case (state_r)
        STATE_IDLE:
            if (adclrc == 1'b0) begin
                state_w = STATE_LEFT_WAIT;
            end
        STATE_LEFT: begin
            if (counter_r == 4'd15) begin
                data_en_w = 1'b1;
                state_w = STATE_LEFT_WAIT;
            end
            counter_w = counter_r + 1;
            buffer_w = {buffer_r[14:0], adcdat};
        end
        STATE_LEFT_WAIT: begin
            data_en_w = 1'b0;
            if (adclrc == 1'b1) begin
                state_w = STATE_RIGHT_WAIT;
                counter_w = 4'd0;
                buffer_w = 16'd0;
            end
        end
        STATE_RIGHT_WAIT: begin
            if (adclrc == 1'b0) begin
                state_w = STATE_LEFT;
                counter_w = 4'd0;
                buffer_w = 16'd0;
            end
        end
    endcase
end

always @(posedge clk_p or negedge rst) begin
    if (rst == 1'b0) begin
        state_r <= STATE_IDLE;
        counter_r <= 4'd0;
        buffer_r <= 16'd0;
        data_en_r <= 1'b0;
    end
    else begin
        state_r <= state_w;
        counter_r <= counter_w;
        buffer_r <= buffer_w;
        data_en_r <= data_en_w;
    end
end

endmodule
