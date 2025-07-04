import displayio
import terminalio
import random
import time
from array import array

### Tetris v0.6.0 ######################################################

# Simple debouncing 
class SimpleDebouncer:

    def __init__(self, debounce_time=0.05):
        self.debounce_time = debounce_time
        self.button_states = {}
        self.last_trigger_times = {}
        
    def register_button(self, button_id):
        """Register a button for debounced monitoring"""
        self.button_states[button_id] = True  # True = not pressed
        self.last_trigger_times[button_id] = 0
        
    def check_button(self, button_id, current_state):
        """Check if button should trigger (returns True on valid press)"""
        current_time = time.monotonic()
        
        # Check if enough time has passed since last trigger
        if current_time - self.last_trigger_times[button_id] < self.debounce_time:
            return False
            
        # Check for button press (transition from True to False)
        if button_id in self.button_states:
            previous_state = self.button_states[button_id]
            self.button_states[button_id] = current_state
            
            if previous_state and not current_state:  # Button pressed
                self.last_trigger_times[button_id] = current_time
                return True
        
        return False


class Brick:
    BRICKS = b'ftqr\xf0'
    ROTATIONS = [
        (1, 0, 0, 1, -1, -1),
        (0, 1, -1, 0, -1, 0),
        (-1, 0, 0, -1, -2, 0),
        (0, -1, 1, 0, -2, -1),
    ]

    def __init__(self, kind):
        self.x = 1
        self.y = 2
        self.color = kind % 5 + 1
        self.rotation = 0
        self.kind = kind

    def draw(self, image, color=None):
        if color is None:
            color = self.color
        data = self.BRICKS[self.kind]
        rot = self.ROTATIONS[self.rotation]
        mask = 0x01
        for y in range(2):
            y += rot[5]
            for x in range(4):
                x += rot[4]
                if data & mask:
                    try:
                        image[self.x + x * rot[0] + y * rot[1],
                              self.y + x * rot[2] + y * rot[3]] = color
                    except IndexError:
                        pass
                mask <<= 1

    def hit(self, image, dx=0, dy=0, dr=0):
        data = self.BRICKS[self.kind]
        rot = self.ROTATIONS[(self.rotation + dr) % 4]
        mask = 0x01
        for y in range(2):
            y += rot[5]
            for x in range(4):
                x += rot[4]
                if data & mask:
                    try:
                        if image[self.x + dx + x * rot[0] + y * rot[1],
                                 self.y + dy + x * rot[2] + y * rot[3]]:
                            return True
                    except IndexError:
                        return True
                mask <<= 1
        return False



def brick_game(hw_state):
    """Main function to run the brick game."""
    # Initialize display
    display = hw_state["display"]
    fpga_buttons = hw_state["fpga_overlay"].set_mode_buttons()
    button_a = hw_state["btn_action"][0]
    button_b = hw_state["btn_action"][1]

    # Initialize debouncer
    debouncer = SimpleDebouncer(debounce_time=0.040)  # 40ms debounce
    button_ids = ['left', 'up', 'center', 'down', 'right', 'a', 'b']
    for btn_id in button_ids:
        debouncer.register_button(btn_id)

    # Game setup
    palette = displayio.Palette(6)
    palette[0] = 0x7f7f7f # background
    palette[1] = 0xffff00 # Square piece
    palette[2] = 0xff7f00 # L piece
    palette[3] = 0x0000ff # J piece
    palette[4] = 0x800080 # T piece
    palette[5] = 0x00ffff # Bar piece
    text_palette = displayio.Palette(2)
    text_palette[0] = 0x222222
    text_palette[1] = 0xffeedd
    flag_palette = displayio.Palette(2)
    flag_palette[0] = 0x990000
    flag_palette[1] = 0x00ff00
    w, h = terminalio.FONT.get_bounding_box()
    text_grid = displayio.TileGrid(terminalio.FONT.bitmap,
        tile_width=w, tile_height=h, pixel_shader=text_palette, width=8, height=1)
    text_grid.x = 96
    text_grid.y = 50
    text = terminalio.Terminal(text_grid, terminalio.FONT)
    desc_grid = displayio.TileGrid(terminalio.FONT.bitmap,
        tile_width=w, tile_height=h, pixel_shader=text_palette, width=25, height=1)
    desc_grid.x = -30
    desc_grid.y = 130
    desc_text = terminalio.Terminal(desc_grid, terminalio.FONT)
    screen = displayio.Bitmap(10, 20, 6)
    preview = displayio.Bitmap(4, 4, 6)
    bricks = displayio.Group(scale=8)
    bricks.append(displayio.TileGrid(screen, pixel_shader=palette, x=0, y=-4))
    bricks.append(displayio.TileGrid(preview, pixel_shader=palette, x=12, y=0))
    root = displayio.Group()
    root.append(bricks)
    root.append(text_grid)
    root.append(desc_grid)
    root[0] = displayio.Group()
    root[0] = bricks

    # center the game on the screen
    root.x = 80
    root.y = 70
    display.root_group = root

    brick = None
    score = 0
    next_brick = Brick(random.randint(0, 4))
    tick = time.monotonic() + 0.5  # Initialize tick to future time

    last_inputs = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1]  # Store last 10 inputs
    konami = [1, 1, 3, 3, 0, 4, 0, 4, 6, 5] # Konami code sequence UUDDLRLRBA

    cheat_multiplier = 1

    while True:

        # check for konami code
        if last_inputs == konami:  
            desc_text.write("SECRET MULTIPLIER ACTIVE!")
            score += 1 # hint that konami was entered
            cheat_multiplier = 1000
            last_inputs = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

            
        # Spawn new brick if needed 
        if brick is None:
            # Taunt the player
            reply = random.choice([
                        "So much 4 cyber 'expert' ",
                        "Mum sent u 2 skool 4 dis?",
                        "bro u got try meh????????",
                        "meow meow meow meow meow ",
                        "meow meow u lost meowmeow",
                        "omg y u so noob meow meow", # cak
                        "stop playing go bak 2 sku", # cak
                        "i tot finalist wld b btr!", # cak
                        "Um, maybe can try harder?", # kh
                        "Bro rm rf last brain cell", # kh
                        "Smth easier... whats 1+1?"  # kh
                    ])
            desc_text.write(reply)
            text.write("\r\n%08d" % score)
            next_brick.draw(preview, 0)
            brick = next_brick
            brick.x = screen.width // 2
            next_brick = Brick(random.randint(0, 4))
            next_brick.draw(preview)
            if brick.hit(screen, 0, 0):
                
                # Game over, if score enough, show grey flag
                if score > 9998:
                    desc_text.write("grey{go_do_this_on_stage}")
                    time.sleep(10)
                    root.x = 0 # reset position
                    root.y = 0
                    break
                else:
                    # Loss lines
                    reply = random.choice([
                        "loser! loser alert class!",
                        "how old alr cant game ah?",
                        "gray{here_is_a_pity_flag}",
                        "u touched too much grass?",
                        "gray{this_guy_bad_@_game}",
                        "gray{fke_fleg_cos_u_lost}", # cak
                        "go solv u chals skrub lol", # cak
                        "wow i actl beat some1 tdy", # cak
                        "yur mommy is dissapointed", # kh
                        "That's a real sad attempt", # kh
                        "gray{no_way_u_fall_4_dis}"
                    ])
                    desc_text.write(reply)
                    time.sleep(2)
                    desc_text.write("Restarting game..........")
                    time.sleep(2)
                    brick_game(hw_state) # restart game

        # Only update tick when gravity should apply
        if tick <= time.monotonic():
            tick = time.monotonic() + 0.5  # Set next gravity time

        # Input handling loop (waits for next grav tick)
        while True:
            current_time = time.monotonic()
            # Break for gravity tick when it's time
            if tick <= current_time:
                break
            
            brick.draw(screen, 0) # Clear brick

            # input handling with debouncer
            # 0 = left, 1 = up, 2 = center, 3 = down, 4 = right, 5 = a, 6 = b
            if debouncer.check_button('left', fpga_buttons[0].value): # left [0]
                if not brick.hit(screen, -1, 0):
                    brick.x -= 1
                    last_inputs.append(0)
                    last_inputs.pop(0) # remove first element

            if debouncer.check_button('right', fpga_buttons[4].value): # right [4]
                if not brick.hit(screen, 1, 0):
                    brick.x += 1
                    last_inputs.append(4)
                    last_inputs.pop(0) # remove first element

            if debouncer.check_button('down', fpga_buttons[3].value): # down [3]
                if not brick.hit(screen, 0, 1):
                    brick.y += 1
                    last_inputs.append(3)
                    last_inputs.pop(0) # remove first element

            if debouncer.check_button('a', button_a.value): # rotate CW [5]
                if not brick.hit(screen, 0, 0, 1):
                    brick.rotation = (brick.rotation + 1) % 4
                    last_inputs.append(5)
                    last_inputs.pop(0) # remove first element

            if debouncer.check_button('b', button_b.value): # rotate CCW [6]
                if not brick.hit(screen, 0, 0, -1):
                    brick.rotation = (brick.rotation - 1) % 4
                    last_inputs.append(6)
                    last_inputs.pop(0) # remove first element

            if debouncer.check_button('center', fpga_buttons[2].value): # hard drop (triggers on press instead of release)
                while not brick.hit(screen, 0, 1):
                    brick.y += 1

            if debouncer.check_button('up', fpga_buttons[1].value): # up [1]
                if not brick.hit(screen, 0, 1):
                    last_inputs.append(1)
                    last_inputs.pop(0) # remove first element

            brick.draw(screen) # Redraw brick
            time.sleep(0.075) # delay

        # Line clearning logic
        brick.draw(screen, 0)
        if brick.hit(screen, 0, 1):
            brick.draw(screen)
            combo = 0

            for y in range(screen.height):
                for x in range(screen.width):
                    if not screen[x, y]:
                        break # found empty space
                else:
                    # if cheat code is active, increase score
                    combo += 1
                    score += combo * cheat_multiplier

                    for yy in range(y, 0, -1):
                        for x in range(screen.width):
                            screen[x, yy] = screen[x, yy - 1]
            brick = None
        else:
            brick.y += 1
            brick.draw(screen)


