`include "define.v"

`define IDLE 3'b000
`define IFETCH 3'b001
module mem_ctrl (
    input wire clk,
    input wire rst,
    input wire rdy,
    
    input wire        from_ic_ready,
    input wire [31:0] from_ic_addr,
    output reg        to_ic_ready,
    output reg [31:0] to_ic_data,

    input wire        io_buffer_full,
    input wire [ 7:0] from_mem_data,
    output reg [ 7:0] to_mem_data,
    output reg [31:0] to_mem_addr,
    output reg        mem_wr,

    input wire        from_lsb_ready,
    input wire [31:0] from_lsb_addr,
    input wire [ 5:0] from_lsb_op
);
reg [2:0] stat;
reg [1:0] if_index;
reg ic_ok, lsb_ok;

always @(posedge clk) begin
    if (rst) begin
        to_ic_data <= 0;
        to_ic_ready <= 0;
        to_mem_addr <= 0;
        to_mem_data <= 0;
        mem_wr <= 0;
    end
    else if (!rdy) begin
        
    end
    else begin
        if (ic_ok) begin
            ic_ok <= 0;
            to_ic_ready <= 0;
        end
        if (stat == `IDLE) begin
            if (from_ic_ready) begin
                stat = `IFETCH;
                if_index = 2'b00;
            end
        end
        else if(stat == `IFETCH && from_ic_ready) begin
            case (if_index)
                2'b00 : begin
                    to_ic_data[ 7: 0] <= from_mem_data;
                    if_index = 2'b01;
                end
                2'b01 : begin
                    to_ic_data[15 : 8] <= from_mem_data;
                    if_index = 2'b10;
                end
                2'b10 : begin
                    to_ic_data[23:16] <= from_mem_data;
                    if_index = 2'b11;
                end
                2'b11 : begin
                    to_ic_data[31:24] <= from_mem_data;
                    to_ic_ready = 1;
                    if_index = 2'b00;
                    ic_ok = 1;
                end
            endcase
        end
        else if(stat == `) begin
            
        end
    end
end
endmodule //mem_ctrl
