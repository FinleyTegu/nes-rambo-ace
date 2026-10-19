import json
from pathlib import Path
p=json.loads(Path(__file__).with_name('payload.json').read_text())

def receiver_test(values):
 a=bytearray(2048);a[0x606:0x706]=bytes(p['first'])
 stream=[n for v in values for n in [v&240,(v<<4)&240]]
 pc=0x606;A=X=Y=C=0;Z=False;sp=0;n=0
 while pc!=p['initializerAddress']:
  op=a[pc];pc+=1
  if op in (0xa2,0xa9,0xc9):
   v=a[pc];pc+=1
   if op==0xa2:X=v;Z=X==0
   elif op==0xa9:A=v;Z=A==0
   else:C=int(A>=v);Z=A==v
  elif op==0x9a:sp=X
  elif op==0xa8:Y=A;Z=Y==0
  elif op==0x85:a[a[pc]]=A;pc+=1
  elif op==0xa5:A=a[a[pc]];pc+=1;Z=A==0
  elif op==0x20:
   target=a[pc]|a[pc+1]<<8;pc+=2;assert target==0x632
   A=stream[n];n+=1;Z=A==0
  elif op==0x29:A&=a[pc];pc+=1;Z=A==0
  elif op in (0x91,0x11):
   zp=a[pc];pc+=1;dest=(a[zp]|a[zp+1]<<8)+Y
   if op==0x91:a[dest]=A
   else:A|=a[dest];Z=A==0
  elif op==0x4a:C=A&1;A>>=1;Z=A==0
  elif op==0xc8:Y=(Y+1)&255;Z=Y==0
  elif op==0xe6:dest=a[pc];pc+=1;a[dest]=(a[dest]+1)&255;Z=a[dest]==0
  elif op==0xd0:
   off=a[pc];pc+=1
   if not Z:pc+=off if off<128 else off-256
  elif op==0x4c:pc=a[pc]|a[pc+1]<<8
  else:raise AssertionError((hex(pc-1),hex(op)))
 assert n==1024 and a[0x400:0x600]==bytes(values) and sp==255
receiver_test(p['second'])
receiver_test([(i*73+19)&255 for i in range(512)])
assert p['receiver'][-14:]==[0xad,0x24,1,0xcd,0x24,1,0xf0,0xfb,0x20,0x4e,0x8e,0xa5,0xb,0x60]
for start in [0,1,127,255]:
 a=bytearray(2048);a[0x640:0x640+len(p['nativeCode'])]=bytes(p['nativeCode'])
 pc=p['labels']['page_ready']+2;X=Y=A=0;Z=N=False;frames=0;flag=start;poll=0;calls=0;mouth=0;open_count=closed_count=0
 while pc!=p['labels']['wait_done']:
  op=a[pc];pc+=1
  if op==0xa9:A=a[pc];pc+=1
  elif op==0x85:
   addr=a[pc];pc+=1;assert addr==0x14;mouth=A
  elif op==0x20:
   target=a[pc]|a[pc+1]<<8;pc+=2;assert target==0x554
   calls+=1;mouth=(mouth+1)&255
   if mouth&15==0:
    if mouth&16:open_count+=1
    else:closed_count+=1
   if mouth==0:mouth=128
  elif op==0xa2:X=a[pc];pc+=1
  elif op==0xa0:Y=a[pc];pc+=1
  elif op in (0xad,0xcd):
   addr=a[pc]|a[pc+1]<<8;pc+=2;assert addr==0x124
   if op==0xad:A=flag;poll=0
   else:
    if poll==1:flag=(flag+1)&255;frames+=1
    poll+=1;Z=A==flag
  elif op==0xca:X=(X-1)&255;Z=X==0;N=X>=128
  elif op==0x88:Y=(Y-1)&255;Z=Y==0;N=Y>=128
  elif op in (0xf0,0xd0,0x10):
   off=a[pc];pc+=1;take=Z if op==0xf0 else (not Z if op==0xd0 else not N)
   if take:pc+=off if off<128 else off-256
  else:raise AssertionError((hex(pc-1),hex(op)))
 assert frames==301 and calls==301 and open_count==9 and closed_count==9,(frames,calls,open_count,closed_count)
assert len(p['expectedPalette'])==32
assert all(len(line)<=19 for page in p['pages'] for line in page['lines'])
url=''.join(p['pages'][3]['lines'][1:]);assert url=='github.com/FinleyTegu/nes-rambo-ace'
actual=[' '.join(page['lines']) for page in p['pages']]
assert actual[0]=='Johnny, we have a problem.'
assert actual[1]=="Turns out our game's password inputs aren't properly validated."
assert actual[2]=='I have a new mission for you.'
assert actual[3].replace('github.com/ FinleyTegu/ nes-rambo-ace',url)+' '+actual[4]=='Go to '+url+' and see what the problem is.'
assert actual[5]=='People could use this to break the any% record.'
assert actual[6]=='Or even make us play Pong or Snake.'
assert actual[7]=='Any questions?'
assert actual[8]=='Just one. What the hell is a GitHub?'
assert p['second'][0x154:0x164]==[0x8a,0x48,0x20,0x70,0x89,0xa5,0x14,0xd0,4,0xa9,0x80,0x85,0x14,0x68,0xaa,0x60]
print('PASS: stock mouth wrapper; 9 open/9 closed changes per 301-frame page; 512-byte receiver execution, two nibble frames per byte, native timer=301 frames at four counter phases, exact wording and one-box URL')
