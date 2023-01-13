module alu (
    input  logic [7:0] a,
    input  logic [7:0] b,
    input  logic c,
    output logic [7:0] y,
    output logic [3:0] flgs,    // {N,V,Z,C}
    input  logic [3:0] control
);

    localparam C = 0, Z = 1, V = 2, N = 3;

    always_comb begin
        flgs[C] = 1'b0;
        case (control)
            4'b0000: {flgs[C], y} = ({1'b0, a} + {1'b0, b});                    // ADD
            4'b0001: {flgs[C], y} = ({1'b0, a} + {1'b0, b} + {8'h00, c});       // ADC
            4'b0010: {flgs[C], y} = ({1'b0, a} + {1'b0, (~b)} + 9'd1);          // SUB
            4'b0011: {flgs[C], y} = ({1'b0, a} + {1'b0, (~b)} + {8'h00, c});    // SBC
            4'b0100: y = a & b;                                                 // AND
            4'b0101: y = a & b;                                                 // BIT
            4'b0110: y = a | b;                                                 // OR
            4'b0111: y = a ^ b;                                                 // EOR
            4'b1000: {flgs[C], y} = {a, 1'b0};                                  // ASL
            4'b1010: {y, flgs[C]} = {1'b0, a};                                  // LSR
            4'b1001: {flgs[C], y} = {a, c};                                     // ROL
            4'b1011: {y, flgs[C]} = {c, a};                                     // ROR
            default: {flgs[C], y} = a + b;
        endcase
    end

    assign flgs[N] = (control == 4'b0101) ? b[7] : y[7];
    assign flgs[V] = (control == 4'b0101) ? b[6] :
        ((~(a[7] ^ (b[7] ^ control[1]))) & (a[7] ^ y[7]));
    assign flgs[Z] = (y == 8'h00);
    
endmodule
