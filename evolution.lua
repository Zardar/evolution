--programm Evolution. Authot Taoshi (Zardar)
local evo={}
local computer = require('computer')
local unicode = require('unicode')
local gpu = require('component').gpu
local term = require('term')
local os = require('os')
local text,show = '',''
local x_dim, y_dim = gpu.getResolution()
local xs = x_dim*2-8 --размер по х в точках символов брайля
local ys = y_dim*4-16 --по у
local iter, dots, changes, neighbors = 0, 0, 0, 0
local l,r = 'left','right'
local pullSignal = computer.pullSignal
local field, snap, screen, actualFieldChanges = {},{},{},{}
local chars, actions,presets = {},{},{}
local user_draw = {unicode.char(0x2800),unicode.char(0x28ff)}
local scroll_x = math.floor(xs/2 - x_dim/4) --задел на тот случай
local scroll_y = math.floor(ys/2 - y_dim/2) --если решу добавить скроллинг
local mode = 'edit'--текущее состояние программы
local restart = false
local events = {touch='touch',drag='touch',drop='touch',key_up='keyUp'}
local time = computer.uptime()
local t = time

--SPECTR
local buttons = {   '(C)lear  (E)dit  (P)lay  (R)estart  (T)erminate', 
                    '(S)top  (P)lay  (C)lear   ПКМ - рисовать,  ЛКМ - стереть',
                    '(S)top  (R)estart'
}
local ru_keys={
    [1067]='s',[1099]='s',[1057]='c',[1089]='c',
    [1059]='e',[1091]='e',[1047]='p',[1079]='p',
    [1050]='r',[1082]='r',[1045]='t',[1077]='t',
}
screen.left,screen.right = {},{}

--опишем биткарту шрифта брайля
local bits = {} 
bits[1]={1,8,2,16,4,32,64,128}
bits[-1]={-1,-8,-2,-16,-4,-32,-64,-128}
--добавим символы для линий и углов
bits.border={
    w=54,h1=184,h2=71,tl1=176,tl2=118,tr1=182,
    tr2=70,br1=62,br2=7,bl1=56,bl2=55
}
for f in pairs (bits.border) do
    bits.border[f]=unicode.char(bits.border[f]+10240)
end
bits.line=''
for f=3,x_dim-2 do
    bits.line=bits.line..bits.border.w
end
bits.border.tl1=bits.border.tl1..bits.border.tl2
bits.border.tr1=bits.border.tr1..bits.border.tr2
bits.border.bl1=bits.border.bl1..bits.border.bl2
bits.border.br1=bits.border.br1..bits.border.br2
bits.border.h1=bits.border.h1..bits.border.h2
local buffer = gpu.allocateBuffer(1,1)
gpu.setActiveBuffer(buffer)
-----
--field содержит опорную информацию о поле для вычислений
--screen[l] содержит перечень проверяемых узлов field
--actualFieldChanges принимает изменения field
-----

--перехват ивентов. надстройка над ОС
function computer.pullSignal(...)
    local e = {pullSignal(...)}
        if events[e[1]] then
            return actions[events[e[1]]](e)
        end
    return true --table.unpack(e) 
end

-------------------------------------------

--actions by key_up

--actions.l=function(e)
 --   if mode == 'edit' or mode == 'select' then 
  --      mode = 'preset'
   --     loadPreset()
 --   end 
 --   return true
--end

actions.c=function()
    if mode == 'play' then
        return true 
    end
    gpu.setActiveBuffer(0)
    term.clear()
    evo.border()
    gpu.setActiveBuffer(buffer)
    return evo.tablesInit()
end
actions.s=function()
    --select
    return evo.select()
end
actions.p=function()
    --play
    if mode == 'play' then
      return true
    end
    return evo.goToPlay()
end
actions.e=function()
    --edit
    if mode=='select' then
    evo.cls_snap()
    return evo.userInput()
  end
  return true
end
actions.t=function()
    --tetminate
    if mode ~= 'select' then
        return true
    end
    mode='terminate'
    gpu.setActiveBuffer(0)
    term.clear()
    computer.pullSignal = pullSignal
    evo=nil
    return true
end
actions.r=function()
    --restart
    if mode ~= 'select' and mode ~= 'play' then
        return true
    end
    if restart then
        return evo.re_start() 
    end
    return true
end
-----------------------------------------------
--1touch 2addres 3x 4y 5 0or1 = LorR
--user draws on screen
actions.touch=function(e)
    if mode ~= 'edit' then
        return true
    end 
    local x = math.floor(e[3]/2)
    local y = math.floor(e[4])
    if y+2 >= y_dim or e[3]<3 or e[3]+2>=x_dim or y<2 then
        return true 
    end
    field[y+scroll_y][x+scroll_x] = e[5]
    local c = math.floor(e[5]+1)
    local txt = user_draw[c]..user_draw[c]
    gpu.setActiveBuffer(0)
    gpu.set(x*2,y,txt)
    gpu.setActiveBuffer(buffer)
    return true
end

actions.keyUp=function(e)
    local key=math.floor(e[3])
    if key > 128 then
        key = string.lower(ru_keys[key])
    else
        key=string.lower(string.char(key))
    end
    if actions[key] then
        return actions[key](e)
    end
    return true
end
-----------------------------------------------
function evo.border()
    gpu.set(1,1,bits.border.tl1)
    gpu.set(x_dim-1,1,bits.border.tr1)

    gpu.set(3,1,bits.line)
    gpu.set(3,y_dim-2,bits.line)
    for f=3,y_dim-3 do
        gpu.set(1,f,bits.border.h1)
        gpu.set(x_dim-1,f,bits.border.h1)
    end
    gpu.set(1,y_dim-2,bits.border.bl1)
    gpu.set(x_dim-1,y_dim-2,bits.border.br1)
    return true
end

function evo.priehali()
  text='Игра окончена'
  gpu.setActiveBuffer(0)
  gpu.set(20,y_dim,text)
  gpu.setActiveBuffer(buffer)
  return evo.select()
end

function evo.select()
--вывод clear, edit, play
  if mode == 'edit' then
    evo.saveChanges()
  end
  mode='select'
  gpu.setActiveBuffer(0)
  gpu.set(3,y_dim-1,buttons[1])
  gpu.setActiveBuffer(buffer)
  return true
end

function evo.re_start()
  mode = 'restart'
  evo.tablesInit()
  for y in pairs (snap) do 
      for x in pairs (snap[y]) do
          field[y][x] = snap[y][x]
      end
  end
  return evo.goToPlay()
end

----добавим пресеты
function evo.loadPreset()
    --set on screen
    --text of available presets

    
    
end

--проинициируем все узлы таблиц в field и таблицы в screen
function evo.tablesInit()
    for y = 1,ys do 
        field[y] = {}
        actualFieldChanges[y] = {}
        screen[l][y] = {}
        for x=1, xs do 
            field[y][x] = 0
        end
    end
    local ch_y = math.floor(ys/4)
    local ch_x = math.floor(xs/2)
    for y = 1,ch_y do 
        chars[y]={}
        for x = 1,ch_x do 
            chars[y][x] = 0x2800
        end
    end    
    return true   
end

function evo.cls_snap()
    for y = 1, ys do
        snap[y] = {}
    end
    return true
end

--попросим пользователя внести начальные данные.
function evo.userInput()
    mode = 'edit'
    gpu.setActiveBuffer(0)
    term.clear()
    evo.border()
    gpu.set(3,y_dim-1,buttons[2])
    gpu.setActiveBuffer(buffer)
    return true
end

--попробуем описать трансформацию значений массива в шрифт брайля
function evo.toUnicode()
  local ch_x,ch_y,yy,xx=0,0,0,0
    for y in pairs(actualFieldChanges) do
        ch_y=y+3  yy=y-1
        ch_y=math.floor(ch_y/4)
        for x in pairs(actualFieldChanges[y]) do
          ch_x=x+1  xx=x-1
            ch_x=math.floor(ch_x/2)
            chars[ch_y][ch_x]=chars[ch_y][ch_x]+bits[actualFieldChanges[y][x]][1+(yy%4)*2+xx%2]
        end
    end
    return true
end

--вычисление координат прилегающих клеток
function evo.getAdjoining(n,ns)
local yl, yr = 1,1
    if n > 1 and n < ns then 
        yl = n-1 
        yr = n+1 
    else
        if n == 1 then 
            yl, yr = ns, n+1
        else 
            yl,yr = n-1, 1 
        end 
    end
    return yl,yr
end

--обозначим соседей узлов сменивших состояние
function evo.setScreen(yl,y,yr,xl,x,xr,s)
    screen[s][yl][x] = '?'
    screen[s][y][x] = '?'
    screen[s][yr][x] = '?'
    screen[s][yl][xl] = '?'
    screen[s][y][xl] = '?'
    screen[s][yr][xl] = '?'
    screen[s][yl][xr] = '?'
    screen[s][y][xr] = '?'
    screen[s][yr][xr] = '?'
return 'completed'
end

--активация списков экрана узлов и соседей
function evo.saveChanges()
    dots = 0
    changes = 0
    for y in pairs(field) do
       local yl,yr = evo.getAdjoining(y,ys)
        for x in pairs(field[y])do 
            if field[y][x] == 1 then
                snap[y][x] = 1
                actualFieldChanges[y][x] = 1
                dots = dots + 1
                changes = changes + 1
                local xl,xr = evo.getAdjoining(x,xs)
                evo.setScreen(yl,y,yr,xl,x,xr,l)
            end 
        end
    end 
    restart = true
    return true
end

--очищаем экран и отправляемся к сохранению
-- изменений поля в экране
function evo.goToPlay()
    gpu.setActiveBuffer(0)
    term.clear()
    evo.border()
    gpu.setActiveBuffer(buffer)
    if mode == 'edit' or mode == 'restart' then
        evo.saveChanges()    
        iter=0
        evo.toUnicode()
        evo.showMustGoOne()
    end
    mode = "play"
    gpu.setActiveBuffer(buffer)
    gpu.set(3,y_dim-1,buttons[3])
    gpu.setActiveBuffer(0)
    return  evo.main()
end

--поиск узлов которые сменят состояние
function evo.whatNews()
    time = t
    changes = 0
    for y=1,ys do 
        screen[r][y] = {}
        actualFieldChanges[y] = {}
    end
    --получаем из левого экрана сведения о узлах 
    --реалии которых нам интересны 
    for y in pairs (screen[l]) do 
        local yl,yr=evo.getAdjoining(y,ys)
        for x in pairs(screen[l][y]) do 
            local xl,xr=evo.getAdjoining(x,xs)
            neighbors = 
            field[y][xl] + field[y][xr] + 
            field[yl][xl] + field[yl][x] + field[yl][xr] +
            field[yr][xl] + field[yr][x] + field[yr][xr]
            if neighbors == 3 then 
                if field[y][x] == 0 then
                    evo.setScreen(yl,y,yr,xl,x,xr,r)
                    --узел ожил
                    dots = dots+1
                    changes=changes+1
                    actualFieldChanges[y][x] = 1
                end
            else 
                if neighbors ~= 2 then 
                    if field[y][x] == 1 then
                        evo.setScreen(yl,y,yr,xl,x,xr,r)
                        --узел погиб
                        dots = dots-1
                        changes = changes+1
                        actualFieldChanges[y][x] = -1
                    end
                end 
            end 
        end 
    end 
    return true
end
    --вычисления следующего состояния колонии завершены
    --произведём имплементацию изменений
function evo.implementDots()
    for y in pairs(actualFieldChanges) do
        for x in pairs(actualFieldChanges[y]) do
            field[y][x] = field[y][x] + actualFieldChanges[y][x]
        end
    end
    if changes ~= 0 then
        return true
    else
        --за прошедшую итерацию не было изменений
        return evo.priehali()
    end
end

--теперь выведем на экран символы брайля
function evo.showMustGoOne()
    gpu.setActiveBuffer(0)
    for y in pairs(chars)do
        show=''
        
        for x in pairs(chars[y])do
            show = show..unicode.char(chars[y][x])    
        end
        gpu.set(3,y+1,show)
    end
    gpu.setActiveBuffer(buffer)
    return true
end

---для перехода к следующему витку поменяем ссылки на левое и правое
function evo.swap()
    l,r = r,l
end

--вывод инфо. Число точек, циклов
function evo.iteration()
    text = 'iter:'..tostring(iter)..' dots:'..tostring(dots)..'    '
    --if t - time < 0.95 then os.sleep(0.95-(t-time)) end
    gpu.setActiveBuffer(0)
    gpu.set(3,y_dim,text)
    gpu.setActiveBuffer(buffer)
    iter = iter+1
    os.sleep(0.01)
    return true
end

function evo.main()
  
  while mode=='play' do
      evo.whatNews()
      evo.implementDots()
      evo.toUnicode()
      evo.showMustGoOne()
      evo.iteration()
      evo.swap()
  end
  return true
end

evo.cls_snap()
evo.tablesInit()
evo.userInput()
return evo