
module fifo_model
# (
  parameter width = 8, depth = 2
)
(
  input                      clk,
  input                      rst,
  input                      push,
  input                      pop,
  input        [width - 1:0] write_data,
  output logic [width - 1:0] read_data,
  output logic               empty,
  output logic               full
);

  logic [width - 1:0] queue [$];
  logic [width - 1:0] dummy;

  always @ (posedge clk)
  begin
    if (rst)
    begin
      queue = {};
    end
    else
    begin
      assert (~ (queue.size () == depth & push & ~ pop));
      assert (~ (queue.size () == 0     & pop));

      if (queue.size () > 0 & pop)
        dummy = queue.pop_front ();

      if (queue.size () < depth & push)
        queue.push_back (write_data);
    end

    if (queue.size () > 0)
      read_data <= queue [0];
    else
      read_data <= 'x;

    empty <= queue.size () == 0;
    full  <= queue.size () == depth;
  end

endmodule
