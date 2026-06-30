module alu (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [5:0]  aluc,
    output logic [31:0] r,
    output logic        zero,
    output logic        carry,
    output logic        negative,
    output logic        overflow,
    output logic        flag
);

    localparam logic [5:0]
        ADD  = 6'b100000,
        ADDU = 6'b100001,
        SUB  = 6'b100010,
        SUBU = 6'b100011,
        AND_ = 6'b100100,
        OR_  = 6'b100101,
        XOR_ = 6'b100110,
        NOR_ = 6'b100111,
        SLT  = 6'b101010,
        SLTU = 6'b101011,
        SLL  = 6'b000000,
        SRL  = 6'b000010,
        SRA  = 6'b000011,
        SLLV = 6'b000100,
        SRLV = 6'b000110,
        SRAV = 6'b000111,
        LUI  = 6'b001111;

    logic [31:0] result;
    logic [32:0] add_ext;
    logic [32:0] sub_ext;
    logic        valid_op;

    always_comb begin
        add_ext = {1'b0, a} + {1'b0, b};
        sub_ext = {1'b0, a} + {1'b0, ~b} + 33'd1;

        result   = 32'bz;
        carry    = 1'b0;
        overflow = 1'b0;
        flag     = 1'bz;
        valid_op = 1'b1;

        case (aluc)

            ADD: begin
                result   = add_ext[31:0];
                carry    = add_ext[32];
                overflow = (a[31] == b[31]) && (result[31] != a[31]);
            end

            ADDU: begin
                result   = add_ext[31:0];
                carry    = add_ext[32];
                overflow = 1'b0;
            end

            SUB: begin
                result   = sub_ext[31:0];
                carry    = sub_ext[32]; // 1 = no borrow, 0 = borrow
                overflow = (a[31] != b[31]) && (result[31] != a[31]);
            end

            SUBU: begin
                result   = sub_ext[31:0];
                carry    = sub_ext[32]; // 1 = no borrow, 0 = borrow
                overflow = 1'b0;
            end

            AND_: begin
                result = a & b;
            end

            OR_: begin
                result = a | b;
            end

            XOR_: begin
                result = a ^ b;
            end

            NOR_: begin
                result = ~(a | b);
            end

            SLT: begin
                flag   = ($signed(a) < $signed(b));
                result = {31'd0, flag};
            end

            SLTU: begin
                flag   = (a < b);
                result = {31'd0, flag};
            end

            SLL: begin
                result = b << a;
            end

            SRL: begin
                result = b >> a;
            end

            SRA: begin
                result = $signed(b) >>> a;
            end

            SLLV: begin
                result = b << a[4:0];
            end

            SRLV: begin
                result = b >> a[4:0];
            end

            SRAV: begin
                result = $signed(b) >>> a[4:0];
            end

            LUI: begin
                result = {a[15:0], 16'h0000};
            end

            default: begin
                valid_op = 1'b0;
                result   = 32'bz;
                carry    = 1'bz;
                overflow = 1'bz;
                flag     = 1'bz;
            end

        endcase

        r = result;

        zero = (result === 32'd0);

        if (valid_op) begin
            negative = result[31];
        end else begin
            negative = 1'bz;
        end
    end

endmodule

/*aluc     OP     Behavior
100000     ADD    r = a + b (signed)
100001     ADDU   r = a + b (unsigned)
100010     SUB    r = a - b (signed)
100011     SUBU   r = a - b (unsigned)
100100     AND    r = a & b
100101     OR     r = a | b
100110     XOR    r = a ⊕ b
100111     NOR    r = ~(a | b)
101010     SLT    r = 1 if a < b (signed), else 0; also sets flag
101011     SLTU   r = 1 if a < b (unsigned), else 0; also sets flag
000000     SLL    r = b << a
000010     SRL    r = b >> a (logical)
000011     SRA    r = b >>> a (arithmetic)
000100     SLLV   r = b << a[4:0]
000110     SRLV   r = b >> a[4:0] (logical)
000111     SRAV   r = b >>> a[4:0] (arithmetic)
001111     LUI    r = a[15:0], 16'h0000

For any unrecognized aluc value, r is high-impedance.

zero is asserted when r equals 
0
0.

flag reflects the comparison result for SLT (a 
<
< b signed) and SLTU (a 
<
< b unsigned)
*/