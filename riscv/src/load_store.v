`define LSB_SIZE 15:0
`define LSB_LEN 16
module LSB (
    input wire clk,
    input wire rst,
    inout wire rdy,

    input wire        from_dc_ok,
    input wire [31:0] vj, vk,
    input wire [ 4:0] qj, qk, en,
    input wire [ 5:0] opt,
    
    output wire is_lsb_full,

    input wire        CDB_1_ok,
    input wire [ 4:0] CDB_1_en,
    input wire [31:0] CDB_1_val,

    input wire        CDB_2_ok,
    input wire [ 4:0] CDB_2_en,
    input wire [31:0] CDB_2_val,

    input wire clear
);

reg [ 5:0] op[`LSB_SIZE];
reg [31:0] Vj[`LSB_SIZE], Vk[`LSB_SIZE];
reg [ 4:0] Qj[`LSB_SIZE], Qk[`LSB_SIZE], Qr[`LSB_SIZE];
reg [ 3:0] L, R;
integer i;
assign is_lsb_full = (L == R + 1) && from_dc_ok;

always @(posedge clk) begin
    if (rst) begin
        L <= 0;
        R <= 0;
        for (i = 0; i < `LSB_LEN; ++i) begin
            Qj[i] <= 0;
            Qk[i] <= 0;
        end
    end
    else if(!rdy) begin
        
    end
    else if(clear) begin
        
    end
    else begin
        if (from_dc_ok) begin
            op[R] <= opt; Qr[i] <= en;
            Vj[R] <= vj; Vk[R] <= vk;
            Qj[R] <= qj; Qk[R] <= qk;
            R <= R + 1;
        end
    end
end
endmodule //LSB
