# RISC-MIPS32-simplified
this is a simplified implementation of the MIPS32 processor with reduced number of instructions. The project also uses pipelining for quicker implementation of instructions.
<br>
to run the prcessor with a provided testbench use : <br>

1) iverilog -o mips_test RISC_MIPS32.v testbench3.v <br>
2) vvp mips_test <br>

make sure iverilog is installed in the environment path. 
