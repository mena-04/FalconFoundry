module serial_fractional_divider #(
    parameter EXP_WIDTH   = 15,
    parameter DEN_WIDTH   = 18,
    parameter OUT_BITS    = 8,
    parameter OUT_FRAC    = 8,
    parameter COUNT_WIDTH = 4
)(
    input  wire                   clk,
    input  wire                   rst_n,

    input  wire                   start,

    input  wire [EXP_WIDTH-1:0]   numerator,
    input  wire [DEN_WIDTH-1:0]   denominator,

    output reg  [OUT_BITS-1:0]    quotient,
    output reg                    busy,
    output reg                    done,
    output reg                    div_by_zero
);

    /*
        This divider computes:

            quotient = floor((numerator / denominator) * 2^OUT_FRAC)

        For this project:

            OUT_BITS = 8
            OUT_FRAC = 8

        So the output is an 8-bit Q0.8 probability byte.

        The algorithm matches the Python model:

            rem = numerator
            quotient = 0

            repeat OUT_FRAC times:
                rem = rem << 1
                quotient = quotient << 1
                if rem >= denominator:
                    rem = rem - denominator
                    quotient_bit = 1
                else:
                    quotient_bit = 0

        Special case:
            numerator == denominator gives 8'b11111111 = 255,
            matching your Python model.
    */

    reg [DEN_WIDTH:0] rem;
    reg [DEN_WIDTH:0] den_reg;

    reg [OUT_BITS-1:0] quotient_work;
    reg [COUNT_WIDTH-1:0] bit_count;

    reg [DEN_WIDTH:0] rem_shift;
    reg [DEN_WIDTH:0] rem_after;
    reg quotient_bit;

    wire [DEN_WIDTH:0] numerator_ext;
    wire [DEN_WIDTH:0] denominator_ext;

    assign numerator_ext   = {{(DEN_WIDTH+1-EXP_WIDTH){1'b0}}, numerator};
    assign denominator_ext = {1'b0, denominator};

    always @* begin
        rem_shift = rem << 1;

        if (rem_shift >= den_reg) begin
            rem_after    = rem_shift - den_reg;
            quotient_bit = 1'b1;
        end else begin
            rem_after    = rem_shift;
            quotient_bit = 1'b0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rem           <= {(DEN_WIDTH+1){1'b0}};
            den_reg       <= {(DEN_WIDTH+1){1'b0}};
            quotient_work <= {OUT_BITS{1'b0}};
            bit_count     <= {COUNT_WIDTH{1'b0}};
            quotient      <= {OUT_BITS{1'b0}};
            busy          <= 1'b0;
            done          <= 1'b0;
            div_by_zero   <= 1'b0;
        end else begin
            done <= 1'b0;

            if (start && !busy) begin
                quotient      <= {OUT_BITS{1'b0}};
                quotient_work <= {OUT_BITS{1'b0}};
                bit_count     <= {COUNT_WIDTH{1'b0}};
                div_by_zero   <= 1'b0;

                if (denominator == {DEN_WIDTH{1'b0}}) begin
                    rem         <= {(DEN_WIDTH+1){1'b0}};
                    den_reg     <= {(DEN_WIDTH+1){1'b0}};
                    busy        <= 1'b0;
                    quotient    <= {OUT_BITS{1'b0}};
                    done        <= 1'b1;
                    div_by_zero <= 1'b1;
                end else begin
                    rem     <= numerator_ext;
                    den_reg <= denominator_ext;
                    busy    <= 1'b1;
                end

            end else if (busy) begin
                rem           <= rem_after;
                quotient_work <= {quotient_work[OUT_BITS-2:0], quotient_bit};

                if (bit_count == (OUT_FRAC - 1)) begin
                    quotient  <= {quotient_work[OUT_BITS-2:0], quotient_bit};
                    busy      <= 1'b0;
                    done      <= 1'b1;
                    bit_count <= {COUNT_WIDTH{1'b0}};
                end else begin
                    bit_count <= bit_count + {{(COUNT_WIDTH-1){1'b0}}, 1'b1};
                end
            end
        end
    end

endmodule
