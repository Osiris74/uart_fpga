module fifo 
#
(
    parameter   WIDTH           = 8,
    parameter   DEPTH           = 16
)
(
    input                clk,
    input                rst,
    input                push,
    input                pop,
    input  [WIDTH - 1:0] write_data,
    output [WIDTH - 1:0] read_data,
    output               empty,
    output               full
);

//------------------------------------ Internal parameters ---------------------------------
localparam  pointer_width           = $clog2 (DEPTH);
localparam  extended_pointer_width  = pointer_width + 1;

// Stores current read & write pointers
logic [extended_pointer_width - 1:0] ext_wr_ptr, ext_rd_ptr;

wire [pointer_width - 1:0] wr_ptr = ext_wr_ptr [pointer_width - 1:0];
wire [pointer_width - 1:0] rd_ptr = ext_rd_ptr [pointer_width - 1:0];

// Internal data array
logic [WIDTH - 1:0] data [0: DEPTH - 1];
//------------------------------------ Internal parameters ---------------------------------


//------------------------------------ Output assignment -----------------------------------

assign empty = (ext_rd_ptr == ext_wr_ptr);
assign full  = (ext_rd_ptr[pointer_width - 1:0]          == ext_wr_ptr[pointer_width - 1:0]) &&
               (ext_rd_ptr[extended_pointer_width - 1] != ext_wr_ptr[extended_pointer_width - 1]); 

always_ff @ (posedge clk)
if (push)
  data [wr_ptr] <= write_data;

assign read_data = data [rd_ptr];



always_ff @ (posedge clk or posedge rst)
if (rst)
begin
  ext_wr_ptr <= '0;
  ext_rd_ptr <= '0;
end
else 
begin
    if (push && (!full || pop))
    begin
        ext_wr_ptr <= ext_wr_ptr + 1'b1;
    end
    if (pop && (!empty))
    begin
        ext_rd_ptr <= ext_rd_ptr + 1'b1;
    end
end


endmodule