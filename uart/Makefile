#makefile

SRCS = uart_tx.v\
		tb_uart.v

TMP_DIR = tmp

.PHONY: all
all: $(TMP_DIR)/dump.vcd

$(TMP_DIR)/dump.vcd: $(TMP_DIR)/test.out
	vvp $(TMP_DIR)/test.out

$(TMP_DIR)/test.out: $(SRCS)
	mkdir -p $(TMP_DIR)
	iverilog -D DUMPFILE="\"$(TMP_DIR)/dump.vcd\"" -o $(TMP_DIR)/test.out $(SRCS)

	
.PHONY: run
run: $(TMP_DIR)/dump.vcd
	gtkwave $(TMP_DIR)/dump.vcd uart.sav

.PHONY: clean
clean:
	rm -rf $(TMP_DIR)
