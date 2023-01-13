module timer_tri (
    input  logic clk,
    input  logic cpu_en,

    input  logic reset,
    input  logic set_timer_low,
    input  logic set_timer_high,
    input  logic [7:0] new_timer_data,

    output logic next_step
);

    logic [10:0] timer, timer_max;

    assign next_step = (timer == 11'd0);

    always_ff @(posedge clk) begin
        if (cpu_en) begin
            if (set_timer_low) begin
                timer_max[7:0] <= new_timer_data;
            end else if (set_timer_high) begin
                timer_max[10:8] <= new_timer_data[2:0];
            end
        end
    end

    always_ff @(posedge clk) begin
        if (cpu_en) begin
            if (reset) begin
                timer <= timer_max;
            end else begin
                timer <= (timer == 11'd0) ? timer_max : (timer - 11'd1);
            end
        end
    end
    
endmodule
