module wram (
    input  logic clk,
    input  logic cpu_en,
    input  logic [10:0] addr,
    output logic [7:0] rdata,
    input  logic [7:0] wdata,
    input  logic write
);

    wram_bram wram_bram(            // IP (1-PORT RAM)
        .address(addr),
        .clock(~clk),
        .data(wdata),
        .wren(write),
        .q(rdata)
    );

endmodule
