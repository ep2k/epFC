module epFC (
    input  logic pin_clk,               // 50MHz
    input  logic pin_n_reset,

    output logic [3:0] vga_r,
    output logic [3:0] vga_g,
    output logic [3:0] vga_b,
    output logic vga_hs,
    output logic vga_vs,

    output logic sound_left,            // Pulse-density modulation
    output logic sound_right,


    // ---- Cartridge ----

    // 3.3V <-> 5V
    inout  logic [7:0] prg_data,
    inout  logic [7:0] chr_data,

    // 3.3V -> 5V, 74HCT04(inverter)を挟むため予め反転
    output logic [14:0] n_prg_addr,
    output logic [13:0] n_chr_addr,
    output logic chr_addr_13,

    output logic chr_write,
    output logic chr_read,
    output logic rom_sel,
    output logic prg_write,
    output logic n_phi2,

    output logic prg_dir,
    output logic chr_dir,

    // 3.3V <- 5V
    input  logic n_irq,
    input  logic n_vram_cs,
    input  logic vram_a10,


    // ---- DUALSHOCK ----

    input  logic p1_dat,
    output logic p1_cmd,
    output logic p1_sel,
    output logic p1_sclk,
    input  logic p1_ack,

    input  logic p2_dat,
    output logic p2_cmd,
    output logic p2_sel,
    output logic p2_sclk,
    input  logic p2_ack,


    // ---- Additional Functions ----

    input  logic [4:0] sound_mute,      // pin_switch[4:0]
    input  logic [1:0] graphic_off,     // pin_switch[6:5]
    input  logic pad_exchange,          // pin_switch[7]
    input  logic int_hori_mirroring,    // pin_switch[8]
    input  logic use_int_rom,           // pin_switch[9]


    // ---- LEDs ----

    output logic [9:0] led,
    output logic [6:0] hex_5,
    output logic [6:0] hex_4,
    output logic [6:0] hex_3,
    output logic [6:0] hex_2,
    output logic [6:0] hex_1,
    output logic [6:0] hex_0

);

    logic clk;      // 10.74MHz (for ppu)
    logic cpu_en;   // 3clkに1度イネーブル (for cpu)
    logic vga_clk;  // 25.175MHz (VGA 640x480 @60Hz)
    logic pad_clk;  // 500kHz (for pad driver)
    logic phi2;     // cpu_clkから数十ns遅延 (for cartridge)

    logic [15:0] prg_addr;
    logic [7:0] prg_rdata, int_prg_rdata, prg_wdata;

    logic [13:0] chr_addr;
    logic [7:0] chr_rdata, int_chr_rdata, chr_wdata;

    logic [15:0] write_pixel_num;
    logic [5:0] write_pixel_color;
    logic pixel_write;
    
    logic [15:0] read_pixel_num;
    logic [5:0] read_pixel_color;

    logic [8:0] sound_wave;
    logic [19:0] sound_volumes;
    logic sound_pdm;
    logic [4:0] sound_volumes_pwm;

    // □/×/○|△|R1|L1|R2|L2/←/↓/→/↑/ST/SW→/SW←/SEL (dualshock)
    logic [15:0] pad_p1, pad_p2, pad_p1_reg, pad_p2_reg;
    logic p1_connect, p2_connect, p1_connect_reg, p2_connect_reg;

    // →/←/↓/↑/ST/SEL/B/A (nes)
    logic [7:0] buttons_p1, buttons_p2;

    logic button_reset;
    logic no_push_pwm;



    assign sound_left = sound_pdm;
    assign sound_right = sound_pdm;


    assign prg_data = prg_write ? prg_wdata : 'z;
    assign chr_data = chr_write ? chr_wdata : 'z;

    assign prg_rdata = use_int_rom ? int_prg_rdata : prg_data;
    assign chr_rdata = use_int_rom ? int_chr_rdata : chr_data;

    assign n_prg_addr = ~prg_addr[14:0];
    assign n_chr_addr = ~chr_addr;
    assign chr_addr_13 = chr_addr[13];

    assign rom_sel = prg_addr[15] & phi2;
    assign n_phi2 = ~phi2;
    
    assign prg_dir = prg_write;
    assign chr_dir = chr_write;


    assign buttons_p1 = ~{
        pad_p1_reg[5],  // →
        pad_p1_reg[7],  // ←
        pad_p1_reg[6],  // ↓
        pad_p1_reg[4],  // ↑
        pad_p1_reg[3],  // Start
        pad_p1_reg[0],  // Select
        pad_p1_reg[14], // B
        pad_p1_reg[13]  // A
    };

    assign buttons_p2 = ~{
        pad_p2_reg[5],  // →
        pad_p2_reg[7],  // ←
        pad_p2_reg[6],  // ↓
        pad_p2_reg[4],  // ↑
        pad_p2_reg[3],  // Start
        pad_p2_reg[0],  // Select
        pad_p2_reg[14], // B
        pad_p2_reg[13]  // A
    };

    // 1P R1,L1,R2,L2同時押しでリセット
    assign button_reset = (pad_p1_reg[11:8] == 4'h0);

    always_ff @(posedge clk) begin
        pad_p1_reg <= pad_exchange ? pad_p2 : pad_p1;
        pad_p2_reg <= pad_exchange ? pad_p1 : pad_p2;
        p1_connect_reg <= pad_exchange ? p2_connect : p1_connect;
        p2_connect_reg <= pad_exchange ? p1_connect : p2_connect;
    end


    // ----  Internal ROM  --------------------------

    logic int_irq;
    logic int_vram_cs;
    logic int_vram_a10;

    cartridge cartridge(
        .clk,
        .cpu_en,

        .prg_addr,
        .prg_rdata(int_prg_rdata),
        .prg_wdata,
        .prg_write,

        .chr_addr,
        .chr_rdata(int_chr_rdata),
        .chr_wdata,
        .chr_write,

        .hori_mirroring(int_hori_mirroring),

        .irq(int_irq),
        .vram_cs(int_vram_cs),
        .vram_a10(int_vram_a10)
    );

    // ----------------------------------------


    clock_generator clock_generator(
        .clk_50mhz(pin_clk),

        .clk,
        .phi2,
        .vga_clk,
        .pad_clk,

        .cpu_en
    );

    console console(
        .clk,
        .cpu_en,
        .reset((~pin_n_reset) | button_reset),
        .cart_irq(use_int_rom ? int_irq : (~n_irq)),

        .prg_addr,
        .prg_rdata,
        .prg_wdata,
        .prg_write,

        .chr_addr,
        .chr_rdata,
        .chr_wdata,
        .chr_read,
        .chr_write,

        .vram_cs(use_int_rom ? int_vram_cs : (~n_vram_cs)),
        .vram_a10(use_int_rom ? int_vram_a10 : vram_a10),

        .write_pixel_num,
        .write_pixel_color,
        .pixel_write,
        .graphic_off,

        .sound_wave,
        .sound_volumes,
        .sound_mute,

        .buttons_p1,
        .buttons_p2
    );

    frame_buffer frame_buffer(          // IP (2-PORT RAM)
        .data(write_pixel_color),
        .rdaddress(read_pixel_num),
        .rdclock(vga_clk),
        .wraddress(write_pixel_num),
        .wrclock(clk),
        .wren(pixel_write),
        .q(read_pixel_color)
    );

    vga_controller vga_controller(
        .vga_clk,
        .read_pixel_num,
        .read_pixel_color,
        .vga_r,
        .vga_g,
        .vga_b,
        .vga_hs,
        .vga_vs
    );

    delta_sigma #(.WIDTH(9)) delta_sigma(
        .clk(pin_clk),
        .data_in(sound_wave),
        .pulse_out(sound_pdm)
    );

    pad_driver pad_driver_p1(
        .clk(pad_clk),
        .reset(~pin_n_reset),

        .analog_mode(1'b0),
        .vibrate_sub(1'b0),
        .vibrate(8'h0),

        .dat(p1_dat),
        .cmd(p1_cmd),
        .n_sel(p1_sel),
        .sclk(p1_sclk),
        .n_ack(p1_ack),

        .pad_connect(p1_connect),

        .pad_buttons(pad_p1)
    );

    pad_driver pad_driver_p2(
        .clk(pad_clk),
        .reset(~pin_n_reset),

        .analog_mode(1'b0),
        .vibrate_sub(1'b0),
        .vibrate(8'h0),

        .dat(p2_dat),
        .cmd(p2_cmd),
        .n_sel(p2_sel),
        .sclk(p2_sclk),
        .n_ack(p2_ack),

        .pad_connect(p2_connect),

        .pad_buttons(pad_p2)
    );


    genvar gi;

    generate
        for (gi = 0; gi < 5; gi++) begin : PWMs

            logic [3:0] sound_volume;
            logic [7:0] sound_volume_square;

            assign sound_volume = sound_volumes[gi * 4 + 3 : gi * 4];
            always_comb begin
                unique case (sound_volume)
                    4'h0: sound_volume_square = 8'd0;
                    4'h1: sound_volume_square = 8'd1;
                    4'h2: sound_volume_square = 8'd4;
                    4'h3: sound_volume_square = 8'd9;
                    4'h4: sound_volume_square = 8'd16;
                    4'h5: sound_volume_square = 8'd25;
                    4'h6: sound_volume_square = 8'd36;
                    4'h7: sound_volume_square = 8'd49;
                    4'h8: sound_volume_square = 8'd64;
                    4'h9: sound_volume_square = 8'd81;
                    4'ha: sound_volume_square = 8'd100;
                    4'hb: sound_volume_square = 8'd121;
                    4'hc: sound_volume_square = 8'd144;
                    4'hd: sound_volume_square = 8'd169;
                    4'he: sound_volume_square = 8'd196;
                    4'hf: sound_volume_square = 8'd225;
                endcase
            end

            pwm #(.WIDTH(8)) pwm(
                .clk,
                .din(sound_volume_square),
                .dout(sound_volumes_pwm[gi])
            );
        end
    endgenerate

    assign led = {5'h0, sound_volumes_pwm};

    pwm #(.WIDTH(8)) pwm_no_push(
        .clk,
        .din(8'h1),
        .dout(no_push_pwm)
    );

    seg7_buttons seg7_p1(
        .buttons(buttons_p1),
        .no_push_pwm(p1_connect_reg & no_push_pwm),
        .odat_l(hex_3),
        .odat_r(hex_2)
    );

    seg7_buttons seg7_p2(
        .buttons(buttons_p2),
        .no_push_pwm(p2_connect_reg & no_push_pwm),
        .odat_l(hex_1),
        .odat_r(hex_0)
    );

    assign hex_5 = 7'h7f;
    assign hex_4 = 7'h7f;
    
endmodule
