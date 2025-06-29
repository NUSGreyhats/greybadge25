PROJ=test

all: ${PROJ}.bit

%.json: %.v
	yosys -p "synth_ecp5 -top top -json $@" $<

%_out.config: %.json
	nextpnr-ecp5 --json $< --textcfg $@ --25k --package CABGA256 --lpf pinout.lpf

%.bit: %_out.config
	ecppack --svf ${PROJ}.svf $< $@

${PROJ}.svf : ${PROJ}.bit

clean:
	rm -f *.svf *.bit *.config *.json

.PHONY: all prog clean
