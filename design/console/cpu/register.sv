// 通常のレジスタ

module register (
    input  logic clk,
    input  logic reset,
    input  logic cpu_en,
    input  logic [7:0] wd0,     // 書き込みデータ1 (alu_y)
    input  logic [7:0] wd1,     // 書き込みデータ2 (メモリからの読み値)
    output logic [7:0] rg_out,  // レジスタデータ
    input  logic wd_src,        // 書き込みデータ選択
    input  logic write          // 書き込みイネーブル
);

    logic [7:0] rg = 8'b0;
    logic [7:0] rg_next;

    assign rg_out = rg;
    assign rg_next = wd_src ? wd1 : wd0;

    always_ff @(posedge clk) begin
        if (reset) begin
            rg <= 8'b0;
        end else if (cpu_en & write) begin
            rg <= rg_next;
        end
    end
    
endmodule
