module cpu_addr_decoder (
    input  logic [15:0] addr,

    // output logic [15:0] prg_addr,
    output logic [10:0] wram_addr,
    output logic [2:0] ppu_opcode,
    output logic [4:0] apu_opcode,

    // output logic prg_target,
    output logic wram_target,
    output logic ppu_target,
    output logic apu_target,
    output logic oamdma_target,
    output logic pad1_target,
    output logic pad2_target
);

    // assign prg_addr = addr;
    assign wram_addr = addr[10:0];
    assign ppu_opcode = addr[2:0];
    assign apu_opcode = addr[4:0];

    assign wram_target = (addr[15:13] == 3'b000);           // 0000-1FFF
    assign ppu_target = (addr[15:13] == 3'b001);            // 2000-3FFF
    assign apu_target = (addr[15:5] == 11'b0100_0000_000);  // 4000-401F
    assign oamdma_target = (addr == 16'h4014);
    assign pad1_target = (addr == 16'h4016);
    assign pad2_target = (addr == 16'h4017);

endmodule
