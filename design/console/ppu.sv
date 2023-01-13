module ppu (
    input  logic clk,               // ppu_clk
    input  logic cpu_en,
    input  logic reset,

    input  logic [2:0] opcode,      // cpu_addr[2:0]
    input  logic [7:0] wdata,
    input  logic read,
    input  logic write,
    output logic [7:0] rdata,
    output logic nmi,

    output logic [13:0] ppumap_addr,
    input  logic [7:0] ppumap_rdata,
    output logic [7:0] ppumap_wdata,
    output logic ppumap_read,
    output logic ppumap_write,

    output logic [15:0] pixel_num,
    output logic [4:0] pixel_info,
    output logic pixel_write,

    input  logic [1:0] graphic_off
);

    // ---- Register ------

    logic [14:0] vram_addr, temp_vram_addr;
    logic [2:0] fine_x = 3'b0;
    logic write_toggle = 1'b0;
    logic [7:0] vread_buffer;

    logic vblank = 1'b0;
    logic sp0_hit = 1'b0;
    logic sp_overflow = 1'b0;

    logic [7:2] ppu_ctrl = 6'h0;
    logic [7:0] ppu_mask = 8'h0;
    logic [7:0] oam_addr = 8'h0;

    logic [8:0] pixel_counter = 9'b0; // 0 ~ 340
    logic [8:0] line_counter = 9'd0; // 0 ~ 261

    logic [7:0] name_data;
    logic [7:0] attribute_data;
    logic [7:0] next_pattern_high;
    logic [7:0] next_pattern_low;
    logic [1:0] next_attribute;
    logic [15:0] pattern_shifter_low;
    logic [15:0] pattern_shifter_high;
    logic [7:0] attribute_shifter_low;
    logic [7:0] attribute_shifter_high;

    logic [5:0] sp_num = '0;
    logic [2:0] sp_second_num = '0;
    logic second_oam_full = 1'b0;
    logic sp_eval_finished = 1'b0;
    logic sp_overflow_set = 1'b0;

    // Sprite
    logic [7:0] oam[255:0];
    logic [7:0] second_oam[31:0];
    logic [7:0] sp_exist_next;
    logic [7:0] sp_exist;
    logic [7:0] sp_x[7:0];
    logic [7:0] sp_shifter_low[7:0];
    logic [7:0] sp_shifter_high[7:0];
    logic [1:0] sp_attribute[7:0];
    logic sp_priority[7:0];
    logic is_sprite0, is_sprite0_next;


    // ---- Wire ------

    logic [7:0] ppu_status;
    logic sp_8x16;
    logic not_rendering;
    logic [1:0] pixel_mask;

    logic [13:0] name_addr;
    logic [13:0] attribute_addr;
    logic [13:0] bg_pattern_addr;
    logic [13:0] sp_pattern_addr;
    logic [2:0] sp8_fine_y;
    logic [3:0] sp16_fine_y;
    logic is_sprite_n;

    logic [3:0] bg_pixel;
    logic [4:0] sprites[7:0];
    logic pixel_sp0_hit;

    logic visible_frame;
    logic pre_render_line;
    logic render_line;
    logic first_pixel_of_frame;
    logic left_edge;
    logic last_pixel_of_frame;
    logic sprite_fetch_time;
    logic sprite_evaluation_time;
    logic visible_pixel;
    logic inc_hori_pixel;
    logic inc_vert_pixel;
    logic hori_copy_pixel;
    logic vert_copy_pixel;
    logic set_vblank_pixel;
    logic clear_flgs_pixel;
    logic name_fetch_pixel;
    logic attribute_fetch_pixel;
    logic bg_low_fetch_pixel;
    logic bg_high_fetch_pixel;
    logic next_pattern_load_pixel;
    logic name_addr_pixel;
    logic attribute_addr_pixel;
    logic pattern_addr_pixel;
    logic shift_pixel;

    logic block_left;
    logic block_high;

    logic op_ppuctrl_w;
    logic op_ppumask_w;
    logic op_ppustatus_r;
    logic op_oamaddr_w;
    logic op_oamdata_r;
    logic op_oamdata_w;
    logic op_ppuscroll_w;
    logic op_ppuaddr_w;
    logic op_ppudata_r;
    logic op_ppudata_w;


    // ---- Wire Assignment ------

    // ### Output ####

    always_comb begin
        case (opcode)
            3'h2: rdata = ppu_status;
            3'h4: rdata = oam[oam_addr];
            3'h7: rdata =
                (vram_addr[14:9] == 6'h3f) ? ppumap_rdata : vread_buffer;
            default: rdata = 8'h0;
        endcase
    end

    assign nmi = vblank & ppu_ctrl[7];

    always_comb begin
        if (not_rendering) begin
            ppumap_addr = vram_addr[13:0];
        end else if (name_addr_pixel) begin
            ppumap_addr = name_addr;
        end else if (attribute_addr_pixel) begin
            ppumap_addr = attribute_addr;
        end else if (pattern_addr_pixel) begin
            ppumap_addr = sprite_fetch_time ? sp_pattern_addr : bg_pattern_addr;
        end else begin
            ppumap_addr = vram_addr[13:0];
        end
    end

    assign ppumap_wdata = wdata;
    assign ppumap_read = op_ppudata_r | name_fetch_pixel
                | attribute_fetch_pixel | bg_low_fetch_pixel | bg_high_fetch_pixel;
    assign ppumap_write = op_ppudata_w;
    
    assign pixel_num[15:8] = line_counter[7:0];
    assign pixel_num[7:0] = pixel_counter[8:0] - 9'd1;
    assign pixel_write = visible_pixel;


    // ### Basic Info ####

    assign ppu_status = {vblank, sp0_hit, sp_overflow, 5'b00000};
    assign sp_8x16 = ppu_ctrl[5];
    assign not_rendering = (ppu_mask[4:3] == 2'b00);
    assign pixel_mask = ppu_mask[4:3] & (left_edge ? ppu_mask[2:1] : 2'b11);

    // ### Fetch VRAM Address ####

    assign name_addr = {2'b10, vram_addr[11:0]};
    assign attribute_addr =
            {2'b10, vram_addr[11:10], 4'b1111, vram_addr[9:7], vram_addr[4:2]};
    assign bg_pattern_addr =
            {1'b0, ppu_ctrl[4], name_data, bg_high_fetch_pixel, vram_addr[14:12]};
    assign sp_pattern_addr = sp_8x16
        ? { 1'b0,
            second_oam[{sp_second_num, 2'b01}][0],
            second_oam[{sp_second_num, 2'b01}][7:1],
            sp16_fine_y[3], // 上半身か否か
            bg_high_fetch_pixel,
            sp16_fine_y[2:0]
        }
        : { 1'b0,
            ppu_ctrl[3],
            second_oam[{sp_second_num, 2'b01}],
            bg_high_fetch_pixel,
            sp8_fine_y
        };

    assign sp8_fine_y = second_oam[{sp_second_num, 2'b10}][7]
        ? ~(line_counter - second_oam[{sp_second_num, 2'b00}]) // 反転時はNOT
        : (line_counter - second_oam[{sp_second_num, 2'b00}]);

    assign sp16_fine_y = second_oam[{sp_second_num, 2'b10}][7]
        ? ~(line_counter - second_oam[{sp_second_num, 2'b00}]) // 反転時はNOT
        : (line_counter - second_oam[{sp_second_num, 2'b00}]);

    assign is_sprite_n = sp_8x16
        ? ((line_counter >= oam[{sp_num, 2'b00}])
            & (line_counter <= oam[{sp_num, 2'b00}] + 15)) // 8x16スプライト
        : ((line_counter >= oam[{sp_num, 2'b00}])
            & (line_counter <= oam[{sp_num, 2'b00}] + 7)); // 8x8スプライト

    // ### Pixel Info ####

    assign bg_pixel = {
        attribute_shifter_high[(3'b111 - fine_x)],
        attribute_shifter_low[(3'b111 - fine_x)],
        pattern_shifter_high[(4'hf - {1'b0, fine_x})],
        pattern_shifter_low[(4'hf - {1'b0, fine_x})]
    };

    always_comb begin
        for (int i = 0; i < 8; i++) begin
            sprites[i] = (sp_exist[i] & (sp_x[i] == 8'd0)) ? {
                        sp_priority[i],
                        sp_attribute[i],
                        sp_shifter_high[i][7],
                        sp_shifter_low[i][7]
                    } : 4'h0;
        end
    end

    // ### Timing ####
    
    assign visible_frame = (line_counter < 240);
    assign pre_render_line = (line_counter == 261);
    assign render_line = (visible_frame | pre_render_line);

    assign first_pixel_of_frame = (pixel_counter == 0);
    assign left_edge = (~first_pixel_of_frame) & (pixel_counter < 9);
    assign last_pixel_of_frame = (pixel_counter == 340);

    assign sprite_fetch_time = ((pixel_counter > 256) & (pixel_counter < 321));
    assign sprite_evaluation_time =
                visible_frame & (pixel_counter > 64) & (pixel_counter < 257);

    assign visible_pixel =
                visible_frame & (pixel_counter < 257) & (~first_pixel_of_frame);
    assign inc_hori_pixel = 
            (~first_pixel_of_frame) & (pixel_counter[2:0] == 3'b000)
            & render_line & (~sprite_fetch_time) & (pixel_counter != 256);
    assign inc_vert_pixel = (pixel_counter == 256) & render_line;
    assign hori_copy_pixel = (pixel_counter == 257) & render_line;
    assign vert_copy_pixel =
            pre_render_line & (pixel_counter > 279) & (pixel_counter < 305);
    assign set_vblank_pixel = ((line_counter == 241) & (pixel_counter == 1));
    assign clear_flgs_pixel = (pre_render_line & (pixel_counter == 1));

    assign name_fetch_pixel = render_line & (pixel_counter[2:0] == 1);
    assign attribute_fetch_pixel = render_line & (pixel_counter[2:0] == 3);
    assign bg_low_fetch_pixel = render_line & (pixel_counter[2:0] == 5);
    assign bg_high_fetch_pixel = render_line & (pixel_counter[2:0] == 7);
    assign next_pattern_load_pixel =
            render_line & (pixel_counter[2:0] == 0) & (~first_pixel_of_frame);

    assign name_addr_pixel =
            name_fetch_pixel | (render_line & (pixel_counter[2:0] == 2));
    assign attribute_addr_pixel =
            attribute_fetch_pixel | (render_line & (pixel_counter[2:0] == 4));
    assign pattern_addr_pixel =
            render_line & ((pixel_counter[2:0] > 4) | (pixel_counter[2:0] == 0));

    assign shift_pixel = render_line & (
                ((pixel_counter > 0) & (pixel_counter < 257))
                | ((pixel_counter > 327) & (pixel_counter < 337))
            );

    assign block_left = ~vram_addr[1]; // coarse X の第2ビット
    assign block_high = ~vram_addr[6]; // coarse Y の第2ビット

    // ### Operations from CPU ####

    assign op_ppuctrl_w = cpu_en & write & (opcode == 3'h0);
    assign op_ppumask_w = cpu_en & write & (opcode == 3'h1);
    assign op_ppustatus_r = cpu_en & read & (opcode == 3'h2);
    assign op_oamaddr_w = cpu_en & write & (opcode == 3'h3);
    assign op_oamdata_r = cpu_en & read & (opcode == 3'h4);
    assign op_oamdata_w = cpu_en & write & (opcode == 3'h4);
    assign op_ppuscroll_w = cpu_en & write & (opcode == 3'h5);
    assign op_ppuaddr_w = cpu_en & write & (opcode == 3'h6);
    assign op_ppudata_r = cpu_en & read & (opcode == 3'h7);
    assign op_ppudata_w = cpu_en & write & (opcode == 3'h7);


    // ---- Sequential logic ------

    // ppu_ctrl
    always_ff @(posedge clk) begin
        if (reset) begin
            ppu_ctrl <= 6'h0;
        end else if (op_ppuctrl_w) begin
            ppu_ctrl <= wdata[7:2];
        end
    end

    // ppu_mask
    always_ff @(posedge clk) begin
        if (reset) begin
            ppu_mask <= 8'h0;
        end else if (op_ppumask_w) begin
            ppu_mask <= wdata;
        end
    end

    // oam_addr
    always_ff @(posedge clk) begin
        if (reset) begin
            oam_addr <= 8'h0;
        end else if (op_oamaddr_w) begin
            oam_addr <= wdata;
        end else if (op_oamdata_w) begin
            oam_addr <= oam_addr + 8'b1;
        end
    end

    // write_toggle
    always_ff @(posedge clk) begin
        if (reset) begin
            write_toggle <= 1'b0;
        end else if (op_ppustatus_r) begin
            write_toggle <= 0;
        end else if (op_ppuscroll_w | op_ppuaddr_w) begin
            write_toggle <= ~write_toggle;
        end
    end

    // temp_vram_addr
    always_ff @(posedge clk) begin
        if (op_ppuctrl_w) begin
            temp_vram_addr[11:10] <= wdata[1:0];
        end else if (op_ppuscroll_w) begin
            if (~write_toggle) begin // 1st write
                temp_vram_addr[4:0] <= wdata[7:3]; // coarse X
            end else begin // 2nd write
                temp_vram_addr[14:12] <= wdata[2:0]; // fine Y
                temp_vram_addr[9:5] <= wdata[7:3]; // coarse Y
            end
        end else if (op_ppuaddr_w) begin
            if (~write_toggle) begin // 1st write
                temp_vram_addr[14:8] <= {1'b0, wdata[5:0]};
            end else begin // 2nd write
                temp_vram_addr[7:0] <= wdata;
            end
        end
    end

    // vread_buffer
    always_ff @(posedge clk) begin
        if (op_ppudata_r) begin
            vread_buffer <= ppumap_rdata;
        end
    end

    // fine_x
    always_ff @(posedge clk) begin
        if (reset) begin
            fine_x <= 3'h0;
        end else if (op_ppuscroll_w & (~write_toggle)) begin // 1st write
            fine_x <= wdata[2:0];
        end
    end

    // OAM
    always_ff @(posedge clk) begin
        if (reset) begin
            for (int i = 0; i < 256; i++) begin
                oam[i] <= 8'b0;
            end
        end else if (op_oamdata_w) begin
            // OAMDATA W, OAMDMA時にも使用
            oam[oam_addr] <= wdata;
        end
    end

    // pixel_counter
    always_ff @(posedge clk) begin
        if (reset) begin
            pixel_counter <= 0;
        end else begin
            pixel_counter <= last_pixel_of_frame ? 0 : (pixel_counter + 1);
        end
    end

    // line_counter
    always_ff @(posedge clk) begin
        if (reset) begin
            line_counter <= 0;
        end else if (last_pixel_of_frame) begin
            line_counter <= pre_render_line ? 0 : (line_counter + 1);
        end
    end

    // vram_addr
    always_ff @(posedge clk) begin

        if (op_ppuaddr_w) begin
            // PPUADDR W
            if (write_toggle) begin // 2nd write
                vram_addr <= {temp_vram_addr[14:8], wdata};
            end

        end else if (op_ppudata_r | op_ppudata_w) begin
            // PPUDATA R/W
            vram_addr <= (ppu_ctrl[2] ? (vram_addr + 8'd32) : (vram_addr + 8'd1));

        end else if ((~not_rendering) & inc_hori_pixel) begin

            {vram_addr[10], vram_addr[4:0]} <= ({vram_addr[10], vram_addr[4:0]} + 1);

        end else if ((~not_rendering) & inc_vert_pixel) begin

            if ({vram_addr[9:5], vram_addr[14:12]} == 8'b11101_111) begin
                {vram_addr[9:5], vram_addr[14:12]} <= 8'h00;
                vram_addr[11] <= ~vram_addr[11]; // ネームテーブルY反転
            end else begin
                {vram_addr[9:5], vram_addr[14:12]} <= ({vram_addr[9:5], vram_addr[14:12]} + 1);
            end

        end else if ((~not_rendering) & hori_copy_pixel) begin

            {vram_addr[10], vram_addr[4:0]} <= {temp_vram_addr[10], temp_vram_addr[4:0]};

        end else if ((~not_rendering) & vert_copy_pixel) begin

            {vram_addr[14:11], vram_addr[9:5]} <= {temp_vram_addr[14:11], temp_vram_addr[9:5]};

        end

    end

    // Flags
    always_ff @(posedge clk) begin
        if (clear_flgs_pixel) begin
            vblank <= 1'b0;
            sp0_hit <= 1'b0;
            sp_overflow <= 1'b0;
        end else if (set_vblank_pixel) begin
            vblank <= 1'b1;
        end else if (op_ppustatus_r) begin
            // PPUSTATUS R
            vblank <= 1'b0;
        end else if (visible_pixel & (pixel_counter != 256) & pixel_sp0_hit) begin
            sp0_hit <= 1'b1;
        end else if (sp_overflow_set) begin
            sp_overflow <= 1'b1;
        end else if (last_pixel_of_frame) begin
            is_sprite0 <= is_sprite0_next;
        end
    end

    // BG / Sprite Fetch
    always_ff @(posedge clk) begin
        if (name_fetch_pixel) begin
            name_data <= ppumap_rdata;
        end else if (attribute_fetch_pixel) begin
            attribute_data <= ppumap_rdata;
        end else if (bg_low_fetch_pixel) begin
            next_pattern_low <= ppumap_rdata;
        end else if (bg_high_fetch_pixel) begin
            next_pattern_high <= ppumap_rdata;
        end
    end

    // pattern_shifter
    always_ff @(posedge clk) begin
        if (shift_pixel) begin
            if (next_pattern_load_pixel) begin
                pattern_shifter_low[7:0] <= next_pattern_low;
                pattern_shifter_high[7:0] <= next_pattern_high;
                pattern_shifter_low[15:8] <= pattern_shifter_low[14:7];
                pattern_shifter_high[15:8] <= pattern_shifter_high[14:7];
            end else begin
                pattern_shifter_low <= {pattern_shifter_low[14:0], 1'b0};
                pattern_shifter_high <= {pattern_shifter_high[14:0], 1'b0};
            end
        end
    end

    // attribute_shifter
    always_ff @(posedge clk) begin
        if (shift_pixel) begin
            attribute_shifter_low <= {attribute_shifter_low[6:0], next_attribute[0]};
            attribute_shifter_high <= {attribute_shifter_high[6:0], next_attribute[1]};
        end
    end

    // next_attibute
    always_ff @(posedge clk) begin
        if (next_pattern_load_pixel) begin
            if (block_left & block_high) begin              // upper left
                next_attribute <= attribute_data[1:0];
            end else if (block_left & (~block_high)) begin  // lower left
                next_attribute <= attribute_data[5:4];
            end else if ((~block_left) & block_high) begin  // upper right
                next_attribute <= attribute_data[3:2];
            end else begin                                  // lower right
                next_attribute <= attribute_data[7:6];
            end
        end
    end

    // sp_x, sp_exist
    always_ff @(posedge clk) begin
        if (visible_pixel) begin
            for (int i = 0; i < 8; i++) begin
                if (sp_x[i] != '0) begin
                    sp_x[i] <= sp_x[i] - 3'b001;
                end
            end
        end else if (sprite_fetch_time & bg_high_fetch_pixel) begin
            sp_x[sp_second_num] <= second_oam[{sp_second_num, 2'b11}];
            sp_exist[sp_second_num] <= sp_exist_next[sp_second_num];
        end
    end

    // sp_shifter, sp_attribute
    always_ff @(posedge clk) begin
        if (visible_pixel) begin
            for (int i = 0; i < 8; i++) begin
                if (sp_x[i] == '0) begin
                    sp_shifter_low[i] <= {sp_shifter_low[i][6:0], 1'b0};
                    sp_shifter_high[i] <= {sp_shifter_high[i][6:0], 1'b0};
                end
            end
        end else if (sprite_fetch_time) begin
           if (bg_low_fetch_pixel) begin
               sp_shifter_low[sp_second_num] <= second_oam[{sp_second_num, 2'b10}][6]
                ? {
                    ppumap_rdata[0],
                    ppumap_rdata[1],
                    ppumap_rdata[2],
                    ppumap_rdata[3],
                    ppumap_rdata[4],
                    ppumap_rdata[5],
                    ppumap_rdata[6],
                    ppumap_rdata[7]
                } : ppumap_rdata;  // 水平反転時に逆順
           end else if (bg_high_fetch_pixel) begin
               sp_shifter_high[sp_second_num] <= second_oam[{sp_second_num, 2'b10}][6]
                ? {
                    ppumap_rdata[0],
                    ppumap_rdata[1],
                    ppumap_rdata[2],
                    ppumap_rdata[3],
                    ppumap_rdata[4],
                    ppumap_rdata[5],
                    ppumap_rdata[6],
                    ppumap_rdata[7]
                } : ppumap_rdata; // 水平反転時に逆順
               sp_attribute[sp_second_num] <= second_oam[{sp_second_num, 2'b10}][1:0];
           end
        end
    end

    // second_oam, sprite registers
    always_ff @(posedge clk) begin
        
        if (render_line & (pixel_counter < 32)) begin

            sp_num <= '0;
            sp_second_num <= '0;
            second_oam_full <= 1'b0;
            sp_eval_finished <= 1'b0;
            sp_overflow_set <= 1'b0;
            second_oam[pixel_counter] <= 8'hff;
            sp_exist_next[pixel_counter] <= 1'b0;
            is_sprite0_next <= 1'b0;

        end else if (sprite_evaluation_time) begin

            if (~sp_eval_finished) begin
                
                if (is_sprite_n) begin // 走査線上にスプライトがある

                    if (sp_num == 0) begin
                        is_sprite0_next <= 1'b1; // 次の走査線にスプライト0が存在
                    end

                    if (second_oam_full) begin
                        sp_overflow_set <= 1'b1;
                        sp_eval_finished <= 1'b1;
                    end else begin
                        second_oam[{sp_second_num, 2'b00}] <= oam[{sp_num, 2'b00}];
                        second_oam[{sp_second_num, 2'b01}] <= oam[{sp_num, 2'b01}];
                        second_oam[{sp_second_num, 2'b10}] <= oam[{sp_num, 2'b10}];
                        second_oam[{sp_second_num, 2'b11}] <= oam[{sp_num, 2'b11}];
                        sp_exist_next[sp_second_num] <= 1'b1;
                        {second_oam_full, sp_second_num} <= sp_second_num + 1;
                    end

                end

                if (sp_num == 63) begin
                    sp_eval_finished <= 1'b1;
                    sp_second_num <= 1'b0;
                end else begin
                    sp_num <= sp_num + 1;
                end

            end
        end else if (sprite_fetch_time & bg_high_fetch_pixel) begin
            sp_second_num <= sp_second_num + 1;
            sp_priority[sp_second_num] <= second_oam[{sp_second_num, 2'b10}][5];
        end
    end

    pixel_generator pixel_generator(
        .bg_pixel,
        .sprites,
        .is_sprite0,
        .mask(pixel_mask),

        .graphic_off,

        .pixel_info,
        .pixel_sp0_hit
    );

endmodule
