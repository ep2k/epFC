module console (
    input  logic clk,           // 10.74MHz (clk for ppu)
    input  logic cpu_en,        // 3clkに1度イネーブル (clk for cpu)
    input  logic reset,
    input  logic cart_irq,

    output logic [15:0] prg_addr,
    input  logic [7:0] prg_rdata,
    output logic [7:0] prg_wdata,
    output logic prg_write,

    output logic [13:0] chr_addr,
    input  logic [7:0] chr_rdata,
    output logic [7:0] chr_wdata,
    output logic chr_read,
    output logic chr_write,

    input  logic vram_cs,
    input  logic vram_a10,

    output logic [15:0] write_pixel_num,
    output logic [5:0] write_pixel_color,
    output logic pixel_write,
    input  logic [1:0] graphic_off,

    output logic [8:0] sound_wave,
    output logic [19:0] sound_volumes,
    input  logic [4:0] sound_mute,

    input  logic [7:0] buttons_p1,
    input  logic [7:0] buttons_p2
);

    logic [15:0] cpu_addr, cpu_addr_eff, cpu_addr_eff_reg;
    logic [7:0] cpu_rdata, cpu_rdata_reg, cpu_wdata, cpu_wdata_reg;
    logic cpu_write_raw, cpu_write, cpu_write_reg;
    logic cpu_read_raw, cpu_read, cpu_read_reg;

    logic nmi, apu_irq;

    logic prg_target, wram_target, ppu_target, apu_target, oamdma_target;
    logic pad1_target, pad2_target;

    logic [10:0] wram_addr;
    logic [2:0] ppu_opcode;
    logic [4:0] apu_opcode;

    logic [7:0] wram_rdata, ppu_rdata, apu_rdata, pad1_rdata, pad2_rdata;

    logic [13:0] ppumap_addr;
    logic [7:0] ppumap_rdata, ppumap_wdata;
    logic ppumap_read, ppumap_write;

    logic palette_target;
    logic [7:0] vram_rdata, palette_rdata;

    logic oamdma, oamdma_write;
    logic [15:0] oamdma_addr;

    logic [4:0] write_pixel_info;

    logic apudma;
    logic [15:0] apudma_addr;


    // ------ Cartridge --------------

    // cartへの出力信号はレジスタを介さない
    assign prg_addr = cpu_addr_eff;
    assign prg_wdata = cpu_wdata;
    assign prg_target = (cpu_addr_eff >= 16'h4020);
    assign prg_write = prg_target & cpu_write;

    assign chr_addr = ppumap_addr;
    assign chr_wdata = ppumap_wdata;
    assign chr_read = (~vram_cs) & (~palette_target) & ppumap_read;
    assign chr_write = (~vram_cs) & (~palette_target) & ppumap_write;


    // ------ CPU --------------

    assign cpu_read = cpu_read_raw & (~(oamdma | apudma));
    assign cpu_write = cpu_write_raw & (~(oamdma | apudma));

    always_comb begin
        if (pad1_target) begin
            cpu_rdata = pad1_rdata;
        end else if (pad2_target) begin
            cpu_rdata = pad2_rdata;
        end else if (wram_target) begin
            cpu_rdata = wram_rdata;
        end else if (ppu_target) begin
            cpu_rdata = ppu_rdata;
        end else if (apu_target) begin
            cpu_rdata = apu_rdata;
        end else begin
            cpu_rdata = prg_rdata;
        end
    end

    // cpu_addr_eff (dmaを考慮したcpu_addr)
    always_comb begin
        if (apudma) begin
            cpu_addr_eff = apudma_addr;
        end else if (oamdma) begin
            cpu_addr_eff = oamdma_addr;
        end else begin
            cpu_addr_eff = cpu_addr;
        end
    end

    // タイミングエラー軽減のためのレジスタ
    always_ff @(posedge clk) begin
        cpu_addr_eff_reg <= cpu_addr_eff;
        cpu_read_reg <= cpu_read;
        cpu_write_reg <= cpu_write;
        cpu_wdata_reg <= cpu_wdata;
        cpu_rdata_reg <= cpu_rdata;
    end


    cpu cpu(
        .clk,
        .cpu_en(cpu_en & (~(oamdma | apudma))),
        .reset,

        .mem_addr(cpu_addr),
        .mem_rdata(prg_target ? prg_rdata : cpu_rdata_reg),
        .mem_wdata(cpu_wdata),
        .mem_read(cpu_read_raw),
        .mem_write(cpu_write_raw),

        .nmi,
        .irq(cart_irq | apu_irq)
    );

    cpu_addr_decoder cpu_addr_decoder(
        .addr(cpu_addr_eff_reg),

        .wram_addr,
        .ppu_opcode,
        .apu_opcode,
        
        .wram_target,
        .ppu_target,
        .apu_target,
        .oamdma_target,
        .pad1_target,
        .pad2_target
    );

    wram wram(
        .clk,
        .cpu_en,
        .addr(wram_addr),
        .rdata(wram_rdata),
        .wdata(cpu_wdata_reg),
        .write(wram_target & cpu_write_reg)
    );


    // ------ PPU --------------

    assign palette_target = (ppumap_addr[13:8] == 6'b11_1111);

    always_comb begin
        if (palette_target) begin
            ppumap_rdata = palette_rdata;
        end else if (vram_cs) begin
            ppumap_rdata = vram_rdata;
        end else begin
            ppumap_rdata = chr_rdata;
        end
    end


    ppu ppu(
        .clk,
        .cpu_en,
        .reset,

        .opcode(oamdma ? 3'h4 : ppu_opcode),
        .wdata(oamdma ? cpu_rdata_reg : cpu_wdata_reg),
        .read((~oamdma) & ppu_target & cpu_read_reg),
        .write(oamdma ? oamdma_write : (ppu_target & cpu_write_reg)),
        .rdata(ppu_rdata),
        .nmi,

        .ppumap_addr,
        .ppumap_rdata,
        .ppumap_wdata,
        .ppumap_read,
        .ppumap_write,

        .pixel_num(write_pixel_num),
        .pixel_info(write_pixel_info),
        .pixel_write,

        .graphic_off
    );

    vram vram(
        .clk,
        .addr({vram_a10, ppumap_addr[9:0]}),
        .rdata(vram_rdata),
        .wdata(ppumap_wdata),
        .write(ppumap_write & vram_cs & (~palette_target))
    );

    palette palette(
        .clk,
        .reset,

        .addr(ppumap_addr[4:0]),
        .rdata(palette_rdata),
        .wdata(ppumap_wdata),
        .write(ppumap_write & palette_target),

        .pixel_info(write_pixel_info),
        .pixel_color(write_pixel_color)
    );

    oamdma_controller oamdma_controller(
        .clk,
        .cpu_en,
        .reset,
        .stop(apudma),

        .start(oamdma_target & cpu_write_reg),
        .start_addr(cpu_wdata_reg),
        .dma(oamdma),
        .addr(oamdma_addr),
        .write(oamdma_write)
    );


    // ------ APU --------------

    apu apu(
        .clk,
        .cpu_en,
        .reset,

        .opcode(apu_opcode),
        .wdata(cpu_wdata_reg),
        .write(apu_target & cpu_write_reg),
        .read(apu_target & cpu_read_reg),
        .rdata(apu_rdata),
        .irq(apu_irq),

        .dma_read(apudma),
        .dma_addr(apudma_addr),
        .dma_rdata(cpu_rdata_reg),

        .wave_out(sound_wave),
        .volumes(sound_volumes),

        .mute(sound_mute)
    );


    // ------ PAD --------------

    pad pad1(
        .clk,
        .cpu_en,
        .reset,

        .buttons(buttons_p1),

        .write(pad1_target & cpu_write_reg),
        .read(pad1_target & cpu_read_reg),
        .pad_data(pad1_rdata)
    );

    pad pad2(
        .clk,
        .cpu_en,
        .reset,

        .buttons(buttons_p2),

        .write(pad1_target & cpu_write_reg),
        .read(pad2_target & cpu_read_reg),
        .pad_data(pad2_rdata)
    );

endmodule
