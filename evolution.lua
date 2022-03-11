local computer=require('computer')
local unicode = require('unicode')
local gpu = require('component').gpu
local term = require('term')
local os = require('os')
local text = ''
local x_dim, y_dim = gpu.getResolution()
local iter, dots, changes, neighbors = 0, 0, 0, 0
local l,r = 'left','right'
local pullSignal=computer.pullSignal
local field, screen, actualScreenChanges={},{},{}
local events, chars, actions = {},{},{}
local user_draw={unicode.char(0x2800),unicode.char(0x28ff)}
local scroll_x=xs/2-x_dim/4
local scroll_y=ys/4-y_dim/2
local setDots=unicode.char(0x28ff)..unicode.char()
local xs=x_dim*2
local ys=y_dim*4-8
local mode='edit'
events.touch='touch'
events.drag='touch'
events.drop='touch'
events.key_down='keyDown'
screen.left,screen.right = {},{}

--перехват ивентов. надстройка над ОС
function computer.pullSignal(...)
    local e={pullSignal(...)}
        if events[e[1]] then
            return events[e[1]](e)
        end
    return table.unpack(e) 
end

function userSet(y,x,c)
    local txt=user_draw[c]..user_draw[c]
    gpu.set(x*2,y,txt)
    return true
end

--1touch 2addres 3x 4y 5 0or1 = LorR
function events.touch(e)
    local x=(e[3]-e[3]%2)/2
    local y=e[4]
    if mode == 'play' then 
        if x < 45 and x>39 and y > y_dim-1 then
            return userInput()
        else
            return 'showMustGoOne'
        end
    end
    if x < 6 and y > y_dim-1 then 
        return goToPlay()
    end
    field[y][x]=e[5]
    local c=e[5]+1
    return userSet(y,x,c)
end


--field содержит опорную информацию о поле для вычислений
--screen содержит перечень узлов field, к которым необходимо
--прявить пристальное внимание и выяснить их дальнейшую судьбу
--actualScreenChanges представляет собой список узлов
--сменивших своё состояние в течении текущей итерации.
=======
actions.s=function()
    --stop
    end
actions.p=function()
    --play
    end
actions.e=function()
    --exit menu
    end
function events.keyDown(e)
    local key=string.lower(string.char(e[4]))
        if actions[key] then
            actions[key]()
        end
    return (e)
end
        
function touch(e)
    
    
    end

--проинициируем все узлы таблиц в field и таблицы в screen
local function tablesInit()
	for y = 1,ys do 
	    field[y] = {}
        actualScreenChanges[y] = {}
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
	return userInput()   
end
--опишем биткарту шрифта брайля
local bits = {1,8,2,16,4,32,64,128}
--попробуем описать трансформацию значений массива в шрифт брайля
function toUnicode()
	for y in pairs(actualScreenChanges) do
        local ch_y=math.floor((y-y%4)/4)+1
        for x in pairs(actualScreenChanges) do
            local ch_x=math.floor((x-x%2)/2)+1
			print (actualScreenChanges[y][x])
			chars[ch_y][ch_x]=chars[ch_y][ch_x]+bits[(y%4)*2+x%2+1]*actualScreenChanges[y][x]
		end
	end
	return showMustGoOne()
end

--попросим пользователя внести начальные данные.
function userInput()
    mode = 'edit'
    gpu.set(1,y_dim,'play')
    return true
end

--функция вычисления координат прилегающих клеток
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

--здесь создаются целеуказания для проверок напряжений узлов
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

--сохраняем первичный список состояний узлов
function saveChanges()--получаем имя таблицы
    for y in pairs(field)do
       local yl,yr = getAdjoining(y,ys)
        for x in pairs(field[y])do 
            if field[y][x] == 1 then 
                actualScreenChanges[y][x] = 1
                dots = dots + 1
                local xl,xr = getAdjoining(x,xs)
                setScreen(yl,y,yr,xl,x,xr,l)
            end 
        end
    end
--вопросом у нас помечены подозрительные узлы
return toUnicode()
end

function goToPlay()
    mode = 'play'
    term.clear()
    gpu.set(40,y_dim,'STOP')
    return saveChanges()
end
--поиск узлов которые сменят состояние
function whatNews(l,r)--left and right sides
    changes = 0
    for y=1,ys do 
    	screen[r][y] = {}
		actualScreenChanges[y] = {}
    end
    --получаем из левого экрана сведения о узлах 
    --реалии которых нам интересны 
    for y in pairs (screen[l]) do 
        local yl,yr=getAdjoining(y,ys)
        for x in pairs(screen[l][y]) do 
            local xl,xr=getAdjoining(x,xs)
            neighbors = 
            field[y][xl] + field[y][x]+ field[y][xr] + 
            field[yl][xl] + field[yl][x] + field[yl][xr] +
            field[yr][xl] + field[yr][x] + field[yr][xr]
            if neighbors == 3 then 
                if field[y][x] == 0 then
                    setScreen(yl,y,yr,xl,x,xr,r)
                	--узел ожил
                    dots = dots+1
                    changes=changes+1
                	actualScreenChanges[y][x] = 1
                end
            else 
                if neighbors ~= 2 then 
                    if field[y][x] == 1 then
                        setScreen(yl,y,yr,xl,x,xr,r)
                    	--узел погиб
                        dots = dots-1
                        changes = changes+1
                    	actualScreenChanges[y][x] = -1
                    end
                end 
            end 
        end 
    end
    --вычисления следующего состояния колонии завершены
    --произведём имплементацию изменений
    for y in pairs(actualScreenChanges) do
        for x in pairs(actualScreenChanges[y]) do
            field[y][x] = field[y][x] + actualScreenChanges[y][x]
        end
    end
    return toUnicode()
end

    --теперь выведем на экран символы брайля
function showMustGoOne()
	for y in pairs(chars)do
		for x in pairs(chars[y])do
            a = unicode.char(chars[y][x])
            gpu.set(x,y,a)
		end
	end 
  return 'set complete'
end
---для перехода к следующему витку поменяем ссылки на левое и правое
function swap()
    l,r = r,l
    return true
end

--здесь мы проверяем не надоело ли пользователю лицезреть эволюцию
function allOK()
    local status = true 
    if mode == 'edit' then status = false end
    return status
end
function iteration()
    text = tostring(iter)..' '..tostring(dots)..' '
    gpu.set(8,y_dim,text)
    if dots == 0 then return true end
    iter = iter+1
    os.sleep(0.05)
    return swap()
end
--вроде всё готово к началу работы програмки
tablesInit()
--запрашиваем начальное состояние поля
--записываем полученные данные в мониторинг посредством screen
---создадим цикл, чтобы всё работало

function main()
while allOK() do 
    whatNews(l,r)
    --print('can I convert it to unicode?')
    toUnicode()
    --print('show me, baby')
    showMustGoOne()
    --swap screens
    swap()
    --show iteration info
    gpu.set(1,ys,tostring(iter)..' '..tostring(dots)..' ')
    iter=iter+1
    --a little wait for OS
    os.sleep(0.05)
end

main()
--В итоге у нас получилась довольно симпатичная програмка
--Возможно, в будущем я найду интерес и время
--чтобы дописать вывод на экран и реализовать интерактивность
--Пока же оставляю код в его настоящем виде
--и предоставляю к осмотру заинтересованной публикой