_C=False
_B=None
_A=True
import displayio,terminalio,random,time
from array import array

class BouncyCastle:
	def __init__(A,debounce_time=.05):A.debounce_time=debounce_time;A.button_states={};A.last_trigger_times={}
	def reg(A,button_id):B=button_id;A.button_states[B]=_A;A.last_trigger_times[B]=0
	def chk(A,button_id,current_state):
		C=current_state;B=button_id;D=time.monotonic()
		if D-A.last_trigger_times[B]<A.debounce_time:return _C
		if B in A.button_states:
			E=A.button_states[B];A.button_states[B]=C
			if E and not C:A.last_trigger_times[B]=D;return _A
		return _C
class Brick:
	BRICKS=b'ftqr\xf0';ROTATIONS=[(1,0,0,1,-1,-1),(0,1,-1,0,-1,0),(-1,0,0,-1,-2,0),(0,-1,1,0,-2,-1)]
	def __init__(A,kind):A.x=1;A.y=2;A.color=kind%5+1;A.rotation=0;A.kind=kind
	def draw(A,image,color=_B):
		C=color
		if C is _B:C=A.color
		G=A.BRICKS[A.kind];B=A.ROTATIONS[A.rotation];F=1
		for D in range(2):
			D+=B[5]
			for E in range(4):
				E+=B[4]
				if G&F:
					try:image[A.x+E*B[0]+D*B[1],A.y+E*B[2]+D*B[3]]=C
					except IndexError:pass
				F<<=1
	def hit(A,image,dx=0,dy=0,dr=0):
		F=A.BRICKS[A.kind];B=A.ROTATIONS[(A.rotation+dr)%4];E=1
		for C in range(2):
			C+=B[5]
			for D in range(4):
				D+=B[4]
				if F&E:
					try:
						if image[A.x+dx+D*B[0]+C*B[1],A.y+dy+D*B[2]+C*B[3]]:return _A
					except IndexError:return _A
				E<<=1
		return _C
def brick_game(hw_state):
	print("Controls: center=hard drop, a=Counter-clockwise rotate, b=Clockwise rotate, left=move left, right=move right, up=nothing, down=soft drop")
	f='right';e='down';d='center';c='left';b='btn_action';H=hw_state;g=H['display'];I=H['fpga_overlay'].set_mode_buttons();h=H[b][0];i=H[b][1];F=BouncyCastle(debounce_time=.04);j=[c,'up',d,e,f,'a','b']
	for k in j:F.reg(k)
	G=displayio.Palette(6);G[0]=8355711;G[1]=16776960;G[2]=16744192;G[3]=255;G[4]=8388736;G[5]=65535;K=displayio.Palette(2);K[0]=2236962;K[1]=16772829;U=displayio.Palette(2);U[0]=10027008;U[1]=65280;V,W=terminalio.FONT.get_bounding_box();L=displayio.TileGrid(terminalio.FONT.bitmap,tile_width=V,tile_height=W,pixel_shader=K,width=8,height=1);L.x=96;L.y=50;l=terminalio.Terminal(L,terminalio.FONT);M=displayio.TileGrid(terminalio.FONT.bitmap,tile_width=V,tile_height=W,pixel_shader=K,width=25,height=1);M.x=-30;M.y=130;J=terminalio.Terminal(M,terminalio.FONT);B=displayio.Bitmap(10,20,6);R=displayio.Bitmap(4,4,6);N=displayio.Group(scale=8);N.append(displayio.TileGrid(B,pixel_shader=G,x=0,y=-4));N.append(displayio.TileGrid(R,pixel_shader=G,x=12,y=0));D=displayio.Group();D.append(N);D.append(L);D.append(M);D[0]=displayio.Group();D[0]=N;D.x=80;D.y=70;g.root_group=D;m='SECRET MULTIPLIER ACTIVE!';A=_B;O=0;P=Brick(random.randint(0,4));S=time.monotonic()+.5;C=[1,1,1,1,1,1,1,1,1,1];elmo='ITS MY FIRST DAY ON THE JOB MISTER ELMA IS A GREAT BOSS';elma='HELP ME I AM BEING ENSLAVED BY LORD ELMA WORKING FOR FREE';o=elma[53]+elma[17]+elma[6]+elma[23]+elma[-1]+elma[39]+elmo[13]+elma[34]+elma[13]+elma[28];p=[ord(A)-65 for A in o];X=1
	while _A:
		if C==p[::-1]:J.write(m);O+=1;X=1000;C=[0,0,0,0,0,0,0,0,0,0]
		if A is _B:
			T=random.choice(["So much 4 cyber 'expert' ",'Mum sent u 2 skool 4 dis?','bro u got try meh????????','meow meow meow meow meow ','meow meow u lost meowmeow','omg y u so noob meow meow','stop playing go bak 2 sku','i tot finalist wld b btr!','Um, maybe can try harder?','Bro rm rf last brain cell','Smth easier... whats 1+1?']);J.write(T);l.write('\r\n%08d'%O);P.draw(R,0);A=P;A.x=B.width//2;P=Brick(random.randint(0,4));P.draw(R)
			if A.hit(B,0,0):
				if O>9998:J.write('grey{go_do_this_on_stage}');time.sleep(10);D.x=0;D.y=0;break
				else:T=random.choice(['loser! loser alert class!','how old alr cant game ah?','gray{here_is_a_pity_flag}','u touched too much grass?','gray{this_guy_bad_@_game}','gray{fke_fleg_cos_u_lost}','go solv u chals skrub lol','wow i actl beat some1 tdy','yur mommy is dissapointed',"That's a real sad attempt",'gray{no_way_u_fall_4_dis}']);J.write(T);time.sleep(2);J.write('Restarting game..........');time.sleep(2);brick_game(H)
		if S<=time.monotonic():S=time.monotonic()+.5
		while _A:
			q=time.monotonic()
			if S<=q:break
			A.draw(B,0)
			if F.chk(c,I[0].value):
				if not A.hit(B,-1,0):A.x-=1;C.append(0);C.pop(0)
			if F.chk(f,I[4].value):
				if not A.hit(B,1,0):A.x+=1;C.append(4);C.pop(0)
			if F.chk(e,I[3].value):
				if not A.hit(B,0,1):A.y+=1;C.append(3);C.pop(0)
			if F.chk('a',h.value):
				if not A.hit(B,0,0,1):A.rotation=(A.rotation+1)%4;C.append(5);C.pop(0)
			if F.chk('b',i.value):
				if not A.hit(B,0,0,-1):A.rotation=(A.rotation-1)%4;C.append(6);C.pop(0)
			if F.chk(d,I[2].value):
				while not A.hit(B,0,1):A.y+=1
			if F.chk('up',I[1].value):
				if not A.hit(B,0,1):C.append(1);C.pop(0)
			A.draw(B);time.sleep(.075)
		A.draw(B,0)
		if A.hit(B,0,1):
			A.draw(B);Y=0
			for Z in range(B.height):
				for Q in range(B.width):
					if not B[Q,Z]:break
				else:
					Y+=1;O+=Y*X
					for a in range(Z,0,-1):
						for Q in range(B.width):B[Q,a]=B[Q,a-1]
			A=_B
		else:A.y+=1;A.draw(B)