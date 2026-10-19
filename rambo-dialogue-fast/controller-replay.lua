-- FAST candidate controller-only dialogue, automatic native five-second holds; no RAM/register installation.
local mem=emu.memType.nesDebug
local mission='F?0fizk7Gp4fFbsGGWm2XdACr0Y4GHWX'
local rows={'0123456789','ABCDEFGHIJ','KLMNOPQRST','UVWXYZ','abcdefghij','klmnopqrst','uvwxyz?!'}
local targets={}
for i=1,32 do targets[#targets+1]={r=7,c=0,label='BS'} end
for i=1,#mission do
 local ch=mission:sub(i,i)
 local found=false
 for r,row in ipairs(rows) do
  local c=row:find(ch,1,true)
  if c then targets[#targets+1]={r=r-1,c=c-1,label=ch}; found=true; break end
 end
 assert(found)
end
targets[#targets+1]={r=7,c=4,label='END'}
local payload={}
local stage={41,6,72,72,105,69,72,10,73,96,10,72,73,32,72,106,72,10,105,36,72,73,37,72,74,105,32,72,74,73,66,72,72,69,36,72,73,104,74,72,74,105,64,72,105,65,72,74,101,36,72,41,32,72,73,40,72,105,72,10,72,74,105,74,72,105,102,72,106,73,34,72,10,73,69,72,73,32,106,72,96}
for i,v in ipairs(stage) do payload[0x1a6+i]=v end
local data={}
for a=0x1f7,0x1a7,-1 do data[#data+1]=payload[a] end
data[#data+1]=1; data[#data+1]=0xa6
for i,v in ipairs(data) do
 assert(v~=0 and (v&0x10)==0 and (i==#data or v<128))
 assert((v&0x0c)~=0x0c and (v&3)~=3, 'opposing directions are forbidden')
end
-- The game clamps decoded $0114=$BE to $63, and sets $0117=$01.
local expected={0xfc,0x20,0xbc,0x87,0xad,0x33,0x01,0x48,0x10,0xf7,0x60,0x18,0xa5,0x00,0x10,0x18,0xa6,0x00,0x5a,0x2e,0x63,0,0,1}
local function buttons(v)
 return {a=(v&128)~=0,b=(v&64)~=0,select=(v&32)~=0,start=(v&16)~=0,up=(v&8)~=0,down=(v&4)~=0,left=(v&2)~=0,right=(v&1)~=0}
end
local vectors={99,130,123,129,129,140,229,241,138,120,241,123,116,137,120,241,116,255,131,133,130,117,127,120,128,228,255,255,109,136,133,129,134,241,130,136,135,241,130,136,133,255,122,116,128,120,144,134,241,131,116,134,134,138,130,133,119,255,124,129,131,136,135,134,241,116,133,120,129,144,135,255,131,133,130,131,120,133,127,140,241,137,116,127,124,119,116,135,120,119,228,255,255,98,241,123,116,137,120,241,116,241,129,120,138,255,128,124,134,134,124,130,129,241,121,130,133,241,140,130,136,228,255,255,96,130,241,135,130,255,122,124,135,123,136,117,228,118,130,128,145,255,95,124,129,127,120,140,109,120,122,136,145,255,129,120,134,231,133,116,128,117,130,231,116,118,120,255,255,116,129,119,241,134,120,120,241,138,123,116,135,241,135,123,120,255,131,133,130,117,127,120,128,241,124,134,228,255,255,105,120,130,131,127,120,241,118,130,136,127,119,241,136,134,120,255,135,123,124,134,241,135,130,241,117,133,120,116,126,241,135,123,120,255,116,129,140,146,241,133,120,118,130,133,119,228,255,255,104,133,241,120,137,120,129,241,128,116,126,120,241,136,134,255,131,127,116,140,241,105,130,129,122,241,130,133,241,108,129,116,126,120,228,255,255,90,129,140,241,132,136,120,134,135,124,130,129,134,142,255,255,99,136,134,135,241,130,129,120,228,241,112,123,116,135,241,135,123,120,255,123,120,127,127,241,124,134,241,116,241,96,124,135,97,136,117,142,255,255,0,138,72,32,112,137,165,20,208,4,169,128,133,20,104,170,96,11,208,5,12,16,25,4,72,11,0,4,12,170,32,20,4,72,11,28,4,12,170,32,20,4,72,11,93,4,12,170,32,20,4,72,11,124,4,12,170,32,20,4,72,11,169,4,12,170,32,20,4,72,11,199,4,12,170,32,20,4,72,11,248,4,12,170,32,20,4,72,11,29,5,12,170,32,20,5,0,11,45,5,12,36,34,20,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,6,12,24,48,96,192,128,2,6,12,24,48,96,192,128,98,100,8,16,38,70,0,0,98,100,8,16,38,70,0,0,255,255,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
local first={162,255,154,169,0,133,6,168,169,4,133,7,32,50,6,41,240,145,6,32,50,6,74,74,74,74,17,6,145,6,200,208,235,230,7,165,7,201,6,208,227,76,64,6,173,36,1,205,36,1,240,251,32,78,142,165,11,96,162,255,154,169,16,141,0,32,169,0,141,1,32,169,6,141,68,1,32,177,194,169,133,141,0,1,32,220,202,32,71,203,169,5,141,68,1,32,177,194,169,14,141,132,1,32,115,193,32,89,128,169,0,133,10,32,154,142,162,0,169,248,157,0,2,232,232,232,232,208,247,169,0,133,17,133,18,169,100,133,13,169,5,133,14,160,0,169,0,133,17,32,196,129,152,72,169,1,133,20,162,45,160,1,173,36,1,205,36,1,240,251,32,84,5,202,208,242,136,16,239,104,168,192,87,144,216,76,191,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
local stream={}
for _,v in ipairs(first) do stream[#stream+1]=v end
for _,v in ipairs(vectors) do stream[#stream+1]=v end
local bitstream={}
for _,v in ipairs(stream) do for b=0,7 do bitstream[#bitstream+1]=0x40|((v>>b)&1) end end
local fastIndex=0
local nibbles={}
for _,v in ipairs(vectors) do nibbles[#nibbles+1]=v&0xf0;nibbles[#nibbles+1]=(v<<4)&0xf0 end
local decodeFrame,decoded=0,0
local mode='entry'
local frame,transferFrame,n,ti,held=0,0,0,1,0
local failed=false
local entryValidated=false
local transferValidated=false
local function fail(msg) failed=true; emu.log('FAIL '..msg); emu.breakExecution() end
emu.addEventCallback(function()
 frame=frame+1
 local v=0
 if mode=='entry' then
  local phase=(frame-1)%8
  if phase==0 then
   held=0
   local t=targets[ti]
   if t then
    local c,r=emu.read(3,mem),emu.read(4,mem)
    if r==7 then c=c-(c%2) end -- BS/SP/END each occupy two cursor columns.
    if r~=t.r then held=(r<t.r) and 4 or 8
    elseif c~=t.c then held=(c<t.c) and 1 or 2
    else
     held=128
     if ti%8==0 or t.label=='END' then emu.log('Entered target '..ti..'/65: '..t.label) end
     ti=ti+1
    end
   else mode='awaitNative'; emu.log('Mission submitted: '..mission) end
  end
  if phase<4 then v=held end
 elseif mode=='fast' then
  v=nibbles[fastIndex] or 0
 elseif mode=='decode' then
  decodeFrame=decodeFrame+1
  local f=decodeFrame-5
  local i=math.floor(f/2)+1
  v=(f>=0 and f%2<1) and (bitstream[i] or 0) or 0
  if decodeFrame==8*#bitstream+100 then fail('reader timeout decoded='..decoded) end
 elseif mode=='transfer' then
  transferFrame=transferFrame+1
  local f=transferFrame-5
  local i=math.floor(f/2)+1
  v=(f>=0 and f%2<1) and (data[i] or 0) or 0
  if transferFrame>8*#data+100 then fail('transfer timeout; pushes='..n) end
 end
 emu.setInput(buttons(v),0)
 if frame>70000 then fail('overall timeout; mode='..mode..'; target='..ti) end
end,emu.eventType.inputPolled)
emu.addMemoryCallback(function()
 if mode=='entry' or mode=='awaitNative' then
  local ok=true
  for i,v in ipairs(expected) do
   local got=emu.read(0xff+i,mem)
   if got~=v then ok=false; emu.log(string.format('DECODE mismatch %04X got %02X expected %02X',0xff+i,got,v)) end
  end
  local s=emu.getState()
  emu.log(string.format('Entry registers A=%02X X=%02X Y=%02X SP=%02X',s['cpu.a'],s['cpu.x'],s['cpu.y'],s['cpu.sp']))
  ok=ok and s['cpu.sp']==0xf7 and s['cpu.a']==0 and s['cpu.x']==0x5c and s['cpu.y']==9
  entryValidated=ok
  emu.log('Actual mission-code native entry: bytes and registers match='..tostring(ok))
  if not ok then fail('entry mismatch'); return end
  mode='transfer'; transferFrame=0
 end
end,emu.callbackType.exec,0x101)
emu.addMemoryCallback(function()
 if mode~='transfer' then return end
 n=n+1
 local v=emu.read(0x133,mem)
 if v~=data[n] then fail(string.format('push %d received %02X expected %s',n,v,tostring(data[n]))) end
 if n%16==0 or n==#data then emu.log('Controller values received: '..n..'/'..#data) end
end,emu.callbackType.exec,0x107)
emu.addMemoryCallback(function()
 if mode~='transfer' then return end
 local ok=n==#data
 for a=0x1a7,0x1f7 do if emu.read(a,mem)~=payload[a] then ok=false end end
 local constants={{1,22},{2,64},{4,166},{5,0},{6,9},{8,4},{9,0},{0x24,0x78}}
 for _,kv in ipairs(constants) do
  local got=emu.read(kv[1],mem)
  if got~=kv[2] then ok=false; emu.log(string.format('ZP %02X got=%02X want=%02X',kv[1],got,kv[2])) end
 end
 local st=emu.getState()
 emu.log(string.format('81-BYTE STAGE MATCH=%s; A=%02X X=%02X Y=%02X SP=%02X P=%02X',tostring(ok),st['cpu.a'],st['cpu.x'],st['cpu.y'],st['cpu.sp'],st['cpu.ps']))
 if not ok or (st['cpu.ps']&1)~=1 then fail('stage/constants/carry mismatch') end
end,emu.callbackType.exec,0x1a7)
emu.addMemoryCallback(function()
 if mode~='transfer' then return end
 local t={162,0,154,160,8,32,188,135,70,11,126,6,6,136,208,245,232,208,240,76,6,6}
 local ok=true
 for i,v in ipairs(t) do if emu.read(0x190+i,mem)~=v then ok=false end end
 emu.log('CONTROLLER-SYNTHESIZED WRAP STACK RECEIVER MATCH='..tostring(ok))
 if not ok then fail('receiver synthesis mismatch'); return end
 mode='decode'; decodeFrame=0
end,emu.callbackType.exec,0x191)
emu.addMemoryCallback(function()
 if mode=='decode' then local st=emu.getState();if st['cpu.x']%64==0 then emu.log(string.format('FIRST RECEIVER X=%02X SP=%02X',st['cpu.x'],st['cpu.sp'])) end end
end,emu.callbackType.exec,0x194)
emu.addMemoryCallback(function()
 if mode~='decode' then return end
 local ok=true
 for i,v in ipairs(first) do if emu.read(0x605+i,mem)~=v then ok=false end end
 emu.log('CONTROLLER-ONLY FIRST 256 BYTES MATCH='..tostring(ok)..'; native jump $0606')
 if not ok then fail('first-stage data mismatch') end
 mode='fast'
end,emu.callbackType.exec,0x606)
emu.addMemoryCallback(function()
 if mode~='fast' then return end
 local ok=true
 for i,v in ipairs(vectors) do if emu.read(0x3ff+i,mem)~=v then ok=false;emu.log(string.format('MISMATCH %04X got=%02X want=%02X',0x3ff+i,emu.read(0x3ff+i,mem),v)) end end
 emu.log('CONTROLLER-ONLY SECOND 512 BYTES MATCH='..tostring(ok)..'; native entry $0640')
 if not ok then fail('revised payload transfer failed');return end
 emu.log('FAST NATIVE ENTRY input samples='..frame..'; nibbles='..fastIndex);mode='native';emu.log('READY: select Normal speed, then F5 for automatic five-second pages');emu.breakExecution()
end,emu.callbackType.exec,0x640)
emu.addMemoryCallback(function()
 if mode=='decode' then local st=emu.getState();if st['cpu.x']%64==0 then emu.log(string.format('SECOND RECEIVER page=%02X X=%02X',emu.read(0x615,mem),st['cpu.x'])) end end
end,emu.callbackType.exec,0x60b)
emu.addMemoryCallback(function()
 if mode=='transfer' or mode=='decode' or mode=='native' then fail('unexpected reset/BRK path') end
end,emu.callbackType.exec,0xc000)
emu.log('ANIMATED CONTROLLER-ONLY DIALOGUE: 81-byte synthesis, 256+512 bytes, stock colors/music, native five-second waits')
local expectedPalette={15,15,15,15,15,15,15,15,15,15,15,22,15,15,48,48,15,16,54,10,15,22,54,23,15,26,54,55,15,28,54,48}
local allLines={{{99,130,123,129,129,140,229,241,138,120,241,123,116,137,120,241,116},{131,133,130,117,127,120,128,228}},{{109,136,133,129,134,241,130,136,135,241,130,136,133},{122,116,128,120,144,134,241,131,116,134,134,138,130,133,119},{124,129,131,136,135,134,241,116,133,120,129,144,135},{131,133,130,131,120,133,127,140,241,137,116,127,124,119,116,135,120,119,228}},{{98,241,123,116,137,120,241,116,241,129,120,138},{128,124,134,134,124,130,129,241,121,130,133,241,140,130,136,228}},{{96,130,241,135,130},{122,124,135,123,136,117,228,118,130,128,145},{95,124,129,127,120,140,109,120,122,136,145},{129,120,134,231,133,116,128,117,130,231,116,118,120}},{{116,129,119,241,134,120,120,241,138,123,116,135,241,135,123,120},{131,133,130,117,127,120,128,241,124,134,228}},{{105,120,130,131,127,120,241,118,130,136,127,119,241,136,134,120},{135,123,124,134,241,135,130,241,117,133,120,116,126,241,135,123,120},{116,129,140,146,241,133,120,118,130,133,119,228}},{{104,133,241,120,137,120,129,241,128,116,126,120,241,136,134},{131,127,116,140,241,105,130,129,122,241,130,133,241,108,129,116,126,120,228}},{{90,129,140,241,132,136,120,134,135,124,130,129,134,142}},{{99,136,134,135,241,130,129,120,228,241,112,123,116,135,241,135,123,120},{123,120,127,127,241,124,134,241,116,241,96,124,135,97,136,117,142}}}
local glyphs={2,6,12,24,48,96,192,128,2,6,12,24,48,96,192,128,98,100,8,16,38,70,0,0,98,100,8,16,38,70,0,0,255,255}
local nmis,pageNo,readyNmi=0,0,0
local pending=0
emu.addMemoryCallback(function() if mode=='native' then nmis=nmis+1 end end,emu.callbackType.exec,0xee55)
emu.addMemoryCallback(function()
 if mode~='native' then return end
 pageNo=pageNo+1;readyNmi=nmis
 local ok=true
 local ptr=(pageNo==9) and 0x2224 or 0x20aa
 for row,line in ipairs(allLines[pageNo]) do for i,v in ipairs(line) do if emu.read(ptr+(row-1)*0x40+i-1,emu.memType.nesPpuMemory)~=v then ok=false end end end
 for i,v in ipairs(expectedPalette) do if emu.read(0x3eff+i,emu.memType.nesPpuMemory)~=v then ok=false end end
 for i=1,32 do if emu.read(0x190f+i,emu.memType.nesPpuMemory)~=glyphs[i] then ok=false end end
 ok=ok and emu.read(0x15f,mem)==14 and emu.read(0x184,mem)==14
 emu.log(string.format('PAGE %d text/stock palettes/white glyphs/music match=%s Y=%02X',pageNo,tostring(ok),emu.getState()['cpu.y']))
 if not ok then fail('revised page verification failed');return end
 -- No A injection or page pauses: timing is entirely native.
end,emu.callbackType.exec,0x69e)
emu.addMemoryCallback(function()
 if mode~='native' then return end
 emu.log(string.format('PAGE %d native wait elapsed=%d NMI frames',pageNo,nmis-readyNmi))
 if nmis-readyNmi~=301 then fail('wrong delay') end
end,emu.callbackType.exec,0x6b9)
emu.addMemoryCallback(function() if mode=='native' then emu.log('PASS: CONTROLLER-ONLY NINE-PAGE RUN COMPLETE; stock palette/music, all 301-frame delays verified; stock mouth animation');emu.breakExecution() end end,emu.callbackType.exec,0x6bf)
emu.addEventCallback(function() if pending>0 then pending=pending-1;if pending==0 then emu.log('REVISED page visible '..pageNo);emu.breakExecution() end end end,emu.eventType.endFrame)
emu.addMemoryCallback(function() if mode=='native' then fail('unexpected reset') end end,emu.callbackType.exec,0xc000)

local mouthCalls,upperOpen,upperClosed,lowerOpen,lowerClosed=0,0,0,0,0
emu.addMemoryCallback(function()
 if mode~='native' then return end
 mouthCalls=mouthCalls+1
end,emu.callbackType.exec,0x8970)
emu.addMemoryCallback(function()
 if mode~='native' then return end
 local x=emu.getState()['cpu.x'];local a=emu.getState()['cpu.a']
 if x==0x30 and a==0xf8 then upperOpen=upperOpen+1 elseif x==0x30 and a==0x48 then upperClosed=upperClosed+1
 elseif x==0xb0 and a==0xf8 then lowerOpen=lowerOpen+1 elseif x==0xb0 and a==0xa8 then lowerClosed=lowerClosed+1 end
end,emu.callbackType.exec,0x89f9)
emu.addMemoryCallback(function()
 if mode~='native' then return end
 local expected=pageNo*301
 local ok=mouthCalls==expected and upperOpen>0 and upperClosed>0 and (pageNo<9 or (lowerOpen>0 and lowerClosed>0))
 emu.log(string.format('MOUTH page=%d calls=%d U open=%d closed=%d L open=%d closed=%d match=%s',pageNo,mouthCalls,upperOpen,upperClosed,lowerOpen,lowerClosed,tostring(ok)))
 if not ok then fail('stock mouth verification failed') end
end,emu.callbackType.exec,0x6b9)

emu.addMemoryCallback(function()
 if mode~='fast' then return end
 fastIndex=fastIndex+1
 if fastIndex%128==1 then emu.log('FAST nibble '..fastIndex..'/1024') end
end,emu.callbackType.exec,0x632)
emu.addMemoryCallback(function()
 if mode~='fast' then return end
 local got=emu.read(0xb,mem)&0xf0
 if got~=nibbles[fastIndex] then fail(string.format('fast nibble %d got=%02X expected=%02X',fastIndex,got,nibbles[fastIndex] or 0)) end
end,emu.callbackType.exec,0x63f)
