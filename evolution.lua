local computer = require('computer')
local unicode = require('unicode')
local gpu = require('component').gpu
local term = require('term')
local os = require('os')
local text,show = '',''
local x_dim, y_dim = gpu.getResolution()
local xs = x_dim*2 --размер по х в точках символов брайля
local ys = y_dim*4-8 --по у
local iter, dots, changes, neighbors = 0, 0, 0, 0
local l,r = 'left','right'
local pullSignal = computer.pullSignal
local field, snap, screen, actualFieldChanges = {},{},{},{}
local chars, actions,preset = {},{},{}
local user_draw = {unicode.char(0x2800),unicode.char(0x28ff)}
local scroll_x = xs/2 - x_dim/4 --задел на тот случай
local scroll_y = ys/4 - y_dim/2 --если решу добавить скроллинг
local mode = 'edit'--текущее состояние программы
local restart = false
local events = {touch='touch',drag='touch',drop='touch',key_up='keyUp'}
local time, t = computer.uptime(), 0
--SPECTR
local buttons = {'(C)lear  (E)dit  (P)lay  (R)estart  (T)erminate', 
    '(S)top  (P)lay  (C)lear', '(S)top  (R)estart'}
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
 --   if mode == 'edit' or mode == 'stop' then 
  --      mode = 'preset'
   --     loadPreset()
 --   end 
 --   return true
--end

actions.c=function(e)
    if mode == 'play' then
        return true 
    end
    return tablesInit()
end
actions.s=function()
    --stop
    mode='stop'
    return select()
end
actions.p=function()
    --play
    return goToPlay()
end
actions.e=function()
    --edit
    if mode=='select' then
    cls_snap()
    return userInput()
  end
  return e
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

actions.r=function(e)
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
        return (e) 
    end 
    local x = (e[3]-e[3]%2)/2
    local y = e[4]
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
  gpu.set(1,y_dim-1,text)
  return select()
end

function select()
--вывод clear, edit, play
mode='select'
gpu.set(16,y_dim-1,buttons[1])
return true
end

function re_start()
    tablesInit()
    for y in pairs (snap) do 
        field[y] = {}
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
    local ch_y = (ys-ys%4)/4
    local ch_x = (xs-xs%4)/2
    for y = 1,ch_y do 
        chars[y]={}
        for x = 1,ch_x do 
            chars[y][x] = 0x2800
        end
    end    
    return true   
end

--попробуем описать трансформацию значений массива в шрифт брайля
function toUnicode()
    for y in pairs(actualFieldChanges) do
        local ch_y=math.floor((y-y%4)/4)+1
        for x in pairs(actualFieldChanges[y]) do
            local ch_x=math.floor((x-x%2)/2)+1
            --print (actualFieldChanges[y][x])
            chars[ch_y][ch_x]=chars[ch_y][ch_x]+bits[actualFieldChanges[y][x]][(y%4)*2+x%2+1]
        end
    end
    return true
end

--попросим пользователя внести начальные данные.
function userInput()
    mode = 'edit'
    term.clear()
    gpu.set(16,y_dim-1,buttons[2])
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
    return main()
end

--очищаем экран и отправляемся к сохранению
-- изменений поля в экране
function goToPlay()
    mode='play'
    term.clear()
    gpu.set(16,y_dim-1,buttons[3])
    return saveChanges()
end
--поиск узлов которые сменят состояние
function whatNews()
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
        for x in pairs(chars[y])do
            show = unicode.char(chars[y][x])
            gpu.set(x,y,show)
        end
    end 
  return true
end

---для перехода к следующему витку поменяем ссылки на левое и правое
function swap()
    l,r = r,l
    if mode == 'play' then
        return true
    else
        return select()
    end
end

--вывод инфо. Число точек, циклов
function iteration()
    t=computer.uptime()
    if t - time < 1 then os.sleep(1-(t-time)) end
    text = 'iter:'..tostring(iter)..' dots:'..tostring(dots)..' calc.time:'..t-time
    time=t
    gpu.set(8,y_dim,text)
    --if dots == 0 then return true end
    iter = iter+1
    os.sleep(0.05)
    return true
end
function cls_snap()
    for y = 1, ys do
        snap[y] = {}
    end
    return true
end
--вроде всё готово к началу работы програмки
cls_snap()
tablesInit()
userInput()
function main()
    iter=0
    toUnicode()
    showMustGoOne()
    whatNews()
    implementDots()
    while mode=='play' do
        toUnicode()
        showMustGoOne()
        iteration()
        swap()
        whatNews()
        implementDots()
    end
end
