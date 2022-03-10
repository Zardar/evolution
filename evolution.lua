--Алгоритм 'Эволюция' придумал John Horton Conway
--Всех заинтересованных в подробностях отправляю в вики.
--На днях, при просмотре раздела 'игры' местного форума',
--взгляд мой натолкнулся на тему с его реализацией.
--Сам код предоставленный в ней я подробно не рассматривал,
--но идея воплотить давнишние размышления в код вспыхнула.
--Ниже будет расположено моё решение этого алгоритма
--в рамках языка lua, среда Open Computers 1.7.5

--Проинициируем массивы. они будут носить заданный размер 248*248
--Этот размер связан исключительно с удобством вывода на экран
--почти максимального поля и, возмоно, инфопанели
local unicode=require('unicode')
local gpu=require('component').gpu
local os=require('os')
local text = ''
local x_dim, y_dim = gpu.getResolution()
xs=x_dim*2
ys=y_dim*4-8
local iter=0
local dots=5
local field, screen, actualScreenChanges,chars = {},{},{},{}
--field содержит опорную информацию о поле для вычислений
--screen содержит перечень узлов field, к которым необходимо
--прявить пристальное внимание и выяснить их дальнейшую судьбу
--actualScreenChanges представляет собой список узлов
--сменивших своё состояние в течении текущей итерации.
--проинициируем все узлы таблиц в field и таблицы в screen
screen.left,screen.right = {},{}
local l,r = 'left','right'
local function tablesInit()
	for y = 1,ys do 
	    field[y] = {}
        actualScreenChanges[y] = {}
        screen[l][y] = {}
	    for x=1, xs do 
	        field[y][x] = 0
	    end
	end
	local ch_y=(ys-ys%4)/4
	local ch_x=(xs-xs%4)/2
	for y=1,ch_y do 
        chars[y]={}
	    for x=1,ch_x do 
            chars[y][x]=0x2800
	    end
    end    
	return 'tadaaa'
    
end
--опишем биткарту шрифта брайля
local bits = {1,8,2,16,4,32,64,128}
--попробуем описать трансформацию значений массива в шрифт брайля
function toUnicode()
	for y in pairs(actualScreenChanges) do
		local ch_y=math.floor((y-y%4)/4)+1--1,
		for x in pairs(actualScreenChanges[y]) do
			local ch_x=math.floor((x-x%2)/2)+1
			--единица равна сету, используется or
			--ноль равен войду, используется and
			chars[ch_y][ch_x]=chars[ch_y][ch_x]+bits[(y%4)*2+x%2+1]*actualScreenChanges[y][x]
		end
	end
	return true
end

--попросим пользователя внести начальные данные
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
                actualScreenChanges[y][x]=1
                local xl,xr = getAdjoining(x,xs)
                setScreen(yl,y,yr,xl,x,xr,l)
            end 
        end
    end
--вопросом у нас помечены все узлы, где
--в следующий цикл будут произведены проверки
return 'addition complite'
end

--теперь попробуем произвести вычисления
--определяющие состояние поля в следующей итерации.
--для этого нам понадобится пройти по таблице screen,
--соотнести значения данных в ней с ячейками 
--обсчитываемого поля и сохранить изменения.
--на данный момент у на есть:
--1.поле, содержащее состояние всех узлов.
--2.зеркальное поле, в которое будут внесены изменения.
--3.таблица-указатель, на основе которой произойдут рассчёты.
--4.пустая таблица-указатель
function whatNews(l,r)--left and right sides
    local neighbors = 0
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
        --if #actualScreenChanges[y]==0 then 
        --    actualScreenChanges=nil 
        --end
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

--выведем изменения на монитор
function showMustGoOne()
    --show news on screen
    --теперь выведем на экран символы брайля
	--а за тем избавимся от пустых фрагментов (0x2800)
	for y in pairs(chars)do
		for x in pairs(chars[y])do
            a=unicode.char(chars[y][x])
            gpu.set(x,y,a)
		end
	end
  return 'обновления успешно отображены'
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
toUnicode()
showMustGoOne()

while allOK() do 
    whatNews(l,r)
    toUnicode()
    showMustGoOne()
    swap()
    text = tostring(iter)..' '..tostring(dots)..' '
    gpu.set(1,y_dim,text)
    iter=iter+1
    os.sleep(0.1)
end

--В итоге у нас получилась довольно симпатичная програмка
--Возможно, в будущем я найду интерес и время
--чтобы дописать вывод на экран и реализовать интерактивность
--Пока же оставляю код в его настоящем виде
--и предоставляю к осмотру заинтересованной публикой.