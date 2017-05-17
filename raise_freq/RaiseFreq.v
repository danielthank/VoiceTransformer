module raiseFreq(clk,clk_cal,rst,fft1_data,fft1_valid,freq1,fft1_fin,
    fft2_data,fft2_valid,freq2,fft2_fin,raise_valid,raise_fin,
    raise_data,freq_out);

parameter width = 32;
parameter width2 = 16;

input clk;
input clk_cal;
input rst;
input fft1_valid,fft1_fin;
input signed [width-1:0] fft1_data;
input [5:0] freq1;
input fft2_valid,fft2_fin;
input signed [width-1:0] fft2_data;
input [5:0] freq2;
output raise_valid, raise_fin;
output [width-1:0] raise_data;
output [5:0] freq_out;

reg signed [width2-1:0] cur_r1_r, cur_r1_w;
reg signed [width2-1:0] cur_i1_r,cur_i1_w;
reg signed [width2-1:0] cur_r2_r,cur_r2_w;
reg signed [width2-1:0] cur_i2_r,cur_i2_w;
reg [5:0] cur_freq1;
reg [5:0] cur_freq2;
reg [1:0] quar1;
reg [1:0] quar2;

reg [2:0] state; 
reg [2:0] n_state;
//reg raise_fin_r, raise_fin_w;

reg fin;
reg valid;
reg [5:0] raised_freq_r,raised_freq_w;

reg [3:0] count_precision_r,count_precision_w;
reg signed [15:0] angle_sum1_r,angle_sum1_w;//phase of polar coor.
reg signed [15:0] angle_sum2_r,angle_sum2_w;//phase of polar coor.
reg signed [15:0] r2_r,r2_w;//radius of polar coor. we don't need radius of r1
reg signed [15:0] angle_diff_r,angle_diff_w;
reg signed [15:0] raised_r_r,raised_r_w;
reg signed [15:0] raised_i_r,raised_i_w;
reg [31:0] raised_output_r,raised_output_w;
reg [1:0] raised_quar;
reg [15:0] phi_r [0:63];
reg [15:0] phi_w [0:63];
reg [15:0] cur_phi_r,cur_phi_w;
//reg [5:0]index_w,index_r;
integer index;

//constant
wire signed [15:0] atan_table [0:7];
assign atan_table[0] = 16'd2880;
assign atan_table[1] = 16'd1700;
assign atan_table[2] = 16'd898;
assign atan_table[3] = 16'd456;
assign atan_table[4] = 16'd229;
assign atan_table[5] = 16'd115;
assign atan_table[6] = 16'd57;
assign atan_table[7] = 16'd29;

reg [8:0] len_scale = 9'd39;

parameter check_quar = 3'd0;
parameter to_polar = 3'd1;
parameter angle_diff  = 3'd2;
parameter add_phi = 3'd3;
parameter check_quar2 = 3'd4;
parameter to_rect  = 3'd5;
parameter output_ready  = 3'd6;
parameter error = 3'd7;

//next-state logic
always @(*)begin
    n_state = error;
    cur_r1_w = cur_r1_r;
    cur_i1_w = cur_i1_r;
    cur_r2_w = cur_r2_r;
    cur_i2_w = cur_i2_r;
    angle_sum1_w = angle_sum1_r;
    angle_sum2_w = angle_sum2_r;
    count_precision_w = count_precision_r;
    r2_w = r2_r;
    angle_diff_w = angle_diff_r;
    raised_r_w = raised_r_r;
    raised_i_w = raised_i_r;
    raised_output_w = raised_output_r;
    raised_freq_w = raised_freq_r;
    for (index = 0; index < 64; index = index + 1)begin
        phi_w[index]  = phi_r[index] ;
    end
    //raise_fin_w = fin;
    if (fft1_valid == 1)begin
        case (state)
            check_quar:
            begin
                if (cur_r1_r<0)begin
                    if (cur_i1_r>=0)quar1 <= 2;else quar1 <= 3;
                    cur_r1_w = -cur_r1_r;
                end
                else begin
                    quar1 <= 1; //don't care 1 or 4 because same in calculation
                    cur_r1_w = cur_r1_r;
                end
                if (cur_r2_r<0)begin
                    if (cur_i2_r>=0)quar2 <= 2;else quar2 <= 3;
                    cur_r2_w = -cur_r2_r;
                end
                else begin
                    quar2 <= 1; //don't care 1 and 2 because same in calculation
                    cur_r2_w = cur_r2_r;
                end
                angle_sum1_w = 0;
                angle_sum2_w = 0;
                count_precision_w = 0;
                n_state = to_polar;
            end
            to_polar:
            begin
                case(count_precision_r)
                    4'd9:
                    begin
                        n_state = angle_diff;
                    end
                    4'd8:
                    begin
                        case(quar1)
                            2'd1: angle_sum1_w = angle_sum1_r>>>6;
                            2'd2: angle_sum1_w = ((16'sd11520) - angle_sum1_r)>>>6;
                            2'd3: angle_sum1_w = (-(angle_sum1_r+(16'sd11520)))>>>6;
                        endcase
                        case(quar2)
                            2'd1: angle_sum2_w = angle_sum2_r>>>6;
                            2'd2: angle_sum2_w = ((16'sd11520) - angle_sum2_r)>>>6;
                            2'd3: angle_sum2_w = (-(16'sd180<<<6) - angle_sum2_r)>>>6;
                        endcase
                        if (cur_r2_r>16'd512)r2_w = (cur_r2_r>>>6)*len_scale;
                        else r2_w = (cur_r2_r*len_scale)>>>6;
                        n_state = state;
                    end
                    default:
                    begin
                        if (cur_i1_r>=0)begin
                            cur_r1_w = cur_r1_r + (cur_i1_r >>> count_precision_r);
                            cur_i1_w = cur_i1_r - (cur_r1_r >>> count_precision_r);
                            angle_sum1_w = angle_sum1_r + atan_table[count_precision_r];
                        end
                        else begin
                            cur_r1_w = cur_r1_r - (cur_i1_r >>> count_precision_r);
                            cur_i1_w = cur_i1_r + (cur_r1_r >>> count_precision_r);
                            angle_sum1_w = angle_sum1_r - atan_table[count_precision_r];
                        end
                        if (cur_i2_r>=0)begin
                            cur_r2_w = cur_r2_r + (cur_i2_r >>> count_precision_r);
                            cur_i2_w = cur_i2_r - (cur_r2_r >>> count_precision_r);
                            angle_sum2_w = angle_sum2_r + atan_table[count_precision_r];
                        end
                        else begin
                            cur_r2_w = cur_r2_r - (cur_i2_r >>> count_precision_r);
                            cur_i2_w = cur_i2_r + (cur_r2_r >>> count_precision_r);
                            angle_sum2_w = angle_sum2_r - atan_table[count_precision_r];
                        end
                        r2_w = r2_r;
                        n_state = to_polar;
                    end
                endcase
                count_precision_w = count_precision_r + 1;
            end
            angle_diff:
            begin
                n_state = add_phi;
                count_precision_w = 0;
                cur_phi_w = phi_r [cur_freq1]; //for debug usage
                if ((angle_sum2_r - angle_sum1_r)>16'sd180) begin//>pi
                    angle_diff_w = (angle_sum2_r - angle_sum1_r) - 16'sd360;
                end
                else if (((angle_sum2_r - angle_sum1_r)+16'sd180)<0) begin//<pi 
                    angle_diff_w = (angle_sum2_r - angle_sum1_r) + 16'sd360;
                end
                else begin 
                    angle_diff_w = (angle_sum2_r - angle_sum1_r); 
                end
            end
            add_phi:
            begin
                case(count_precision_r)
                    4'd0:
                    begin
                        angle_diff_w = angle_diff_r+phi_r[cur_freq1];
                        count_precision_w = count_precision_r + 1;
                        n_state = state;
                    end
                    4'd1:
                    begin
                        if (angle_diff_r>16'sd180) begin//>pi
                            angle_diff_w = angle_diff_r - 16'sd360;
                        end
                        else if ((angle_diff_r+16'sd180)<0) begin//<pi 
                            angle_diff_w = angle_diff_r + 16'sd360;
                        end
                        else begin 
                            angle_diff_w = angle_diff_r; 
                        end
                        count_precision_w = count_precision_r + 1;
                        n_state = state;
                    end
                    4'd2:
                    begin
                        angle_diff_w = angle_diff_r;
                        phi_w[cur_freq1] = angle_diff_r;
                        count_precision_w = 0;
                        n_state = check_quar2;
                    end
                    default:
                    begin
                        angle_diff_w = angle_diff_r;
                        count_precision_w = 0;
                        n_state = state;
                    end
                endcase
            end
            check_quar2:
            begin
                if (angle_diff_r<=16'sd180 && angle_diff_r>16'sd90)begin
                    raised_quar <= 2;
                    angle_diff_w = (16'sd180-angle_diff_r)<<<6;
                end
                else if ((angle_diff_r+16'sd90)<16'sd0 && (angle_diff_r+16'sd180)>16'sd0)begin
                    raised_quar <= 3;
                    angle_diff_w = (-(16'sd180+angle_diff_r))<<<6;
                end
                else begin
                    raised_quar <= 1; //don't care 1 or 4 because same in calculation
                    angle_diff_w = angle_diff_r<<<6;
                end
                if (r2_r>16'd512)raised_r_w = (r2_r>>>6)*len_scale;
                else raised_r_w = (r2_r*len_scale)>>>6;
                count_precision_w = 0;
                n_state = to_rect;
                raised_i_w = 0;
            end
            to_rect:
            begin
                case(count_precision_r)
                    4'd9:
                    begin
                        raised_output_w = {raised_r_r,raised_i_r};
                        raised_freq_w = cur_freq1;
                        n_state = output_ready;
                    end
                    4'd8:
                    begin
                        case(raised_quar)
                            2'd1: raised_r_w = raised_r_r;
                            2'd2: raised_r_w = -raised_r_r;
                            2'd3: raised_r_w = -raised_r_r;
                        endcase
                        raised_i_w = raised_i_r;
                        n_state = state;
                    end
                    default:
                    begin
                        if (angle_diff_r>=0)begin
                            raised_r_w = raised_r_r - (raised_i_r >>> count_precision_r);
                            raised_i_w = raised_i_r + (raised_r_r >>> count_precision_r);
                            angle_diff_w = angle_diff_r - atan_table[count_precision_r];
                        end
                        else begin
                            raised_r_w = raised_r_r + (raised_i_r >>> count_precision_r);
                            raised_i_w = raised_i_r - (raised_r_r >>> count_precision_r);
                            angle_diff_w = angle_diff_r + atan_table[count_precision_r];
                        end
                        n_state = state;
                    end
                endcase
                count_precision_w = count_precision_r + 1;
            end
            output_ready:
            begin
                if (valid == 0)valid = 1;
                n_state = error;
            end
        endcase
    end
end

assign raise_valid = valid;
assign raise_data = raised_output_r;
assign freq_out = raised_freq_r;
assign raise_fin = (raised_freq_r == 6'd63) ? 1 : 0;

//use cur_freq1 to reset state
always @(cur_freq1)begin
    if (fft1_valid)n_state = check_quar;
end

//seq part of calculation
always @(posedge clk_cal)begin
    if (rst)begin
        state <= 0;
        cur_r1_r <= 0;
        cur_i1_r <= 0;
        cur_r2_r <= 0;
        cur_i2_r <= 0;
        angle_sum1_r <= 0;
        angle_sum2_r <= 0;
        count_precision_r <= 0;
        r2_r <= 0;
        angle_diff_r <= 0;
        raised_r_r <= 0;
        raised_i_r <= 0;
        valid <= 0;
        raised_output_r <= 0;
        raised_freq_r <= 0;
        for (index=0; index<64; index=index+1) begin
            phi_r[index] <= 0;
        end
        cur_phi_r <= 0;
    end
    else begin
        state <= n_state;
        cur_r1_r <= cur_r1_w;
        cur_i1_r <= cur_i1_w;
        cur_r2_r <= cur_r2_w;
        cur_i2_r <= cur_i2_w;
        angle_sum1_r = angle_sum1_w;
        angle_sum2_r = angle_sum2_w;
        count_precision_r = count_precision_w;
        r2_r <= r2_w;
        angle_diff_r <= angle_diff_w;
        raised_r_r <= raised_r_w;
        raised_i_r <= raised_i_w;
        raised_output_r <= raised_output_w;
        raised_freq_r <= raised_freq_w;
        for (index=0; index<64; index=index+1) begin
            phi_r[index] <= phi_w[index];
        end
        cur_phi_r <= cur_phi_w;
    end
end

//seq part of getting data from fft
always @(posedge clk)begin
    if (rst)begin
        cur_r1_r <= 0;
        cur_i1_r <= 0;
        cur_r2_r <= 0;
        cur_i2_r <= 0;
        cur_freq1 <= 63;
        cur_freq2 <= 63;
    end
    else begin 
        if ((fft1_valid == 1'b1) && (fft2_valid == 1'b1))begin
            cur_r1_r <= fft1_data[(width-1):(width2)];
            cur_i1_r <= fft1_data[(width2-1):0];
            cur_r2_r <= fft2_data[(width-1):(width2)];
            cur_i2_r <= fft2_data[(width2-1):0];
            
            cur_freq1 <= freq1;
            cur_freq2 <= freq2;
        end
    end
end

endmodule

