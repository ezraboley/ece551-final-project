VSIM_EXE = "vsim -c"
VLOG_EXE = "vlog -work work"
DC_EXE   = "design_vision -shell dc_shell -f"
WORK     = "work."

all: Segway_tb Segway
	$(VSIM_EXE) $(WORK)Segway_tb

synth:
	$(DC_EXE) Segway.dc

Segway: Segway.v
	$(VLOG_EXE) Segway.v inert_intf.sv A2D_intf.sv AUTH_blk.sv
