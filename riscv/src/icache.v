// `define CACHE_SIZE 255:0

// module icache (
//     input wire clk,
//     input wire rst,
//     input wire rdy,
    
//     input wire         from_if_ready,
//     input wire [31:0]  from_if_addr,
//     output reg        to_if_ok,
//     output reg [31:0] to_if_ins,

//     input wire        from_mctr_ok,
//     input wire [31:0] from_mctr_data,
//     output reg        to_mctr_ready,
//     output reg [31:0] to_mctr_addr
// );

// reg [31:0] cData[`CACHE_SIZE];
// reg cValid[`CACHE_SIZE];
// reg [31:10] cTag[`CACHE_SIZE];

// integer i;

// wire [7:0] index;
// wire [21:0] tag;
// wire cache_hit = cValid[index] && cTag[index] == tag;
// assign index = from_if_addr[9:2];
// assign tag = from_if_addr[31:10];

// // assign isHit = 

// always @(posedge clk) begin
//     // $$display("rst: %d rdy: %d from_if_ready");
//     if (rst) begin
//         for (i = 0; i < 256; ++i) begin
//             cData[i] <= 0;
//             cValid[i] <= 0;
//             cTag[i] <= 0;
//         end
//         to_if_ok <= 0;
//         to_mctr_ready <= 0;
//     end
//     else if (!rdy) begin
        
//     end
//     else if (from_if_ready) begin
//         // $display(">>>>");
//         if (cValid[index] && cTag[index] == tag) begin
//             to_if_ins <= cData[index];
//             to_if_ok <= 1;
//         end
//         else begin
//             // $display("ok from_mctr_ok: %d to_mctr_ready: %d ", from_mctr_ok, to_mctr_ready);
//             if (from_mctr_ok) begin
//                 cValid[i] <= 1;
//                 cTag[i] <= tag;
//                 cData[i] <= from_mctr_data;
//                 to_if_ok <= 1;
//                 to_if_ins <= from_mctr_data;
//                 to_mctr_ready <= 0;
//             end
//             else if(!to_mctr_ready) begin
//                 to_mctr_ready <= 1;
//                 to_if_ok <= 0;
//                 to_mctr_addr <= from_if_addr;
//             end
//         end
//     end
// end
    
// endmodule //icache
