TMPFILE = verilog/*.log verilog/INCA_libs verilog/*.sdf verilog/*.sdc verilog/*_syn.v verilog/*.fsdb verilog/*.sdf.X out/*.out *.syn *.svf *.pvl *.mr *.log
RM = rm -rf

all: sim dc dcsim
sim:
	$(MAKE) -C verilog sim
dc:
	dc_shell -f synthesis.scr
dcsim:
	$(MAKE) -C verilog dcsim
check:
	$(MAKE) -C verilog check
lvs:
	cp encounter/CHIP.v encounter/CHIP.gds LVS
	$(MAKE) -C LVS all
	vim LVS/lvs_test.rep
drc:
	cp encounter/CHIP.gds DRC
	$(MAKE) -C DRC/BaseRule all
clean:
	$(RM) $(TMPFILE)
