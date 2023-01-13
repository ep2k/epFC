module frame_counter (
    input  logic clk,
    input  logic cpu_en,
    input  logic reset,

    input  logic set_control,
    input  logic [1:0] new_control,
    output logic quarter_frame,
    output logic half_frame,

    input  logic clear_irq,
    output logic irq
);

    logic [1:0] control;
    logic [15:0] frame_counter = 16'd0;
    logic irq_flg;

    logic frame_counter_max;
    logic set_irq;

    assign irq = irq_flg;

    assign quarter_frame =
                (frame_counter == 16'd7457)
                    | (frame_counter == 16'd22371)
                    | half_frame;
    
    assign half_frame =
        (frame_counter == 16'd14913) | frame_counter_max;

    assign set_irq = (~control[1]) & (
                        (frame_counter == 16'd29828)
                        | (frame_counter == 16'd29829)
                        | (frame_counter == 16'd0)
                    );

    assign frame_counter_max = control[1]
                ? (frame_counter == 16'd37281)
                : (frame_counter == 16'd29829);

    always_ff @(posedge clk) begin
        if (cpu_en & set_control) begin
            control <= new_control;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            frame_counter <= 16'd0;
        end else if (cpu_en) begin
            frame_counter <=
                frame_counter_max ? 16'd0 : (frame_counter + 16'd1);
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            irq_flg <= 1'b0;
        end else if (cpu_en) begin
            if (clear_irq | control[0]) begin
                irq_flg <= 1'b0;
            end else if (set_irq) begin
                irq_flg <= 1'b1;
            end
        end
    end
    
endmodule
