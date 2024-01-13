`include "def.v"

`define IDLE 3'b000
`define IFETCH 3'b001
`define READ   3'b010
`define WRITE  3'b011
`define STALL 3'b100

module mem_ctrl (
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire clear,
    
    input wire        from_ic_ready,
    input wire [31:0] from_ic_addr,
    output reg        to_ic_ready,
    output reg [31:0] to_ic_data,

    input wire        io_buffer_full,
    
    input wire [ 7:0] from_mem_data,
    output reg [ 7:0] to_mem_data,
    output reg [31:0] to_mem_addr,
    output reg        mem_wr,

    output reg        to_lsb_done,
    input wire        from_lsb_ready,
    input wire [31:0] from_lsb_addr,
    input wire [ 5:0] from_lsb_op,
    input wire [31:0] from_lsb_imm,
    input wire [31:0] from_lsb_val,

    output reg         CDB_2_ok,
    output reg  [ 3:0] CDB_2_en,
    output wire [31:0] CDB_2_val
);
reg [2:0] stat, rw_index, if_index, res_index;
reg [31:0] data, store_addr;
reg ic_ok, lsb_ok, is_U;
reg [5:0] opt;
reg [31:0] val;

assign CDB_2_val = data;

// integer write_out;

// initial begin
//     write_out = $fopen("wr.txt","w");
// end

always @(posedge clk) begin
    if (rst) begin
        to_ic_data <= 0;
        to_ic_ready <= 0;
        to_mem_addr <= 0;
        to_mem_data <= 0;
        mem_wr <= 0;
        to_lsb_done <= 0;
        CDB_2_ok <= 0;
        stat <= `IDLE;
    end
    else if (!rdy) begin
        // $fclose(write_out);
    end
    else begin
        if (CDB_2_ok) begin
           CDB_2_ok <= 0;
        end
        if (stat == `IDLE) begin
            // to_lsb_done <= 1;
            if(from_lsb_ready && !clear) begin
                // to_lsb_done <= 
                stat <= from_lsb_op[5:3] == 3'b111 ? `WRITE : `READ;
                if (from_lsb_op[5:3] == 3'b111) begin
                    // if (from_lsb_addr + from_lsb_imm == 32'h00030000) begin
                        // $fdisplay(write_out, "store !! pos: %x val: %x", from_lsb_addr + from_lsb_imm, from_lsb_val);
                    // end
                    store_addr <= from_lsb_addr + from_lsb_imm;
                end
                else begin
                    to_mem_addr <= from_lsb_addr + from_lsb_imm;
                end
                // data <= 0;
                rw_index <= 3'b000;
                // if (from_lsb_op[5:3] == 3'b111) begin
                //     store_addr <= from_lsb_addr + from_lsb_imm;
                // end
                case (from_lsb_op)
                    `LB  : res_index <= 0;
                    `LH  : res_index <= 1;
                    `LW  : res_index <= 3;
                    `LBU : res_index <= 0;
                    `LHU : res_index <= 1;
                    `SB  : res_index <= 0;
                    `SH  : res_index <= 1;
                    `SW  : res_index <= 3;
                    default : res_index <= 0;
                endcase
                if (from_lsb_op == `LBU || from_lsb_op == `LHU) begin
                    is_U <= 1;
                end
                mem_wr <= 0;
                if (from_lsb_op[5:3] == 3'b111) begin
                    data <= from_lsb_val;
                end
                else begin
                    val <= from_lsb_val;
                    data <= 0;
                end
            end
            else if(from_ic_ready && !clear) begin
                stat <= `IFETCH;
                if_index <= 3'b000;
                mem_wr <= 0;
                to_mem_addr <= from_ic_addr;
            end
            
        end
        else if(stat == `IFETCH && from_ic_ready) begin
            if (!clear) begin
                case (if_index)
                    3'b000 : begin
                        if_index <= 3'b001;
                        to_mem_addr <= to_mem_addr + 1;
                    end
                    3'b001 : begin
                        to_ic_data[ 7: 0] <= from_mem_data;
                        if_index <= 3'b010;
                        to_mem_addr <= to_mem_addr + 1;
                    end
                    3'b010 : begin
                        to_ic_data[15 : 8] <= from_mem_data;
                        if_index <= 3'b011;
                        to_mem_addr <= to_mem_addr + 1;
                    end
                    3'b011 : begin
                        to_ic_data[23:16] <= from_mem_data;
                        to_mem_addr <= 0;
                        // to_ic_ready <= 1;
                        if_index <= 3'b100;
                    end
                    3'b100 : begin
                        to_ic_data[31:24] <= from_mem_data;
                        // ic_ok <= 1;
                        to_ic_ready <= 1;
                        if_index <= 3'b101;
                    end
                    3'b101 : begin
                        stat = `IDLE;
                        // ic_ok <= 0;
                        to_ic_ready <= 0;
                        if_index <= 3'b000;
                    end
                endcase
            end
            else begin
                stat <= clear ? `STALL : `IDLE;
                to_ic_ready <= 0;
            end
        end
        else if(stat == `READ) begin
            if (from_lsb_ready && !clear) begin
                case (rw_index)
                    3'b000 : begin
                        // to_mem_addr <= to_mem_addr + 1;
                        rw_index <= 3'b001;
                        if (res_index == 0) begin
                            // to_lsb_done <= 1;
                            rw_index <= 3'b100;
                        end
                        else begin
                            rw_index <= 3'b001;
                            to_mem_addr <= to_mem_addr + 1;
                        end
                        // if (res_index == 0) begin
                        //     if (!is_U) begin
                        //         data[31:8] <= {24{data[7]}};
                        //     end
                        //     to_lsb_done <= 1;
                        //     rw_index <= 3'b100;
                        // end
                        // else begin
                        //     rw_index <= 3'b001;
                        //     to_mem_addr <= to_mem_addr + 1;
                        // end
                    end
                    3'b001 : begin
                        data[7:0] <= from_mem_data;
                        if (res_index == 1) begin
                            // to_lsb_done <= 1;
                            rw_index <= 3'b100;
                        end
                        else begin
                            rw_index <= 3'b010;
                            to_mem_addr <= to_mem_addr + 1;
                        end
                        // data[15:8] <= from_mem_data;
                        // if (res_index == 1) begin
                        //     if (!is_U) begin
                        //         data[31:16] = {16{data[15]}};
                        //     end
                        //     to_lsb_done <= 1;
                        //     rw_index <= 3'b100;
                        // end
                        // else begin
                        //     rw_index <= 3'b010;
                        //     to_mem_addr <= to_mem_addr + 1;
                        // end
                    end
                    3'b010 : begin
                        data[15:8] <= from_mem_data;
                        rw_index <= 3'b011;
                        to_mem_addr <= to_mem_addr + 1;
                        // data[23:16] <= from_mem_data;
                        // rw_index <= 3'b011;
                        // to_mem_addr <= to_mem_addr + 1;
                    end
                    3'b011 : begin
                        data[23:16] <= from_mem_data;
                        rw_index <= 3'b100;
                        to_mem_addr <= 0;
                        // to_lsb_done <= 1;
                        // data[31:24] <= from_mem_data;
                        // rw_index <= 3'b100;
                        // to_mem_addr <= to_mem_addr + 1;
                        // to_lsb_done <= 1;
                    end
                    3'b100 : begin
                        CDB_2_ok <= 1;
                        CDB_2_en <= val[3:0];
                        case (res_index)
                            0 : begin
                                data[7:0] <= from_mem_data;
                                if (!is_U) data[31:8] <= {24{from_mem_data[7]}};
                            end
                            1 : begin
                                data[15:8] <= from_mem_data;
                                if (!is_U) data[31:16] <= {16{from_mem_data[7]}};
                            end
                            default: begin
                                data[31:24] <= from_mem_data;
                            end
                        endcase
                        rw_index <= 5;
                        to_lsb_done <= 1;
                    end
                        // CDB_2_ok <= 1;
                        // CDB_2_en <= val;
                        // rw_index <= 0;
                        // stat <= `IDLE;
                        // to_lsb_done <= 0;
                    3'b101 : begin
                        CDB_2_ok <= 0;
                        // CDB_2_en <= val;
                        // CDB_2_val <= data;
                        rw_index <= 0;
                        stat <= `IDLE;
                        to_mem_addr <= 0;
                        to_lsb_done <= 0;
                    end
                endcase
            end
            else begin
                stat <= `IDLE;
                to_lsb_done <= 0;
            end
        end
        else if (stat == `WRITE && (store_addr[17:16] != 2'b11 || !io_buffer_full)) begin
            if (from_lsb_ready) begin
               case (rw_index)
                    3'b000 : begin
                        to_mem_addr <= store_addr;
                        mem_wr <= 1;
                        to_mem_data <= data[7:0];
                        if (res_index == 0) begin
                            to_lsb_done <= 1;
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
                            to_lsb_done <= 1;
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
                        to_lsb_done <= 1;
                    end
                    3'b100 : begin
                        mem_wr <= 0;
                        to_mem_addr <= 0;
                        rw_index <= 3'b000;
                        to_lsb_done <= 0;
                        stat <= `IDLE;
                    end
                endcase
            end
            else begin
                stat <= `IDLE;
                to_lsb_done <= 0;
            end
        end
        else if (stat == `STALL) begin
            stat <= `IDLE;
        end
    end
end
endmodule //mem_ctrl
