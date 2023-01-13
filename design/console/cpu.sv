module cpu (
    input  logic clk,
    input  logic cpu_en,
    input  logic reset,

    output logic [15:0] mem_addr,
    input  logic [7:0] mem_rdata,
    output logic [7:0] mem_wdata,
    output logic mem_read,
    output logic mem_write,

    input  logic nmi,
    input  logic irq
);

    logic [7:0] addr_high, addr_low;

    logic [2:0] addr_high_src;
    logic [1:0] addr_low_src;

    logic [7:0] alu_a, alu_b, alu_y;
    logic [3:0] alu_flgs;
    logic [3:0] alu_a_src;
    logic [2:0] alu_b_src;
    logic [3:0] alu_control;

    logic [7:0] a, x, y, s, p, op, al, ah, data;
    logic [15:0] pc;
 
    logic a_src, x_src, y_src, s_src, p_src, pcl_src, pch_src, ah_src, data_src;
    logic [1:0] al_src;

    logic [7:0] p_next;

    logic a_write, x_write, y_write, s_write, pcl_write, pch_write;
    logic op_write, al_write, ah_write, data_write;
    logic [7:0] p_write;

    logic pc_inc, s_inc, s_dec;

    logic [7:0] val;
    logic [1:0] val_select;


    // ------ Controller --------------

    cpu_controller controller(
        .clk,
        .cpu_en,
        .op,
        .p,
        .reset,
        .nmi,
        .irq,
        .alu_flgs,
        .pcl_m(pc[7]),
        .al_m(al[7]),

        .addr_high_src,
        .addr_low_src,
        .mem_read,
        .mem_write,

        .alu_a_src,
        .alu_b_src,
        .alu_control,

        .a_src,
        .x_src,
        .y_src,
        .s_src,
        .p_src,
        .pcl_src,
        .pch_src,
        .al_src,
        .ah_src,
        .data_src,

        .p_next,
        .val_select,

        .a_write,
        .x_write,
        .y_write,
        .s_write,
        .pcl_write,
        .pch_write,
        .op_write,
        .al_write,
        .ah_write,
        .data_write,
        .p_write,

        .pc_inc,
        .s_inc,
        .s_dec
    );

    // ------ Memory --------------

    always_comb begin
        case (addr_high_src)
            3'b000: addr_high = pc[15:8];
            3'b001: addr_high = ah;
            3'b100: addr_high = 8'h00;
            3'b101: addr_high = 8'h01;
            3'b110: addr_high = 8'hff;
            default: addr_high = pc[15:8];
        endcase
    end
    always_comb begin
        case (addr_low_src)
            2'b00: addr_low = pc[7:0];
            2'b01: addr_low = al;
            2'b10: addr_low = s;
            default: addr_low = pc[7:0];
        endcase
    end

    assign mem_addr = {addr_high, addr_low};
    assign mem_wdata = alu_y;

    // ------ ALU --------------
    
    always_comb begin
        case (alu_a_src)
            4'b0000: alu_a = a;
            4'b0001: alu_a = x;
            4'b0010: alu_a = y;
            4'b0011: alu_a = s;
            4'b0100: alu_a = p;
            4'b0101: alu_a = pc[15:8];
            4'b0110: alu_a = pc[7:0];
            4'b1000: alu_a = al;
            4'b1001: alu_a = ah;
            4'b1010: alu_a = data;
            4'b1111: alu_a = mem_rdata;
            default: alu_a = a;
        endcase
    end

    always_comb begin
        case (alu_b_src)
            3'b000: alu_b = 8'h00;
            3'b001: alu_b = 8'h01;
            3'b010: alu_b = y;
            3'b011: alu_b = al;
            3'b111: alu_b = mem_rdata;
            default: alu_b = 8'h00;
        endcase
    end

    alu alu(
        .a(alu_a),
        .b(alu_b),
        .c(p[0]),
        .y(alu_y),
        .flgs(alu_flgs),
        .control(alu_control)
    );

    // ------ Register --------------

    always_comb begin
        case (val_select)
            2'b00: val = 8'hfa;
            2'b01: val = 8'hfc;
            2'b10: val = 8'hfe;
            default: val = 8'hfa;
        endcase
    end

    register reg_a(
        .clk,
        .reset,
        .cpu_en,
        .wd0(alu_y),
        .wd1(mem_rdata),
        .rg_out(a),
        .wd_src(a_src),
        .write(a_write)
    );

    register reg_x(
        .clk,
        .reset,
        .cpu_en,
        .wd0(alu_y),
        .wd1(mem_rdata),
        .rg_out(x),
        .wd_src(x_src),
        .write(x_write)
    );

    register reg_y(
        .clk,
        .reset,
        .cpu_en,
        .wd0(alu_y),
        .wd1(mem_rdata),
        .rg_out(y),
        .wd_src(y_src),
        .write(y_write)
    );

    s_register reg_s(
        .clk,
        .reset,
        .cpu_en,
        .wd0(alu_y),
        .wd1(mem_rdata),
        .s_out(s),
        .s_src,
        .s_write,
        .s_inc,
        .s_dec
    );

    p_register reg_p(
        .clk,
        .reset,
        .cpu_en,
        .wd0(p_next),
        .wd1(mem_rdata),
        .p_out(p),
        .p_src,
        .p_write
    );

    pc_register reg_pc(
        .clk,
        .reset,
        .cpu_en,
        .wd0(alu_y),
        .wd1(mem_rdata),
        .pc_out(pc),
        .pcl_src,
        .pch_src,
        .pcl_write,
        .pch_write,
        .pc_inc
    );

    op_register reg_op(
        .clk,
        .reset,
        .cpu_en,
        .wd(mem_rdata),
        .op_out(op),
        .op_write
    );

    al_register reg_al(
        .clk,
        .reset,
        .cpu_en,
        .wd00(alu_y),
        .wd01(mem_rdata),
        .wd10(val),
        .al_out(al),
        .al_src,
        .al_write
    );

    register reg_ah(
        .clk,
        .reset,
        .cpu_en,
        .wd0(alu_y),
        .wd1(mem_rdata),
        .rg_out(ah),
        .wd_src(ah_src),
        .write(ah_write)
    );

    register reg_data(
        .clk,
        .reset,
        .cpu_en,
        .wd0(alu_y),
        .wd1(mem_rdata),
        .rg_out(data),
        .wd_src(data_src),
        .write(data_write)
    );

endmodule
