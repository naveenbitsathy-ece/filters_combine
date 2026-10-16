
module combine_filters (
    input             clk,
    input             rst,
    input      [15:0] data_in,
    input      [15:0] cut_off,
    input      [15:0] cut_off1,
    input      [1:0]  filter_en,
    output reg [15:0] data_out
);

always @(posedge clk) begin
    if (rst) begin
        data_out <= 16'd0;
    end
    else begin
        case (filter_en)

            2'b00: begin // Low-pass: below lower cutoff
                if (data_in < cut_off)
                    data_out <= data_in;
                else
                    data_out <= 16'd0;
            end

            2'b01: begin // High-pass: above cutoff
                if (data_in > cut_off)
                    data_out <= data_in;
                else
                    data_out <= 16'd0;
            end

            2'b10: begin // Band-pass: between cutoffs
                if ((data_in > cut_off) &&
                    (data_in < cut_off1))
                    data_out <= data_in;
                else
                    data_out <= 16'd0;
            end

            2'b11: begin // Band-stop: outside cutoffs
                if ((data_in < cut_off) ||
                    (data_in > cut_off1))
                    data_out <= data_in;
                else
                    data_out <= 16'd0;
            end

            default: data_out <= 16'd0;

        endcase
    end
end

endmodule
