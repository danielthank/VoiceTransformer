module i2s_write(
    clk_n,
    rst,
    daclrc,
    dacdat,
    data,
    data_en
);

input clk_n;
input rst;
input daclrc;
input [15:0] data;
input data_en;

output reg dacdat;

localparam [2:0]
    STATE_IDLE = 3'd0,
    STATE_LEFT = 3'd1,
    STATE_LEFT_WAIT = 3'd2,
    STATE_RIGHT = 3'd3,
    STATE_RIGHT_WAIT = 3'd4;

reg [2:0] state_r, state_w;
reg [3:0] counter_r, counter_w;
reg [15:0] buffer_r, buffer_w;
reg [15:0] next_r, next_w;

always @(*) begin
    state_w = state_r;
    counter_w = counter_r;
    buffer_w = buffer_r;
    if (data_en) begin
        next_w = data;
    end
    else begin
        next_w = next_r;
    end
    dacdat = 1'b0;
    case (state_r)
        STATE_IDLE:
            if (daclrc == 1'b0) begin
                state_w = STATE_LEFT_WAIT;
            end
            else begin
                state_w = STATE_RIGHT_WAIT;
            end
        STATE_LEFT: begin
            if (counter_r == 4'd15) begin
                state_w = STATE_LEFT_WAIT;
            end
            counter_w = counter_r + 1;
            dacdat = buffer_r[15];
            buffer_w = {buffer_r[14:0], 1'b0};
        end
        STATE_LEFT_WAIT: begin
            if (daclrc == 1'b1) begin
                state_w = STATE_RIGHT;
                counter_w = 4'd0;
                buffer_w = next_r;
            end
        end
        STATE_RIGHT: begin
            if (counter_r == 4'd15) begin
                state_w = STATE_RIGHT_WAIT;
            end
            counter_w = counter_r + 1;
            dacdat = buffer_r[15];
            buffer_w = {buffer_r[14:0], 1'b0};
        end
        STATE_RIGHT_WAIT: begin
            if (daclrc == 1'b0) begin
                state_w = STATE_LEFT;
                counter_w = 4'd0;
                buffer_w = next_r;
            end
        end
    endcase
end

always @(negedge clk_n or negedge rst) begin
    if (rst == 1'b0) begin
        state_r <= STATE_IDLE;
        counter_r <= 4'd0;
        buffer_r <= 16'd0;
        next_r <= 16'd0;
    end
    else begin
        state_r <= state_w;
        counter_r <= counter_w;
        buffer_r <= buffer_w;
        next_r <= next_w;
    end
end

endmodule
