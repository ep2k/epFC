// OPレジスタ

module op_register (
    input  logic clk,
    input  logic reset,
    input  logic cpu_en,
    input  logic [7:0] wd,      // 書き込みデータ (メモリからの読み値)
    output logic [7:0] op_out,  // レジスタデータ
    input  logic op_write       // 書き込みイネーブル
);

    logic [7:0] op = 8'b0;
    assign op_out = op;

    always_ff @(posedge clk) begin
        if (reset) begin
            op <= 8'b0;
        end else if (cpu_en & op_write) begin
            op <= wd;
        end
    end
    
endmodule
