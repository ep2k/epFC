module pulse_generator (
    input  logic clk,
    input  logic cpu_en,

    input  logic reset,
    input  logic [1:0] duty,
    input  logic next_step,

    output logic pulse_raw
);

    logic [2:0] step = 3'd0;

    always_ff @(posedge clk) begin
        if (cpu_en) begin
            if (reset) begin
                step <= 3'd0;
            end else if (next_step) begin
                step <= step + 3'd1;
            end
        end
    end

    always_comb begin
        unique case (duty)
            2'b00: pulse_raw = (step == 3'd1);                      // 01000000
            2'b01: pulse_raw = ((step == 3'd1) | (step == 3'd2));   // 01100000
            2'b10: pulse_raw = ((step >= 3'd1) & (step <= 3'd4));   // 01111000
            2'b11: pulse_raw = ~((step == 3'd1) | (step == 3'd2));  // 10011111
        endcase
    end
    
endmodule
