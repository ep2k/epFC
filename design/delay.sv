module delay #(parameter DELAY_NUM = 150) ( // DELAY_NUMは偶数
    input  logic original,
    output logic delayed
);

    (* syn_keep=1 *) logic [DELAY_NUM - 1:1] inv;

    genvar i;

    generate
        for(i = 2; i < DELAY_NUM; ++i) begin: delay_block
            assign inv[i] = ~inv[i-1];
        end
    endgenerate

    assign inv[1] = ~original;
    assign delayed = ~inv[DELAY_NUM-1];
    
endmodule
