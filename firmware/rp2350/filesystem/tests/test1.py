import gc
import hardware
import apps
import board
import digitalio

gc.enable()

### Initialisation ####################################
hw_state = hardware.hw_state
apps.display_fpga_loading_menu(hw_state)
hw_state["fpga_overlay"].init()
hw_state["fpga_overlay"].set_mode((0,1,0))

fpga_interconnect_pins = [board.GP8, board.GP9, board.GP10, board.GP11,	board.GP12]

### FPGA Interconnect
def overlay_interconnect_pins():
    dio = []
    for p in fpga_interconnect_pins:
        d = digitalio.DigitalInOut(p)
        d.direction = digitalio.Direction.OUTPUT
        dio.append(d)
    return dio

interconnect = overlay_interconnect_pins()
for p in interconnect:
    p.value = False