module MIPSProcessor_tb;

    reg clk;
    reg reset;
  wire [16:0] result;

    // Instantierea modulului principal al procesorului
    MIPSProcessor dut(
        .clk(clk),
        .reset(reset),
      .result(result)
    );

    // Generare semnal clock
    always #5 clk = ~clk;

    initial begin
        // Initializarea semnalelor de intrare
        reset = 0;
        clk = 0;

        // Pregatirea fisierului vcd
        $dumpfile("simulation.vcd");
        $dumpvars;


        // Oprirea simularii
        #500 $finish;
    end

endmodule
