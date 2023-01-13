module color_to_rgb (
    input logic [5:0] pixel_color,
    output logic [11:0] rgb
);

    always_comb begin
        unique case (pixel_color)
            6'd00: rgb = 12'h666;
            6'd01: rgb = 12'h028;
            6'd02: rgb = 12'h11a;
            6'd03: rgb = 12'h309;
            6'd04: rgb = 12'h507;
            6'd05: rgb = 12'h603;
            6'd06: rgb = 12'h600;
            6'd07: rgb = 12'h420;
            6'd08: rgb = 12'h230;
            6'd09: rgb = 12'h140;
            6'd10: rgb = 12'h040;
            6'd11: rgb = 12'h040;
            6'd12: rgb = 12'h034;
            6'd13: rgb = 12'h000;
            6'd14: rgb = 12'h000;
            6'd15: rgb = 12'h000;
            6'd16: rgb = 12'haaa;
            6'd17: rgb = 12'h15d;
            6'd18: rgb = 12'h33f;
            6'd19: rgb = 12'h62f;
            6'd20: rgb = 12'h91c;
            6'd21: rgb = 12'hb17;
            6'd22: rgb = 12'ha22;
            6'd23: rgb = 12'h840;
            6'd24: rgb = 12'h660;
            6'd25: rgb = 12'h380;
            6'd26: rgb = 12'h180;
            6'd27: rgb = 12'h083;
            6'd28: rgb = 12'h078;
            6'd29: rgb = 12'h000;
            6'd30: rgb = 12'h000;
            6'd31: rgb = 12'h000;
            6'd32: rgb = 12'hfff;
            6'd33: rgb = 12'h5af;
            6'd34: rgb = 12'h88f;
            6'd35: rgb = 12'hc7f;
            6'd36: rgb = 12'hf6f;
            6'd37: rgb = 12'hf6c;
            6'd38: rgb = 12'hf77;
            6'd39: rgb = 12'he92;
            6'd40: rgb = 12'hbb0;
            6'd41: rgb = 12'h8d0;
            6'd42: rgb = 12'h5e2;
            6'd43: rgb = 12'h4e7;
            6'd44: rgb = 12'h4ce;
            6'd45: rgb = 12'h444;
            6'd46: rgb = 12'h000;
            6'd47: rgb = 12'h000;
            6'd48: rgb = 12'hfff;
            6'd49: rgb = 12'hbef;
            6'd50: rgb = 12'hddf;
            6'd51: rgb = 12'hecf;
            6'd52: rgb = 12'hfcf;
            6'd53: rgb = 12'hfce;
            6'd54: rgb = 12'hfcc;
            6'd55: rgb = 12'hfda;
            6'd56: rgb = 12'hee8;
            6'd57: rgb = 12'hcf8;
            6'd58: rgb = 12'hbfa;
            6'd59: rgb = 12'hafc;
            6'd60: rgb = 12'haef;
            6'd61: rgb = 12'hbbb;
            6'd62: rgb = 12'h000;
            6'd63: rgb = 12'h000;
        endcase
    end
    
endmodule
