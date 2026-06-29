module counting_ones #(
    parameter int DATA_WIDTH = 16
) (
    input  logic [DATA_WIDTH-1:0]      din,
    output logic [$clog2(DATA_WIDTH):0] dout
);

    // This module computes a popcount:
    //
    //   dout = number of 1 bits in din
    //
    // Example:
    //
    //   din  = 16'b0000_0000_1011_0101
    //   dout = 5
    //
    // The simple way is:
    //
    //   count = din[0] + din[1] + din[2] + ...
    //
    // But that can synthesize into a long chain of adders.
    // Here we build a balanced adder tree instead.

    // The largest possible answer is DATA_WIDTH.
    //
    // If DATA_WIDTH = 16, the largest count is 16.
    // 16 decimal is 5'b10000, so we need 5 bits.
    //
    // $clog2(16) is 4, which only gives enough bits to represent 0..15.
    // That is why we add 1.
    localparam int COUNT_WIDTH = $clog2(DATA_WIDTH) + 1;

    // A binary tree halves the number of values at every level.
    //
    // If DATA_WIDTH = 16:
    //
    //   level 0: 16 values
    //   level 1:  8 values
    //   level 2:  4 values
    //   level 3:  2 values
    //   level 4:  1 value
    //
    // So we need 4 reduction levels.
    //
    // $clog2(16) = 4.
    //
    // If DATA_WIDTH = 10, $clog2(10) = 4 too, because 2^4 = 16 is
    // the next power of two large enough to hold 10 input bits.
    localparam int LEVELS = $clog2(DATA_WIDTH);

    // PAD_WIDTH is the number of leaves in the internal tree.
    //
    // It is DATA_WIDTH rounded up to the next power of two.
    //
    // If DATA_WIDTH = 16:
    //
    //   PAD_WIDTH = 16
    //
    // If DATA_WIDTH = 10:
    //
    //   PAD_WIDTH = 16
    //
    // The extra 6 leaves are tied to zero. They do not change the sum.
    // They just make the tree shape regular:
    //
    //   16 -> 8 -> 4 -> 2 -> 1
    localparam int PAD_WIDTH = 1 << LEVELS;

    // level is a 2D unpacked array of partial sums.
    //
    // Think of it as:
    //
    //   level[which_tree_level][which_node_in_that_level]
    //
    // The packed part:
    //
    //   logic [COUNT_WIDTH-1:0]
    //
    // means each partial sum is COUNT_WIDTH bits wide.
    //
    // The unpacked part:
    //
    //   [0:LEVELS][0:PAD_WIDTH-1]
    //
    // means we have LEVELS+1 rows, and PAD_WIDTH slots per row.
    //
    // Many of those slots are unused at higher levels. That is okay.
    // Example with DATA_WIDTH = 16:
    //
    //   level[0][0..15] are leaves
    //   level[1][0..7]  are sums of 2 leaves
    //   level[2][0..3]  are sums of 4 leaves
    //   level[3][0..1]  are sums of 8 leaves
    //   level[4][0]     is the final sum
    logic [COUNT_WIDTH-1:0] level [0:LEVELS][0:PAD_WIDTH-1];

    genvar i;
    genvar j;
    genvar k;

    generate
        // --------------------------------------------------------------------
        // Build tree level 0.
        //
        // level[0] is the leaf level of the tree.
        //
        // For real input bits:
        //
        //   level[0][i] = din[i]
        //
        // For padded leaves beyond DATA_WIDTH:
        //
        //   level[0][i] = 0
        //
        // Example with DATA_WIDTH = 10 and PAD_WIDTH = 16:
        //
        //   level[0][0]  = din[0]
        //   ...
        //   level[0][9]  = din[9]
        //   level[0][10] = 0
        //   ...
        //   level[0][15] = 0
        // --------------------------------------------------------------------
        for (i = 0; i < PAD_WIDTH; i++) begin : gen_input_level
            if (i < DATA_WIDTH) begin : gen_real_input
                assign level[0][i] = din[i];
            end else begin : gen_padding_input
                assign level[0][i] = '0;
            end
        end

        for (j = 1; j <= LEVELS; j++) begin : gen_sum_level
            // LEVELS is the number of reduction levels after the base input
            // level.
            //
            // level[0] is the padded input bits.
            // level[1] sums pairs of level[0].
            // level[2] sums pairs of level[1].
            // ...
            // level[LEVELS] contains the single final popcount result.
            for (k = 0; k < (PAD_WIDTH >> j); k++) begin : gen_sum_node
                // At destination level j, this is the number of nodes to build:
                //
                //   PAD_WIDTH >> j
                //
                // If PAD_WIDTH = 8:
                //
                //   j = 1 -> 8 >> 1 = 4 nodes in level[1]
                //   j = 2 -> 8 >> 2 = 2 nodes in level[2]
                //   j = 3 -> 8 >> 3 = 1 node  in level[3]
                //
                // Each node adds two adjacent nodes from the previous level.
                assign level[j][k] = level[j-1][2*k] + level[j-1][2*k + 1];
            end
        end
    endgenerate

    // The final answer lives at the root of the tree.
    //
    // For DATA_WIDTH = 16:
    //
    //   dout = level[4][0]
    //
    // For DATA_WIDTH = 10:
    //
    //   dout = level[4][0]
    //
    // because 10 was padded up to a 16-leaf tree.
    assign dout = level[LEVELS][0];

endmodule