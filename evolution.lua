
local unicode=require('unicode')
local gpu=require('component').gpu
local os=require('os')
local computer=require('computer')
local x_dim, y_dim = gpu.getResolution()
local iter=0
local dots=0
local mode='edit'
local events={}
local scroll_x=xs/2-x_dim/4
local scroll_y=ys/4-y_dim/2
local setDots=unicode.char(0x28ff)..unicode.char()
local l,r = 'left','right'
local neighbors = 0
screen.left,screen.right = {},{}
xs=x_dim*2
ys=y_dim*4-8

events.touch='touch'
events.drag='touch'
events.drop='touch'
events.key_down='keyDown'
actions={}
actions.s=function()
    --stop
    end
actions.p=function()
    --play
    end
actions.e=function()
    --exit menu
    end
function keyDown(e)
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
        screen[l][y] = {} screen[r][y] = {}
	    for x=1, xs do 
	        field[y][x] = 0
	    end
	end
	local ch_y=(ys-ys%4)/4
	local ch_x=xs-xs%4)/2
	for y=1,ch_y do chars[y]={}
	    for x=1,ch_x do chars[y][x]=0x2800
	    end
	return 'tadaaa'
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
	return true
end

--попросим пользователя внести начальные данные.
function userInput(l)
	field[23][23]=1 field[23][24]=1 field[22][25]=1 field[24][25]=1 field[24][24]=1
	
    return 'получили данные'
end

--функция вычисления координат прилегающих клеток
local function getAdjoining(n,ns)
local yl, yr = 1,1
    if n > 1 and n < ns then 
        yl=n-1 
        yr=n+1 
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
local function setScreen(yl,y,yr,xl,x,xr,s)
    screen[s][yl][x]='?'
    screen[s][y][x]='?'
    screen[s][yr][x]='?'
    screen[s][yl][xl]='?'
    screen[s][y][xl]='?'
    screen[s][yr][xl]='?'
    screen[s][yl][xr]='?'
    screen[s][y][xr]='?'
    screen[s][yr][xr]='?'
return 'completed'
end

--сохраняем первичный список состояний узлов
local function saveChanges()--получаем имя таблицы
for y in pairs(field)do
   local yl,yr = getAdjoining(y,ys)
    for x in pairs(field[y])do 
        if field[y][x] == 1 then 
            local xl,xr = getAdjoining(x,xs)
            setScreen(yl,y,yr,xl,x,xr,l)
        end 
    end
end
--вопросом у нас помечены подозрительные узлы
return 'addition complite'
end
--поиск узлов которые сменят состояние
function whatNews(l,r)--left and right sides
    for y=1,ys do 
    	screen[r][y]={}
		actualScreenChanges[y]={}
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
                if field[y][x]==0 then
                    setScreen(yl,y,yr,xl,x,xr,r)
                	--узел ожил
                    dots=dots+1
                	actualScreenChanges[y][x]=1
                end
            else 
                if neighbors ~= 2 then 
                    if field[y][x]==1 then
                        setScreen(yl,y,yr,xl,x,xr,r)
                    	--узел погиб
                        dots=dots-1
                    	actualScreenChanges[y][x]=-1
                    end
                end 
            end 
        end 
    end
    --вычисления следующего состояния колонии завершены
    --произведём имплементацию изменений
    for y in pairs(actualScreenChanges) do
        for x in pairs(actualScreenChanges[y]) do
            field[y][x]=field[y][x]+actualScreenChanges[y][x]
        end
    end
    return 'calculations completed'
end

    --теперь выведем на экран символы брайля
function showMustGoOne()
	for y in pairs(chars)do
		for x in pairs(chars[y])do
        a=unicode.char(chars[y][x])
			gpu.set(x,y,a)
		end
	end
  return 'set complete'
end
---для перехода к следующему витку поменяем ссылки на левое и правое
function swap()
    l,r = r,l
    return 'swap complete'
end

--здесь мы проверяем не надоело ли пользователю лицезреть эволюцию
function allOK()
    local status = true 
    --some comparisions
    return status
end

--вроде всё готово к началу работы програмки
tablesInit()
--запрашиваем начальное состояние поля
userInput(l)
--записываем полученные данные в мониторинг посредством screen
saveChanges()
---создадим цикл, чтобы всё работало

while allOK() do 
    --print('whatsUP?')
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
