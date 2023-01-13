// インデックス値でnew_timer_maxを選択

module timer_noise (
    input  logic clk,
    input  logic cpu_en,

    input  logic apu_clk,

    input  logic reset,
    input  logic set_timer,
    input  logic [3:0] new_timer_index,

    output logic next_step
);

    logic [11:0] timer, timer_max;
    logic [11:0] new_timer_max;

    assign next_step = (apu_clk & (timer == 12'd0));

    always_ff @(posedge clk) begin
        if (cpu_en & set_timer) begin
            timer_max <= new_timer_max;
        end
    end

    always_ff @(posedge clk) begin
        if (cpu_en) begin
            if (reset) begin
                timer <= timer_max;
            end else if (apu_clk) begin
                timer <= (timer == 12'd0) ? timer_max : (timer - 12'd1);
            end
        end
    end

    always_comb begin
        unique case (new_timer_index)
            4'h0: new_timer_max = 12'h4;
            4'h1: new_timer_max = 12'h8;
            4'h2: new_timer_max = 12'h10;
            4'h3: new_timer_max = 12'h20;
            4'h4: new_timer_max = 12'h40;
            4'h5: new_timer_max = 12'h60;
            4'h6: new_timer_max = 12'h80;
            4'h7: new_timer_max = 12'ha0;
            4'h8: new_timer_max = 12'hca;
            4'h9: new_timer_max = 12'hfe;
            4'ha: new_timer_max = 12'h17c;
            4'hb: new_timer_max = 12'h1fc;
            4'hc: new_timer_max = 12'h2fa;
            4'hd: new_timer_max = 12'h3f8;
            4'he: new_timer_max = 12'h7f2;
            4'hf: new_timer_max = 12'hfe4;
        endcase
    end
    
endmodule
