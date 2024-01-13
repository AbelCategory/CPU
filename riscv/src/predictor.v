`define BHT_SIZE 255:0
`define BHT_LEN 256

module predictor (
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire [31:0] pc_cur,
    input wire [31:0] ins,
    output reg [31:0] pc_next,
    output reg is_jump,
    // output reg [31:0] pc_nnxt,

    input wire from_rob_ok,
    input wire rob_is_jump,
    input wire [31:0] data
);
reg [1:0] BHT[`BHT_SIZE];
integer i;
wire [8:0] bht_pos, add_pos;
assign bht_pos = data[10:2];

always @(posedge clk) begin
    if (rst) begin
        for (i = 0; i < `BHT_LEN; i = i + 1) begin
            BHT[i] <= 0;
        end
    end
    else if (!rdy) begin
        
    end
    else if(from_rob_ok) begin
        if (rob_is_jump) begin
            if (BHT[bht_pos] != 3) BHT[bht_pos] <= BHT[bht_pos] + 1;
        end
        else begin
            if (BHT[bht_pos] != 0) BHT[bht_pos] <= BHT[bht_pos] - 1;
        end
    end
end

assign add_pos = pc_cur[10:2];

always @(*) begin
    case (ins[6:0])
        7'b1101111 : begin //JAL
            pc_next = pc_cur + {{12{ins[31]}}, ins[19:12], ins[20], ins[30:21], 1'b0};
            is_jump = 1;
        end
        7'b1100011 : begin // Branch
            if (BHT[add_pos] >= 2'b10) begin
                pc_next = pc_cur + {{20{ins[31]}}, ins[7], ins[30:25], ins[11:8], 1'b0};
                is_jump = 1;
            end
            else begin
                pc_next = pc_cur + 4;
                is_jump = 0;
            end
        end
        default: begin
            pc_next = pc_cur + 4;
            is_jump = 0;
        end
    endcase
end
endmodule //predictor
