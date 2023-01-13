module oamdma_controller (
    input  logic clk, // ppu_clk
    input  logic cpu_en,
    input  logic reset,
    input  logic stop,
    
    input  logic start,
    input  logic [7:0] start_addr,
    output logic dma = 1'b0,
    output logic [15:0] addr,
    output logic write
);

    logic [7:0] start_addr_reg;
    logic [8:0] counter = 9'h0; // counter[0]=1 でwrite
    logic start_prev = 1'b0;

    always_ff @(posedge clk) begin
        if ((~stop) & cpu_en) begin
            start_prev <= start;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            counter <= 9'h0;
        end else if ((~stop) & cpu_en) begin
            counter <= dma ? (counter + 9'h1) : 9'h0;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            dma <= 1'b0;
        end else if ((~stop) & cpu_en) begin
            if ((~dma) & start & (~start_prev)) begin
                dma <= 1'b1;
            end else if (counter == 9'b1111_1111_1) begin
                dma <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk) begin
        if ((~stop) & cpu_en & (~dma) & start & (~start_prev)) begin
            start_addr_reg <= start_addr;
        end
    end

    assign addr = {start_addr_reg, counter[8:1]};
    assign write = (~stop) & dma & counter[0];
    
endmodule
