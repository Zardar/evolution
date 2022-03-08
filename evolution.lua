--Алгоритм 'Эволюция' придумал John Horton Conway
--Всех заинтересованных в подробностях отправляю в вики.
--На днях, при просмотре раздела 'игры' местного форума',
--взгляд мой натолкнулся на тему с его реализацией.
--Сам код предоставленный в ней я подробно не рассматривал,
--но идея воплотить давнишние размышления в код вспыхнула.
--Ниже будет расположено моё решение этого алгоритма
--в рамках языка lua, среда Open Computers 1.7.5

--Когда-то в прошлом я узнал отсуществовании решения
--этой задачи, выполнявшейся в разы быстрее остальных.
--Меня это заинтересовало, и после некоторых размышлений
--мной было придумано довольно быстрое решение.
--Оно не было тогда реализовано. Сейчас, по прошествии
--полутора десятков лет, я попробую припомнить и повторить его
--с некоторыми изменениями соответствующими реалиям выбранной среды.

--Итак, начнём: у нас есть поле ограниченных размеров.
--На поле есть некоторое количество сгруппированных точек.
--Для обсчёта их состояний нам понадобятся 2 основных массива,
--каждый из которых будет содержать всё поле:
--один будет содержать текущие точки
--в другой будут заноситься изменения для следующей генерации.
--После завершения вычислений ссылки на массивы меняются местами.
--В дополнительном, иерархично расположенном выше массиве
--screen, будут отображаться ссылки для следующей итерации вычислений.
--задачей этого массива будет предоставление посредством ссылок сведений
--о координатах узлов, изменивших своё состояние, и смежных с ними.
--Ещё один, весьма похожий на него массив actualScreenChanges,
--используется как список произошедших изменений
--для вывода их на экран монитора.
--для начала вычислений нам понадобится занести данные
--в массивы field и screen.

--Проинициируем массивы. они будут носить заданный размер 248*248
--Этот размер связан исключительно с удобством вывода на экран
--почти максимального поля и, возмоно, инфопанели
unicode=require('unicode')
gpu=require('component').gpu
local xs, ys = 248, 248

local field, screen, actualScreenChanges,chars = {},{},{},{}
--field содержит опорную информацию о поле для вычислений
--screen содержит перечень узлов field, к которым необходимо
--прявить пристальное внимание и выяснить их дальнейшую судьбу
--actualScreenChanges представляет собой список узлов
--сменивших своё состояние в течении текущей итерации.
--проинициируем все узлы таблиц в field и таблицы в screen
field.right,field.left,screen.left,screen.right = {},{},{},{}
local l,r = 'left','right'
local function tablesInit()
	for y = 1,ys do 
	    field[r][y] = {}
	    field[l][y] = {}
	    for x=1, xs do 
	        field[r][y][x] = 0
	        field[l][y][x] = 0
	    end
	end
	local ch_y=(ys-ys%4)/4
	for y=1,ch_y do chars[y]={}end
	return 'tadaaa'
end

--назначили левое поле источником рассчётов следующей итерации

--опишем биткарту шрифта брайля
local bits = {1,8,2,16,4,32,64,128}
--попробуем описать трансформацию значений массива в шрифт брайля
function toUnicode(r,l)
	for y in pairs(actualScreenChanges) do
		ch_y=(y-y%4)/4+1
		if not chars[ch_y] then
			chars[ch_y]={}
		end
		for x in pairs(actualScreenChanges) do
			ch_x=(x-x%2)/2+1
			--единица равна сету, используется or
			--ноль равен войду, используется and
			if not chars[ch_y][ch_x] then 
				chars[ch_y][ch_x]=0
			end
			print (bits[(y%4)*2+x%2+1])
			print (chars[ch_y][ch_x])
			print (actualScreenChanges[y][x])
			chars[ch_y][ch_x]=chars[ch_y][ch_x]+bits[(y%4)*2+x%2+1]*actualScreenChanges[y][x]
		end
	end
	return true
end

--попросим пользователя внести начальные данные
function userInput(l)
	field[l][23]={}
	field[l][23][23]=1
	field[l][23][23]=1
	field[l][23][23]=1
	field[l][22][23]=1
    return 'получили данные'
end

--функция вычисления координат прилегающих клеток
local function getAdjoining(n,ns)
local yl, yr = 1,1
    if n > 1 and n < ns then 
        yl=n-1 
        yr=n+n-1 
    else
        if n== 1 then 
            yl, yr = ys, n+1
        else 
            yl,yr = n-1, n-1 
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
screen[l]={}
for y=1,ys do screen[l][y]={} end
for y in pairs(field[l])do
   yl,yr = getAdjoining(y,ys)
    for x in pairs(field[l])do 
        if field[l][y][x] == 1 then 
            xl,xr = getAdjoining(x,xs)
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
    screen[r]={}
    actualScreenChanges={}
    for y=1,ys do 
    	screen[r][y]={} 
		actualScreenChanges[y]={}
    end
    --получаем из левого экрана сведения о узлах 
    --реалии которых нам интересны 
    for y in pairs (screen[l]) do 
        yl,yr=getAdjoining(y,ys)
        for x in pairs(screen[l][y]) do 
            xl,xr=getAdjoining(x,xs)
            if not field[l][yl] then field[l][yl]={}end
            if not field[l][yr]then field[l][yr]={}end
            neighbors = 
            (field[l][y][xl] or 0) + (field[l][y][x] or 0)+ (field[l][y][xr] or 0)+ 
            (field[l][yl][xl] or 0) + (field[l][yl][x] or 0) + (field[l][yl][xr] or 0)+
            (field[l][yr][xl] or 0) + (field[l][yr][x] or 0) + (field[l][yr][xr] or 0) 
            if neighbors == 3 then 
                setScreen(yl,y,yr,xl,x,xr,r)
                field[r][y][x]=1
                if field[l][y][x]==0 then
                	--узел ожил
                	actualScreenChanges[y][x]=1
                end
            else 
                if neighbors ~= 2 then 
                    setScreen(yl,y,yr,xl,x,xr,r)
                    field[r][y][x]=0
                    if field[l][y][x]==1 then
                    	--узел погиб
                    	actualScreenChanges[y][x]=-1
                    end
                end 
            end 
        end 
        if actualScreenChanges[y]=={} then actualScreenChanges[y]=nil end
    end
    --вычисления следующего состояния колонии завершены
    return 'calculations completed'
end

--выведем изменения на монитор
function showMustGoOne()
    --show news on screen
    --теперь выведем на экран символы брайля
	--а за тем избавимся от пустых фрагментов (0x2800)
	for y in pairs(chars)do
		for x in pairs(chars[y])do
			gpu.set(x,y,unicode.char(10240+chars[y][x]))
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
while allOK() do 
    whatNews(l,r)
    toUnicode(r,l)
    showMustGoOne()
    swap()
end

--В итоге у нас получилась довольно симпатичная програмка
--Возможно, в будущем я найду интерес и время
--чтобы дописать вывод на экран и реализовать интерактивность
--Пока же оставляю код в его настоящем виде
--и предоставляю к осмотру заинтересованной публикой.
