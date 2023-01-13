// ALレジスタ

module al_register (
    input  logic clk,
    input  logic reset,
    input  logic cpu_en,
    input  logic [7:0] wd00,    // 書き込みデータ1 (alu_y)
    input  logic [7:0] wd01,    // 書き込みデータ2 (メモリからの読み値)
    input  logic [7:0] wd10,    // 書き込みデータ3 (VAL)
    output logic [7:0] al_out,  // レジスタデータ
    input  logic [1:0] al_src,  // 書き込みデータ選択
    input  logic al_write       // 書き込みイネーブル
);

    logic [7:0] al = 8'hfc;
    logic [7:0] al_next;

    assign al_out = al;

    always_comb begin
        case (al_src)
            2'b00: al_next = wd00;
            2'b01: al_next = wd01;
            2'b10: al_next = wd10;
            default: al_next = wd00;
        endcase
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            al <= 8'hfc;
        end else if (cpu_en & al_write) begin
            al <= al_next;
        end
    end
    
endmodule
