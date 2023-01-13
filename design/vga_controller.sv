module vga_controller (
    input  logic vga_clk,               // 25MHz
    output logic [15:0] read_pixel_num, // 0 ~ 61439
    input  logic [5:0] read_pixel_color,
    output logic [3:0] vga_r,
    output logic [3:0] vga_g,
    output logic [3:0] vga_b,
    output logic vga_hs,
    output logic vga_vs
);

    localparam H_SYNC = 10'd96;
    localparam H_BACK = 10'd48;
    localparam H_ACTIVE = 10'd640;
    localparam H_FRONT = 10'd16;
    localparam H_MAX = H_SYNC + H_BACK + H_ACTIVE + H_FRONT - 10'd1;

    localparam V_SYNC = 10'd2;
    // localparam V_BACK = 10'd32;
    localparam V_BACK = 10'd2; // for my display
    localparam V_ACTIVE = 10'd480;
    // localparam V_FRONT = 10'd11;
    localparam V_FRONT = 10'd41; // for my display
    localparam V_MAX = V_SYNC + V_BACK + V_ACTIVE + V_FRONT - 10'd1;

    localparam SIDE_BAR = 10'd64;


    logic [9:0] h_count = 10'd0; // 0 ~ 799
    logic [9:0] v_count = 10'd0; // 0 ~ 524

    logic visible;

    logic [8:0] x; // 0 ~ 511 (LSB無視で0 ~ 255)
    logic [8:0] y; // 0 ~ 479 (LSB無視で0 ~ 239)

    logic [11:0] vga_rgb_next;
    logic [11:0] vga_rgb = 12'h0;


    assign x = h_count - (H_SYNC + H_BACK + SIDE_BAR) + 2; // frame_bufferからの読み出しに1クロック + vga_rgbへの格納に1クロック
    assign y = v_count - (V_SYNC + V_BACK);
    assign read_pixel_num = {y[8:1], x[8:1]};

    color_to_rgb color_to_rgb(
        .pixel_color(read_pixel_color),
        .rgb(vga_rgb_next)
    );

    always_ff @(posedge vga_clk) begin
        vga_rgb <= vga_rgb_next;
    end

    assign visible =
            (h_count >= H_SYNC + H_BACK + SIDE_BAR)
            & (h_count < H_SYNC + H_BACK + H_ACTIVE - SIDE_BAR)
            & (v_count >= V_SYNC + V_BACK)
            & (v_count < V_SYNC + V_BACK + V_ACTIVE);

    assign {vga_r, vga_g, vga_b} = visible ? vga_rgb : 12'h0;

    // --- Horizontal ---------

    always_ff @(posedge vga_clk) begin
        h_count <= (h_count == H_MAX) ? 10'd0 : (h_count + 10'd1);
    end

    assign vga_hs = (h_count >= H_SYNC);

    // --- Vertical ---------
    
    always_ff @(posedge vga_clk) begin
        if (h_count == H_MAX) begin
            v_count <= (v_count == V_MAX) ? 10'd0 : (v_count + 10'd1);
        end
    end

    assign vga_vs = (v_count >= V_SYNC);
    
endmodule
