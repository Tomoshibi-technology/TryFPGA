#makefile

SRCS = full_adder_nand.v\
		tb_full_adder_nand.v


All: dump.vcd

dump.vcd: test.out
	vvp test.out -dumpfile dump.vcd

test.out: $(SRCS)
	iverilog -o test.out $(SRCS)

.PHONY: run
run: dump.vcd
	gtkwave dump.vcd

.PHONY: clean
clean:
	rm -f test.out dump.vcd
