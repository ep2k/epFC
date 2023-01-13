module pulse #(parameter CH2) (
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

    // {duty, halt, constant flag, constant volume}
    logic [7:0] control = 8'h00;

    logic [3:0] volume_raw;
    logic next_step;
    logic mute;
    logic pulse_raw;
    logic length_counter_out;

    assign length_status = length_counter_out;

    always_ff @(posedge clk) begin
        if (cpu_en & op[0]) begin
            control <= wdata;
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

    timer_pulse #(.CH2(CH2)) timer_pulse(
        .clk,
        .cpu_en,

        .apu_clk,
        .half_frame,

        .reset(timer_reset),
        .set_timer_low(op[2]),
        .set_timer_high(op[3]),
        .new_timer_data(wdata),
        .sweep_reload(op[1]),

        .next_step,
        .mute
    );

    pulse_generator pulse_generator(
        .clk,
        .cpu_en,

        .reset(reset | op[3]),
        .duty(control[7:6]),
        .next_step,

        .pulse_raw
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

    assign volume = (length_counter_out & (~mute)) ? volume_raw : 4'h0;
    assign wave = pulse_raw ? volume : 4'h0;
    
endmodule
