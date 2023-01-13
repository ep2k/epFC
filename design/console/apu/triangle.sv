module triangle (
    input  logic clk,
    input  logic cpu_en,
    input  logic reset,

    input  logic half_frame,
    input  logic quarter_frame,

    input  logic [3:0] op,
    input  logic [7:0] wdata,
    input  logic enable,

    input  logic timer_reset,
    
    output logic length_status,
    output logic [3:0] wave,
    output logic [3:0] volume
);

    logic [7:0] control = 8'h00;

    logic timer_out;
    logic length_counter_out;
    logic linear_counter_out;

    assign length_status = length_counter_out;

    always_ff @(posedge clk) begin
        if (cpu_en & op[0]) begin
            control <= wdata;
        end
    end

    timer_tri timer_tri(
        .clk,
        .cpu_en,

        .reset(timer_reset),
        .set_timer_low(op[2]),
        .set_timer_high(op[3]),
        .new_timer_data(wdata),

        .next_step(timer_out)
    );

    linear_counter linear_counter(
        .clk,
        .cpu_en,

        .quarter_frame,

        .reload(op[3]),
        .control,

        .out(linear_counter_out)
    );

    length_counter length_counter(
        .clk,
        .cpu_en,
        .reset,

        .half_frame,

        .set_length(op[3]),
        .new_length(wdata[7:3]),
        .halt(control[7]),
        .enable,

        .out(length_counter_out)
    );

    tri_generator tri_generator(
        .clk,
        .cpu_en,

        .next_step(timer_out & linear_counter_out & length_counter_out),
        
        .tri_wave(wave)
    );

    assign volume = (linear_counter_out & length_counter_out) ? 4'h4 : 4'h0;
    
endmodule
