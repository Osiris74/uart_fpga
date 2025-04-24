module tb_fifo;

  localparam fifo_width = 8, fifo_depth = 16;

  logic                    clk;
  logic                    rst;
  logic                    push;
  logic                    pop;
  logic [fifo_width - 1:0] write_data;

  logic [fifo_width - 1:0] rtl_read_data;
  logic                    rtl_empty;
  logic                    rtl_full;

  logic [fifo_width - 1:0] model_read_data;
  logic                    model_empty;
  logic                    model_full;

  //--------------------------------------------------------------------------

  fifo
  # (
    .WIDTH (fifo_width),
    .DEPTH (fifo_depth)
  )
  rtl
  (
    .read_data ( rtl_read_data ),
    .empty     ( rtl_empty     ),
    .full      ( rtl_full      ),
    .*
  );

  //--------------------------------------------------------------------------

  fifo_model
  # (
    .width (fifo_width),
    .depth (fifo_depth)
  )
  model
  (
    .read_data ( model_read_data ),
    .empty     ( model_empty     ),
    .full      ( model_full      ),
    .*
  );

  //--------------------------------------------------------------------------

  initial
  begin
    clk = '0;
    forever #5 clk = ~ clk;
  end

  //--------------------------------------------------------------------------

  // Monitor

  always @ (posedge clk)
    # 1  // This delay is necessary because of combinational logic after ff
    if (rst === '0)
    begin
      assert ( rtl_empty === model_empty );
      assert ( rtl_full  === model_full  );

      if (~ rtl_empty)
        assert ( rtl_read_data === model_read_data );
    end

  //--------------------------------------------------------------------------

  // Logger

  always @ (posedge clk)
    if (rst === '0 & (push | pop))
    begin
      if (push)
        $write ("push %h", write_data);
      else
        $write ("       ");

      if (pop)
        $write ("  pop %h", rtl_read_data);
      else
        $write ("        ");

      # 1 ;  // This delay is necessary because of combinational logic after ff

      $write ("  %5s %4s",
        rtl_empty ? "empty" : "     ",
        rtl_full  ? "full"  : "    ");

      $write (" [");

      for (int i = 0; i < model.queue.size (); i ++)
        $write (" %h", model.queue [model.queue.size () - i - 1]);

      $display (" ]");
    end

  //--------------------------------------------------------------------------

  initial
  begin
    `ifdef __ICARUS__
      $dumpvars;
    `endif

    //------------------------------------------------------------------------
    // Initialization

    push <= '0;
    pop  <= '0;

    //------------------------------------------------------------------------
    // Reset

    # 3 rst <= '1;
    repeat (5) @ (posedge clk);
    rst <= '0;

    //------------------------------------------------------------------------

    $display ("*** Fill and empty");

    push <= '1;

    for (int i = 0; i < fifo_depth; i ++)
    begin
      write_data <= i * 16 + i;
      @ (posedge clk);
    end

    push <= '0;
    pop  <= '1;

    repeat (fifo_depth)
      @ (posedge clk);

    pop  <= '0;
    repeat (2) @ (posedge clk);

    //------------------------------------------------------------------------

    $display ("*** Fill half and run back-to-back, then empty");

    push <= '1;

    for (int i = 0; i < fifo_depth / 2; i ++)
    begin
      write_data <= i * 16 + i;
      @ (posedge clk);
    end

    pop <= '1;

    repeat (5)
      for (int i = 0; i < fifo_depth; i ++)
      begin
        write_data <= i * 16 + i;
        @ (posedge clk);
      end

    push <= '0;

    do
    begin
      @ (posedge clk);
      # 1;  // This delay is necessary because of combinational logic after ff
    end
    while (~ rtl_empty);

    pop <= '0;
    repeat (2) @ (posedge clk);

    //------------------------------------------------------------------------

    $display ("*** Randomized test");

    repeat (5) @ (posedge clk);

    repeat (200)
    begin
      @ (posedge clk);
      # 1  // This delay is necessary because of combinational logic after ff

      pop  <= '0;
      push <= '0;

      if (rtl_full & $urandom_range (1, 100) <= 40)
      begin
        pop  <= '1;
        push <= '1;

        write_data <= $urandom;
      end

      if (~ rtl_empty & $urandom_range (1, 100) <= 50)
        pop <= '1;

      if (~ rtl_full & $urandom_range (1, 100) <= 60)
      begin
        push <= '1;
        write_data <= $urandom;
      end
    end

    //------------------------------------------------------------------------

    $display;

    `ifdef MODEL_TECH  // Mentor ModelSim and Questa
      $stop;
    `else
      $finish;
    `endif
  end

endmodule
