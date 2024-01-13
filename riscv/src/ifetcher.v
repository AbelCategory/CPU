`define IDLE 3'b000
`define BUSY 3'b001
`define STALL 3'b010
`define WORK 3'b011
`define CACHE_SIZE 255:0

module ifetcher (
    input wire clk,
    input wire rst,
    input wire rdy,

    // input wire        from_ic_hit,
    // input wire [31:0] from_ic_data,
    // output wire        to_ic_ready,
    // output wire [31:0] to_ic_addr,

    
    input wire        from_mctr_ok,
    input wire [31:0] from_mctr_data,
    output reg        to_mctr_ready,
    output reg [31:0] to_mctr_addr,

    input wire rs_full,
    input wire lsb_full,
    input wire rob_full,

    input wire        from_decoder_ok,
    input wire [31:0] from_decoder_pc,  
    
    output reg        to_decoder_ready,
    output reg [31:0] to_decoder_data,
    output reg [31:0] to_decoder_pc,
    output reg        to_decoder_isjp,

    // input wire        from_predictor_ok,
    // input wire 
    input wire [31:0] from_predictor_npc,
    output wire [31:0] to_predictor_pc,
    output wire [31:0] to_predictor_ins,
    input wire is_jp,

    input wire        from_rob_set,
    input wire [31:0] from_rob_pc
);
reg [31:0] pc;
wire [31:0] next_pc = from_predictor_npc;
reg [2:0] stat;

assign to_predictor_pc = pc;
assign to_predictor_ins = cData[index];

// assign to_ic_addr = pc;
// assign to_ic_ready = stat != `STALL;

integer i;

reg [31:0] cData[`CACHE_SIZE];
reg cValid[`CACHE_SIZE];
reg [31:10] cTag[`CACHE_SIZE];

wire [7:0] index;
wire [21:0] tag;
wire cache_hit = cValid[index] && cTag[index] == tag;
assign index = pc[9:2];
assign tag = pc[31:10];


always @(posedge clk) begin
    // $display("%d ",);
    if (rst) begin
        pc <= 0;
        stat <= `IDLE;
        for (i = 0; i < 256; ++i) begin
            cData[i] <= 0;
            cValid[i] <= 0;
            cTag[i] <= 0;
        end
        // to_if_ok <= 0;
        to_mctr_ready <= 0;
    // $display("yfygfyiyi %d %d %d %d %d\n", clk, rst, pc, to_decoder_pc, to_ic_addr);
    end
    else if(!rdy) begin

    end
    else if(from_rob_set) begin
        to_decoder_ready <= 0;
        pc <= from_rob_pc;
        stat <= `IDLE;
        to_mctr_ready <= 0;
        // stat <= `WORK;
    end
    else begin
        if (stat == `STALL) begin
            if (from_decoder_ok) begin
                to_decoder_ready <= 0;
                pc <= from_decoder_pc;
                // to_ic_ready <= 0;
                to_mctr_ready <= 0;
                stat <= `IDLE;
            end
        end
        else if(stat == `IDLE) begin
            stat <= `BUSY;
            to_decoder_ready <= 0;
            if (!cache_hit) begin
                to_mctr_ready <= 1;
                to_mctr_addr <= pc;
            end
        end
        else if (cache_hit) begin
            // to_predictor_ins <= from_ic_data;
            if (!rob_full && !lsb_full) begin 
                to_decoder_data <= cData[index];
                to_decoder_pc <= pc;
                to_decoder_ready <= 1;
                to_decoder_isjp <= is_jp;

                pc <= next_pc;
                stat <= cData[index][6:0] != 7'b1100111 ? `IDLE : `STALL;
            end
            else begin
                to_decoder_ready <= 0;
            end
            // stat <= `IDLE;
        end
        else begin
            to_decoder_ready <= 0;
            if (from_mctr_ok) begin
                cValid[index] <= 1;
                cTag[index] <= tag;
                cData[index] <= from_mctr_data;

                to_mctr_ready <= 0;
            end
        end
    end
end
endmodule //ifetcher
