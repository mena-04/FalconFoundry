module delta_unit #(
    parameter IN_WIDTH  = 8,
    parameter MAG_WIDTH = 9
)(
    input  wire signed [IN_WIDTH-1:0]  x_q,
    input  wire signed [IN_WIDTH-1:0]  max_q,

    output wire signed [MAG_WIDTH-1:0] delta_q,
    output wire        [MAG_WIDTH-1:0] magnitude
);

    assign delta_q = $signed({x_q[IN_WIDTH-1], x_q}) -
                     $signed({max_q[IN_WIDTH-1], max_q});

    assign magnitude = (delta_q < 0) ? -delta_q : delta_q;

endmodule