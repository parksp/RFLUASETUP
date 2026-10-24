-- Offline, lazy-loaded motor selector. Browsing never writes to the FC.
return function(h)
 local M={active=false}
 local brands,models,brand,items={},nil,nil,{}
 local stage,prior,query,edit,focus,first='brands',nil,'','',1,1
 local selected,notice,lastFocus=nil,nil,1
 local keys={}
 for c in string.gmatch('1234567890QWERTYUIOPASDFGHJKLZXCVBNM-.','.')do keys[#keys+1]=c end
 for _,k in ipairs({'SPACE','DEL','CLEAR','DONE','CANCEL'})do keys[#keys+1]=k end
 local function loadData(name)
  local ok,chunk=pcall(loadScript,'/SCRIPTS/RFLUASETUP/DATA/HELICOPTERS/'..name..'.lua')
  if not ok or type(chunk)~='function'then return nil end
  local good,value=pcall(chunk);if good and type(value)=='table'then return value end
 end
 local function rebuild()
  items={};local words={};for w in string.gmatch(string.lower(query),'%S+')do words[#words+1]=w end
  for i,m in ipairs(models or{})do
   local text=string.lower(m[1]..' '..tostring(m[2])..'kv');local match=true
   for _,word in ipairs(words)do if not string.find(text,word,1,true)then match=false;break end end
   if match then items[#items+1]=i end
  end
  focus=1;first=1
 end
 local function clip(s,n)
  if #s<=n then return s end
  local start=n
  while start>0 and s:byte(start)>=128 and s:byte(start)<=191 do start=start-1 end
  local b=s:byte(start)or 0
  local width=b>=240 and 4 or(b>=224 and 3 or(b>=192 and 2 or 1))
  if start+width-1>n then n=start-1 end
  return string.sub(s,1,n)
 end
 local function short(s,n)if #s>n then return clip(s,n-3)..'...'end;return s end
 local function wrap(s,x,y,width)
  local line='';for word in string.gmatch(s,'%S+')do
   if #line+#word+1>width then h.txt(x,y,line,'text');y=y+23;if y>329 then return y end;line=word else line=line==''and word or line..' '..word end
  end
  if line~=''then h.txt(x,y,line,'text')end;return y+23
 end
 local function back()
  notice=nil
  if stage=='search'then stage=prior;focus=1
  elseif stage=='review'then stage='models';focus=lastFocus
  elseif stage=='models'then models=nil;items={};brand=nil;query='';stage='brands';focus=1;first=1;collectgarbage()
  else M.active=false end
 end
 function M.open()
  brands=loadData('index')or{};models=nil;brand=nil;items={};query='';stage='brands';focus=1;first=1;notice=#brands==0 and'CATALOG FILES NOT FOUND'or nil;M.active=true
 end
 function M.action(action,index)
  notice=nil
  if action=='back'then back()
  elseif action=='item'then
   if stage=='brands'then brand=brands[index];models=loadData(brand[2]);if not models then notice='MODEL FILE NOT FOUND';return end;query='';stage='models';rebuild()
   else lastFocus=index;selected=models[items[index]];stage='review';focus=1 end
  elseif action=='search'then prior=stage;edit=query;stage='search';focus=1
  elseif action=='key'then
   local k=keys[index]
   if k=='DONE'then query=edit;stage=prior;rebuild()
   elseif k=='CANCEL'then stage=prior;focus=1
   elseif k=='CLEAR'then edit=''
   elseif k=='DEL'then edit=string.sub(edit,1,-2)
   elseif #edit<32 then edit=edit..(k=='SPACE'and' 'or k)end
  elseif action=='apply'then
   if not selected then return end
   local ok,msg=h.apply(brand[1],selected)
   if ok then M.active=false else notice=msg or'READ FC FIRST'end
  elseif action=='up'or action=='down'then
   local count=stage=='brands'and#brands or#items
   first=math.max(1,math.min(math.max(1,count-5),first+(action=='up'and-6 or 6)));focus=first
  end
 end
 local function enter()
  if stage=='search'then M.action('key',focus)
  elseif stage=='review'then M.action(focus==1 and'apply'or'back')
  else local count=stage=='brands'and#brands or#items
   if focus<=count then M.action('item',focus)
   elseif stage=='models'and focus==count+1 then M.action('search')else back()end
  end
 end
 function M.event(e)
  if e==EVT_VIRTUAL_EXIT then back();return true end
  local count=stage=='search'and#keys or(stage=='review'and 2 or(stage=='brands'and#brands+1 or#items+2))
  if e==EVT_VIRTUAL_NEXT then focus=focus%math.max(1,count)+1;return true
  elseif e==EVT_VIRTUAL_PREV then focus=(focus-2)%math.max(1,count)+1;return true
  elseif e==EVT_VIRTUAL_ENTER then enter();return true end
  return false
 end
 local function btn(id,label,x,y,w,selected,action,index,color)
  h.button('mc'..id,label,x,y,w,34,selected,{kind='gearCatalog',value=action,index=index},color or'cyan')
 end
 function M.draw()
  h.header('HELICOPTER CATALOG',notice or(stage=='brands'and'MANUFACTURER A-Z'or brand[1]))
  if stage=='search'then
   h.txt(28,94,'MODEL SEARCH','cyan');h.txt(28,125,edit..'_','text',true)
   for i,k in ipairs(keys)do local row=math.floor((i-1)/10);local col=(i-1)%10;local x,w=24+col*75,70;if i>=#keys-2 then x=24+(i-(#keys-2))*170;w=160 end;btn('key'..i,k,x,170+row*42,w,focus==i,'key',i)end
   h.footer('Search within this manufacturer. Words match model name.');return
  elseif stage=='review'then
   local y=wrap(selected[1],28,96,65)
   h.txt(28,y+15,selected[10]and(selected[10][1]==0 and'SELECT DOCUMENTED CONFIGURATION'or'PUBLISHED MANUFACTURER RATIOS')or(selected[3]>0 and'MANUAL VERIFIED DEFAULT'or'MANUAL INPUT REQUIRED'),'orange',true)
   wrap((selected[8]=='independent_tail'or selected[8]=='independent_direct')and'Independent tail motor: no fixed tail/main gear ratio. APPLY MAIN changes only the main fields.'or selected[10]and selected[4]or(selected[8]=='direct'and'Direct main drive, fixed 1:1. Check the fitted tail belt pulleys.'or selected[3]>0 and'Check the fitted pinion and pulleys. Defaults refer to the documented version.'or'No default ratios supplied. Enter the complete main and tail drive using your actual parts.'),28,y+70,70)
   btn('apply','CONFIGURE GEARS / RPM >',28,360,470,focus==1,'apply')
   btn('back','< MODELS',530,360,230,focus==2,'back');h.footer('Preview only. Applying ratios and SAVE FC are separate actions.');return
  end
  local count=stage=='brands'and#brands or#items
  if focus<=count then if focus<first then first=focus elseif focus>first+5 then first=focus-5 end end
  h.txt(28,92,stage=='brands'and'SELECT MANUFACTURER'or('SEARCH: '..(query==''and'(all models)'or query)),'cyan')
  if count==0 then h.txt(28,160,'NO MATCHING MODELS','orange')end
  for i=first,math.min(count,first+5)do
   local label
   if stage=='brands'then label=brands[i][1]..'   ('..brands[i][3]..')'
   else local m=models[items[i]];label=short(m[1],80)end
   btn('item'..i,label,28,119+(i-first)*39,685,focus==i,'item',i)
  end
  btn('up','^',725,119,48,false,'up');btn('down','v',725,314,48,false,'down')
  h.txt(28,365,tostring(count)..' entries','muted')
  if stage=='models'then btn('search','SEARCH',250,395,230,focus==count+1,'search')end
  btn('back','< BACK',530,395,230,focus==(stage=='brands'and count+1 or count+2),'back')
  h.footer('Roller: browse / ENTER: select / RTN: back. Catalog stored on SD card.')
 end
 return M
end
