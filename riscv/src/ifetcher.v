module ifetcher (
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire        from_ic_hit,
    input wire [31:0] from_ic_data,
    output reg        to_ic_ready,
    output reg [31:0] to_ic_addr,

    output reg [31:0] to_decoder_data
);
reg [31:0] pc;
reg [2:0] stat;
always @(posedge clk) begin
    if (rst) begin
        pc <= 0;
        to_ic_ready <= 0;
    end
    else if(!rst) begin
        
    end
    else begin
        
    end

end
endmodule //ifetcher
