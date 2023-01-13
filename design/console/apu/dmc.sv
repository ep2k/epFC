module dmc (
    input  logic clk,
    input  logic cpu_en,
    input  logic reset,
    
    input  logic [3:0] op,
    input  logic [7:0] wdata,
    input  logic enable,

    input  logic timer_reset,

    output logic dma_read,
    output logic [15:0] dma_addr,
    input  logic [7:0] dma_rdata,

    output logic active,
    output logic irq,
    output logic [6:0] wave,
    output logic [3:0] volume
);
    
    logic irq_enable, loop;
    logic [7:0] first_sample_length;

    logic [6:0] delta_counter = 7'd0;
    logic [14:0] address;
    logic [11:0] sample_length = 12'd0;
    logic [7:0] buffer;
    logic buffer_empty = 1'b1;
    logic [7:0] shifter;
    logic [3:0] remaining_bits = 4'h0;
    logic silence;
    logic irq_flg;

    logic next_step;
    logic shifter_empty;


    assign active = (sample_length != 12'h0);
    assign irq = irq_flg;
    assign wave = delta_counter;
    assign volume = silence ? 4'h0 : 4'h8;

    assign dma_read = (sample_length != 12'h0) & buffer_empty;
    assign dma_addr = {1'b1, address};

    assign shifter_empty = (remaining_bits == 4'h0);

    always_ff @(posedge clk) begin
        if (reset) begin
            {irq_enable, loop} <= 2'b00;
        end else if (cpu_en & op[0]) begin
            {irq_enable, loop} <= wdata[7:6];
        end
    end

    always_ff @(posedge clk) begin
        if (cpu_en & op[3]) begin
            first_sample_length <= wdata;
        end
    end

    // address
    always_ff @(posedge clk) begin
        if (cpu_en) begin
            if (op[2]) begin
                address <= {1'b1, wdata, 6'h0};
            end else if ((sample_length != 12'd0) & buffer_empty) begin
                address <= address + 15'h1;
            end
        end
    end

    // sample_length
    always_ff @(posedge clk) begin
        if (reset) begin
            sample_length <= 12'd0;
        end else if (cpu_en) begin
            if (op[3]) begin
                sample_length <= {wdata, 4'b0001};
            end else if (buffer_empty & (sample_length == 12'd1) & loop) begin
                sample_length <= {first_sample_length, 4'b0001};
            end else if (buffer_empty & (sample_length != 12'd0)) begin
                sample_length <= sample_length - 12'd1;
            end
        end
    end

    // buffer, buffer_empty
    always_ff @(posedge clk) begin
        if (reset) begin
            buffer_empty <= 1'b1;
        end else if (cpu_en) begin
            if ((sample_length != 12'd0) & buffer_empty) begin
                buffer <= dma_rdata;
                buffer_empty <= 1'b0;
            end else if (next_step & shifter_empty) begin
                buffer_empty <= 1'b1;
            end
        end
    end

    // irq_flg
    always_ff @(posedge clk) begin
        if (reset) begin
            irq_flg <= 1'b0;
        end else if (cpu_en) begin
            if (~irq_enable) begin
                irq_flg <= 1'b0;
            end else if (buffer_empty & (sample_length == 12'd1) & (~loop)) begin
                irq_flg <= 1'b1;
            end
        end
    end

    // remaining_bits
    always_ff @(posedge clk) begin
        if (reset) begin
            remaining_bits <= 4'h0;
        end else if (cpu_en & next_step) begin
            remaining_bits <= (remaining_bits == 4'h0) ? 4'h8 : (remaining_bits - 4'h1);
        end
    end

    // silence
    always_ff @(posedge clk) begin
        if (cpu_en & next_step & shifter_empty) begin
            silence <= buffer_empty;
        end
    end

    // shifter
    always_ff @(posedge clk) begin
        if (cpu_en & next_step) begin
            shifter <= shifter_empty ? buffer : {1'b0, shifter[7:1]};
        end
    end

    // delta_counter
    always_ff @(posedge clk) begin
        if (reset) begin
            delta_counter <= 7'h0;
        end else if (cpu_en & op[1]) begin
            delta_counter <= wdata[6:0];
        end else if (cpu_en & next_step & (~shifter_empty) & (~silence)) begin
            if ((~shifter[0]) & (delta_counter >= 2)) begin
                delta_counter <= delta_counter - 2;
            end else if (shifter[0] & (delta_counter < 126)) begin
                delta_counter <= delta_counter + 2;
            end
        end
    end

    timer_dmc timer_dmc(
        .clk,
        .cpu_en,

        .reset(timer_reset),
        .set_timer(op[0]),
        .new_timer_index(wdata[3:0]),
        
        .next_step
    );

endmodule
