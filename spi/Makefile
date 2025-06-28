# 変数定義

IVERILOG := iverilog
VVP      := vvp
GTKWAVE  := gtkwave

SRC_DIR  := src
TOP_TB   := sim/tb_top.v
SIM_SRCS := $(TOP_TB) $(wildcard $(SRC_DIR)/*.v)

TEMP_DIR := tmp
SIM_OUT  := $(TEMP_DIR)/sim.out
VCD      := $(TEMP_DIR)/wave.vcd
SAV      := sim/waveformat.sav


.PHONY: all
all: sim wave

.PHONY: sim
sim: $(SIM_OUT)
	$(VVP) $(SIM_OUT)

$(SIM_OUT): $(SIM_SRCS) | $(TEMP_DIR)
	$(IVERILOG) -g2012 -I$(SRC_DIR) -o $@ $(SIM_SRCS)

$(TEMP_DIR):
	mkdir -p $@

.PHONY: wave
wave: $(VCD)
	@if command -v $(GTKWAVE) >/dev/null; then $(GTKWAVE) $(VCD) $(SAV) & fi

.PHONY: clean
clean:
	rm -rf $(TEMP_DIR)