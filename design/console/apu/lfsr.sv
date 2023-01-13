module lfsr (
    input  logic clk,
    input  logic cpu_en,

    input  logic next_step,
    input  logic mode,
    
    output logic noise_raw
);

    logic [14:0] shifter = 14'h1;
    logic feed_back;

    assign feed_back = shifter[0] ^ (mode ? shifter[6] : shifter[1]);
    assign noise_raw = ~shifter[0];

    always_ff @(posedge clk) begin
        if (cpu_en & next_step) begin
            shifter <= {feed_back, shifter[14:1]};
        end
    end
    
endmodule
