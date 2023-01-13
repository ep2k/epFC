module clock_generator (
    input  logic clk_50mhz,
    
    output logic clk,       // 21.47MHz/4 (for ppu)
    output logic phi2,      // 21.47MHz/12 + delay (for cartridge)
    output logic vga_clk,   // 25.175MHz (640x480 @60Hz)
    output logic pad_clk,   // 500kHz (for pad driver)

    output logic cpu_en     // 3clkに一度イネーブル (for cpu)
);

    logic pllout_0, pllout_1, pll_locked;
    logic base_clk; // 21.47MHz
    logic phi2_raw;
    logic [3:0] counter = 4'b0010;
    logic [5:0] pad_counter = 6'h0;

    pll pll(                    // IP (PLL)
        .refclk(clk_50mhz),
        .rst(1'b0),
        .outclk_0(pllout_0),
        .outclk_1(pllout_1),
        .locked(pll_locked)
    );

    assign base_clk = pll_locked & pllout_0;
    assign vga_clk = pll_locked & pllout_1;


    always_ff @(posedge clk_50mhz) begin
        pad_counter <= (pad_counter == 6'd49) ? 6'd0 : (pad_counter + 6'd1);
        if (pad_counter == 6'd49) begin
            pad_clk <= ~pad_clk;
        end
    end

    always_ff @(posedge base_clk) begin
        counter <= (counter == 4'hd) ? 4'h2 : (counter + 4'h1);
        case (counter)
            4'h5: cpu_en <= 1'b1;
            4'h9: cpu_en <= 1'b0;
            default: ;
        endcase
    end

    // base_clk:    010101010101010101010101010101010101010101010101010
    // clk:         100001111000011110000111100001111000011110000111100
    // phi2:        100000000000011111111111100000000000011111111111100
    // cpu_en:      000000000111111110000000000000000111111110000000000
    // counter:     D2233445566778899AABBCCDD2233445566778899AABBCCDD22
    assign clk = ~counter[1];
    assign phi2_raw = counter[3]; // cpu_enでのclkと同タイミングで立ち上がり
    // assign cpu_en = (counter >= 4'h6) & (counter < 4'hA);

    delay delay(
        .original(phi2_raw),
        .delayed(phi2)
    );

endmodule
