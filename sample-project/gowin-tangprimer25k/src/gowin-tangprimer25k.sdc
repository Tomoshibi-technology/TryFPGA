//Copyright (C)2014-2025 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.11.01 Education 
//Created Time: 2025-07-07 01:05:38
create_clock -name osc -period 20 -waveform {0 10} [get_ports {clk27m}]
