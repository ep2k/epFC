module palette (
    input  logic clk,
    input  logic reset,
    
    input  logic [4:0] addr,
    output logic [7:0] rdata,
    input  logic [7:0] wdata,
    input  logic write,

    input  logic [4:0] pixel_info, // {sprite, palette_num(2), color(2)}
    output logic [5:0] pixel_color
);

    logic [5:0] palette[31:0];

    assign rdata = {2'b00, palette[addr]};

    always_ff @(posedge clk) begin
        if (reset) begin
            for (int i = 0; i < 32; i++) begin
                palette[i] <= 6'b0;
            end
        end else if (write) begin
            if (addr[1:0] == 2'b00) begin
                palette[{1'b0, addr[3:0]}] <= wdata[5:0];
            end else begin
                palette[addr] <= wdata[5:0];
            end
        end
    end

    // pixel_info -> pixel_color
    always_comb begin
        if (pixel_info[1:0] == 2'b00) begin
            pixel_color = palette[5'd0]; // [TODO]PPUADDRが3F00~3FFFのとき，背景色3F00の代わりに指している色を使う?
        end else begin
            pixel_color = palette[pixel_info];
        end
    end

endmodule
