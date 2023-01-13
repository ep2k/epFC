// Pレジスタ

module p_register (
    input  logic clk,
    input  logic reset,
    input  logic cpu_en,
    input  logic [7:0] wd0,     // 書き込みデータ1 (コントローラーからの信号)
    input  logic [7:0] wd1,     // 書き込みデータ2 (メモリからの読み値)
    output logic [7:0] p_out,   // レジスタデータ
    input  logic p_src,         // 書き込みデータ選択
    input  logic [7:0] p_write  // 書き込みイネーブル
);

    logic [7:0] p = 8'h34;
    logic [7:0] p_next;

    assign p_out = p;
    assign p_next = p_src ? wd1 : wd0;

    always_ff @(posedge clk) begin
        if (reset) begin
            p <= 8'h34;
        end else if (cpu_en) begin
            for (int i = 0; i < 8; i++) begin
                if (p_write[i]) begin
                    p[i] <= p_next[i];
                end
            end
            p[5] <= 1'b1;
        end
    end
    
endmodule
