// PCレジスタ

module pc_register (
    input  logic clk,
    input  logic reset,
    input  logic cpu_en,
    input  logic [7:0] wd0,     // 書き込みデータ1 (alu_y)
    input  logic [7:0] wd1,     // 書き込みデータ2 (メモリからの読み値)
    output logic [15:0] pc_out, // レジスタデータ
    input  logic pcl_src,       // PCLへの書き込みデータ選択
    input  logic pch_src,       // PCLへの書き込みデータ選択
    input  logic pcl_write,     // PCLの書き込みイネーブル
    input  logic pch_write,     // PCHの書き込みイネーブル
    input  logic pc_inc         // インクリメント
);

    logic [15:0] pc = 16'b0;
    logic [7:0] pcl_next, pch_next;

    assign pc_out = pc;
    assign pcl_next = pcl_src ? wd1 : wd0;
    assign pch_next = pch_src ? wd1 : wd0;

    always_ff @(posedge clk) begin
        if (reset) begin
            pc <= 16'b0;
        end else if (cpu_en) begin
            if (pc_inc) begin
                pc <= pc + 16'b1;
            end else begin
                if (pcl_write) begin
                    pc[7:0] <= pcl_next;
                end
                if (pch_write) begin
                    pc[15:8] <= pch_next;
                end
            end
        end
    end
    
endmodule
