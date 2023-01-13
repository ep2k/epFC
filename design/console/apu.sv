module apu (
    input  logic clk,
    input  logic cpu_en,
    input  logic reset,

    input  logic [4:0] opcode,
    input  logic [7:0] wdata,
    input  logic write,
    input  logic read,
    output logic [7:0] rdata,
    output logic irq,

    output logic dma_read,
    output logic [15:0] dma_addr,
    input  logic [7:0] dma_rdata,

    output logic [8:0] wave_out = 9'h0,
    output logic [19:0] volumes = 20'h0,

    input  logic [4:0] mute
);

    logic [3:0] pulse1_wave, pulse2_wave, tri_wave, noise_wave;
    logic [6:0] dmc_wave;
    logic [8:0] wave_out_next;
    logic [19:0] volumes_next;

    logic pulse1_status, pulse2_status, tri_status, noise_status;

    logic dmc_irq, dmc_active;
    logic frame_irq;

    logic [3:0] opcode_bits;
    logic [3:0] op_pulse1, op_pulse2, op_tri, op_noise, op_dmc;
    logic op_status, op_control, op_frame_counter;

    logic apu_clk = 1'b0;
    logic quarter_frame, half_frame;
    logic [1:0] timer_reset_counter; // 1のときにtimerをリセット
    logic timer_reset;

    logic [4:0] enables = 5'h00;

    assign rdata = {
        dmc_irq, frame_irq, 1'b0, dmc_active,
        noise_status, tri_status, pulse2_status, pulse1_status
    };

    assign irq = dmc_irq | frame_irq;

    assign opcode_bits = {
        (opcode[1:0] == 2'b11),
        (opcode[1:0] == 2'b10),
        (opcode[1:0] == 2'b01),
        (opcode[1:0] == 2'b00)
    };

    assign op_pulse1 = (write & (opcode[4:2] == 3'b000)) ? opcode_bits : 4'b0000;
    assign op_pulse2 = (write & (opcode[4:2] == 3'b001)) ? opcode_bits : 4'b0000;
    assign op_tri = (write & (opcode[4:2] == 3'b010)) ? opcode_bits : 4'b0000;
    assign op_noise = (write & (opcode[4:2] == 3'b011)) ? opcode_bits : 4'b0000;
    assign op_dmc = (write & (opcode[4:2] == 3'b100)) ? opcode_bits : 4'b0000;
    assign op_status = read & (opcode == 5'h15);
    assign op_control = write & (opcode == 5'h15);
    assign op_frame_counter = write & (opcode == 5'h17);

    assign timer_reset = (timer_reset_counter == 2'b01);

    always_ff @(posedge clk) begin
        if (cpu_en) begin
            apu_clk <= ~apu_clk;
        end
    end

    always_ff @(posedge clk) begin
        if (cpu_en) begin
            if (op_frame_counter) begin
                timer_reset_counter <= 2'b11;
            end else if (timer_reset_counter != 2'b00) begin
                timer_reset_counter <= timer_reset_counter - 2'b01;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            enables <= 5'h00;
        end else if (cpu_en & op_control) begin
            enables <= wdata[4:0];
        end
    end

    always_ff @(posedge clk) begin
        wave_out <= wave_out_next;
        volumes <= volumes_next;
    end
    
    frame_counter frame_counter(
        .clk,
        .cpu_en,
        .reset,

        .set_control(op_frame_counter),
        .new_control(wdata[7:6]),
        .quarter_frame,
        .half_frame,

        .clear_irq(op_status),
        .irq(frame_irq)
    );

    pulse #(.CH2(0)) pulse1(
        .clk,
        .cpu_en,
        .reset,

        .apu_clk,
        .half_frame,
        .quarter_frame,

        .op(op_pulse1),
        .wdata,
        .enable(enables[0]),

        .timer_reset,
        
        .length_status(pulse1_status),
        .wave(pulse1_wave),
        .volume(volumes_next[3:0])
    );

    pulse #(.CH2(1)) pulse2(
        .clk,
        .cpu_en,
        .reset,

        .apu_clk,
        .half_frame,
        .quarter_frame,

        .op(op_pulse2),
        .wdata,
        .enable(enables[1]),

        .timer_reset,
        
        .length_status(pulse2_status),
        .wave(pulse2_wave),
        .volume(volumes_next[7:4])
    );

    triangle triangle(
        .clk,
        .cpu_en,
        .reset,

        .half_frame,
        .quarter_frame,

        .op(op_tri),
        .wdata,
        .enable(enables[2]),

        .timer_reset,

        .length_status(tri_status),
        .wave(tri_wave),
        .volume(volumes_next[11:8])
    );

    noise noise(
        .clk,
        .cpu_en,
        .reset,

        .apu_clk,
        .half_frame,
        .quarter_frame,

        .op(op_noise),
        .wdata,
        .enable(enables[3]),

        .timer_reset,

        .length_status(noise_status),
        .wave(noise_wave),
        .volume(volumes_next[15:12])
    );

    dmc dmc(
        .clk,
        .cpu_en,
        .reset,

        .op(op_dmc),
        .wdata,
        .enable(enables[4]),

        .timer_reset,

        .dma_read,
        .dma_addr,
        .dma_rdata,

        .active(dmc_active),
        .irq(dmc_irq),
        .wave(dmc_wave),
        .volume(volumes_next[19:16])
    );

    mix mix(
        .pulse1_wave,
        .pulse2_wave,
        .tri_wave,
        .noise_wave,
        .dmc_wave,
        .mute,
        
        .sum_wave(wave_out_next)
    );
    
endmodule
