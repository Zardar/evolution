--programm Evolution. Authot Taoshi (Zardar)
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
                    '(S)top  (P)lay  (C)lear',
                    '(S)top  (R)estart'
                }
screen.left,screen.right = {},{}

--опишем биткарту шрифта брайля
local bits = {} 
bits[1]={1,8,2,16,4,32,64,128}
bits[-1]={-1,-8,-2,-16,-4,-32,-64,-128}

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
    return table.unpack(e) 
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
    term.clear()
    return tablesInit()
end
actions.s=function()
    --select
    return select()
end
actions.p=function()
    --play
    if mode == 'play' then
      return true
    end
    return goToPlay()
end
actions.e=function()
    --edit
    if mode=='select' then
    cls_snap()
    return userInput()
  end
  return true
end
actions.t=function()
    --tetminate
    if mode ~= 'select' then
        return true
    end
    mode='terminate'
    term.clear()
    computer.pullSignal = pullSignal
    return true
end
actions.r=function()
    --restart
    if mode ~= 'select' and mode ~= 'play' then
        return true
    end
    if restart then
        return re_start() 
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
    local c = e[5]+1
    local txt = user_draw[c]..user_draw[c]
    gpu.set(x*2,y,txt)
    return true
end

actions.keyUp=function(e)
    local key=string.lower(string.char(e[3]))
        if actions[key] then
            return actions[key](e)
        end
    return true
end
-----------------------------------------------
function priehali()
  text='Игра окончена'
  gpu.set(20,y_dim,text)
  return select()
end

function select()
--вывод clear, edit, play
  if mode == 'edit' then
    saveChanges()
  end
  mode='select'
  gpu.set(3,y_dim-1,buttons[1])
  return true
end

function re_start()
  mode = 'restart'
  tablesInit()
  for y in pairs (snap) do 
      for x in pairs (snap[y]) do
          field[y][x] = snap[y][x]
      end
  end
  return goToPlay()
end

----добавим пресеты
function loadPreset()
    --set on screen
    --text of available presets
    
    
end

--проинициируем все узлы таблиц в field и таблицы в screen
function tablesInit()
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

function cls_snap()
    for y = 1, ys do
        snap[y] = {}
    end
    return true
end

--попросим пользователя внести начальные данные.
function userInput()
    mode = 'edit'
    term.clear()
    gpu.set(3,y_dim-1,buttons[2])
    return true
end

cls_snap()
tablesInit()
userInput()

--попробуем описать трансформацию значений массива в шрифт брайля
function toUnicode()
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
function getAdjoining(n,ns)
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
function setScreen(yl,y,yr,xl,x,xr,s)
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
function saveChanges()
    dots = 0
    changes = 0
    for y in pairs(field) do
       local yl,yr = getAdjoining(y,ys)
        for x in pairs(field[y])do 
            if field[y][x] == 1 then
                snap[y][x] = 1
                actualFieldChanges[y][x] = 1
                dots = dots + 1
                changes = changes + 1
                local xl,xr = getAdjoining(x,xs)

                setScreen(yl,y,yr,xl,x,xr,l)
            end 
        end
    end 
    restart = true
    return true
end

--очищаем экран и отправляемся к сохранению
-- изменений поля в экране
function goToPlay()
    term.clear()
    if mode == 'edit' or mode == 'restart' then
        saveChanges()    
        iter=0
        toUnicode()
        showMustGoOne()
    end
    mode = "play"
    gpu.set(3,y_dim-1,buttons[3])
    return  main()
end

--поиск узлов которые сменят состояние
function whatNews()
    time = t
    changes = 0
    for y=1,ys do 
        screen[r][y] = {}
        actualFieldChanges[y] = {}
    end
    --получаем из левого экрана сведения о узлах 
    --реалии которых нам интересны 
    for y in pairs (screen[l]) do 
        local yl,yr=getAdjoining(y,ys)
        for x in pairs(screen[l][y]) do 
            local xl,xr=getAdjoining(x,xs)
            neighbors = 
            field[y][xl] + field[y][xr] + 
            field[yl][xl] + field[yl][x] + field[yl][xr] +
            field[yr][xl] + field[yr][x] + field[yr][xr]
            if neighbors == 3 then 
                if field[y][x] == 0 then
                    setScreen(yl,y,yr,xl,x,xr,r)
                    --узел ожил
                    dots = dots+1
                    changes=changes+1
                    actualFieldChanges[y][x] = 1
                end
            else 
                if neighbors ~= 2 then 
                    if field[y][x] == 1 then
                        setScreen(yl,y,yr,xl,x,xr,r)
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
function implementDots()
    for y in pairs(actualFieldChanges) do
        for x in pairs(actualFieldChanges[y]) do
            field[y][x] = field[y][x] + actualFieldChanges[y][x]
        end
    end
    if changes ~= 0 then
        return true
    else
        --за прошедшую итерацию не было изменений
        return priehali()
    end
end

--теперь выведем на экран символы брайля
function showMustGoOne()
    for y in pairs(chars)do
        show=''
        for x in pairs(chars[y])do
            show = show..unicode.char(chars[y][x])    
        end
        gpu.set(3,y+1,show)
    end
    t=computer.uptime() 
    return true
end

---для перехода к следующему витку поменяем ссылки на левое и правое
function swap()
    l,r = r,l
end

--вывод инфо. Число точек, циклов
function iteration()
    text = 'iter:'..tostring(iter)..' dots:'..tostring(dots)..'    '
    --if t - time < 0.95 then os.sleep(0.95-(t-time)) end
    gpu.set(3,y_dim,text)
    iter = iter+1
    os.sleep(0.05)
    return true
end

function main()
  
  while mode=='play' do
      whatNews()
      implementDots()
      toUnicode()
      showMustGoOne()
      iteration()
      swap()
  end
  return true
end

cls_snap()
tablesInit()
userInput()