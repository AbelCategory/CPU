`include "define.v"

`define IDLE 3'b000
`define IFETCH 3'b001
`define READ   3'b010
`define WRITE  3'b011
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
    input wire [ 5:0] from_lsb_op,
    input wire [31:0] from_lsb_imm,
    input wire [31:0] from_lsb_val,

    output reg        CDB_2_ok,
    output reg [ 4:0] CDB_2_en,
    output reg [31:0] CDB_2_val
);
reg [2:0] stat, rw_index, if_index, res_index;
reg [31:0] data;
reg ic_ok, lsb_ok, is_U;
reg [5:0] opt;
reg [31:0] val;

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
        if (CDB_2_ok) begin
           CDB_2_ok <= 0;
        end
        if (stat == `IDLE) begin
            if(from_lsb_ready) begin
                stat <= from_lsb_op[5:3] == 3'b111 ? `WRITE : `READ;
                to_mem_addr <= from_lsb_addr + from_lsb_imm;
                case (from_lsb_op)
                    `LB  : res <= 0;
                    `LH  : res <= 1;
                    `LW  : res <= 3;
                    `LBU : res <= 0;
                    `LHU : res <= 1;
                    `SB  : res <= 0;
                    `SH  : res <= 1;
                    `SW  : res <= 3;
                endcase
                if (from_lsb_op == `LBU || from_lsb_op == `LHU) begin
                    is_U <= 1;
                end
                mem_wr <= 0;
                if (from_lsb_op[5:3] == 3'b111) begin
                    data <= from_lsb_val;
                end
            end
            else if(from_ic_ready) begin
                stat <= `IFETCH;
                if_index <= 3'b000;
                mem_wr <= 0;
                to_mem_addr <= from_ic_addr;
            end
            
        end
        else if(stat == `IFETCH && from_ic_ready) begin
            case (if_index)
                3'b000 : begin
                    to_ic_data[ 7: 0] <= from_mem_data;
                    if_index <= 3'b001;
                    to_mem_addr <= to_mem_addr + 1;
                end
                3'b001 : begin
                    to_ic_data[15 : 8] <= from_mem_data;
                    if_index <= 3'b010;
                    to_mem_addr <= to_mem_addr + 1;
                end
                3'b010 : begin
                    to_ic_data[23:16] <= from_mem_data;
                    if_index <= 3'b011;
                    to_mem_addr <= to_mem_addr + 1;
                end
                3'b011 : begin
                    to_ic_data[31:24] <= from_mem_data;
                    to_ic_ready <= 1;
                    if_index <= 3'b100;
                    ic_ok <= 1;
                end
                3'b100 : begin
                    ic_ok <= 0;
                    stat = `IDLE;
                    if_index <= 3'b000;
                end
            endcase
        end
        else if(stat == `READ) begin
            case (rw_index)
                3'b000 : begin
                    data[7:0] <= from_mem_data;
                    if (res_index == 0) begin
                        if (!is_U) begin
                            data[31:8] <= {24{data[7]}};
                        end

                        rw_index <= 3'b100;
                    end
                    else begin
                        endrw_index <= 3'b001;
                        to_mem_addr <= to_mem_addr + 1;
                    end
                end
                3'b001 : begin
                    data[15:8] <= from_mem_data;
                    if (res_index == 1) begin
                        if (!is_U) begin
                            data[31:16] = {16{data[15]}};
                        end
                        rw_index <= 3'b100;
                    end
                    else begin
                        rw_index <= 3'b010;
                        to_mem_addr <= to_mem_addr + 1;
                    end
                end
                3'b010 : begin
                    data[23:16] <= from_mem_data;
                    rw_index <= 3'b011;
                    to_mem_addr <= to_mem_addr + 1;
                end
                3'b011 : begin
                    data[31:24] <= from_mem_data;
                    rw_index <= 3'b100;
                    to_mem_addr <= to_mem_addr + 1;
                end
                3'b100 : begin
                    CDB_2_ok <= 1;
                    CDB_2_en <= val;
                    CDB_2_val <= data;
                    rw_index <= 0;
                    stat = `IDLE;
                end
            endcase
        end
        else if (stat == `WRITE) begin
            case (rw_index)
                3'b000 : begin
                    mem_wr <= 1;
                    to_mem_data <= data[7:0];
                    if (res_index == 0) begin
                        rw_index <= 3'b100;
                    end
                    else begin
                        rw_index <= 3'b001;
                    end
                end
                3'b001 : begin
                    to_mem_data <= data[15:8];
                    to_mem_addr <= to_mem_addr + 1;
                    if (res_index == 1) begin
                        rw_index <= 3'b100;
                    end
                    else begin
                        rw_index <= 3'b010;
                    end
                end
                3'b010 : begin
                    to_mem_data <= data[23:16];
                    to_mem_addr <= to_mem_addr + 1;
                    rw_index <= 3'b011;
                end
                3'b011 : begin
                    to_mem_data <= data[31:24];
                    to_mem_addr <= to_mem_addr + 1;
                    rw_index <= 3'b100;
                end
                3'b100 : begin
                    mem_wr <= 0;
                    rw_index <= 3'b000;
                end
            endcase
        end
    end
end
endmodule //mem_ctrl
