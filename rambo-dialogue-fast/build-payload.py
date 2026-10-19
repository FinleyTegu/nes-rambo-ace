"""Build revised Rambo dialogue with stock palettes/music and native five-second waits."""
import json
from pathlib import Path
PAGES=[
 ('Colonel',['Johnny, we have a','problem.']),
 ('Colonel',['Turns out our',"game's password","inputs aren't",'properly validated.']),
 ('Colonel',['I have a new','mission for you.']),
 ('Colonel',['Go to','github.com/','FinleyTegu/','nes-rambo-ace']),
 ('Colonel',['and see what the','problem is.']),
 ('Colonel',['People could use','this to break the','any% record.']),
 ('Colonel',['Or even make us','play Pong or Snake.']),
 ('Colonel',['Any questions?']),
 ('Rambo',['Just one. What the','hell is a GitHub?'])]
PUNCT={' ':0xf1,'.':0xe4,',':0xe5,'-':0xe7,'?':0x8e,'!':0x8f,"'":0x90,'/':0x91,'%':0x92}
def enc(s):return [PUNCT[c] if c in PUNCT else ord(c)+(25 if c.isupper() else 19) for c in s]
text=[];ptrs=[]
for who,lines in PAGES:
 assert all(len(line)<=19 for line in lines) and len(lines)<=4
 ptrs.append(0x400+len(text))
 for i,line in enumerate(lines):
  if i:text.append(255)
  text+=enc(line)
 text += [255,255]
assert 0x400+len(text)<=0x5d0
slash=[2,6,12,24,48,96,192,128]
percent=[0x62,0x64,0x08,0x10,0x26,0x46,0,0]
glyphs=slash+slash+percent+percent+[255,255]
script=[11,0xd0,5,12,0x10,0x19]
for (who,lines),ptr in zip(PAGES,ptrs):
 script += [4,0x48] if who=='Colonel' else [5,0]
 script += [11,ptr&255,ptr>>8,12,0xaa if who=='Colonel' else 0x24,0x20 if who=='Colonel' else 0x22,20]
assert len(script)==87
base=0x640;code=[];labels={};fix=[]
def emit(*b):code.extend(b)
def label(n):labels[n]=base+len(code)
def branch(op,n):emit(op,0);fix.append((len(code)-1,n))
def lda(v):emit(0xa9,v)
def sta(a):emit(0x8d,a&255,a>>8)
def jsr(a):emit(0x20,a&255,a>>8)
emit(0xa2,0xff,0x9a);lda(0x10);sta(0x2000);lda(0);sta(0x2001)
lda(6);sta(0x144);jsr(0xc2b1);lda(0x85);sta(0x100);jsr(0xcadc);jsr(0xcb47)
lda(5);sta(0x144);jsr(0xc2b1)
lda(0x0e);sta(0x184);jsr(0xc173)
jsr(0x8059);lda(0);emit(0x85,0x0a);jsr(0x8e9a)
emit(0xa2,0);lda(0xf8);label('sprites');emit(0x9d,0,2,0xe8,0xe8,0xe8,0xe8);branch(0xd0,'sprites')
lda(0);emit(0x85,0x11,0x85,0x12);lda(0x64);emit(0x85,0x0d);lda(5);emit(0x85,0x0e,0xa0,0)
label('page');lda(0);emit(0x85,0x11);jsr(0x81c4)
label('page_ready');emit(0x98,0x48,0xa9,1,0x85,0x14,0xa2,0x2d,0xa0,1)
label('wait_frame');emit(0xad,0x24,1)
label('same_frame');emit(0xcd,0x24,1);branch(0xf0,'same_frame');jsr(0x554);emit(0xca);branch(0xd0,'wait_frame');emit(0x88);branch(0x10,'wait_frame')
label('wait_done');emit(0x68,0xa8,0xc0,len(script));branch(0x90,'page');label('idle');emit(0x4c,labels['idle']&255,labels['idle']>>8)
for at,n in fix:
 d=labels[n]-(base+at+1);assert -128<=d<=127;code[at]=d&255
assert base+len(code)<=0x706,(len(code),hex(base+len(code)))
receiver=[162, 255, 154, 169, 0, 133, 6, 168, 169, 4, 133, 7, 32, 50, 6, 41, 240, 145, 6, 32, 50, 6, 74, 74, 74, 74, 17, 6, 145, 6, 200, 208, 235, 230, 7, 165, 7, 201, 6, 208, 227, 76, 64, 6, 173, 36, 1, 205, 36, 1, 240, 251, 32, 78, 142, 165, 11, 96]
first=[0]*256;second=[0]*512
for address,values in [(0x606,receiver),(base,code)]:
 start=address-0x606;assert start>=0 and start+len(values)<=256;first[start:start+len(values)]=values
second[:len(text)]=text
# Preserve timer X, run stock animation, and keep its enable counter alive across wrap.
wrapper=[0x8a,0x48,0x20,0x70,0x89,0xa5,0x14,0xd0,4,0xa9,0x80,0x85,0x14,0x68,0xaa,0x60]
second[0x154:0x154+len(wrapper)]=wrapper
second[0x164:0x164+len(script)]=script
second[0x1d0:0x1d0+len(glyphs)]=glyphs
out={'status':'Revised candidate; emulator verification pending','firstAddress':0x606,'first':first,'secondAddress':0x400,'second':second,'initializerAddress':base,'nativeCode':code,'receiver':receiver,'vmScriptAddress':0x564,'vmScript':script,'textAddress':0x400,'text':text,'textPointers':ptrs,'glyphAddress':0x5d0,'glyphs':glyphs,'pages':[{'speaker':w,'lines':ls} for w,ls in PAGES],'labels':labels,'waitFrames':301,'musicId':14,'paletteRoutine':0x8e9a,'expectedPalette':[15]*11+[22,15,15,48,48,15,16,54,10,15,22,54,23,15,26,54,55,15,28,54,48]}
Path(__file__).with_name('payload.json').write_text(json.dumps(out,indent=2))
print('Text',len(text),'code',len(code),'script',len(script),'labels',labels)
print('\n\n'.join(w+': '+' / '.join(ls) for w,ls in PAGES))
