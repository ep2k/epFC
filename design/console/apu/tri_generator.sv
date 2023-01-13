module tri_generator (
    input logic clk,
    input logic cpu_en,

    input logic next_step,
    
    output logic [3:0] tri_wave
);

    logic [4:0] step = 5'd0;

    always_ff @(posedge clk) begin
        if (cpu_en & next_step) begin
            step <= step + 5'd1;
        end
    end

    // F,E,D,...,2,1,0,0,1,2,...,E,F
    assign tri_wave = step[4] ? step[3:0] : ~step[3:0];
    
endmodule
