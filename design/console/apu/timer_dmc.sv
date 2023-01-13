module timer_dmc (
    input  logic clk,
    input  logic cpu_en,

    input  logic reset,
    input  logic set_timer,
    input  logic [3:0] new_timer_index,

    output logic next_step
);

    logic [8:0] timer, timer_max;
    logic [8:0] new_timer_max;

    assign next_step = (timer == 9'h0);

    always_ff @(posedge clk) begin
        if (cpu_en & set_timer) begin
            timer_max <= new_timer_max;
        end
    end

    always_ff @(posedge clk) begin
        if (cpu_en) begin
            if (reset) begin
                timer <= timer_max;
            end else begin
                timer <= (timer == 9'h0) ? timer_max : (timer - 9'h1);
            end
        end
    end

    always_comb begin
        unique case (new_timer_index)
            4'h0: new_timer_max = 9'h1ac;
            4'h1: new_timer_max = 9'h17c;
            4'h2: new_timer_max = 9'h154;
            4'h3: new_timer_max = 9'h140;
            4'h4: new_timer_max = 9'h11e;
            4'h5: new_timer_max = 9'h0fe;
            4'h6: new_timer_max = 9'h0e2;
            4'h7: new_timer_max = 9'h0d6;
            4'h8: new_timer_max = 9'h0be;
            4'h9: new_timer_max = 9'h0a0;
            4'ha: new_timer_max = 9'h08e;
            4'hb: new_timer_max = 9'h080;
            4'hc: new_timer_max = 9'h06a;
            4'hd: new_timer_max = 9'h054;
            4'he: new_timer_max = 9'h048;
            4'hf: new_timer_max = 9'h036;
        endcase
    end
    
endmodule
