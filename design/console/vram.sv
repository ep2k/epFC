module vram (
    input  logic clk, // ppu_clk
    input  logic [10:0] addr,
    output logic [7:0] rdata,
    input  logic [7:0] wdata,
    input  logic write
);

    // logic [7:0] vram[2047:0]; // 2kB

    // assign rdata = vram[addr];

    // always_ff @(posedge clk) begin
    //     if (write) begin
    //         vram[addr] <= wdata;
    //     end
    // end

    vram_bram vram_bram(            // IP (1-PORT RAM)
        .address(addr),
        .clock(~clk),
        .data(wdata),
        .wren(write),
        .q(rdata)
    );
    
endmodule
