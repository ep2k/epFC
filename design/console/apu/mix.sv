module mix (
    input  logic [3:0] pulse1_wave,
    input  logic [3:0] pulse2_wave,
    input  logic [3:0] tri_wave,
    input  logic [3:0] noise_wave,
    input  logic [6:0] dmc_wave,
    input  logic [4:0] mute,

    output logic [8:0] sum_wave
);

    logic [7:0] pulse_table;
    logic [8:0] tnd_table;
    
    logic [4:0] pulse_table_arg;
    logic [7:0] tnd_table_arg;

    logic [3:0] pulse1_wave_eff, pulse2_wave_eff;
    logic [3:0] tri_wave_eff, noise_wave_eff;
    logic [6:0] dmc_wave_eff;
    
    assign pulse1_wave_eff = mute[0] ? 4'h0 : pulse1_wave;
    assign pulse2_wave_eff = mute[1] ? 4'h0 : pulse2_wave;
    assign tri_wave_eff = mute[2] ? 4'h0 : tri_wave;
    assign noise_wave_eff = mute[3] ? 4'h0 : noise_wave;
    assign dmc_wave_eff = mute[4] ? 7'h0 : dmc_wave;

    assign pulse_table_arg = pulse1_wave_eff + pulse2_wave_eff;
    assign tnd_table_arg =
        tri_wave_eff + tri_wave_eff + tri_wave_eff
            + noise_wave_eff + noise_wave_eff + dmc_wave_eff;

    assign sum_wave = pulse_table + tnd_table;

    always_comb begin
        case (pulse_table_arg)
            5'd0: pulse_table = 8'd0;
            5'd1: pulse_table = 8'd6;
            5'd2: pulse_table = 8'd12;
            5'd3: pulse_table = 8'd17;
            5'd4: pulse_table = 8'd23;
            5'd5: pulse_table = 8'd28;
            5'd6: pulse_table = 8'd34;
            5'd7: pulse_table = 8'd39;
            5'd8: pulse_table = 8'd44;
            5'd9: pulse_table = 8'd49;
            5'd10: pulse_table = 8'd53;
            5'd11: pulse_table = 8'd58;
            5'd12: pulse_table = 8'd63;
            5'd13: pulse_table = 8'd67;
            5'd14: pulse_table = 8'd72;
            5'd15: pulse_table = 8'd76;
            5'd16: pulse_table = 8'd80;
            5'd17: pulse_table = 8'd84;
            5'd18: pulse_table = 8'd88;
            5'd19: pulse_table = 8'd92;
            5'd20: pulse_table = 8'd96;
            5'd21: pulse_table = 8'd100;
            5'd22: pulse_table = 8'd104;
            5'd23: pulse_table = 8'd108;
            5'd24: pulse_table = 8'd111;
            5'd25: pulse_table = 8'd115;
            5'd26: pulse_table = 8'd118;
            5'd27: pulse_table = 8'd122;
            5'd28: pulse_table = 8'd125;
            5'd29: pulse_table = 8'd128;
            5'd30: pulse_table = 8'd132;
            default: pulse_table = 8'd0;
        endcase
    end

    always_comb begin
        case (tnd_table_arg)
            8'd0: tnd_table = 9'd0;
            8'd1: tnd_table = 9'd3;
            8'd2: tnd_table = 9'd7;
            8'd3: tnd_table = 9'd10;
            8'd4: tnd_table = 9'd14;
            8'd5: tnd_table = 9'd17;
            8'd6: tnd_table = 9'd20;
            8'd7: tnd_table = 9'd23;
            8'd8: tnd_table = 9'd27;
            8'd9: tnd_table = 9'd30;
            8'd10: tnd_table = 9'd33;
            8'd11: tnd_table = 9'd36;
            8'd12: tnd_table = 9'd39;
            8'd13: tnd_table = 9'd42;
            8'd14: tnd_table = 9'd46;
            8'd15: tnd_table = 9'd49;
            8'd16: tnd_table = 9'd52;
            8'd17: tnd_table = 9'd55;
            8'd18: tnd_table = 9'd58;
            8'd19: tnd_table = 9'd61;
            8'd20: tnd_table = 9'd64;
            8'd21: tnd_table = 9'd66;
            8'd22: tnd_table = 9'd69;
            8'd23: tnd_table = 9'd72;
            8'd24: tnd_table = 9'd75;
            8'd25: tnd_table = 9'd78;
            8'd26: tnd_table = 9'd81;
            8'd27: tnd_table = 9'd84;
            8'd28: tnd_table = 9'd86;
            8'd29: tnd_table = 9'd89;
            8'd30: tnd_table = 9'd92;
            8'd31: tnd_table = 9'd95;
            8'd32: tnd_table = 9'd97;
            8'd33: tnd_table = 9'd100;
            8'd34: tnd_table = 9'd103;
            8'd35: tnd_table = 9'd105;
            8'd36: tnd_table = 9'd108;
            8'd37: tnd_table = 9'd110;
            8'd38: tnd_table = 9'd113;
            8'd39: tnd_table = 9'd116;
            8'd40: tnd_table = 9'd118;
            8'd41: tnd_table = 9'd121;
            8'd42: tnd_table = 9'd123;
            8'd43: tnd_table = 9'd126;
            8'd44: tnd_table = 9'd128;
            8'd45: tnd_table = 9'd131;
            8'd46: tnd_table = 9'd133;
            8'd47: tnd_table = 9'd135;
            8'd48: tnd_table = 9'd138;
            8'd49: tnd_table = 9'd140;
            8'd50: tnd_table = 9'd143;
            8'd51: tnd_table = 9'd145;
            8'd52: tnd_table = 9'd147;
            8'd53: tnd_table = 9'd150;
            8'd54: tnd_table = 9'd152;
            8'd55: tnd_table = 9'd154;
            8'd56: tnd_table = 9'd156;
            8'd57: tnd_table = 9'd159;
            8'd58: tnd_table = 9'd161;
            8'd59: tnd_table = 9'd163;
            8'd60: tnd_table = 9'd165;
            8'd61: tnd_table = 9'd168;
            8'd62: tnd_table = 9'd170;
            8'd63: tnd_table = 9'd172;
            8'd64: tnd_table = 9'd174;
            8'd65: tnd_table = 9'd176;
            8'd66: tnd_table = 9'd178;
            8'd67: tnd_table = 9'd181;
            8'd68: tnd_table = 9'd183;
            8'd69: tnd_table = 9'd185;
            8'd70: tnd_table = 9'd187;
            8'd71: tnd_table = 9'd189;
            8'd72: tnd_table = 9'd191;
            8'd73: tnd_table = 9'd193;
            8'd74: tnd_table = 9'd195;
            8'd75: tnd_table = 9'd197;
            8'd76: tnd_table = 9'd199;
            8'd77: tnd_table = 9'd201;
            8'd78: tnd_table = 9'd203;
            8'd79: tnd_table = 9'd205;
            8'd80: tnd_table = 9'd207;
            8'd81: tnd_table = 9'd209;
            8'd82: tnd_table = 9'd211;
            8'd83: tnd_table = 9'd213;
            8'd84: tnd_table = 9'd215;
            8'd85: tnd_table = 9'd217;
            8'd86: tnd_table = 9'd218;
            8'd87: tnd_table = 9'd220;
            8'd88: tnd_table = 9'd222;
            8'd89: tnd_table = 9'd224;
            8'd90: tnd_table = 9'd226;
            8'd91: tnd_table = 9'd228;
            8'd92: tnd_table = 9'd229;
            8'd93: tnd_table = 9'd231;
            8'd94: tnd_table = 9'd233;
            8'd95: tnd_table = 9'd235;
            8'd96: tnd_table = 9'd237;
            8'd97: tnd_table = 9'd238;
            8'd98: tnd_table = 9'd240;
            8'd99: tnd_table = 9'd242;
            8'd100: tnd_table = 9'd244;
            8'd101: tnd_table = 9'd245;
            8'd102: tnd_table = 9'd247;
            8'd103: tnd_table = 9'd249;
            8'd104: tnd_table = 9'd250;
            8'd105: tnd_table = 9'd252;
            8'd106: tnd_table = 9'd254;
            8'd107: tnd_table = 9'd255;
            8'd108: tnd_table = 9'd257;
            8'd109: tnd_table = 9'd259;
            8'd110: tnd_table = 9'd260;
            8'd111: tnd_table = 9'd262;
            8'd112: tnd_table = 9'd264;
            8'd113: tnd_table = 9'd265;
            8'd114: tnd_table = 9'd267;
            8'd115: tnd_table = 9'd268;
            8'd116: tnd_table = 9'd270;
            8'd117: tnd_table = 9'd272;
            8'd118: tnd_table = 9'd273;
            8'd119: tnd_table = 9'd275;
            8'd120: tnd_table = 9'd276;
            8'd121: tnd_table = 9'd278;
            8'd122: tnd_table = 9'd279;
            8'd123: tnd_table = 9'd281;
            8'd124: tnd_table = 9'd282;
            8'd125: tnd_table = 9'd284;
            8'd126: tnd_table = 9'd285;
            8'd127: tnd_table = 9'd287;
            8'd128: tnd_table = 9'd288;
            8'd129: tnd_table = 9'd290;
            8'd130: tnd_table = 9'd291;
            8'd131: tnd_table = 9'd293;
            8'd132: tnd_table = 9'd294;
            8'd133: tnd_table = 9'd296;
            8'd134: tnd_table = 9'd297;
            8'd135: tnd_table = 9'd298;
            8'd136: tnd_table = 9'd300;
            8'd137: tnd_table = 9'd301;
            8'd138: tnd_table = 9'd303;
            8'd139: tnd_table = 9'd304;
            8'd140: tnd_table = 9'd305;
            8'd141: tnd_table = 9'd307;
            8'd142: tnd_table = 9'd308;
            8'd143: tnd_table = 9'd310;
            8'd144: tnd_table = 9'd311;
            8'd145: tnd_table = 9'd312;
            8'd146: tnd_table = 9'd314;
            8'd147: tnd_table = 9'd315;
            8'd148: tnd_table = 9'd316;
            8'd149: tnd_table = 9'd318;
            8'd150: tnd_table = 9'd319;
            8'd151: tnd_table = 9'd320;
            8'd152: tnd_table = 9'd322;
            8'd153: tnd_table = 9'd323;
            8'd154: tnd_table = 9'd324;
            8'd155: tnd_table = 9'd325;
            8'd156: tnd_table = 9'd327;
            8'd157: tnd_table = 9'd328;
            8'd158: tnd_table = 9'd329;
            8'd159: tnd_table = 9'd331;
            8'd160: tnd_table = 9'd332;
            8'd161: tnd_table = 9'd333;
            8'd162: tnd_table = 9'd334;
            8'd163: tnd_table = 9'd336;
            8'd164: tnd_table = 9'd337;
            8'd165: tnd_table = 9'd338;
            8'd166: tnd_table = 9'd339;
            8'd167: tnd_table = 9'd340;
            8'd168: tnd_table = 9'd342;
            8'd169: tnd_table = 9'd343;
            8'd170: tnd_table = 9'd344;
            8'd171: tnd_table = 9'd345;
            8'd172: tnd_table = 9'd346;
            8'd173: tnd_table = 9'd348;
            8'd174: tnd_table = 9'd349;
            8'd175: tnd_table = 9'd350;
            8'd176: tnd_table = 9'd351;
            8'd177: tnd_table = 9'd352;
            8'd178: tnd_table = 9'd353;
            8'd179: tnd_table = 9'd355;
            8'd180: tnd_table = 9'd356;
            8'd181: tnd_table = 9'd357;
            8'd182: tnd_table = 9'd358;
            8'd183: tnd_table = 9'd359;
            8'd184: tnd_table = 9'd360;
            8'd185: tnd_table = 9'd361;
            8'd186: tnd_table = 9'd362;
            8'd187: tnd_table = 9'd363;
            8'd188: tnd_table = 9'd365;
            8'd189: tnd_table = 9'd366;
            8'd190: tnd_table = 9'd367;
            8'd191: tnd_table = 9'd368;
            8'd192: tnd_table = 9'd369;
            8'd193: tnd_table = 9'd370;
            8'd194: tnd_table = 9'd371;
            8'd195: tnd_table = 9'd372;
            8'd196: tnd_table = 9'd373;
            8'd197: tnd_table = 9'd374;
            8'd198: tnd_table = 9'd375;
            8'd199: tnd_table = 9'd376;
            8'd200: tnd_table = 9'd377;
            8'd201: tnd_table = 9'd378;
            8'd202: tnd_table = 9'd379;
            default: tnd_table = 9'd0;
        endcase
    end

endmodule
