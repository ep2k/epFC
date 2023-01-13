module noise (
    input  logic clk,
    input  logic cpu_en,
    input  logic reset,

    input  logic apu_clk,
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

    logic [5:0] control;
    logic mode;
    logic next_step;
    logic noise_raw;
    logic length_counter_out;
    logic [3:0] volume_raw;

    assign length_status = length_counter_out;

    always_ff @(posedge clk) begin
        if (cpu_en & op[0]) begin
            control <= wdata[5:0];
        end
    end

    always_ff @(posedge clk) begin
        if (cpu_en & op[2]) begin
            mode <= wdata[7];
        end
    end

    envelope envelope(
        .clk,
        .cpu_en,

        .quarter_frame,

        .loop(control[5]),
        .constant_volume(control[4]),
        .start(op[3]),
        .param(control[3:0]),

        .volume(volume_raw)
    );

    timer_noise timer_noise(
        .clk,
        .cpu_en,

        .apu_clk,

        .reset(timer_reset),
        .set_timer(op[2]),
        .new_timer_index(wdata[3:0]),

        .next_step
    );

    lfsr lfsr(
        .clk,
        .cpu_en,

        .next_step,
        .mode,

        .noise_raw
    );

    length_counter length_counter(
        .clk,
        .cpu_en,
        .reset,

        .half_frame,

        .set_length(op[3]),
        .new_length(wdata[7:3]),
        .halt(control[5]),
        .enable,
        
        .out(length_counter_out)
    );

    assign volume = length_counter_out ? volume_raw : 4'h0;
    assign wave = noise_raw ? volume : 4'h0;
    
endmodule
