# 変数定義

IVERILOG := iverilog
VVP      := vvp
GTKWAVE  := gtkwave

SRC_DIR  := src
TOP_TB   := sim/tb_top.v
NEOPIXEL_TB := sim/tb_neopixel.v
SIM_SRCS := $(TOP_TB) $(wildcard $(SRC_DIR)/*.v)
NEOPIXEL_SRCS := $(NEOPIXEL_TB) $(SRC_DIR)/neopixel.v

TEMP_DIR := tmp
SIM_OUT  := $(TEMP_DIR)/sim.out
NEOPIXEL_OUT := $(TEMP_DIR)/neopixel.out
VCD      := $(TEMP_DIR)/wave.vcd
NEOPIXEL_VCD := $(TEMP_DIR)/neopixel.vcd
SAV      := sim/waveformat.sav
NEO_SAV := sim/waveformat-neo.sav


.PHONY: all
all: sim wave

.PHONY: sim
sim: $(SIM_OUT)
	$(VVP) $(SIM_OUT)

.PHONY: neopixel
neopixel: $(NEOPIXEL_OUT)
	$(VVP) $(NEOPIXEL_OUT)

$(SIM_OUT): $(SIM_SRCS) | $(TEMP_DIR)
	$(IVERILOG) -g2012 -I$(SRC_DIR) -o $@ $(SIM_SRCS)

$(NEOPIXEL_OUT): $(NEOPIXEL_SRCS) | $(TEMP_DIR)
	$(IVERILOG) -g2012 -I$(SRC_DIR) -o $@ $(NEOPIXEL_SRCS)

$(TEMP_DIR):
	mkdir -p $@

.PHONY: wave
wave: $(VCD)
	@if command -v $(GTKWAVE) >/dev/null; then $(GTKWAVE) $(VCD) $(SAV) & fi

$(VCD): $(SIM_OUT)
	$(VVP) $(SIM_OUT)

.PHONY: neopixel-wave
neopixel-wave: $(NEOPIXEL_VCD)
	@if command -v $(GTKWAVE) >/dev/null; then $(GTKWAVE) $(NEOPIXEL_VCD) $(NEO_SAV) & fi

$(NEOPIXEL_VCD): $(NEOPIXEL_OUT)
	$(VVP) $(NEOPIXEL_OUT)

.PHONY: clean
clean:
	rm -rf $(TEMP_DIR)