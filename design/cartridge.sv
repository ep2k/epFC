// Support for NROM only

module cartridge (
    input  logic clk,
    input  logic cpu_en,
    
    input  logic [15:0] prg_addr,
    output logic [7:0] prg_rdata,
    input  logic [7:0] prg_wdata,
    input  logic prg_write,

    input  logic [13:0] chr_addr,
    output logic [7:0] chr_rdata,
    input  logic [7:0] chr_wdata,
    input  logic chr_write,

    input  logic hori_mirroring,

    output logic irq,
    output logic vram_cs,
    output logic vram_a10
);

    assign irq = 1'b0;
    assign vram_cs = chr_addr[13];
    assign vram_a10 = hori_mirroring ? chr_addr[11] : chr_addr[10];

    prg_rom prg_rom(            // IP (1-PORT ROM)
        .clock(~clk),
        .address(prg_addr[14:0]),
        .q(prg_rdata)
    );

    chr_rom chr_rom(            // IP (1-PORT ROM)
        .clock(~clk),
        .address(chr_addr[12:0]),
        .q(chr_rdata)
    );
    
endmodule
