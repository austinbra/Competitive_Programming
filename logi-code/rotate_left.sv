module rotate_left (
  input  logic [7:0] in,
  input  logic [2:0] shift,
  output logic [7:0] out
);
    localparam [$clog2($bits(in)-1):0] WIDTH = $bits(in);
    localparam [$clog2($bits(shift)-1):0] SHIFT_WIDTH = $bits(shift);

    genvar i;
    generate
        if (WIDTH == 1) begin : GEN_WIDTH_1
            assign out = in;
        end else begin : GEN_ROTATE
            logic [WIDTH-1:0] stage [0:SHIFT_WIDTH];

            assign stage[0] = in;

            for (i = 0; i < SHIFT_WIDTH; i = i + 1) begin : ROT_STAGE
                localparam int AMT = 1 << i;

                assign stage[i+1] =
                    shift[i]
                        ? {stage[i][WIDTH-AMT-1:0], stage[i][WIDTH-1:WIDTH-AMT]}
                        : stage[i];
            end

            assign out = stage[SHIFT_WIDTH];
        end
    endgenerate
endmodule