// RISCV32I CPU top module
// port modification allowed for debugging purposes

`include "def.v"
// `include "decoder.v"
// `include "exec.v"
// `include "icache.v"
// `include "ifetcher.v"
// `include "load_store.v"
// `include "mem_ctrl.v"
// `include "predictor.v"
// `include "reg_file.v"
// `include "reorder_buffer.v"
// `include "reservation_station.v"


module cpu(
  input  wire                 clk_in,			// system clock signal
  input  wire                 rst_in,			// reset signal
	input  wire					        rdy_in,			// ready signal, pause cpu when low

  input  wire [ 7:0]          mem_din,		// data input bus
  output wire [ 7:0]          mem_dout,		// data output bus
  output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
  output wire                 mem_wr,			// write/read signal (1 for write)
	
	input  wire                 io_buffer_full, // 1 if uart buffer is full
	
	output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)
wire rs_full, lsb_full, rob_full;
wire clear;

wire if_ic_hit, if_to_ic_ready, if_to_dc_ready;
wire [31:0] if_ic_data, if_ic_addr, if_to_dc_data, if_to_dc_pc, pre_to_if_npc, if_to_pre_pc, if_to_pre_ins;
wire if_to_dc_jp, dc_to_if_pc_ok, pre_to_jp;
wire [31:0] dc_to_if_pc, rob_to_if_pc;

//rob_to_predictor
wire rob_is_jump, rob_to_pre_ok, pred_jump;
wire [31:0] rob_pre_data;

wire mctr_to_ic_ok, ic_to_mctr_ok;
wire [31:0] mctr_to_ic_data, ic_to_mctr_addr;

ifetcher If(.clk(clk_in), .rst(rst_in), .rdy(rdy_in), 
            .from_mctr_ok(mctr_to_ic_ok), .from_mctr_data(mctr_to_ic_data), .to_mctr_ready(ic_to_mctr_ok), .to_mctr_addr(ic_to_mctr_addr),
            // .from_ic_hit(if_ic_hit), .from_ic_data(if_ic_data), .to_ic_ready(if_to_ic_ready), .to_ic_addr(if_ic_addr),
            .rs_full(rs_full), .lsb_full(lsb_full), .rob_full(rob_full),
            .from_decoder_ok(dc_to_if_pc_ok), .from_decoder_pc(dc_to_if_pc),
            .to_decoder_ready(if_to_dc_ready), .to_decoder_data(if_to_dc_data), .to_decoder_pc(if_to_dc_pc), .to_decoder_isjp(if_to_dc_jp), 
            .from_predictor_npc(pre_to_if_npc), .to_predictor_pc(if_to_pre_pc), .to_predictor_ins(if_to_pre_ins), .is_jp(pre_to_jp),
            .from_rob_set(rob_to_pre_ok), .from_rob_pc(rob_to_if_pc)
            );

// icache Ic(.clk(clk_in), .rst(rst_in), .rdy(rdy_in),
//           .from_if_ready(if_to_ic_ready), .from_if_addr(if_ic_addr), .to_if_ok(if_ic_hit), .to_if_ins(if_ic_data),
//           .from_mctr_ok(mctr_to_ic_ok), .from_mctr_data(mctr_to_ic_data), .to_mctr_ready(ic_to_mctr_ok), .to_mctr_addr(ic_to_mctr_addr));


predictor Pre(.clk(clk_in), .rst(rst_in), .rdy(rdy_in),
              .pc_cur(if_to_pre_pc), .ins(if_to_pre_ins), .pc_next(pre_to_if_npc),
              .is_jump(pre_to_jp),
              .from_rob_ok(rob_to_pre_ok), .rob_is_jump(rob_is_jump), .data(rob_pre_data)
              );

// wire dc_reg_ok;
wire [4:0] reg_Rj, reg_Rk;
wire [3:0] reg_rob_Qj, reg_rob_Qk;
wire rob_Qj_ok, rob_Qk_ok;
wire [31:0] reg_rob_Vj, reg_rob_Vk;
wire [31:0] reg_Vj, reg_Vk;
wire [4:0] reg_Qj, reg_Qk;
wire [3:0] rob_en;

wire rob_commit;
wire [3:0] rob_commit_en;
wire [31:0] rob_commit_val;
wire [4:0] rob_commit_addr;

wire dec_rs_ok, dec_lsb_ok, dec_lsb_ready, dec_lsb_isok;
wire dec_rob_ok, dec_rob_jp, dec_rob_is_ok;
wire [31:0] dec_rs_vj, dec_rs_vk, dec_lsb_vj, dec_lsb_vk, dec_rob_val, dec_rob_pc, dec_rob_jpc;
wire [4:0] dec_rs_qj, dec_rs_qk, dec_lsb_qj, dec_lsb_qk;
wire [4:0] dec_rob_en;
wire [5:0] dec_rs_opt, dec_lsb_opt, dec_rob_opt;

REG Reg(.clk(clk_in), .rst(rst_in), .rdy(rdy_in),
        .from_dc_ok(dec_rob_ok), .Rj(reg_Rj), .Rk(reg_Rk), .Rr(dec_rob_en), 
        .Vj(reg_Vj), .Vk(reg_Vk), .Qj(reg_Qj), .Qk(reg_Qk),
        .rob_en(rob_en),
        .to_rob_Qj(reg_rob_Qj), .to_rob_Qk(reg_rob_Qk), 
        .rob_Qj_ok(rob_Qj_ok), .rob_Qk_ok(rob_Qk_ok),
        .rob_Vj(reg_rob_Vj), .rob_Vk(reg_rob_Vk),
        .rob_commit(rob_commit), .rob_commit_en(rob_commit_en), .rob_commit_val(rob_commit_val), .rob_commit_addr(rob_commit_addr),
        .clear(clear)
        );

Decoder Issue(
           .rst(rst_in), .rdy(rdy_in), .clear(clear),
           .from_if_ok(if_to_dc_ready), .from_if_pc(if_to_dc_pc), .from_if_ins(if_to_dc_data), .from_if_jp(if_to_dc_jp),

           .to_rs_ready(dec_rs_ok), .rs_vj(dec_rs_vj), .rs_vk(dec_rs_vk),
           .rs_qj(dec_rs_qj), .rs_qk(dec_rs_qk),
           .to_rs_opt(dec_rs_opt),

           .to_lsb_ready(dec_lsb_ok), .to_lsb_isok(dec_lsb_isok),
           .lsb_vj(dec_lsb_vj), .lsb_vk(dec_lsb_vk), 
           .lsb_qj(dec_lsb_qj), .lsb_qk(dec_lsb_qk), 
           .to_lsb_opt(dec_lsb_opt),

           .to_rob_ready(dec_rob_ok), .to_rob_opt(dec_rob_opt), .to_rob_en(dec_rob_en),
           .to_rob_isok(dec_rob_is_ok), .to_rob_jp(dec_rob_jp), 
           .to_rob_val(dec_rob_val), .to_rob_pc(dec_rob_pc), .to_rob_jpc(dec_rob_jpc),

           .to_if_ok(dc_to_if_pc_ok), .to_if_pc(dc_to_if_pc),

           .Rj(reg_Rj), .Rk(reg_Rk),
           .vj(reg_Vj), .vk(reg_Vk),
           .qj(reg_Qj), .qk(reg_Qk),

           .CDB_1_ok(CDB_1_ok), .CDB_1_en(CDB_1_en), .CDB_1_val(CDB_1_val),
           .CDB_2_ok(CDB_2_ok), .CDB_2_en(CDB_2_en), .CDB_2_val(CDB_2_val)
           );

wire CDB_1_ok, CDB_2_ok;
wire [3:0] CDB_1_en, CDB_2_en;
wire [31:0] CDB_1_val, CDB_2_val;


wire exec_ok;
wire [5:0] exec_opt;
wire [31:0] exec_rs1, exec_rs2, exec_imm;
wire [3:0] exec_en;

exec Exe(.rs_ok(exec_ok), .opt(exec_opt), .rs1(exec_rs1), .rs2(exec_rs2), .imm(exec_imm), .en(exec_en),
         .CDB_1_ok(CDB_1_ok), .CDB_1_en(CDB_1_en), .CDB_1_val(CDB_1_val)
         );

wire lsb_mem_ok, lsb_mem_done;
wire [31:0] lsb_mem_addr, lsb_mem_imm, lsb_mem_val;
wire [5:0] lsb_mem_op;

mem_ctrl Mctr(.clk(clk_in), .rst(rst_in), .rdy(rdy_in), 
              .clear(clear), 
              .from_ic_ready(ic_to_mctr_ok), .from_ic_addr(ic_to_mctr_addr), .to_ic_ready(mctr_to_ic_ok), .to_ic_data(mctr_to_ic_data),
              .io_buffer_full(io_buffer_full),
              .from_mem_data(mem_din), .to_mem_data(mem_dout),
              .to_mem_addr(mem_a), .mem_wr(mem_wr),
              .to_lsb_done(lsb_mem_done), .from_lsb_ready(lsb_mem_ok),
              .from_lsb_addr(lsb_mem_addr), .from_lsb_op(lsb_mem_op), 
              .from_lsb_imm(lsb_mem_imm), .from_lsb_val(lsb_mem_val),
              .CDB_2_ok(CDB_2_ok), .CDB_2_en(CDB_2_en), .CDB_2_val(CDB_2_val)
              );

RS Rs(.clk(clk_in), .rst(rst_in), .rdy(rdy_in),
      .from_dc_ok(dec_rs_ok), .vj(dec_rs_vj), .vk(dec_rs_vk),
      .qj(dec_rs_qj), .qk(dec_rs_qk), .opt(dec_rs_opt),
      .from_rob_en(rob_en),
      .is_rs_full(rs_full),
      .to_alu_ok(exec_ok), .to_alu_opt(exec_opt),
      .to_alu_rs1(exec_rs1), .to_alu_rs2(exec_rs2), .to_alu_imm(exec_imm),
      .to_alu_en(exec_en),
      .CDB_1_ok(CDB_1_ok), .CDB_1_en(CDB_1_en), .CDB_1_val(CDB_1_val),
      .CDB_2_ok(CDB_2_ok), .CDB_2_en(CDB_2_en), .CDB_2_val(CDB_2_val),
      .clear(clear)
      );

wire lsb_rob_commit;
wire [3:0] from_rob_L, lsb_rob_pos;

LSB Lsb(.clk(clk_in), .rst(rst_in), .rdy(rdy_in),
        .from_dc_ok(dec_lsb_ok), .from_dc_isk(dec_lsb_isok),
        .vj(dec_lsb_vj), .vk(dec_lsb_vk),
        .qj(dec_lsb_qj), .qk(dec_lsb_qk), .opt(dec_lsb_opt),
        .from_mc_ok(lsb_mem_done), .to_mc_ok(lsb_mem_ok),
        .to_mc_addr(lsb_mem_addr), .to_mc_imm(lsb_mem_imm),
        .to_mc_val(lsb_mem_val), .to_mc_opt(lsb_mem_op),

        .is_lsb_full(lsb_full),
        .from_rob_en(rob_en), .from_rob_L(from_rob_L),
        .from_rob_commit(lsb_rob_commit), .from_rob_pos(lsb_rob_pos),
        .CDB_1_ok(CDB_1_ok), .CDB_1_en(CDB_1_en), .CDB_1_val(CDB_1_val),
        .CDB_2_ok(CDB_2_ok), .CDB_2_en(CDB_2_en), .CDB_2_val(CDB_2_val),
        .clear(clear)
        );

ROB Rob(.clk(clk_in), .rst(rst_in), .rdy(rdy_in),

        .from_dc_ok(dec_rob_ok), .opt(dec_rob_opt), .val(dec_rob_val),
        .en(dec_rob_en), .dc_ok(dec_rob_is_ok), 
        .dc_jump(dec_rob_jp), .dc_pc(dec_rob_pc), .dc_jump_addr(dec_rob_jpc),

        .is_rob_full(rob_full), .clear(clear),
        .out_rob_en(rob_en), .out_rob_L(from_rob_L),

        .to_predictor_ok(rob_to_pre_ok), .to_predictor_add(rob_pre_data), .to_predictor_jump(rob_is_jump),
        .to_if_addr(rob_to_if_pc), 

        .reg_commit(rob_commit), .reg_commit_en(rob_commit_en), 
        .reg_commit_val(rob_commit_val), .reg_commit_addr(rob_commit_addr),

        .to_lsb_commit(lsb_rob_commit), .to_lsb_pos(lsb_rob_pos),

        .from_reg_Qj(reg_rob_Qj), .from_reg_Qk(reg_rob_Qk),
        .reg_Qj_ok(rob_Qj_ok), .reg_Qk_ok(rob_Qk_ok),
        .reg_Vj(reg_rob_Vj), .reg_Vk(reg_rob_Vk),

        
        .CDB_1_ok(CDB_1_ok), .CDB_1_en(CDB_1_en), .CDB_1_val(CDB_1_val),
        .CDB_2_ok(CDB_2_ok), .CDB_2_en(CDB_2_en), .CDB_2_val(CDB_2_val)
        );

always @(posedge clk_in)
  begin
    if (rst_in)
      begin
      
      end
    else if (!rdy_in)
      begin
      
      end
    else
      begin
      
      end
  end

endmodule