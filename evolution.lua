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

--Проинициируем массивы. они будут носить заданный размер 250*250
local field, screen, actualScreenChanges = {},{},{}
--field содержит опорную информацию о поле для вычислений
--screen содержит перечень узлов field, к которым необходимо
--прявить пристальное внимание и выяснить их дальнейшую судьбу
--actualScreenChanges представляет собой список узлов
--сменивших своё состояние в течении текущей итерации.
--проинициируем все узлы таблиц в field и таблицы в screen
field.righ,field.left,screen.left,screen.right = {},{},{},{}

local function tablesInit()
local xs, ys = 250, 250
for y = 1,ys do 
    field.right[y] = {}
    field.left[y] = {}
    for x=1, xs do 
        field.right[y][x] = 0
        field.left[y][x] = 0
    end
end
return 'tadaaa'
end

local l,r = 'left','right'
--назначили левое поле источником рассчётов следующей итерации

--попросим пользователя внести начальные данные
function userInput(l)
    return 'получили данные'
end

--функция вычисления координат прилегающих клеток
local function getAdjoining(y,ys)
local yl, yr = 1,1
    if y > 1 and y < ys then 
        yl=y-1 
        yr=y+y-1 
    else
        if y== 1 then 
            yl, yr = ys, y+1
        else 
            yl,yr = y-1, y-1 
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
local function saveChanges(l)--получаем имя таблицы
local s=l
for y in pairs(field[l])do
   yl,yr = getAdjoining(y,ys)
    for x in pairs(field[l])do 
        if field[l][y][x] == 1 then 
            xl,xr = getAdjoining(x,xs)
            setScreen(yl,y,yr,xl,x,xr,s)
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
    local p=l
    local neighbors = 0
    screen[r]={}
    actualScreenChanges={}
    --подтаблицы экрана необходимо инициировать заранее
    for y = 1, ys do 
        screen[r][y]={}
        actualScreenChanges[y]={}
    end
    --получаем из левого экрана сведения о узлах 
    --реалии которых нам интересны 
    for y in pairs (screen[l]) do 
        yl,yr=getAdjoining(y)
        for x in pairs(screen[l][y]) do 
            xl,xr=getAdjoining(x)
            neighbors = 
            field[p][y][xl] + field[p][y][x] + field[p][y][xr] + 
            field[p][yl][xl]+field[p][yl][x]+field[p][yl][xr]+
            field[p][yr][xl]+field[p][yr][x]+field[p][yr][xr] 
            if neighbors == 3 then 
                setScreen(yl,y,yr,xl,x,xr,r) 
                --без проверки переключаем состояние узла
                field[r][y][x]=1
                actualScreenChanges[y][x]=1
            else 
                if neighbors ~= 2 then 
                    setScreen(yl,y,yr,xl,x,xr,r)
                    field[r][y][x]=0
                    actualScreenChanges[y][x]=0
                end 
            end 
        end 
    end
    --вычисления следующего состояния колонии завершены
    return 'calculations completed'
end

--выведем изменения на монитор
function showMustGoOne(actualScreenChanges)
    --show news on screen
    return 'обновления успешно отображены'
end

---для перехода к следующему витку поменяем ссылки на левое и правое
function swap(l,r)
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
--запрашиваем начальное состояние поля
userInput(l)
--записываем полученные данные в мониторинг посредством screen
saveChanges()

---создадим цикл, чтобы всё работало
while allOK() do 
    whatNews(l,r)
    showMustGoOne(actualScreenChanges)
    swap(l,r)
end

--В итоге у нас получилась довольно симпатичная програмка
--Возможно, в будущем я найду интерес и время
--чтобы дописать вывод на экран и реализовать интерактивность
--Пока же оставляю код в его настоящем виде
--и предоставляю к осмотру заинтересованной публикой.