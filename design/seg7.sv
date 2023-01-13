module seg7 (
    input  logic [3:0] idat,
    output logic [6:0] odat
);

    always_comb begin
        case (idat)
            4'h0: odat = 7'b1000000;
            4'h1: odat = 7'b1111001;
            4'h2: odat = 7'b0100100;
            4'h3: odat = 7'b0110000;
            4'h4: odat = 7'b0011001;
            4'h5: odat = 7'b0010010;
            4'h6: odat = 7'b0000010;
            4'h7: odat = 7'b1011000;
            4'h8: odat = 7'b0000000;
            4'h9: odat = 7'b0010000;
            4'ha: odat = 7'b0001000;
            4'hb: odat = 7'b0000011;
            4'hc: odat = 7'b1000110;
            4'hd: odat = 7'b0100001;
            4'he: odat = 7'b0000110;
            4'hf: odat = 7'b0001110;
            default: odat = 7'b1111111;
        endcase
    end
    
endmodule
