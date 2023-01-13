module pad (
    input  logic clk,
    input  logic cpu_en,
    input  logic reset,

    input  logic [7:0] buttons,
    
    input  logic write,
    input  logic read,
    output logic [7:0] pad_data
);

    logic [2:0] now_button = 3'h0;
    
    always_ff @(posedge clk) begin
        if (reset) begin
            now_button <= 3'h0;
        end else if (cpu_en) begin
            if (write) begin
                now_button <= 3'h0;
            end else if (read) begin
                now_button <= now_button + 3'h1;
            end
        end
    end

    assign pad_data = {7'h0, buttons[now_button]};
    
endmodule
