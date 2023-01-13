module envelope (
    input  logic clk,
    input  logic cpu_en,

    input  logic quarter_frame,

    input  logic loop,
    input  logic constant_volume,
    input  logic start,
    input  logic [3:0] param,

    output logic [3:0] volume
);

    logic [3:0] divider;
    logic [3:0] decay_counter;
    logic start_flg;

    always_ff @(posedge clk) begin
        if (cpu_en) begin
            if (start) begin
                start_flg <= 1'b1;
            end else if (quarter_frame) begin
                start_flg <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (cpu_en & quarter_frame) begin
            divider <= ((divider == 4'h0) | start_flg)
                                ? param : (divider - 4'h1);
        end
    end

    always_ff @(posedge clk) begin
        if (cpu_en & quarter_frame) begin
            if (start_flg) begin
                decay_counter <= 4'hf;
            end else if ((divider == 4'h0) & ((decay_counter != 4'h0) | loop)) begin
                decay_counter <= decay_counter - 4'h1;
            end
        end
    end

    assign volume = constant_volume ? param : decay_counter;
    
endmodule
