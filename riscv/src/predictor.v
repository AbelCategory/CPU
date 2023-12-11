module predictor (
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire [31:0] pc_cur,
    input wire [31:0] ins,
    output wire [31:0] pc_pred
);
assign pc_pred = pc_cur + 4;
endmodule //predictor
