
`timescale 1ns/1ps

module combine_filters_tb;

reg clk;
reg rst;
reg [15:0] data_in;
reg [15:0] cut_off;
reg [15:0] cut_off1;
reg [1:0] filter_en;

wire [15:0] data_out;

combine_filters dut (
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .cut_off(cut_off),
    .cut_off1(cut_off1),
    .filter_en(filter_en),
    .data_out(data_out)
);

// 10 ns clock period
initial clk = 0;
always #5 clk = ~clk;

task test_sample;
    input [1:0] mode;
    input [15:0] sample;
    begin
        @(negedge clk);
        filter_en = mode;
        data_in = sample;

        @(posedge clk);
        #1;

        $display(
            "Mode=%b Input=%0d Output=%0d",
            filter_en, data_in, data_out
        );
    end
endtask

initial begin
    rst       = 1;
    data_in   = 0;
    cut_off   = 100;
    cut_off1  = 200;
    filter_en = 0;

    // Reset
    repeat (2) @(negedge clk);
    rst = 0;

    $display("\n--- LOW-PASS ---");
    test_sample(2'b00, 50);   // Pass
    test_sample(2'b00, 150);  // Block

    $display("\n--- HIGH-PASS ---");
    test_sample(2'b01, 50);   // Block
    test_sample(2'b01, 150);  // Pass

    $display("\n--- BAND-PASS ---");
    test_sample(2'b10, 50);   // Block
    test_sample(2'b10, 150);  // Pass
    test_sample(2'b10, 250);  // Block

    $display("\n--- BAND-STOP ---");
    test_sample(2'b11, 50);   // Pass
    test_sample(2'b11, 150);  // Block
    test_sample(2'b11, 250);  // Pass

    $display("\nSimulation completed.");
    $finish;
end

initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(0, combine_filters_tb);

end
endmodule
