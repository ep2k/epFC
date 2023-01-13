module timer_pulse #(parameter CH2) (
    input  logic clk,
    input  logic cpu_en,

    input  logic apu_clk,
    input  logic half_frame,

    input  logic reset,
    input  logic set_timer_low,
    input  logic set_timer_high,
    input  logic [7:0] new_timer_data,
    input  logic sweep_reload,

    output logic next_step,
    output logic mute
);

    logic [10:0] timer, timer_max;

    logic [2:0] sweep_counter = 3'b000;
    logic sweep_reload_flg = 1'b0;

    logic [7:0] sweep_control;
    logic [10:0] shift_timer_max, delta_timer_max, timer_max_sweeped;
    logic sweep_carry;


    assign next_step = (apu_clk & (timer == 11'd0));
    assign mute = (sweep_carry & (~sweep_control[3])) | (timer_max < 11'h8);

    always_comb begin
        unique case (sweep_control[2:0])
            3'b000: shift_timer_max = timer_max;
            3'b001: shift_timer_max = {1'b0, timer_max[10:1]};
            3'b010: shift_timer_max = {2'b0, timer_max[10:2]};
            3'b011: shift_timer_max = {3'b0, timer_max[10:3]};
            3'b100: shift_timer_max = {4'b0, timer_max[10:4]};
            3'b101: shift_timer_max = {5'b0, timer_max[10:5]};
            3'b110: shift_timer_max = {6'b0, timer_max[10:6]};
            3'b111: shift_timer_max = {7'b0, timer_max[10:7]};
        endcase
    end

    assign {sweep_carry, timer_max_sweeped}
        = timer_max
            + (sweep_control[3] ? ((~shift_timer_max) + CH2) : shift_timer_max);

    // timer
    always_ff @(posedge clk) begin
        if (cpu_en) begin
            if (reset) begin
                timer <= timer_max;
            end else if (apu_clk) begin
                timer <= (timer == 11'd0) ? timer_max : (timer - 11'd1);
            end
        end
    end

    // timer_max
    always_ff @(posedge clk) begin
        if (cpu_en) begin
            if (set_timer_low) begin
                timer_max[7:0] <= new_timer_data;
            end else if (set_timer_high) begin
                timer_max[10:8] <= new_timer_data[2:0];
            end else if (half_frame & (sweep_counter == 3'b000) & sweep_control[7] & (~mute) & (sweep_control[2:0] != 3'b000)) begin
                timer_max <= timer_max_sweeped;
            end
        end
    end

    // sweep_counter
    always_ff @(posedge clk) begin
        if (cpu_en & half_frame) begin
            sweep_counter <= ((sweep_counter == 3'b000) | sweep_reload_flg)
                                ? sweep_control[6:4]
                                : (sweep_counter - 3'b001);
        end
    end

    // sweep_control
    always_ff @(posedge clk) begin
        if (cpu_en) begin
            if (sweep_reload) begin
                sweep_control <= new_timer_data;
                sweep_reload_flg <= 1'b1;
            end else if (half_frame) begin
                sweep_reload_flg <= 1'b0;
            end
        end
    end

endmodule
