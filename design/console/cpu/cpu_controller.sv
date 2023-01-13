module cpu_controller (
    input  logic clk,
    input  logic cpu_en,
    input  logic [7:0] op,
    input  logic [7:0] p,
    input  logic reset,
    input  logic nmi,
    input  logic irq,
    input  logic [3:0] alu_flgs,
    input  logic pcl_m,
    input  logic al_m,

    output logic [2:0] addr_high_src,
    output logic [1:0] addr_low_src,
    output logic mem_read,
    output logic mem_write,

    output logic [3:0] alu_a_src,
    output logic [2:0] alu_b_src,
    output logic [3:0] alu_control,

    output logic a_src,
    output logic x_src,
    output logic y_src,
    output logic s_src,
    output logic p_src,
    output logic pcl_src,
    output logic pch_src,
    output logic [1:0] al_src,
    output logic ah_src,
    output logic data_src,

    output logic [7:0] p_next,
    output logic [1:0] val_select,

    output logic a_write,
    output logic x_write,
    output logic y_write,
    output logic s_write,
    output logic pcl_write,
    output logic pch_write,
    output logic op_write,
    output logic al_write,
    output logic ah_write,
    output logic data_write,
    output logic [7:0] p_write,

    output logic pc_inc,
    output logic s_inc,
    output logic s_dec
);

    localparam C = 0, Z = 1, I = 2, D = 3, B = 4, V = 6, N = 7; // P

    typedef enum logic [3:0] {
        S0, S1, S2, S3, S4, S5, S6,
        SI1, SI2, SI3, SI4, SI5, SI6
    } statetype;

    statetype state = SI1;
    statetype next_state;

    always_ff @(posedge clk) begin
        if (reset) begin
            state <= SI1;
        end else if (cpu_en) begin
            state <= next_state; 
        end
    end

    // 割り込みフラグ

    logic reset_flg = 1'b1;
    logic nmi_flg, brk_flg;
    logic nmi_prev;
    logic intflg_clear, brk_set, brk_clear;

    always_ff @(posedge clk) begin
        if (reset) begin
            reset_flg <= 1'b1;
            nmi_flg <= 1'b0;
        end else if (cpu_en) begin
            if (intflg_clear) begin
                nmi_flg <= 1'b0;
                reset_flg <= 1'b0;
            end else begin
                nmi_flg <= nmi_flg | ((~nmi_prev) & nmi); // nmiが0→1のとき1
            end
        end
    end

    always_ff @(posedge clk) begin
        if (cpu_en) begin
            nmi_prev <= nmi;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            brk_flg <= 1'b0;
        end else if (cpu_en) begin
            if (brk_clear) begin
                brk_flg <= 1'b0;
            end else if (brk_set) begin
                brk_flg <= 1'b1;
            end
        end
    end

    // コントロール
    always_comb begin
        
        // ### 既定値 ####################################

        next_state = S0;

        intflg_clear = 1'b0;
        brk_set = 1'b0;
        brk_clear = 1'b0;

        alu_a_src = 4'bxxxx; // A
        alu_b_src = 3'b000; // 0
        alu_control = 4'b0000; // ADD

        addr_high_src = 3'b000; // PCH
        addr_low_src = 2'b00; // PCL

        p_next = {alu_flgs[3:2], 4'b0000, alu_flgs[1:0]};
        p_src = 1'b0; // コントローラー

        a_src = 1'bx;
        x_src = 1'bx;
        y_src = 1'bx;
        s_src = 1'bx;
        pch_src = 1'bx;
        pcl_src = 1'bx;
        al_src = 2'bxx;
        ah_src = 1'bx;
        data_src = 1'bx;

        val_select = 2'bxx;

        mem_write = 1'b0;
        mem_read = 1'b0;
        a_write = 1'b0;
        x_write = 1'b0;
        y_write = 1'b0;
        s_write = 1'b0;
        pcl_write = 1'b0;
        pch_write = 1'b0;
        op_write = 1'b0;
        al_write = 1'b0;
        ah_write = 1'b0;
        data_write = 1'b0;
        p_write = 8'h00;

        pc_inc = 1'b0;
        s_inc = 1'b0;
        s_dec = 1'b0;

        // ###################################################

        if (state == S0) begin
            
            if (nmi_flg | (irq & ~p[I])) begin // 割り込み

                if (nmi_flg) begin
                    val_select = 2'b00; // $FA
                end else begin
                    val_select = 2'b10; // $FE
                end
                
                al_src = 2'b10; // VAL
                al_write = 1'b1;

                p_next[B] = 1'b0; p_write[B] = 1'b1; // Bクリア

                next_state = SI1;

            end else begin
                op_write = 1'b1;
                pc_inc = 1'b1;
                mem_read = 1'b1;
                next_state = S1;
            end

        end else if (state == SI1) begin

            if (brk_flg & (nmi_flg | irq)) begin // BRKスキップ
                brk_clear = 1'b1;
                next_state = S0;
            end else begin
                next_state = SI2;
            end

        end else if (state == SI2 || state == SI3) begin
            
            // [01, S] <- PCH/PCL
            // S--

            addr_high_src = 3'b101; // 01
            addr_low_src = 2'b10; // S
            alu_a_src = (state == SI2) ? 4'b0101 : 4'b0110; // PCH/PCL
            mem_write = ~reset_flg; // RESETのときは書き込まない
            s_dec = 1'b1;

            if (brk_flg & (nmi_flg | irq)) begin // BRKスキップ
                brk_clear = 1'b1;
                next_state = S0;
            end else begin
                next_state = (state == SI2) ? SI3 : SI4;
            end

        end else if (state == SI4) begin
            
            // [01, S] <- P
            // S--

            addr_high_src = 3'b101; // 01
            addr_low_src = 2'b10; // S
            alu_a_src = 4'b0100; // P
            mem_write = ~reset_flg; // RESETのときは書き込まない
            s_dec = 1'b1;
            next_state = SI5;

        end else if (state == SI5) begin
            
            // PCL <- [FF, AL]
            // AL <- AL+1

            addr_high_src = 3'b110; // FF
            addr_low_src = 2'b01; // AL
            mem_read = 1'b1;
            pcl_src = 1'b1; // RD
            pcl_write = 1'b1;

            alu_a_src = 4'b1000; // AL
            alu_b_src = 3'b001; // 1
            al_src = 1'b0; // alu_y
            al_write = 1'b1;

            next_state = SI6;

        end else if (state == SI6) begin
            
            // PCH <- [FF, AL]

            addr_high_src = 3'b110; // FF
            addr_low_src = 2'b01; // AL
            mem_read = 1'b1;
            pch_src = 1'b1; // RD
            pch_write = 1'b1;

            p_next[I] = 1'b1; p_write[I] = 1'b1; // Iセット

            brk_clear = 1'b1;
            intflg_clear = 1'b1;

        end else if (op == 8'hEA) begin // NOP
            
        end else if ((op[4:0] == 5'b1_1000) && (op[7:5] != 3'b100)) begin // フラグ操作
            
            case (op[7:6])
                2'b00: begin
                    p_write[C] = 1'b1;
                    p_next[C] = op[5];
                end
                2'b01: begin
                    p_write[I] = 1'b1;
                    p_next[I] = op[5];
                end
                2'b11: begin
                    p_write[D] = 1'b1;
                    p_next[D] = op[5];
                end
                2'b10: begin
                    p_write[V] = 1'b1;
                    p_next[V] = 1'b0;
                end
                default ;
            endcase

        end else if ({op[7:6], op[4:0]} == 7'b110_1000) begin // INX, INY
            
            // if(op[5]) X <- X+1 else Y <- Y+1

            alu_a_src = op[5] ? 4'b0001 : 4'b0010; // X / Y
            alu_b_src = 3'b001; // 1

            x_src = 1'b0; y_src = 1'b0; // ALU

            x_write = op[5];
            y_write = ~op[5];
            p_write = 8'b1000_0010;

        end else if (op == 8'b1100_1010) begin // DEX

            // X <- X-1

            alu_a_src = 4'b0001; // X
            alu_b_src = 3'b001; // 1
            alu_control = 4'b0010; // SUB

            x_src = 1'b0; // ALU

            x_write = 1'b1;
            p_write = 8'b1000_0010;
            
        end else if (op == 8'b1000_1000) begin // DEY
            
            // Y <- Y-1

            alu_a_src = 4'b0010; // Y
            alu_b_src = 3'b001; // 1
            alu_control = 4'b0010; // SUB

            y_src = 1'b0; // ALU

            y_write = 1'b1;
            p_write = 8'b1000_0010;

        end else if ({op[7:2], op[0]} == 7'b1010_10_0) begin // TAX / TAY
            
            // X/Y <- A+0

            alu_a_src = 4'b0000; // A

            x_src = 1'b0; y_src = 1'b0; // ALU

            x_write = op[1];
            y_write = ~op[1];
            p_write = 8'b1000_0010;

        end else if ({op[7:5], op[3:0]} == 7'b100__1010) begin // TXA / TXS
            
            // A/S <- X+0

            alu_a_src = 4'b0001; // X

            a_src = 1'b0; s_src = 1'b0; // ALU

            a_write = ~op[4];
            s_write = op[4];
            p_write = op[4] ? 8'h00 : 8'b1000_0010; // TXSではフラグ変更なし

        end else if (op == 8'b1001_1000) begin // TYA
            
            // A <- Y+0

            alu_a_src = 4'b0010; // Y

            a_src = 1'b0; // ALU

            a_write = 1'b1;
            p_write = 8'b1000_0010;

        end else if (op == 8'b1011_1010) begin // TSX
            
            // X <- S+0

            alu_a_src = 4'b0011; // S

            x_src = 1'b0; // ALU

            x_write = 1'b1;
            p_write = 8'b1000_0010;

        end else if ({op[7], op[4:0]} == 8'b0__0_1000) begin // スタック PHA,PLA,PHP,PLP

            if (state == S1) begin
                next_state = S2;
            end else if (state == S2) begin
                
                if (op[5]) begin // プル PLA, PLP
                    // S++
                    s_inc = 1'b1; // PLPではインクリメントしない？
                    // s_inc = op[6];
                    next_state = S3;
                end else begin // プッシュ PHA, PHP
                    // [01, S] <- A/P; S--
                    alu_a_src = op[6] ? 4'b0000 : 4'b0100; // A/P
                    addr_high_src = 3'b101; // 01
                    addr_low_src = 2'b10; // S
                    mem_write = 1'b1;
                    s_dec = 1'b1; // PHPではデクリメントしない？
                    // s_dec = op[6];
                end

            end else begin // state == S3
                // A/P <- [01, S]
                alu_a_src = 4'b1111; // RD
                addr_high_src = 3'b101; // 01
                addr_low_src = 2'b10; // S
                mem_read = 1'b1;

                a_src = 1'b0; // ALU
                p_src = ~op[6]; // PLA: p_next, PLP: RD

                a_write = op[6];
                p_write = op[6] ? 8'b1000_0010 : 8'hff;
            end

        end else if (op[4:0] == 5'b1_0000) begin // 分岐

            if (state == S1) begin // オフセットフェッチ
                
                // AL <- [PCH, PCL]
                al_src = 2'b01; // RD
                al_write = 1'b1;
                mem_read = 1'b1;
                pc_inc = 1'b1;

                case (op[7:6])
                    2'b00: next_state = ((p[N] == op[5]) ? S2: S0); // N
                    2'b01: next_state = ((p[V] == op[5]) ? S2: S0); // V
                    2'b10: next_state = ((p[C] == op[5]) ? S2: S0); // C
                    2'b11: next_state = ((p[Z] == op[5]) ? S2: S0); // Z
                    default: ;
                endcase

            end else if (state == S2) begin // オフセット加算
                
                // PCL <- PCL + AL
                alu_a_src = 4'b0110; // PCL
                alu_b_src = 3'b011; // AL
                pcl_src = 1'b0; // ALU
                pcl_write = 1'b1;

                if ((pcl_m == alu_flgs[C]) & (al_m != alu_flgs[C])) begin // ページクロス
                    next_state = alu_flgs[C] ? S3 : S4;
                end

            end else if (state == S3) begin // PCH++
                // PCH <- PCH + 1
                alu_a_src = 4'b0101; // PCH
                alu_b_src = 3'b001; // 1
                pch_src = 1'b0; // ALU
                pch_write = 1'b1;
            end else begin // state == S4, PCH--
                // PCH <- PCH - 1
                alu_a_src = 4'b0101; // PCH
                alu_b_src = 3'b001; // 1
                alu_control = 4'b0010; // SUB
                pch_src = 1'b0; // ALU
                pch_write = 1'b1;
            end
            
        end else if ({op[7:4], op[2:0]} == 7'b0010__100) begin // BIT
            
            if (state == S1) begin // ALフェッチ
                // AL <- [PCH, PCL]
                al_src = 2'b01; // RD
                al_write = 1'b1;
                mem_read = 1'b1;
                pc_inc = 1'b1;
                next_state = op[3] ? S2 : S3;
            end else if (state == S2) begin // AHフェッチ
                // AH <- [PCH, PCL]
                ah_src = 1'b1; // RD
                ah_write = 1'b1;
                mem_read = 1'b1;
                pc_inc = 1'b1;
                next_state = S3;
            end else begin // state == S3, 演算
                // A BIT RD
                addr_high_src = op[3] ? 3'b001 : 3'b100; // AH / 0
                addr_low_src = 2'b01; // AL
                mem_read = 1'b1;
                alu_a_src = 4'b0000; // A
                alu_b_src = 3'b111; // RD
                alu_control = 4'b0101;
                p_write = 8'b1100_0010;
            end

        end else if ({op[7:6], op[4:0]} == 7'b01_0_1100) begin // JMP
            
            if (state == S1) begin // AL/newPCLフェッチ
                // AL <- [PCH, PCL]
                al_src = 2'b01; // RD
                al_write = 1'b1;
                mem_read = 1'b1;
                pc_inc = 1'b1;
                next_state = S2;
                
            end else if (state == S2) begin // AH/newPCHフェッチ
                // PCH, AH <- [PCH, PCL]; PCL <- AL
                pch_src = 1'b1; // RD
                ah_src = 1'b1; // RD
                mem_read = 1'b1;
                pch_write = 1'b1; // Absolute用
                ah_write = 1'b1; // Indirect用

                alu_a_src = 4'b1000; // AL
                pcl_src = 1'b0; // ALU
                pcl_write = 1'b1; // Absolute用

                next_state = (op[5]) ? S3 : S0; // Absolute IndirectならS3

            end else if (state == S3) begin // newPCLフェッチ
                // PCL <- [AH, AL], AL <- AL + 1
                addr_high_src = 3'b001; // AH
                addr_low_src = 2'b01; // AL
                mem_read = 1'b1;
                pcl_src = 1'b1; // RD
                pcl_write = 1'b1;

                alu_a_src = 4'b1000; // AL
                alu_b_src = 3'b001; // 1
                al_src = 1'b0; // ALU
                al_write = 1'b1;

                next_state = S4;

            end else if (state == S4) begin
                // PCH <- [AH, AL]
                addr_high_src = 3'b001; // AH
                addr_low_src = 2'b01; // AL
                mem_read = 1'b1;
                pch_src = 1'b1; // RD
                pch_write = 1'b1;
            end

        end else if (op == 8'b0010_0000) begin // JSR
            
            if (state == S1) begin // newPCLフェッチ
                // AL <- [PCH, PCL]
                al_src = 2'b01; // RD
                mem_read = 1'b1;
                al_write = 1'b1;
                pc_inc = 1'b1;
                next_state = S2;
            end else if (state == S2) begin // Sプリデクリメント
                // S--
                // s_dec = 1'b1; 必要ない
                next_state = S3;
            end else if (state == S3 || state == S4) begin // PCH/PCLプッシュ
                // [01,S] <- PCH; S--
                addr_high_src = 3'b101; // 01
                addr_low_src = 2'b10; // S

                alu_a_src = (state == S3) ? 4'b0101 : 4'b0110; // PCH/PCL
                mem_write = 1'b1;
                s_dec = 1'b1;

                next_state = (state == S3) ? S4 : S5;
            end else begin // state == S5, newPCHフェッチ
                // PCH <- [PCH, PCL]; PCL <- AL
                pch_src = 1'b1;
                pch_write = 1'b1;
                mem_read = 1'b1;

                alu_a_src = 4'b1000;
                pcl_src = 1'b0;
                pcl_write = 1'b1;
            end

        end else if ({op[7:6], op[4:0]} == 8'b01_0_0000) begin // リターン RTS, RTI
            
            if (state == S1) begin // 何もしない
                next_state = S2;
            end else if (state == S2) begin // Sプリインクリメント
                s_inc = 1'b1;
                next_state = op[5] ? S4 : S3; // RTS/RTI
            end else if (state == S3) begin // Pポップ
                
                // P <- [01, S]; S++
                addr_high_src = 3'b101; // 01
                addr_low_src = 2'b10; // S
                mem_read = 1'b1;
                p_src = 1'b1; // RD
                p_write = 8'hff;
                s_inc = 1'b1;
                next_state = S4;

            end else if (state == S4 || state == S5) begin // PCL/PCHポップ
                
                // PCL/PCH <- [01, S]; PCLポップならS++
                addr_high_src = 3'b101; // 01
                addr_low_src = 2'b10; // S
                mem_read = 1'b1;
                pcl_src = 1'b1; pch_src = 1'b1; // RD
                pcl_write = (state == S4);
                pch_write = (state == S5);
                s_inc = (state == S4);
                
                if (state == S4) begin
                    next_state = S5;
                end else if (op[5]) begin // RTS
                    next_state = S6;
                end else begin // RTI
                    next_state = S0;
                end
            end else begin // state == S6, RTSの場合はPCを1進める
                pc_inc = 1'b1;
            end

        end else if (op == 8'h00) begin // BRK

            if (~p[I]) begin
                p_next[B] = 1'b1; p_write[B] = 1'b1; // Bセット
                brk_set = 1'b1;
                val_select = 2'b10; // FE
                al_src = 2'b10; // VAL
                al_write = 1'b1;
                pc_inc = 1'b1; // Iセット時にインクリメントするか不明(多分しない)
                next_state = SI2;
            end else begin
                ;
            end

        end else if (op[1:0] == 2'b01) begin // LDA型，STA型

            if (state == S1) begin // 下位アドレスフェッチ
                // AL <- [PCH, PCL]
                mem_read = 1'b1;
                al_src = 2'b01; // RD
                al_write = 1'b1;
                pc_inc = 1'b1;

                if (op[4:2] == 3'b010) begin // Immediate
                    // 「alu_a = A, alu_b = [PCH, PCL] の演算結果」または[PCH, PCL] → A
                    // pc_writeとa_writeはOP[7:5]で場合分け
                    // [PCH, PCL]と演算

                    alu_a_src = (op[7:6] == 3'b10) ? 4'b1111 : 4'b0000; // LDA:RD / A
                    alu_b_src = (op[7:6] == 2'b10) ? 3'b000 : 3'b111; // LDA:0 / RD

                    a_src = 1'b0; // ALU
                    a_write = ({op[7], op[5]} != 2'b10); // CMP以外は書き込み

                    case (op[7:5])
                        3'b011: alu_control = 4'b0001; // ADC
                        3'b111: alu_control = 4'b0011; // SBC
                        3'b001: alu_control = 4'b0100; // AND
                        3'b000: alu_control = 4'b0110; // ORA
                        3'b010: alu_control = 4'b0111; // EOR
                        3'b110: alu_control = 4'b0010; // CMP (SUB)
                        default: ;
                    endcase

                    if (op[7:5] == 3'b011 || op[7:5] == 3'b111) begin // ADC, SBC
                        p_write = 8'b1100_0011;
                    end else if (op[7:5] == 3'b110) begin // CMP
                        p_write =  8'b1000_0011;
                    end else begin // AND, EOR, ORA, LDA
                        p_write = 8'b1000_0010;
                    end
                end else if (op[4:2] == 3'b001) begin // Zero page
                    next_state = S6;
                end else if (op[4:2] == 3'b100) begin // (z), Y
                    next_state = S3;
                end else begin // Absolute / Zero page, X / Absolute, XY / (z, X)
                    next_state = S2;
                end

            end else if (state == S2) begin // AHフェッチ & AL += X/Y

                // AH <- [PCH, PCL], Indexedなら AL <- AL + X/Y
                mem_read = 1'b1;
                ah_src = 1'b1; // RD
                ah_write = 1'b1;
                pc_inc = op[3]; // Zero pageの場合はインクリメントしない

                alu_a_src = (op[4:2] == 3'b110) ? 4'b0010 : 4'b0001; // Y / X
                alu_b_src = 3'b011; // AL
                al_src = 2'b00; // ALU
                al_write = ~(op[4:2] == 3'b011); // Absoluteの場合は加算しない

                if (op[4:3] == 2'b00) begin // (z, X)
                    next_state = S3;
                end else if (op[4:3] == 2'b11) begin // Absolute, XY
                    next_state = alu_flgs[C] ? S5 : S6;
                end else begin // Absolute / Zero page, X
                    next_state = S6;
                end
                
            end else if (state == S3) begin // 実効アドレス下位バイトフェッチ
                
                // DATA <- [00, AL] 一時的にDATAに保存; AL <- AL + 1
                addr_high_src = 3'b100; // 00
                addr_low_src = 2'b01; // AL
                mem_read = 1'b1;
                data_src = 1'b1; // RD
                data_write = 1'b1;

                alu_a_src = 4'b1000; // AL
                alu_b_src = 3'b001; // 1
                al_src = 2'b00; // ALU
                al_write = 1'b1;

                next_state = S4;

            end else if (state == S4) begin // 実効アドレス上位バイトフェッチ
                
                // AH <- [00, AL]; AL <- DATA (+Y)
                addr_high_src = 3'b100; // 00
                addr_low_src = 2'b01; // AL
                mem_read = 1'b1;
                ah_src = 1'b1;
                ah_write = 1'b1;

                alu_a_src = 4'b1010; // DATA
                alu_b_src = op[4] ? 3'b010 : 3'b000; // Y / 0
                al_src = 2'b00; // ALU
                al_write = 1'b1;

                next_state = alu_flgs[C] ? S5 : S6; // 繰り上がり時はS5

            end else if (state == S5) begin // AH += 1
                
                // AH <- AH + 1
                alu_a_src = 4'b1001; // AH
                alu_b_src = 3'b001; // 1
                ah_src = 1'b0; // ALU
                ah_write = 1'b1;
                next_state = S6;

            end else begin // state == S6, 演算

                // [00, AL] or [AH, AL]と演算
                addr_high_src = (op[3:2] == 2'b01) ? 3'b100 : 3'b001; // 00 / AH
                addr_low_src = 2'b01; // AL

                alu_a_src = (op[7:5] == 3'b101) ? 4'b1111 : 4'b0000; // LDA:RD / A
                alu_b_src = (op[7:6] == 2'b10) ? 3'b000 : 3'b111; // STA,LDA:0 / RD

                a_src = 1'b0; // ALU
                a_write = ({op[7], op[5]} != 2'b10); // CMPとSTA以外は書き込み
                mem_write = (op[7:5] == 3'b100); // STAのみメモリ書き込み
                mem_read = ~mem_write;

                case (op[7:5])
                    3'b011: alu_control = 4'b0001; // ADC
                    3'b111: alu_control = 4'b0011; // SBC
                    3'b001: alu_control = 4'b0100; // AND
                    3'b000: alu_control = 4'b0110; // ORA
                    3'b010: alu_control = 4'b0111; // EOR
                    3'b110: alu_control = 4'b0010; // CMP (SUB)
                    default: ;
                endcase

                if (op[7:5] == 3'b100) begin // STA
                    p_write = 8'h00;
                end else if (op[6:5] == 2'b11) begin // ADC, SBC
                    p_write = 8'b1100_0011;
                end else if (op[7:5] == 3'b110) begin // CMP
                    p_write =  8'b1000_0011;
                end else begin // AND, EOR, ORA, LDA
                    p_write = 8'b1000_0010;
                end
            end
            
        end else if ({op[7], op[1:0]} == 3'b010) begin // シフト型 ASL, LSR, ROL, ROR

            if (state == S1) begin // ALフェッチ

                // AL <- [PCH, PCL]
                mem_read = 1'b1;
                al_src = 2'b01; // RD
                al_write = 1'b1;

                if (op[4:2] == 3'b010) begin // Accumulator
                    // A <- Aのシフト結果
                    alu_a_src = 4'b0000; // A
                    alu_control = {2'b10, op[6:5]};

                    a_src = 1'b0; // ALU
                    a_write = 1'b1;
                    p_write = 8'b1000_0011;
                end else begin
                    pc_inc = 1'b1;
                    next_state = (op[4:3] == 2'b00) ? S4 : S2; // Zero pageならS4
                end

            end else if (state == S2) begin // AHフェッチ & AL += X
                
                // AH <- [PCH, PCL]
                mem_read = 1'b1;
                ah_src = 1'b1; // RD
                ah_write = 1'b1;
                pc_inc = op[3]; // z,Xではインクリメントしない

                // AL <- AL + X
                alu_a_src = 4'b0001; // X
                alu_b_src = 3'b011; // AL
                al_src = 2'b00; // ALU
                al_write = op[4]; // Absoluteでは足さない

                next_state = ((op[4:2] == 3'b111) & alu_flgs[C]) ? S3 : S4; // m,X で繰り上がりならS3

            end else if (state == S3) begin // AH += 1
                
                // AH <- AH + 1
                alu_a_src = 4'b1001; // AH
                alu_b_src = 3'b001; // 1
                ah_write = 1'b1;
                next_state = S4;

            end else if (state == S4) begin // 実効アドレスからフェッチ
                
                // DATA <- [00, AL] / [AH, AL]
                addr_high_src = op[3] ? 3'b001 : 3'b100; // AH / 00
                addr_low_src = 2'b01; // AL
                mem_read = 1'b1;
                data_src = 1'b1; // RD
                data_write = 1'b1;
                next_state = S5;

            end else if (state == S5) begin // 演算
                
                // DATA <- DATAのシフト結果

                alu_a_src = 4'b1010;
                alu_control = {2'b10, op[6:5]};

                data_src = 1'b0; // ALU
                data_write = 1'b1;
                p_write = 8'b1000_0011;

                next_state = S6;

            end else begin // state == S6, ライトバック
                
                // [AH, AL] / [00, AL] <- DATA
                addr_high_src = op[3] ? 3'b001 : 3'b100; // AH / 00
                addr_low_src = 2'b01; // AL
                
                alu_a_src = 4'b1010;

                mem_write = 1'b1;

            end
            
        end else if ({op[7:6], op[2:0]} == 5'b11____110) begin // INC, DEC

            if (state == S1) begin // ALフェッチ
                
                // AL <- [PCH, PCL]
                mem_read = 1'b1;
                al_src = 2'b01; // RD
                al_write = 1'b1;
                pc_inc = 1'b1;

                next_state = (op[4:3] == 2'b00) ? S4 : S2; // Zero pageならS2

            end else if (state == S2) begin // AHフェッチ & AL += X
                
                // AH <- [PCH, PCL]
                mem_read = 1'b1;
                ah_src = 1'b1; // RD
                ah_write = 1'b1;
                pc_inc = op[3]; // Zero pageではインクリメントしない

                // AL <- AL + X
                alu_a_src = 4'b0001; // X
                alu_b_src = 3'b011; // AL
                al_src = 1'b0; // ALU
                al_write = op[4]; // Absoluteでは加算しない

                next_state = ((op[4:3] == 2'b11) & alu_flgs[C]) ? S3 : S4; // m,Xで繰り上がりならS3

            end else if (state == S3) begin // AH += 1
                
                // AH <- AH + 1
                alu_a_src = 4'b1001; // AH
                alu_b_src = 3'b001; // 1
                ah_src = 1'b0; // ALU
                ah_write = 1'b1;
                next_state = S4;

            end else if (state == S4) begin // 実効アドレスからフェッチ

                // DATA <- [00, AL] / [AH, AL]
                addr_high_src = op[3] ? 3'b001 : 3'b100; // AH / 00
                addr_low_src = 2'b01; // AL
                mem_read = 1'b1;
                data_src = 1'b1; // RD
                data_write = 1'b1;
                next_state = S5;
                
            end else if (state == S5) begin // 演算

               // DATA <- DATA +- 1
               alu_a_src = 4'b1010; // DATA
               alu_b_src = 3'b001; // 1
               alu_control[1] = ~op[5]; // ADD / SUB
               
               data_src = 1'b0; // ALU
               data_write = 1'b1;
               p_write = 8'b1000_0010;

               next_state = S6;

            end else begin // state == S6, ライトバック

                // [00, AL] / [AH, AL] <- DATA
                addr_high_src = op[3] ? 3'b001 : 3'b100; // AH / 00
                addr_low_src = 2'b01; // AL

                alu_a_src = 4'b1010; // DATA
                mem_write = 1'b1;
                
            end
            
        end else if ({op[7:6], op[4], op[1:0]} == 5'b11_0___00) begin // CPX, CPY

            if (state == S1) begin // ALフェッチ

                // AL <- [PCH, PCL]
                mem_read = 1'b1;
                al_src = 2'b01; // RD
                al_write = 1'b1;
                pc_inc = 1'b1;

                if (~op[2]) begin // Immediate
                    // X/Y - [PCH, PCL]
                    alu_a_src = op[5] ? 4'b0001 : 4'b0010; // X / Y
                    alu_b_src = 3'b111; // RD
                    alu_control = 4'b0010; // SUB
                    p_write = 8'b1000_0011;
                end else begin
                    next_state = op[3] ? S2 : S3; // zero pageならS3
                end
                
            end else if (state == S2) begin // AHフェッチ

                // AH <- [PCH, PCL]
                mem_read = 1'b1;
                ah_src = 1'b1; // RD
                ah_write = 1'b1;
                pc_inc = 1'b1;
                next_state = S3;

            end else begin // state == S3, 演算

                // X/Y - [AH, AL] / [00, AL]

                addr_high_src = op[3] ? 3'b001 : 3'b100; // AH / 00
                addr_low_src = 2'b01; // AL
                mem_read = 1'b1;

                alu_a_src = op[5] ? 4'b0001 : 4'b0010; // X / Y
                alu_b_src = 3'b111; // RD
                alu_control = 4'b0010; // SUB
                p_write = 8'b1000_0011;

            end
            
        end else if ({op[7:5], op[2], op[0]} == 5'b100__1_0) begin // STX, STY

            if (state == S1) begin // ALフェッチ

                // AL <- [PCH, PCL]
                al_src = 1'b1; // RD
                al_write = 1'b1;
                mem_read = 1'b1;
                pc_inc = 1'b1;

                case (op[4:3])
                    2'b00: next_state = S4; // Zero page
                    2'b01: next_state = S2; // Absolute
                    2'b10: next_state = S3; // z, X/Y
                    default: ;
                endcase
                
            end else if (state == S2) begin // AHフェッチ

                // AH <- [PCH, PCL]
                mem_read = 1'b1;
                ah_src = 1'b1; // RD
                ah_write = 1'b1;
                pc_inc = 1'b1;
                next_state = S4;
                
            end else if (state == S3) begin // AL += X/Y

                // AL <- AL + X/Y
                alu_a_src = op[1] ? 4'b0010 : 4'b0001; // Y / X
                alu_b_src = 3'b011; // AL
                al_src = 2'b00; // ALU
                al_write = 1'b1;
                next_state = S4;
                
            end else begin // state == S4, ストア

                // [AH, AL] / [00, AL] <- X/Y
                addr_high_src = op[3] ? 3'b001 : 3'b100; // AH / 00
                addr_low_src = 2'b01; // AL

                alu_a_src = op[1] ? 4'b0001 : 4'b0010; // X / Y
                
                mem_write = 1'b1;
                
            end
            
        end else if ({op[7:5], op[0]} == 4'b101_____0) begin // LDX, LDY
            
            if (state == S1) begin // ALフェッチ

                // AL <- [PCH, PCL]
                mem_read = 1'b1;
                al_src = 2'b01; // RD
                al_write = 1'b1;
                pc_inc = 1'b1;

                if (op[4:2] == 3'b000) begin // Immediate
                    // X/Y <- [PCH, PCL]
                    alu_a_src = 4'b1111; // RD
                    x_src = 1'b0; // ALU
                    y_src = 1'b0; // ALU
                    x_write = op[1];
                    y_write = ~op[1];
                    p_write = 8'b1000_0010;
                end else begin
                    next_state = (op[4:2] == 3'b001) ? S4 : S2; // Zero pageならS4
                end
                
            end else if (state == S2) begin // AHフェッチ & AL += X/Y

                // AH <- [PCH, PCL]
                mem_read = 1'b1;
                ah_src = 1'b1;
                ah_write = 1'b1;
                pc_inc = (op[3:2] == 2'b11); // Zero pageではインクリメントしない

                // AL <- AL + X/Y
                alu_a_src = op[1] ? 4'b0010 : 4'b0001; // Y / X
                alu_b_src = 3'b011;
                al_src = 2'b00; // ALU
                al_write = op[4];
                
                next_state = ((op[4:2] == 3'b111) & alu_flgs[C]) ? S3 : S4;

            end else if (state == S3) begin // AH += 1

                // AH <- AH + 1
                alu_a_src = 4'b1001;
                alu_b_src = 3'b001;
                ah_src = 1'b0; // ALU
                ah_write = 1'b1;
                next_state = S4;
                
            end else begin // state == S4, ロード

                // X/Y <- [AH, AL] / [00, AL]
                addr_high_src = (op[3:2] == 2'b11) ? 3'b001 : 3'b100; // AH / 00
                addr_low_src = 2'b01; // AL
                mem_read = 1'b1;

                alu_a_src = 4'b1111; // RD

                x_src = 1'b0; // ALU
                y_src = 1'b0; // ALU
                x_write = op[1];
                y_write = ~op[1];
                p_write = 8'b1000_0010;
                
            end

        end else begin
            ;
        end
    end
    
endmodule
