VLOG = ncverilog

TB = tb.v
SRC = top.v i2c_init.v i2s_read.v i2s_write.v
DCSRC = top_syn.v
LIB = ~/Synthesis\(UMC18\)/fsa0m_a_generic_core_21.lib.src
ARG = +ncaccess+rwc +loadpli1=debpli:novas_pli_boot +access+r

sim:
	$(VLOG) $(ARG) $(TB) $(SRC)
dcsim:
	$(VLOG) $(ARG) +define+SDF $(TB) $(DCSRC) $(LIB)
check:
	$(VLOG) -c $(TB)

