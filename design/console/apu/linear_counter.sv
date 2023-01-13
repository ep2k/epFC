module linear_counter (
    input  logic clk,
    input  logic cpu_en,

    input  logic quarter_frame,

    input  logic reload,
    input  logic [7:0] control,
    
    output logic out
);
    
    logic [6:0] counter = 7'd0;
    logic reload_flg;
    
    assign out = (counter != 7'd0);

    always_ff @(posedge clk) begin
        if (cpu_en) begin
            if (reload) begin
                reload_flg <= 1'b1;
            end else if (quarter_frame & (~control[7])) begin
                reload_flg <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (cpu_en & quarter_frame) begin
            if (reload_flg) begin
                counter <= control[6:0];
            end else if (out) begin
                counter <= counter - 7'd1;
            end
        end
    end

endmodule
