module index_counter #(
    parameter WIDTH      = 3,
    parameter LAST_VALUE = 7
)(
    input  wire              clk,
    input  wire              rst_n,

    input  wire              clear,
    input  wire              enable,
    input  wire              wrap,

    output reg  [WIDTH-1:0]  count,
    output wire              last,
    output reg               done_pulse
);

    /*
        Generic index counter.

        For this project:

            WIDTH      = 3
            LAST_VALUE = 7

        Sequence:

            0, 1, 2, 3, 4, 5, 6, 7

        If enable is high when count == LAST_VALUE:
            done_pulse goes high for one clock cycle.

        If wrap = 1:
            counter returns to 0 after LAST_VALUE.

        If wrap = 0:
            counter stays at LAST_VALUE.
    */

    localparam [WIDTH-1:0] LAST_VALUE_W = LAST_VALUE;

    assign last = (count == LAST_VALUE_W);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count      <= {WIDTH{1'b0}};
            done_pulse <= 1'b0;
        end else begin
            done_pulse <= 1'b0;

            if (clear) begin
                count <= {WIDTH{1'b0}};
            end else if (enable) begin
                if (last) begin
                    done_pulse <= 1'b1;

                    if (wrap) begin
                        count <= {WIDTH{1'b0}};
                    end else begin
                        count <= count;
                    end
                end else begin
                    count <= count + {{(WIDTH-1){1'b0}}, 1'b1};
                end
            end
        end
    end

endmodule
