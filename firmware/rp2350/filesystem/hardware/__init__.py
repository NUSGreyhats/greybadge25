import hardware.rp2350
import hardware.default_overlay
import displayio

display, display_bus = hardware.rp2350.rp2350_init_display()
display.root_group = displayio.Group()

overlay = hardware.default_overlay.Overlay()

hw_state = {
    # OLED Display
    "display": display, 
    "display_bus": display_bus, 
    # Buttons
    "btn_action": [hardware.rp2350.button_a, hardware.rp2350.button_b], 
    # Buzzer
    "buzzer": hardware.rp2350.buzzer, 
    # FPGA overlay
    "fpga_overlay": overlay
} 