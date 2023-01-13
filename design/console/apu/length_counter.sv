module length_counter (
    input  logic clk,
    input  logic cpu_en,
    input  logic reset,

    input  logic half_frame,

    input  logic set_length,
    input  logic [4:0] new_length,
    input  logic halt,
    input  logic enable,

    output logic out
);
    
    logic [7:0] length_counter;
    logic [7:0] new_length_counter;

    assign out = (length_counter != 8'h00);

    // length_counter
    always_ff @(posedge clk) begin
        if (reset) begin
            length_counter <= 8'd0;
        end else if (cpu_en) begin
            if (~enable) begin
                length_counter <= 8'd0;
            end else if (set_length) begin
                length_counter <= new_length_counter;
            end else if (half_frame & (~halt) & out) begin
                length_counter <= length_counter - 8'd1;
            end
        end
    end

    always_comb begin
        unique case (new_length)
            5'h1f: new_length_counter = 8'd30;
            5'h1d: new_length_counter = 8'd28;
            5'h1b: new_length_counter = 8'd26;
            5'h19: new_length_counter = 8'd24;
            5'h17: new_length_counter = 8'd22;
            5'h15: new_length_counter = 8'd20;
            5'h13: new_length_counter = 8'd18;
            5'h11: new_length_counter = 8'd16;
            5'h0f: new_length_counter = 8'd14;
            5'h0d: new_length_counter = 8'd12;
            5'h0b: new_length_counter = 8'd10;
            5'h09: new_length_counter = 8'd8;
            5'h07: new_length_counter = 8'd6;
            5'h05: new_length_counter = 8'd4;
            5'h03: new_length_counter = 8'd2;
            5'h01: new_length_counter = 8'd254;

            5'h1e: new_length_counter = 8'd32;
            5'h1c: new_length_counter = 8'd16;
            5'h1a: new_length_counter = 8'd72;
            5'h18: new_length_counter = 8'd192;
            5'h16: new_length_counter = 8'd96;
            5'h14: new_length_counter = 8'd48;
            5'h12: new_length_counter = 8'd24;
            5'h10: new_length_counter = 8'd12;

            5'h0e: new_length_counter = 8'd26;
            5'h0c: new_length_counter = 8'd14;
            5'h0a: new_length_counter = 8'd60;
            5'h08: new_length_counter = 8'd160;
            5'h06: new_length_counter = 8'd80;
            5'h04: new_length_counter = 8'd40;
            5'h02: new_length_counter = 8'd20;
            5'h00: new_length_counter = 8'd10;
        endcase
    end

endmodule
