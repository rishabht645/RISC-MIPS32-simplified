module tb1 ();
    reg clk1,clk2; integer k;
    pipeline_mips32 P(.clk1(clk1),.clk2(clk2));

    initial begin
        clk1 = 0; clk2 = 0;
        repeat (20) begin
            #5 clk1 = 1; #5  clk1 = 0;
            #5 clk2 = 1; #5  clk2 = 0;
        end
    end

    initial begin
        for (k = 0;k<=31 ;k=k+1 ) begin
            P.regbank[k] = k;
        end
        P.memory[0] = 32'h2801000a;    // ADDI  R1,R0,10
        P.memory[1] = 32'h28020014;    // ADDI  R2,R0,20
        P.memory[2] = 32'h28030019;    // ADDI  R3,R0,25
        P.memory[3] = 32'h0ce77800;    // OR    R7,R7,R7   -- dummy instr.
        P.memory[4] = 32'h0ce77800;    // OR    R7,R7,R7   -- dummy instr.
        P.memory[5] = 32'h00222000;    // ADD   R4,R1,R2
        P.memory[6] = 32'h0ce77800;    // OR    R7,R7,R7   -- dummy instr.
        P.memory[7] = 32'h0ce77800;    // OR    R7,R7,R7   -- dummy instr.
        P.memory[8] = 32'h00832800;    // ADD   R5,R4,R3
        P.memory[9] = 32'hfc000000;    // HLT

        P.PC = 0;
        P.HALTED = 0;
        P.BRANCH_TAKEN = 0;

        #280 
        for (k = 1;k<10 ;k=k+1 ) begin
            $display("R%1d - %d", k, P.regbank[k]);
        end
    end

    initial begin
        $dumpfile("mips32.vcd");
        $dumpvars(0,tb1);
        #300 $finish;
    end
endmodule
