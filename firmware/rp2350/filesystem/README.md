# GreyMecha/Army

This is the GreyMecha/Army Firmware (for the RP part anyway). It's based off circuitpython, and includes various challenges.


## Images

To customise the badge with your own (`.jpg` and `.gif`), just put them in the `images` folder. 
Make sure they are 240x240 pixels.

You may use EzGif to convert a video to Gif format. https://ezgif.com/video-to-gif

You may also use EzGif to resize to 240 x 240 pixels. https://ezgif.com/maker



## Challenges

There are 2 kinds of challenges. 
`grey` challenges are ones which are released for GreyCTF 2025 Finals. If you are a finalist, you only need to care about these.
`fun` challenges, meanwhile, are just ones for fun. 

Grey Challenges
1. Hornet Revenge
2. Leaky Pin
3. Bricked Up
3. Shooting Flags
4. Secure Memory
5. CatCore



### Hornet Revenge

I want revenge.

Run this in the Thonny REPL to start the challenge.

```python
from challenge.hornet_revenge import *
```

### Leaky Pin

I wonder if there's something special in the secret pin....

Run this in Thonny to start the challenge.

```python
from challenge.leaky_gpio25 import *
```

### Bricked Up




### Shooting Flags

During Live Firing, the cats were told to "follow the standards" and shoot accordingly. I wonder if it could mean something...



### Secure Memory

Oh wait, the flag is not supposed to be accessed by anyone? Hmm, this should do the trick...
Access the stored values of secure memory at pmod_j2.

Source code: 