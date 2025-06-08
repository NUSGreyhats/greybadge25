FLAG = "grey{eh_live_firing_dont_turn_your_brain_off}"
output = ""
for i in range(len(FLAG)):
    output += f"flag[{i}] = {ord(FLAG[i])};"
    if ((i+1) % 5 == 0):
        output += "\n"
    else:
        output += " "

print(output)