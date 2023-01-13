module pixel_generator (
    input  logic [3:0] bg_pixel,
    input  logic [4:0] sprites[7:0],
    input  logic is_sprite0,            // sprites[0]がスプライト0か
    input  logic [1:0] mask,

    input  logic [1:0] graphic_off,     // BG, スプライトの描画のみオフ

    output logic [4:0] pixel_info,
    output logic pixel_sp0_hit
);

    logic [3:0] bg_pixel_eff; // BGマスクを考慮したbg_pixel
    assign bg_pixel_eff = (mask[0] & (~graphic_off[0])) ? bg_pixel : 4'b0000;

    always_comb begin

        // スプライトマスク or 不透明なスプライトが存在しない
        pixel_info = {1'b0, bg_pixel_eff};

        if (mask[1] & (~graphic_off[1])) begin // スプライト非マスク
            for (int i = 0; i < 8; i++) begin
                // スプライトiが不透明
                if (sprites[i][1:0] != 2'b00) begin
                    if (bg_pixel_eff[1:0] != 2'b00) begin // BGが不透明
                        // 優先度チェック
                        pixel_info = sprites[i][4]
                            ? {1'b0, bg_pixel_eff} : {1'b1, sprites[i][3:0]};
                    end else begin // BGが透明
                        pixel_info = {1'b1, sprites[i][3:0]};
                    end
                    break;
                end
            end
        end

    end

    assign pixel_sp0_hit = is_sprite0 & (mask == 2'b11)
                    & (sprites[0][1:0] != 2'b00) & (bg_pixel[1:0] != 2'b00);
    
endmodule
