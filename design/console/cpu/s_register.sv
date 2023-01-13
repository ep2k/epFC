// Sレジスタ

module s_register (
    input  logic clk,
    input  logic reset,
    input  logic cpu_en,
    input  logic [7:0] wd0,     // 書き込みデータ1 (alu_y)
    input  logic [7:0] wd1,     // 書き込みデータ2 (メモリからの読み値)
    output logic [7:0] s_out,   // レジスタデータ
    input  logic s_src,         // 書き込みデータ選択
    input  logic s_write,       // 書き込みイネーブル
    input  logic s_inc,         // インクリメント
    input  logic s_dec          // デクリメント
);

    logic [7:0] s = 8'hfd;
    logic [7:0] s_next;

    assign s_out = s;
    assign s_next = s_src ? wd1 : wd0;

    always_ff @(posedge clk) begin
        if (reset) begin
            s <= 8'hfd;
        end else if (cpu_en) begin
            if (s_write) begin
                s <= s_next;
            end else if (s_inc) begin
                s <= s + 8'h01;
            end else if (s_dec) begin
                s <= s - 8'h01;
            end
        end
    end
    
endmodule
