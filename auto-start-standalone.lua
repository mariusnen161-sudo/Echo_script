-- Всё в одном: панель Pet Simulator 99, фарм и автозапуск.
-- Вставьте весь код в Madium. Отдельные файлы не нужны.
local embeddedSource = [====[
-- Grand Heaven Chest: один запрос групповой отправки на каждый новый сундук.
-- Подготовлено по открытому проекту Pet Simulator X. Проверка в живом ивенте обязательна.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
assert(player, "Скрипт нужно запускать на клиенте после входа в игру.")
local playerGui = player:WaitForChild("PlayerGui", 15)
assert(playerGui, "Не найден интерфейс игрока.")
local logFile = "heaven-chest-" .. os.date("!%Y%m%d-%H%M%S") .. ".txt"
local logLines = {}
local logAvailable = type(writefile) == "function"
local function record(text)
    local line = os.date("!%Y-%m-%d %H:%M:%S UTC") .. " | " .. text
    table.insert(logLines, line)
    if #logLines > 240 then table.remove(logLines, 1) end
    if logAvailable then
        local ok, err = pcall(writefile, logFile, table.concat(logLines, "\n") .. "\n")
        if not ok then
            logAvailable = false
            warn("[Сундук] Запись диагностики недоступна: " .. tostring(err))
        end
    end
end
record("Запуск версии с диагностикой остановки")
if logAvailable then
    print("[Сундук] Файл диагностики в рабочей папке Madium: " .. logFile)
else
    warn("[Сундук] Madium не предоставил writefile; файл диагностики недоступен.")
end
local old = playerGui:FindFirstChild("HeavenChestHelper")
if old then
    old:SetAttribute("StopReason", "Запущена новая копия скрипта")
    old:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "HeavenChestHelper"
gui:SetAttribute("MainHeartbeat", os.clock())
gui.ResetOnSpawn = false
gui.Parent = playerGui
-- UI component embedded from gui-theme.lua
local UI = (function()
-- Только интерфейс. Игровые действия подключаются через bind().
local function createHeavenUI(gui, player, input)
    local TweenService = game:GetService("TweenService")
    local Theme = {
        bg = Color3.fromRGB(17,16,31), sidebar = Color3.fromRGB(23,20,41),
        card = Color3.fromRGB(33,27,54), purple = Color3.fromRGB(147,51,234),
        lavender = Color3.fromRGB(192,132,252), white = Color3.fromRGB(248,247,255),
        muted = Color3.fromRGB(185,180,204), green = Color3.fromRGB(74,222,128),
        red = Color3.fromRGB(251,113,133), border = Color3.fromRGB(71,55,100),
        width = 850, height = 530, duration = 0.2, radius = 15,
    }
    local ui = {connections={}, groups={}, pages={}, animation=true, scale=1}
    local library, lastRead = nil, -10
    local function connect(signal, fn)
        local c=signal:Connect(fn); table.insert(ui.connections,c); return c
    end
    local function make(class,parent,props)
        local o=Instance.new(class)
        for key,value in pairs(props or {}) do o[key]=value end
        o.Parent=parent
        return o
    end
    local function corner(o,r) make("UICorner",o,{CornerRadius=UDim.new(0,r or Theme.radius)}) end
    local function stroke(o,color,width,transparency)
        return make("UIStroke",o,{ApplyStrokeMode=Enum.ApplyStrokeMode.Border,
            Color=color or Theme.border,Thickness=width or 1.5,Transparency=transparency or 0})
    end
    local function gradient(o,top,bottom,rotation)
        -- Градиенты только на Frame: не умножаем цвет букв TextButton.
        return make("UIGradient",o,{Color=ColorSequence.new(top,bottom),Rotation=rotation or 90})
    end
    local function tween(o,props)
        if not ui.animation then for k,v in pairs(props) do o[k]=v end; return end
        TweenService:Create(o,TweenInfo.new(Theme.duration,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),props):Play()
    end
    local function label(parent,value,x,y,w,h,size,color,bold)
        return make("TextLabel",parent,{Text=value,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),
            BackgroundTransparency=1,TextColor3=color or Theme.white,TextSize=size or 14,
            Font=bold and Enum.Font.GothamBold or Enum.Font.GothamMedium,
            TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,
            TextWrapped=true,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=5})
    end
    local function shape(parent,x,y,w,h,color,rotation,radius)
        local o=make("Frame",parent,{Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),
            BackgroundColor3=color,BorderSizePixel=0,Rotation=rotation or 0,ZIndex=5})
        if radius then corner(o,radius) end
        return o
    end
    local function line(parent,x,y,w,h,color,rotation) return shape(parent,x,y,w,h,color,rotation,2) end
    local function icon(parent,kind,x,y,size,color)
        local f=make("Frame",parent,{Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(28,28),
            BackgroundTransparency=1,ZIndex=5})
        make("UIScale",f,{Scale=size/28})
        color=color or Theme.white
        if kind=="paw" then
            shape(f,7,14,15,12,color,0,7)
            shape(f,1,9,7,9,color,-25,5); shape(f,7,1,7,10,color,-10,5)
            shape(f,16,1,7,10,color,10,5); shape(f,23,9,6,9,color,25,5)
        elseif kind=="home" then
            shape(f,6,12,17,14,color,0,2); shape(f,6,4,17,17,color,45,2)
            shape(f,12,19,5,9,Theme.card,0,1)
        elseif kind=="pick" then
            line(f,5,12,23,5,color,-47); line(f,4,5,22,5,color,27)
        elseif kind=="egg" then
            shape(f,5,2,19,25,color,0,12); line(f,9,18,11,3,Theme.lavender,-25)
        elseif kind=="coin" then
            local coin=shape(f,2,2,25,25,color,0,20); stroke(coin,Theme.lavender,2)
            line(f,12,7,4,15,Theme.card)
        elseif kind=="pin" then
            shape(f,5,0,19,21,color,0,13); shape(f,9,15,11,11,color,45,2)
            shape(f,11,6,7,7,Theme.card,0,5)
        elseif kind=="misc" then
            for i=0,2 do for j=0,2 do shape(f,3+i*9,3+j*9,5,5,color,0,2) end end
        elseif kind=="settings" then
            for i=0,2 do
                line(f,2,5+i*8,25,2,color)
                shape(f,5+(i%2)*10,2+i*8,6,8,color,0,3)
            end
        elseif kind=="chart" then
            shape(f,2,16,6,11,color,0,1); shape(f,11,9,6,18,color,0,1); shape(f,20,1,6,26,color,0,1)
        elseif kind=="play" then
            -- Треугольник составлен из полос, без отсутствующих символов шрифта.
            for i=0,9 do line(f,4+i*2,3+i,2,22-i*2,color) end
        elseif kind=="minus" then line(f,5,13,19,3,color)
        elseif kind=="close" then line(f,3,13,24,3,color,45); line(f,3,13,24,3,color,-45)
        elseif kind=="shield" then
            shape(f,5,3,19,19,color,0,5); shape(f,9,13,11,11,color,45,3)
            line(f,10,13,5,2,Theme.card,40); line(f,13,11,9,2,Theme.card,-45)
        end
        return f
    end
    local function panel(parent,x,y,w,h)
        local f=make("Frame",parent,{Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),
            BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0})
        corner(f); stroke(f)
        gradient(f,Color3.fromRGB(40,33,61),Color3.fromRGB(27,24,43))
        return f
    end
    local function card(parent,x,y,w,h,title,kind)
        local f=panel(parent,x,y,w,h)
        icon(f,kind or "chart",16,12,22,Theme.lavender)
        label(f,title,47,7,w-60,33,18,nil,true)
        shape(f,0,48,w,1,Theme.border)
        return f
    end
    local function action(parent,title,kind,x,y,w,h,group,quiet)
        local b=make("TextButton",parent,{Text=title,TextTransparency=1,AutoButtonColor=false,
            BackgroundTransparency=1,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),ZIndex=4})
        local fill=make("Frame",b,{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=4})
        corner(fill,12)
        local edge=stroke(fill,quiet and Theme.border or Theme.lavender,quiet and 1.2 or 1.6)
        local grad=gradient(fill,quiet and Color3.fromRGB(42,36,60) or Color3.fromRGB(109,53,172),
            quiet and Color3.fromRGB(29,26,45) or Color3.fromRGB(65,32,112))
        if kind then icon(b,kind,13,math.floor((h-25)/2),25,Theme.white) end
        local caption=label(b,title,kind and 49 or 10,0,w-(kind and 59 or 20),h,14,nil,true)
        if not kind then caption.TextXAlignment=Enum.TextXAlignment.Center end
        connect(b:GetPropertyChangedSignal("Text"),function() caption.Text=b.Text end)
        local scale=make("UIScale",b,{Scale=1})
        connect(b.MouseEnter,function() tween(edge,{Color=Theme.lavender,Thickness=2}); tween(fill,{BackgroundColor3=Color3.fromRGB(255,240,255)}) end)
        connect(b.MouseLeave,function() tween(edge,{Color=quiet and Theme.border or Theme.lavender,Thickness=quiet and 1.2 or 1.6}); tween(scale,{Scale=1}) end)
        connect(b.MouseButton1Down,function() tween(scale,{Scale=0.98}) end)
        connect(b.MouseButton1Up,function() tween(scale,{Scale=1}) end)
        if group then ui.groups[group]=ui.groups[group] or {}; table.insert(ui.groups[group],b) end
        return b,grad,edge
    end
    function ui.bind(group,fn)
        for _,b in ipairs(ui.groups[group] or {}) do connect(b.Activated,fn) end
    end
    local root=make("Frame",gui,{Name="Window",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
        Size=UDim2.fromOffset(Theme.width,Theme.height),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0})
    ui.root=root; corner(root,20); stroke(root,Theme.lavender,1.7)
    gradient(root,Color3.fromRGB(28,25,44),Theme.bg,110)
    -- Несколько полупрозрачных контуров дают мягкое свечение без текстур.
    for i=1,3 do
        local glow=make("Frame",root,{Size=UDim2.new(1,i*4,1,i*4),Position=UDim2.fromOffset(-i*2,-i*2),
            BackgroundTransparency=1,ZIndex=0})
        corner(glow,20+i*2); stroke(glow,Theme.purple,2,0.76+i*0.05)
    end
    local scale=make("UIScale",root,{Scale=1})
    local function fit()
        local camera=workspace.CurrentCamera
        if camera then scale.Scale=math.min(ui.scale,(camera.ViewportSize.X-32)/850,(camera.ViewportSize.Y-32)/530) end
        if ui.clampRestore then ui.clampRestore() end
    end
    local function bindCamera()
        fit()
        if ui.cameraConnection then ui.cameraConnection:Disconnect() end
        if workspace.CurrentCamera then
            ui.cameraConnection=connect(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"),fit)
        end
    end
    bindCamera(); connect(workspace:GetPropertyChangedSignal("CurrentCamera"),bindCamera)
    local header=make("Frame",root,{Size=UDim2.new(1,0,0,77),BackgroundTransparency=1,Active=true})
    icon(header,"paw",25,15,45,Theme.lavender)
    label(header,"Pet Simulator 99",90,10,540,34,28,nil,true)
    label(header,"Script GUI | v1.0.0",91,44,500,22,15,Theme.lavender)
    shape(root,0,77,850,1,Theme.border)
    local minimize=action(header,"",nil,742,18,40,38,nil,true); icon(minimize,"minus",6,5,27)
    local close=action(header,"",nil,794,18,40,38,"close",true); icon(close,"close",7,5,26)
    local sidebar=make("Frame",root,{Position=UDim2.fromOffset(14,93),Size=UDim2.fromOffset(174,420),BackgroundTransparency=1})
    make("UIListLayout",sidebar,{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder})
    local content=make("Frame",root,{Position=UDim2.fromOffset(204,93),Size=UDim2.fromOffset(630,420),BackgroundTransparency=1})
    local pages={}
    local nav={}
    local function page(name)
        local f=make("ScrollingFrame",content,{Name=name,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
            BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=Theme.lavender,
            CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=false})
        make("UIPadding",f,{PaddingBottom=UDim.new(0,4),PaddingRight=UDim.new(0,3)})
        pages[name]=f; return f
    end
    local selected
    function ui.select(name)
        if not pages[name] then return end
        selected=name
        for key,f in pairs(pages) do f.Visible=key==name end
        for key,n in pairs(nav) do
            n.gradient.Color=key==name and ColorSequence.new(Color3.fromRGB(153,63,226),Color3.fromRGB(87,38,146))
                or ColorSequence.new(Color3.fromRGB(44,37,64),Color3.fromRGB(29,26,45))
            tween(n.edge,{Color=key==name and Theme.lavender or Theme.border,Thickness=key==name and 2 or 1.2})
        end
        if ui.animation then content.Position=UDim2.fromOffset(211,93); tween(content,{Position=UDim2.fromOffset(204,93)}) end
    end
    local menu={{"Home","home"},{"Farming","pick"},{"Pets","paw"},{"Eggs","egg"},
        {"Boosts","coin"},{"Teleport","pin"},{"Misc","misc"},{"Settings","settings"}}
    for index,entry in ipairs(menu) do
        page(entry[1])
        local b,g,s=action(sidebar,entry[1],entry[2],0,(index-1)*52,174,44,nil,true)
        b.LayoutOrder=index
        nav[entry[1]]={button=b,gradient=g,edge=s}
        connect(b.Activated,function() ui.select(entry[1]) end)
    end
    -- Баннер: настоящая трёхмерная мини-сцена Roblox без внешних картинок.
    local banner=panel(pages.Home,0,0,627,136)
    banner:FindFirstChildWhichIsA("UIGradient"):Destroy()
    gradient(banner,Color3.fromRGB(146,52,222),Color3.fromRGB(67,30,126),15)
    local viewport=make("ViewportFrame",banner,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
        Ambient=Color3.fromRGB(200,185,230),LightColor=Color3.fromRGB(255,245,215),LightDirection=Vector3.new(-1,-1,-2),ZIndex=2})
    corner(viewport)
    local world=make("WorldModel",viewport,{})
    local camera=make("Camera",viewport,{FieldOfView=30,CFrame=CFrame.lookAt(Vector3.new(0,0.5,6),Vector3.new(0,0.3,0))})
    viewport.CurrentCamera=camera
    local function part(parent,class,size,cframe,color)
        return make(class,parent,{Size=size,CFrame=cframe,Color=color,Anchored=true,CanCollide=false,
            Material=Enum.Material.SmoothPlastic,TopSurface=Enum.SurfaceType.Smooth,BottomSurface=Enum.SurfaceType.Smooth})
    end
    local function pet(x,y,color,turn)
        local model=make("Model",world,{})
        part(model,"Part",Vector3.new(2.2,1.9,1.5),CFrame.new(0,0,0),color)
        for _,side in ipairs({-1,1}) do
            part(model,"WedgePart",Vector3.new(0.8,0.8,0.8),CFrame.new(side*0.7,1.15,0)*CFrame.Angles(0,math.pi,0),color)
            local eye=part(model,"Part",Vector3.new(0.61,0.75,0.17),CFrame.new(side*0.52,0.15,0.82),Theme.white)
            eye.Shape=Enum.PartType.Ball
            local pupil=part(model,"Part",Vector3.new(0.29,0.43,0.15),CFrame.new(side*0.52,0.13,0.94),Color3.fromRGB(39,34,63))
            pupil.Shape=Enum.PartType.Ball
            local glint=part(model,"Part",Vector3.new(0.1,0.14,0.08),CFrame.new(side*0.52-0.04,0.25,1.02),Theme.white)
            glint.Shape=Enum.PartType.Ball
            part(model,"Part",Vector3.new(0.17,0.06,0.08),CFrame.new(side*0.09,-0.48,0.81)*CFrame.Angles(0,0,side*0.35),Color3.fromRGB(55,38,69))
        end
        local nose=part(model,"Part",Vector3.new(0.17,0.12,0.1),CFrame.new(0,-0.29,0.84),Color3.fromRGB(248,163,203))
        nose.Shape=Enum.PartType.Ball
        model:PivotTo(CFrame.new(x,y,0)*CFrame.Angles(0,turn,0))
    end
    pet(-4.8,-0.45,Color3.fromRGB(142,146,195),0.25)
    pet(4.8,-0.4,Color3.fromRGB(255,201,42),-0.25)
    for i=1,13 do
        local side=i%2==0 and -1 or 1
        local p=part(world,"Part",Vector3.new(0.13,0.68,0.68),CFrame.new(side*(3.9+(i%4)*0.75),-1.25+(i%3)*0.4,-0.4)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(255,205,44))
        p.Shape=Enum.PartType.Cylinder
    end
    local title=label(banner,"PET SIMULATOR",142,24,343,38,29,Theme.white,true)
    title.TextXAlignment=Enum.TextXAlignment.Center
    stroke(title,Color3.fromRGB(44,22,78),2).ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual
    local number=label(banner,"99",230,60,165,58,52,Color3.fromRGB(255,214,64),true)
    number.TextXAlignment=Enum.TextXAlignment.Center
    stroke(number,Color3.fromRGB(53,28,81),2).ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual
    local statusCard=card(pages.Home,0,149,262,218,"Status","chart")
    local quickCard=card(pages.Home,276,149,351,218,"Quick Actions","play")
    local function row(parent,title,y)
        label(parent,title,16,y,145,24,14)
        local value=label(parent,"OFF",163,y,82,24,14,Theme.red,true)
        value.TextXAlignment=Enum.TextXAlignment.Right
        shape(parent,16,y+27,229,1,Color3.fromRGB(49,40,68))
        return value
    end
    local farming=row(statusCard,"Farming",56)
    local hatch=row(statusCard,"Auto Hatch",86)
    local coins=row(statusCard,"Triple Coins",116)
    label(statusCard,"Account",16,150,78,22,13,Theme.muted)
    local account=label(statusCard,player.DisplayName,93,150,151,22,13,nil,true)
    account.TextXAlignment=Enum.TextXAlignment.Right
    label(statusCard,"Uptime",16,179,78,22,13,Theme.muted)
    local uptime=label(statusCard,"00:00:00",93,179,151,22,14,nil,true); uptime.TextXAlignment=Enum.TextXAlignment.Right
    local farmButton=action(quickCard,"Pause Farming","play",13,64,159,53,"farm")
    action(quickCard,"Eggs · info","egg",181,64,157,53,"eggs")
    local boostButton=action(quickCard,"Triple Coins","coin",13,132,159,53,"boost")
    action(quickCard,"Locations","pin",181,132,157,53,"teleport")
    local statusLabel=label(pages.Home,"Загрузка…",8,376,610,35,12,Theme.muted)
    local function heading(parent,title,desc)
        label(parent,title,3,1,615,34,25,nil,true)
        label(parent,desc,4,40,612,40,13,Theme.muted)
    end
    heading(pages.Farming,"Farming","Heavens Gate · Grand Heaven Chest")
    local farmCard=card(pages.Farming,0,94,627,168,"Автоматический фарм","pick")
    action(farmCard,"Пауза / продолжить","play",16,66,278,46,"farm")
    local farmInfo=label(farmCard,"Жду сундук…",16,123,595,32,13,Theme.muted)
    local progressionCard=card(pages.Farming,0,278,627,178,"Автопрогрессия: Spawn → Heavens Gate","pin")
    local progressionInfo=label(progressionCard,"Нажми «Начать», чтобы фармить и открывать следующие зоны за монеты.",16,56,593,58,13,Theme.muted)
    action(progressionCard,"Начать прогрессию","play",16,124,288,38,"progression")
    action(progressionCard,"Только небесный сундук","coin",320,124,290,38,"chestmode")
    local safety=card(pages.Farming,0,472,627,144,"Приоритет целей","shield")
    label(safety,"Сундуки → большие сейфы → сейфы → подарки → ящики → монеты. Текущая цель сначала разрушается полностью, затем выбирается следующая. Переход в новую зону также ждёт конца атаки.",16,57,593,72,14,Theme.muted)
    heading(pages.Pets,"Pets","Информация из текущего сохранения игры")
    local petCard=card(pages.Pets,0,94,627,120,"Твои питомцы","paw")
    local petsInfo=label(petCard,"Жду данные игры…",16,57,595,47,15)
    local petList=label(pages.Pets,"",8,232,610,155,13,Theme.muted)
    heading(pages.Eggs,"Eggs","Открытие яиц не входит в текущий скрипт")
    local eggCard=card(pages.Eggs,0,94,627,172,"Auto Hatch — не подключён","egg")
    label(eggCard,"Фарм сундука, Triple Coins и анти-AFK доступны. Автооткрытие яиц не реализовано и не будет запускаться этой кнопкой.",16,63,593,82,16,Theme.muted)
    heading(pages.Boosts,"Boosts","Triple Coins и активные личные усиления")
    local boostCard=card(pages.Boosts,0,94,627,164,"Triple Coins","coin")
    local boostInfo=label(boostCard,"Жду данные…",16,58,592,42,14)
    action(boostCard,"Включить / выключить автоактивацию","coin",16,109,594,40,"boost")
    local boostList=label(pages.Boosts,"",10,275,602,128,14,Theme.muted)
    heading(pages.Teleport,"Teleport","Текущая цель и доступность переходов")
    local location=card(pages.Teleport,0,94,627,154,"Heavens Gate","pin")
    label(location,"Маршрут прогрессии: Spawn → Fantasy → Heavens Gate. Режим использует ворота, пушку и порталы игры. Запуск находится во вкладке Farming.",16,60,593,72,15,Theme.muted)
    heading(pages.Misc,"Misc","Дополнительные работающие функции")
    local afkCard=card(pages.Misc,0,94,627,152,"Анти-AFK","shield")
    local afkInfo=label(afkCard,"Жду проверки…",16,57,593,33,14,Theme.muted)
    action(afkCard,"Включить / выключить анти-AFK","shield",16,98,594,38,"afk")
    local logCard=card(pages.Misc,0,261,627,131,"Диагностика","chart")
    local logInfo=label(logCard,"",16,56,593,60,13,Theme.muted)
    heading(pages.Settings,"Settings","Интерфейс и управление скриптом")
    local settings=card(pages.Settings,0,94,627,312,"Настройки","settings")
    label(settings,"Масштаб интерфейса",16,59,290,28,15)
    local scaleDown=action(settings,"-",nil,350,57,45,32)
    local scaleValue=label(settings,"100%",405,57,78,32,14); scaleValue.TextXAlignment=Enum.TextXAlignment.Center
    local scaleUp=action(settings,"+",nil,495,57,45,32)
    local animationButton=action(settings,"Анимации: ВКЛ",nil,16,106,288,40)
    local autoButton=action(settings,"Автозапуск: проверка…",nil,320,106,290,40,"auto")
    label(settings,"F7 — свернуть / развернуть\nF8 — пауза / продолжить фарм",16,163,590,46,14,Theme.muted)
    local stopButton=action(settings,"Остановить",nil,16,242,594,44,"stop",true)
    local notification=panel(root,226,481,596,36); notification.Visible=false
    local note=label(notification,"",12,0,572,36,12)
    local notificationId=0
    function ui.notify(message)
        notificationId=notificationId+1; local id=notificationId
        note.Text=message; notification.Visible=true
        task.delay(4,function() if gui.Parent and notificationId==id then notification.Visible=false end end)
    end
    connect(scaleDown.Activated,function() ui.scale=math.max(0.65,ui.scale-0.1); fit(); scaleValue.Text=math.floor(ui.scale*100+0.5).."%" end)
    connect(scaleUp.Activated,function() ui.scale=math.min(1.3,ui.scale+0.1); fit(); scaleValue.Text=math.floor(ui.scale*100+0.5).."%" end)
    connect(animationButton.Activated,function() ui.animation=not ui.animation; animationButton.Text=ui.animation and "Анимации: ВКЛ" or "Анимации: ВЫКЛ" end)
    ui.bind("eggs",function() ui.select("Eggs") end)
    ui.bind("teleport",function() ui.select("Teleport") end)
    local collapsed=false
    local restoreIcon=action(gui,"",nil,16,110,64,64,nil,true)
    restoreIcon.Name="RestoreIcon"
    restoreIcon.Visible=false
    icon(restoreIcon,"paw",13,11,38,Theme.lavender)
    local iconPlaced,iconMoved=false,false
    local iconPointer,iconStart,iconOrigin
    local function clampIcon(x,y)
        local size=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
        return UDim2.fromOffset(math.clamp(x,8,math.max(8,size.X-72)),math.clamp(y,8,math.max(8,size.Y-72)))
    end
    function ui.clampRestore()
        if iconPlaced then restoreIcon.Position=clampIcon(restoreIcon.Position.X.Offset,restoreIcon.Position.Y.Offset) end
    end
    connect(restoreIcon.InputBegan,function(e)
        if e.UserInputType==Enum.UserInputType.MouseButton1 or e.UserInputType==Enum.UserInputType.Touch then
            iconPointer=e; iconStart=e.Position; iconOrigin=restoreIcon.Position; iconMoved=false
        end
    end)
    connect(input.InputChanged,function(e)
        if not iconPointer then return end
        local mouse=iconPointer.UserInputType==Enum.UserInputType.MouseButton1 and e.UserInputType==Enum.UserInputType.MouseMovement
        local touch=iconPointer.UserInputType==Enum.UserInputType.Touch and e==iconPointer
        if not mouse and not touch then return end
        local dx,dy=e.Position.X-iconStart.X,e.Position.Y-iconStart.Y
        if dx*dx+dy*dy>=36 then iconMoved=true end
        if iconMoved then
            iconPlaced=true
            restoreIcon.Position=clampIcon(iconOrigin.X.Offset+dx,iconOrigin.Y.Offset+dy)
        end
    end)
    connect(input.InputEnded,function(e)
        if iconPointer and (e==iconPointer or (iconPointer.UserInputType==Enum.UserInputType.MouseButton1 and e.UserInputType==Enum.UserInputType.MouseButton1)) then
            iconPointer=nil
        end
    end)
    function ui.collapse()
        collapsed=not collapsed
        notification.Visible=false
        if collapsed and not iconPlaced then
            local viewportSize=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
            local left=root.Position.X.Scale*viewportSize.X+root.Position.X.Offset-850*scale.Scale/2
            local top=root.Position.Y.Scale*viewportSize.Y+root.Position.Y.Offset-530*scale.Scale/2
            restoreIcon.Position=UDim2.fromOffset(
                math.clamp(left,8,math.max(8,viewportSize.X-72)),
                math.clamp(top,8,math.max(8,viewportSize.Y-72)))
            iconPlaced=true
        end
        ui.clampRestore()
        root.Visible=not collapsed
        restoreIcon.Visible=collapsed
    end
    connect(minimize.Activated,ui.collapse)
    connect(restoreIcon.Activated,function() if collapsed and not iconMoved then ui.collapse() end end)
    local dragStart,dragOrigin
    connect(header.InputBegan,function(e)
        if e.UserInputType==Enum.UserInputType.MouseButton1 or e.UserInputType==Enum.UserInputType.Touch then
            dragStart=e.Position; dragOrigin=root.Position
        end
    end)
    connect(input.InputChanged,function(e)
        if dragStart and (e.UserInputType==Enum.UserInputType.MouseMovement or e.UserInputType==Enum.UserInputType.Touch) then
            local d=e.Position-dragStart
            local viewportSize=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
            local centerX=dragOrigin.X.Scale*viewportSize.X+dragOrigin.X.Offset+d.X
            local centerY=dragOrigin.Y.Scale*viewportSize.Y+dragOrigin.Y.Offset+d.Y
            local halfHeight=530*scale.Scale/2
            centerX=math.clamp(centerX,80,viewportSize.X-80)
            centerY=math.clamp(centerY,halfHeight+8,math.max(halfHeight+8,viewportSize.Y-halfHeight-8))
            root.Position=UDim2.fromOffset(centerX,centerY)
        end
    end)
    connect(input.InputEnded,function(e)
        if e.UserInputType==Enum.UserInputType.MouseButton1 or e.UserInputType==Enum.UserInputType.Touch then dragStart=nil end
    end)
    function ui.setLibrary(value) library=value end
    local function setStatus(o,on) o.Text=on and "ON" or "OFF"; o.TextColor3=on and Theme.green or Theme.red end
    function ui.update(state)
        statusLabel.Text=state.message
        farmInfo.Text=(state.mode=="progression" and "Автопрогрессия: " or "Небесный сундук: ")..state.message
        local progress=state.progression
        if progress then
            local summary="Фарм: "..tostring(progress.targetArea or "Town")
            if progress.nextArea then summary=summary.."\nДальше: "..progress.nextArea end
            if progress.price and progress.currency then
                summary=summary.." · "..string.format("%.0f",progress.balance or 0).." / "..string.format("%.0f",progress.price).." "..progress.currency
            end
            progressionInfo.Text=summary.."\n"..tostring(progress.message or "")
        end
        setStatus(farming,state.running); setStatus(hatch,false)
        farmButton.Text=state.running and "Pause Farming" or "Start Farming"
        boostButton.Text=state.autoBoost and "Triple Coins: ON" or "Triple Coins: OFF"
        boostInfo.Text=state.autoBoost and state.boostText or "Автоактивация выключена"
        afkInfo.Text=state.afkText..(state.afkEnabled and "" or " · выключен")
        local seconds=math.floor(state.elapsed)
        uptime.Text=string.format("%02d:%02d:%02d",math.floor(seconds/3600),math.floor(seconds/60)%60,seconds%60)
        local controller=gui.Parent and gui.Parent:FindFirstChild("HeavenChestAutoStart")
        autoButton.Text=controller and (controller:GetAttribute("AutoEnabled") and "Автозапуск: ВКЛ" or "Автозапуск: ВЫКЛ") or "Автозапуск не подключён"
        logInfo.Text=state.logFile or "Файл диагностики недоступен"
        if library and os.clock()-lastRead>=2 then
            lastRead=os.clock()
            local ok,data=pcall(function() return library.Save.Get() end)
            if ok and type(data)=="table" then
                local active=data.Boosts or {}
                setStatus(coins,type(active["Triple Coins"])=="number" and active["Triple Coins"]>0)
                local list={}
                for name,time in pairs(active) do
                    if type(time)=="number" and time>0 then table.insert(list,tostring(name)..": "..math.ceil(time).." сек.") end
                end
                table.sort(list); boostList.Text=#list>0 and table.concat(list,"\n") or "Личных активных бустов нет."
                if type(data.Pets)=="table" then
                    local total,equipped=0,0; local names={}
                    for _,pet in pairs(data.Pets) do
                        if type(pet)=="table" then
                            total=total+1
                            local equippedOk,isEquipped=pcall(function() return library.Shared.HasPetEquipped(data,pet) end)
                            if equippedOk and isEquipped then equipped=equipped+1 end
                            if #names<8 then
                                local entry=library.Directory and library.Directory.Pets and library.Directory.Pets[pet.id]
                                table.insert(names,(entry and entry.name or tostring(pet.id or "Питомец"))..(equippedOk and isEquipped and " · экипирован" or ""))
                            end
                        end
                    end
                    petsInfo.Text="В коллекции: "..total.."    Экипировано: "..equipped
                    petList.Text=table.concat(names,"\n")
                end
            end
        end
    end
    ui.stopButton=stopButton
    ui.closeButton=close
    ui.select("Home")
    if ui.animation then
        root.Position=UDim2.new(0.5,0,0.5,14)
        tween(root,{Position=UDim2.fromScale(0.5,0.5)})
    end
    return ui
end
return createHeavenUI
end)()(gui, player, UserInputService)
local uiConnections = UI.connections
local stopButton, closeButton = UI.stopButton, UI.closeButton
local collapse = UI.collapse
local running, alive = false, true
local farmMode,progressionState,progression = "progression",nil,nil
local controllerState=playerGui:FindFirstChild("HeavenChestAutoStart")
if controllerState then
    local savedMode=controllerState:GetAttribute("FarmMode")
    if savedMode=="chest" or savedMode=="progression" then farmMode=savedMode end
    running=controllerState:GetAttribute("FarmRunning")==true
end
local autoBoostEnabled, afkEnabled = true, true
local uiStartedAt = os.clock()
local boostText = "Triple Coins: ожидание проверки"
local afkText = "Анти-AFK: ожидание проверки"
-- Блокировка относится ко всему циклу сундука, а не к его модели или ID.
-- Игра может менять клиентскую модель и ID во время одной атаки.
local cycle = {sent = false, absentSince = nil}
local function observeChest(state, present, now)
    if present then
        state.absentSince = nil
    else
        state.absentSince = state.absentSince or now
        if now - state.absentSince >= 1.25 then
            state.sent = false
        end
    end
end
local keyConnection, idleConnection
local lastStatus, lastStatusAt = "Инициализация", os.clock()
local function status(text)
    lastStatus, lastStatusAt = text, os.clock()
    local controller=playerGui:FindFirstChild("HeavenChestAutoStart")
    if controller then controller:SetAttribute("FarmMode",farmMode);controller:SetAttribute("FarmRunning",running) end
    if alive then
        UI.update({message=text, running=running, autoBoost=autoBoostEnabled, afkEnabled=afkEnabled,
            boostText=boostText, afkText=afkText, elapsed=os.clock()-uiStartedAt,
            logFile=logAvailable and logFile or "Файл диагностики недоступен",mode=farmMode,progression=progressionState})
    end
end
UI.bind("farm",function()
    running=not running
    if progression then if running then progression.reset() else progression.cancel() end end
    status(running and "Фарм возобновлён" or "Фарм на паузе")
end)
UI.bind("progression",function()
    farmMode="progression";running=true
    if progression then progression.reset() end
    status("Запускаю прогрессию: Spawn → Heavens Gate")
end)
UI.bind("chestmode",function()
    if progression then progression.cancel() end
    farmMode="chest";running=true
    status("Режим небесного сундука: подойди к сундуку")
end)
UI.bind("boost",function()
    autoBoostEnabled=not autoBoostEnabled; status(lastStatus)
end)
UI.bind("afk",function()
    afkEnabled=not afkEnabled; status(lastStatus)
end)
UI.bind("auto",function()
    local controller=playerGui:FindFirstChild("HeavenChestAutoStart")
    if controller then
        controller:SetAttribute("RequestedEnabled",not controller:GetAttribute("AutoEnabled"))
        status("Настройка автозапуска отправлена контроллеру")
    else status("Для автозапуска запусти версию «всё в одном»") end
end)
local function stop()
    if not alive then return end
    gui:SetAttribute("StopReason", "Остановка подтверждена кнопкой")
    alive = false
    if progression then progression.cancel() end
    if keyConnection then keyConnection:Disconnect() end
    if idleConnection then idleConnection:Disconnect() end
    if gui.Parent then gui:Destroy() end
end
gui.Destroying:Connect(function()
    for _, connection in ipairs(uiConnections) do connection:Disconnect() end
    local reason = gui:GetAttribute("StopReason")
    record("Уничтожение панели: " .. tostring(reason or "внешняя причина") .. "; состояние=" .. lastStatus)
    if reason then
        print("[Сундук] Скрипт остановлен: " .. tostring(reason))
    else
        warn("[Сундук] Панель уничтожена извне. Скрипт остановлен; кнопка остановки не нажималась.")
    end
    alive = false
    if progression then progression.cancel() end
    if keyConnection then keyConnection:Disconnect() end
    if idleConnection then idleConnection:Disconnect() end
end)
task.spawn(function()
    while alive do
        task.wait(15)
        if alive then
            record("Проверка работы: " .. (running and "запущен" or "пауза")
                .. "; панель=" .. tostring(gui.Parent ~= nil)
                .. "; состояние=" .. lastStatus
                .. "; возраст состояния=" .. math.floor(os.clock() - lastStatusAt) .. " сек."
                .. "; " .. boostText .. "; " .. afkText)
        end
    end
end)
local stopConfirmUntil = 0
stopButton.Activated:Connect(function()
    local now = os.clock()
    if now < stopConfirmUntil then stop(); return end
    stopConfirmUntil = now + 3
    stopButton.Text = "Ещё раз — стоп"
    UI.notify("Нажми кнопку остановки или × ещё раз для подтверждения")
    task.delay(3, function()
        if alive and os.clock() >= stopConfirmUntil then
            stopButton.Text = "Остановить"
        end
    end)
end)
closeButton.Activated:Connect(function()
    if os.clock() < stopConfirmUntil then stop(); return end
    stopConfirmUntil=os.clock()+3; stopButton.Text="Ещё раз — стоп"
    UI.notify("Нажми × ещё раз в течение 3 секунд для остановки")
    task.delay(3,function() if alive and os.clock()>=stopConfirmUntil then stopButton.Text="Остановить" end end)
end)
keyConnection = UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.F7 then collapse() end
    if not processed and input.KeyCode == Enum.KeyCode.F8 then
        running = not running
        if progression then if running then progression.reset() else progression.cancel() end end
        status(running and "Работа возобновлена" or "Пауза")
    end
end)
status("Загрузка библиотеки игры…")

-- Используем виртуальное нажатие внутри Roblox. Мышь Windows не трогаем.
-- Правая кнопка не вызывает отправку/отзыв петов левой кнопкой.
local afkNextInput, afkCount, afkDisabled = 0, 0, false
local function antiAfkTick(now)
    if not alive or not running or not afkEnabled or afkDisabled or now < afkNextInput then return end
    afkNextInput = now + 60
    local ok, err = pcall(function()
        local virtualUser = game:GetService("VirtualUser")
        local camera = workspace.CurrentCamera
        assert(camera, "Камера ещё не загружена")
        virtualUser:CaptureController()
        virtualUser:ClickButton2(Vector2.new(0, 0), camera.CFrame)
    end)
    if ok then
        afkCount = afkCount + 1
        afkText = "Анти-AFK: виртуальных нажатий — " .. afkCount
        if afkCount == 1 then print("[Сундук] Анти-AFK: первое виртуальное нажатие выполнено.") end
    else
        afkDisabled = true
        afkText = "Анти-AFK: вызов недоступен; см. консоль"
        warn("[Сундук] Анти-AFK не запущен: " .. tostring(err))
    end
end
idleConnection = player.Idled:Connect(function()
    antiAfkTick(os.clock())
end)
task.spawn(function()
    while alive do
        antiAfkTick(os.clock())
        task.wait(1)
    end
end)

local function main()
    local framework = ReplicatedStorage:WaitForChild("Framework", 15)
    assert(framework, "Нет Framework: эта версия игры отличается от проекта.")
    local module = framework:WaitForChild("Library", 15)
    assert(module, "Не найдена Framework.Library.")
    local library = require(module)
    local deadline = os.clock() + 30
    while alive and not library.Loaded and os.clock() < deadline do task.wait(0.25) end
    if not alive then return end
    assert(library.Loaded, "Библиотека игры не загрузилась за 30 секунд.")
    UI.setLibrary(library)
    assert(library.Signal and type(library.Signal.Fire) == "function", "Не найдено событие отправки петов.")
    assert(library.WorldCmds and library.WorldCmds.HasArea, "Не найдена проверка доступности локации.")
    local lastChestPosition, lastChestFolder, lastChestSeen
    local boostNextCheck, boostPendingAt, boostDisabled = 0, nil, false
    local function queueButton(guiButton)
        assert(type(getconnections) == "function",
            "Madium не предоставляет getconnections: вызов кнопки недоступен")
        local callbacks = {}
        for _, connection in ipairs(getconnections(guiButton.Activated)) do
            if connection.Enabled ~= false and type(connection.Function) == "function" then
                table.insert(callbacks, connection.Function)
            end
        end
        if #callbacks == 0 then return false end
        assert(#callbacks == 1, "У кнопки несколько обработчиков; активация отменена")
        -- Обработчики интерфейса запускаем отдельной задачей, как события игры.
        -- Не вызываем их внутри стека проверки запасов.
        task.spawn(callbacks[1])
        return true
    end
    local function handleBoostDialog()
        local message = library.GUI and library.GUI.Message
        if not message or not message.Gui or not message.Gui.Enabled then return false end
        local desc = message.Desc
        local text = desc and desc.Text or ""
        -- Отвечаем только на известный запрос истёкшего Triple Coins.
        if text == "Your Triple Coins Boost has expired. Would you like to renew?" then
            local no = message.No
            if no and no.Visible and no.Active then
                assert(queueButton(no), "Не найден обработчик закрытия окна Triple Coins")
                boostText = "Triple Coins: закрываю предложение открыть магазин"
            else
                boostText = "Triple Coins: жду готовности окна продления"
            end
        else
            boostText = "Triple Coins: жду закрытия другого окна игры"
        end
        return true
    end
    local function activateTripleCoins()
        -- Вызываем только обработчик Use нужного буста, как при ручном
        -- использовании. Кнопки покупки и серверных бустов не затрагиваем.
        assert(type(getconnections) == "function",
            "Madium не предоставляет getconnections: вызов кнопки недоступен")
        local shop = playerGui:FindFirstChild("ExclusiveShop")
        local useButton
        if shop then
            for _, entry in ipairs(shop:GetDescendants()) do
                if entry:GetAttribute("Boost") == "Triple Coins" then
                    local buttons = entry:FindFirstChild("Buttons")
                    local use = buttons and buttons:FindFirstChild("Use")
                    if use and use:IsA("GuiButton") then
                        assert(not useButton, "Найдено несколько кнопок Triple Coins; активация отменена")
                        useButton = use
                    end
                end
            end
        end
        if not useButton then
            boostText = "Triple Coins: открой магазин бустов один раз"
            return false
        end
        if not queueButton(useButton) then
            boostText = "Triple Coins: открой магазин бустов один раз"
            return false
        end
        return true
    end
    local function updateTripleCoins(nearChest)
        if not autoBoostEnabled then return end
        if boostDisabled then return end
        if not nearChest then
            boostText = "Triple Coins: жду подхода к сундуку"
            return
        end
        local now = os.clock()
        if now < boostNextCheck then return end
        boostNextCheck = now + 2
        local ok, err = pcall(function()
            if handleBoostDialog() then return end
            local data = library.Save.Get()
            if not data or type(data.Boosts) ~= "table" or type(data.BoostsInventory) ~= "table" then
                boostText = "Triple Coins: жду загрузки запасов"
                return
            end
            local remaining = data.Boosts["Triple Coins"]
            local stock = data.BoostsInventory["Triple Coins"]
            assert(remaining == nil or type(remaining) == "number", "Неизвестный формат таймера буста")
            assert(stock == nil or type(stock) == "number", "Неизвестный формат запасов буста")
            if remaining and remaining > 0 then
                if boostPendingAt then print("[Сундук] Triple Coins активирован.") end
                boostPendingAt = nil
                boostText = "Triple Coins: активен, осталось " .. math.ceil(remaining) .. " сек."
            elseif boostPendingAt then
                boostText = "Triple Coins: жду появления активного таймера"
                if now - boostPendingAt >= 15 then
                    boostDisabled = true
                    boostText = "Triple Coins: нет подтверждения; автоактивация отключена"
                    warn("[Сундук] Нет подтверждения Triple Coins. Повторных запросов не будет; фарм продолжается.")
                end
            elseif not stock or stock <= 0 then
                boostText = "Triple Coins: закончились в запасе"
            else
                if activateTripleCoins() then
                    boostPendingAt = now
                    boostText = "Triple Coins: обработчик Use запущен; жду таймер"
                end
            end
        end)
        if not ok then
            boostDisabled = true
            boostText = "Triple Coins: ошибка; автоактивация отключена"
            warn("[Сундук] Ошибка Triple Coins: " .. tostring(err))
        end
    end
    -- BEGIN PROGRESSION MODULES
local createProgressionAdapter=(function()
-- Адаптер исследованной копии PSX: штатные BindableEvent/Signal покупки и перехода.
-- Не покупает телепорты, gamepass или предметы за Robux.
local function createProgressionAdapter(library,player,world,options)
    local adapter={}
    local pathfinding=game:GetService("PathfindingService")
    local generation=0
    local moveGoal,moveBusy,nextMoveRetry=nil,false,0
    local currentCoin,coinSentAt,coinHealth,coinProgressAt
    local travelNext,travelAttempts={},{}
    local function root() return player.Character and player.Character:FindFirstChild("HumanoidRootPart") end
    local function humanoid() return player.Character and player.Character:FindFirstChildWhichIsA("Humanoid") end
    local function map() return world:FindFirstChild("__MAP") end
    local function canAct() return options.canAct() end
    function adapter.log(message) options.log("[Прогрессия] "..message) end
    function adapter.cancelMovement()
        generation=generation+1;moveBusy=false;moveGoal=nil
        local h,r=humanoid(),root()
        if h and r then h:MoveTo(r.Position) end
    end
    function adapter.reset()
        travelNext={};travelAttempts={};nextMoveRetry=0
    end
    local function ground(point)
        local params=RaycastParams.new()
        params.FilterType=Enum.RaycastFilterType.Include
        params.FilterDescendantsInstances=map() and {map()} or {}
        local hit=world:Raycast(point+Vector3.new(0,80,0),Vector3.new(0,-200,0),params)
        return hit and hit.Position+Vector3.new(0,3,0) or point+Vector3.new(0,3,0)
    end
    local function approach(point,distance)
        local r=root();if not r then return point end
        local d=Vector3.new(r.Position.X-point.X,0,r.Position.Z-point.Z)
        if d.Magnitude<0.1 then d=Vector3.new(0,0,1) end
        return ground(point+d.Unit*distance)
    end
    local function moveTo(point,now,threshold)
        local r,h=root(),humanoid()
        if not r or not h or h.Health<=0 then return false,"Жду персонажа…" end
        if (r.Position-point).Magnitude<=(threshold or 7) then
            if moveBusy then adapter.cancelMovement() end
            return true
        end
        if moveBusy and moveGoal and (moveGoal-point).Magnitude<7 then return false end
        if now<nextMoveRetry then return false end
        adapter.cancelMovement();moveGoal=point;moveBusy=true
        local token=generation
        task.spawn(function()
            local ok=pcall(function()
                local path=pathfinding:CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=true,WaypointSpacing=6})
                path:ComputeAsync(r.Position,point)
                if path.Status~=Enum.PathStatus.Success then
                    adapter.navigationMessage="Путь не найден. Ожидаю доступный проход или портал."
                    return
                end
                adapter.navigationMessage=nil
                local waypoints=path:GetWaypoints()
                for _,waypoint in ipairs(waypoints) do
                    if token~=generation or not canAct() or root()~=r or h.Health<=0 then return end
                    if waypoint.Action==Enum.PathWaypointAction.Jump then h.Jump=true end
                    h:MoveTo(waypoint.Position)
                    local untilTime=os.clock()+5
                    while (r.Position-waypoint.Position).Magnitude>5 and os.clock()<untilTime do
                        if token~=generation or not canAct() or root()~=r then return end
                        task.wait(0.15)
                    end
                    if (r.Position-waypoint.Position).Magnitude>8 then return end
                end
            end)
            if token==generation then
                moveBusy=false;nextMoveRetry=os.clock()+(ok and 1 or 4)
            end
        end)
        return false
    end
    local function position(object)
        if object:IsA("BasePart") then return object.Position end
        if object:IsA("Model") then return object.PrimaryPart and object.PrimaryPart.Position or object:GetPivot().Position end
        local part=object:FindFirstChildWhichIsA("BasePart",true)
        return part and part.Position
    end
    local function portalFor(area)
        local m=map();local interactive=m and m:FindFirstChild("Interactive")
        local portals=interactive and interactive:FindFirstChild("Portals")
        local nearest,distance;local r=root()
        if portals then for _,p in ipairs(portals:GetDescendants()) do
            if p:GetAttribute("Area")==area then
                local point=position(p);local d=r and point and (r.Position-point).Magnitude or 0
                if not nearest or d<distance then nearest,distance=p,d end
            end
        end end
        return nearest
    end
    local function interact(object)
        local host=object:IsA("Model") and object.PrimaryPart or object
        local event=host and host:FindFirstChild("Activated")
        if not event or not event:IsA("BindableEvent") then return false end
        event:Fire();return true
    end
    local function targetPriority(coin)
        local name=string.lower(tostring(coin:GetAttribute("Name") or ""))
        local function has(word) return string.find(name,word,1,true)~=nil end
        if has("chest") then
            if has("grand") or has("giant") or has("super") or has("large") then return 1 end
            if has("small") then return 3 end
            return 2
        end
        if has("vault") or has("large safe") or has("big safe") then return 4 end
        if has("safe") then return 5 end
        if has("present") or has("gift") then return 6 end
        if has("crate") then return 7 end
        if has("large coins") then return 8 end
        if has("tiny coins") or has("small coins") then return 10 end
        if has("coin") then return 9 end
        return 11
    end
    function adapter.activeTargetArea()
        local things=world:FindFirstChild("__THINGS")
        local folder=things and things:FindFirstChild("Coins")
        if currentCoin and currentCoin.Parent==folder and currentCoin:FindFirstChild("POS") then
            local health=currentCoin:GetAttribute("Health")
            if type(health)~="number" or health>0 then return currentCoin:GetAttribute("Area") end
        end
        currentCoin=nil
        return nil
    end
    local function usePortal(portal,now)
        local point=position(portal);local r=root()
        if not point or not r then return "Жду точку входа портала…" end
        if library.Variables.Teleporting then return "Жду завершения перехода через портал…" end
        local destination=portal:GetAttribute("Area")
        if destination and library.WorldCmds.HasArea(destination) and portal:GetAttribute("Unlocked")~=true then
            return "Жду готовности открытого портала…"
        end
        if (r.Position-point).Magnitude>8 then
            moveTo(approach(point,4),now,3)
            return adapter.navigationMessage or "Иду к входу в портал…"
        elseif now>=(travelNext[portal] or 0) and not library.Variables.MessageOpen then
            adapter.cancelMovement()
            if interact(portal) then
                travelNext[portal]=now+5
                adapter.log("Использован портал: "..tostring(portal:GetAttribute("Area")))
            else return "Жду загрузки обработчика портала…" end
        end
        return "Жду перемещения через портал…"
    end
    local islandNames={
        ["Ancient Island"]=true,["Samurai Island"]=true,["Candy Island"]=true,
        ["Haunted Island"]=true,["Hell Island"]=true,["Heaven Island"]=true,
    }
    local function islandFor(area)
        if area=="Heavens Gate" then return "Heaven Island" end
        return islandNames[area] and area or "hub"
    end
    local function currentFantasyIsland(atPoint)
        local m=map();local markers=m and m:FindFirstChild("Teleports");local r=root()
        local origin=atPoint or (r and r.Position)
        local nearest,distance
        if markers and origin then
            for _,marker in ipairs(markers:GetChildren()) do
                local dir=library.Directory.Areas[marker.Name]
                if marker:IsA("BasePart") and dir and dir.world=="Fantasy" then
                    local d=(origin-marker.Position).Magnitude
                    if not nearest or d<distance then nearest,distance=marker.Name,d end
                end
            end
        end
        return nearest and islandFor(nearest) or nil
    end
    local function routeFantasy(area,now)
        if library.WorldCmds.Get()~="Fantasy" then return false end
        local current=currentFantasyIsland();local destination=islandFor(area)
        if not current then
            adapter.cancelMovement()
            return true,"Жду маркеры локаций Fantasy; прямой путь к острову отключён"
        end
        if current==destination then return false end
        if current~="hub" then
            local back,bestDistance;local r=root()
            for _,hubArea in ipairs({"Fantasy Portals","Enchanted Forest","Fantasy Shop"}) do
                local p=portalFor(hubArea);local point=p and position(p)
                if point and r and currentFantasyIsland(point)==current then
                    local d=(r.Position-point).Magnitude
                    if not back or d<bestDistance then back,bestDistance=p,d end
                end
            end
            if not back then
                adapter.cancelMovement()
                return true,"На острове не найден обратный портал к Fantasy Portals"
            end
            return true,"Возвращаюсь с "..current.." к порталам. "..usePortal(back,now)
        end
        local portal=portalFor(destination)
        if not portal or currentFantasyIsland(position(portal))~="hub" then
            adapter.cancelMovement()
            return true,"Жду портал на "..destination.."; идти напрямую через стены не буду"
        end
        if not library.WorldCmds.HasArea(destination) then
            adapter.cancelMovement()
            return true,"Остров "..destination.." ещё не открыт"
        end
        return true,"Переход на "..destination..". "..usePortal(portal,now)
    end
    function adapter.snapshot(route)
        local save=library.Save.Get()
        if not save or not root() or not library.WorldCmds.HasLoaded() then return {ready=false} end
        if library.Variables.Trading or library.Variables.UsingMachine or library.Variables.UsingCannon or library.Variables.Teleporting
            or (library.Variables.OpeningEgg or 0)>0 then
            adapter.cancelMovement()
            return {ready=false,message="Жду окончания действия в игре…"}
        end
        if library.Shared.IsHardcore then return {ready=false,message="Режим прогрессии пока рассчитан на обычный PSX, без Hardcore"} end
        local owned={}
        for _,zone in ipairs(route) do
            if library.Directory.Areas[zone.name] then owned[zone.name]=library.WorldCmds.HasArea(zone.name) end
        end
        return {ready=true,world=library.WorldCmds.Get(),owned=owned,areas=library.Directory.Areas,currency=save}
    end
    function adapter.preparePurchase(area,now)
        if library.Variables.MessageOpen then return false,"Жду закрытия окна игры…" end
        local m=map();local gates=m and m:FindFirstChild("Gates")
        local gate=gates and gates:FindFirstChild(area)
        local object=gate or portalFor(area)
        if not object then return false,"Жду появления ворот/портала "..area.."…" end
        local point=position(object);if not point then return false,"Нет точки входа "..area end
        -- Покупки островов находятся в хабе. Ворота Heavens Gate — на Heaven Island.
        local purchaseArea=gate and area or "Fantasy Portals"
        local routing,message=routeFantasy(purchaseArea,now)
        if routing then return false,message end
        local r=root();local isPortal=gate==nil
        local radius=isPortal and 8 or 30
        -- Высокие ворота проверяем по горизонтали: их центр бывает выше персонажа.
        local d=Vector3.new(r.Position.X-point.X,0,r.Position.Z-point.Z).Magnitude
        if d>radius then moveTo(approach(point,isPortal and 5 or 18),now,5);return false,"Иду к покупке "..area.."…" end
        adapter.cancelMovement()
        return true,"Открываю покупку "..area.."…"
    end
    function adapter.beginPurchase(purchase)
        local m=map();local gates=m and m:FindFirstChild("Gates")
        local gate=gates and gates:FindFirstChild(purchase.name)
        if gate then library.Signal.Fire("Attempt Buy Gate",gate);return true end
        local portal=portalFor(purchase.name)
        if portal and interact(portal) then return true end
        return false,"Обработчик покупки "..purchase.name.." не найден"
    end
    function adapter.confirmPurchase(purchase)
        local message=library.GUI.Message
        if not message or not message.Gui.Enabled then return nil end
        local amount=library.Functions.Commas(purchase.cost)
        local actual=message.Desc.Text
        local gateText="Are you sure you want to buy this area for "..amount.." "..purchase.currency.."?"
        local portalText="Buy this area for "..amount.." "..purchase.currency.."?"
        if actual~=gateText and actual~=portalText then return "Открыто другое окно; покупка зоны ожидает" end
        -- Повторно проверяем баланс и открытие непосредственно перед Yes.
        local save=library.Save.Get()
        if not save or (save[purchase.currency] or 0)<purchase.cost then return "Недостаточно монет для подтверждения" end
        if library.WorldCmds.HasArea(purchase.name) then return nil end
        if not purchase.confirmed and message.Yes.Visible and message.Yes.Active then
            assert(options.queueButton(message.Yes),"Кнопка Yes покупки недоступна")
            purchase.confirmed=true
            adapter.log("Подтверждена покупка "..purchase.name.." за "..amount.." "..purchase.currency)
        end
        return "Покупаю "..purchase.name.."; жду открытия зоны…"
    end
    function adapter.travelWorld(destination,now)
        if library.WorldCmds.Get()==destination then travelAttempts[destination]=0;return "Мир загружен" end
        if not library.WorldCmds.HasAccess(destination) then return "Мир "..destination.." ещё недоступен" end
        local m=map();local cannons=m and m:FindFirstChild("Cannons")
        local cannon=cannons and cannons:FindFirstChild(destination)
        if not cannon then return "В текущем мире не найдена пушка в "..destination end
        local r=root();if not r then return "Жду персонажа…" end
        if (r.Position-cannon.Position).Magnitude>22 then
            moveTo(approach(cannon.Position,10),now,6)
            return "Иду к пушке в "..destination.."…"
        end
        adapter.cancelMovement()
        if now<(travelNext[destination] or 0) then return "Жду перехода в "..destination.."…" end
        if (travelAttempts[destination] or 0)>=3 then return "Переход не подтверждён. Проверь окно игры и включи прогрессию повторно" end
        if library.Variables.MessageOpen or not library.WorldCmds.CanDoAction() then return "Жду готовности перехода…" end
        if interact(cannon) then
            travelAttempts[destination]=(travelAttempts[destination] or 0)+1
            travelNext[destination]=now+30
            adapter.log("Запрошена пушка в "..destination)
        end
        return "Перехожу в "..destination.."…"
    end
    function adapter.farm(area,now)
        local m=map();local teleports=m and m:FindFirstChild("Teleports")
        local marker=teleports and teleports:FindFirstChild(area)
        local portal=portalFor(area)
        local r=root();if not r then return "Жду персонажа…",false end
        local routing,routeMessage=routeFantasy(area,now)
        if routing then return routeMessage,false end
        -- Сначала обслуживаем уже назначенную цель. Новые спавны, расстояние
        -- и истечение 30 секунд не разрешают выбрать вместо неё другой объект.
        if adapter.activeTargetArea()==area then
            local health=currentCoin:GetAttribute("Health")
            local point=currentCoin.POS.Position
            if health~=coinHealth then coinHealth=health;coinProgressAt=now end
            if (r.Position-point).Magnitude>library.Settings.CoinGrabDistance then
                moveTo(approach(point,12),now,6)
                return "Возвращаюсь к текущей цели в "..area.."…",false
            end
            -- Если атака не началась, повторяем назначение только ТОЙ ЖЕ цели.
            if now-(coinProgressAt or coinSentAt or now)>=30 and now-(coinSentAt or now)>=30 then
                coinSentAt=now
                library.Signal.Fire("Group Select Coin",currentCoin)
            end
            return "Фармлю "..tostring(currentCoin:GetAttribute("Name")).."; жду полного разрушения",true
        end
        local things=world:FindFirstChild("__THINGS");local coins=things and things:FindFirstChild("Coins")
        local target,distance,priority
        if coins then
            for _,coin in ipairs(coins:GetChildren()) do
                local pos=coin:FindFirstChild("POS");local model=coin:FindFirstChild("Coin")
                local health=coin:GetAttribute("Health")
                local coinDir=library.Directory.Coins[coin:GetAttribute("Name")]
                local worldDir=library.Directory.Worlds[library.Directory.Areas[area].world]
                if coinDir and coinDir.currencyType==worldDir.mainCurrency
                    and coin:GetAttribute("Area")==area and coin:GetAttribute("ID")~=nil and pos and model
                    and not model:GetAttribute("PreventClick") and (type(health)~="number" or health>0) then
                    local d=(r.Position-pos.Position).Magnitude
                    local rank=targetPriority(coin)
                    if not target or rank<priority or (rank==priority and d<distance) then
                        target,distance,priority=coin,d,rank
                    end
                end
            end
        end
        if target then
            if distance>math.min(library.Settings.CoinGrabDistance-2,45) then
                moveTo(approach(target.POS.Position,12),now,6)
                return adapter.navigationMessage or ("Иду к фарму в "..area.."…"),false
            end
            adapter.cancelMovement()
            currentCoin=target;coinSentAt=now;coinProgressAt=now;coinHealth=target:GetAttribute("Health")
            library.Signal.Fire("Group Select Coin",target)
            return "Петы отправлены: "..tostring(target:GetAttribute("Name")),true
        end
        if marker then
            if (r.Position-marker.Position).Magnitude>50 then
                moveTo(ground(marker.Position),now,7)
                return adapter.navigationMessage or ("Перехожу к фарму: "..area.."…"),false
            end
            return "Жду появления объектов в "..area.."…",false
        end
        return "Жду точки фарма "..area.."…",false
    end
    return adapter
end
return createProgressionAdapter
end)()
local createProgression=(function()
-- Планировщик прогрессии. Все действия выполняет переданный адаптер игры.
local function createProgression(adapter)
    local route={
        {name="Town",world="Spawn"},{name="Forest",world="Spawn"},
        {name="Beach",world="Spawn"},{name="Mine",world="Spawn"},
        {name="Winter",world="Spawn"},{name="Glacier",world="Spawn"},
        {name="Desert",world="Spawn"},{name="Volcano",world="Spawn"},
        {name="Cave",world="Spawn",noFarm=true},
        {name="Enchanted Forest",world="Fantasy"},
        {name="Fantasy Portals",world="Fantasy",noFarm=true},
        {name="Ancient Island",world="Fantasy"},{name="Samurai Island",world="Fantasy"},
        {name="Candy Island",world="Fantasy"},{name="Haunted Island",world="Fantasy"},
        {name="Hell Island",world="Fantasy"},{name="Heaven Island",world="Fantasy"},
        {name="Heavens Gate",world="Fantasy"},
    }
    local self={pending=nil,failed=false,state={message="Прогрессия готова",targetArea="Town"}}
    local function fail(message)
        self.failed=true; adapter.cancelMovement()
        self.state.message="Прогрессия остановлена: "..message
    end
    function self.cancel() adapter.cancelMovement() end
    function self.reset()
        self.failed=false
        -- Не забываем отправленную покупку: после паузы сначала проверим её результат.
        adapter.cancelMovement()
        if adapter.reset then adapter.reset() end
    end
    local function tick(now)
        if self.failed then return self.state end
        local snapshot=adapter.snapshot(route)
        if not snapshot.ready then self.state.message=snapshot.message or "Жду загрузки игры…";return self.state end
        local target,nextZone
        for _,zone in ipairs(route) do
            if not snapshot.owned[zone.name] then nextZone=zone;break end
            if not zone.noFarm then target=zone end
        end
        self.state.targetArea=target and target.name or "Town"
        self.state.nextArea=nextZone and nextZone.name or nil
        self.state.nearChest=false
        self.state.completed=nextZone==nil
        self.state.price=nil;self.state.currency=nil;self.state.balance=nil
        if self.pending then
            local purchase=self.pending
            self.state.price=purchase.cost;self.state.currency=purchase.currency;self.state.balance=snapshot.currency[purchase.currency]
            if snapshot.owned[purchase.name] then
                adapter.log("Открыта зона: "..purchase.name)
                self.pending=nil;adapter.cancelMovement()
            elseif now-purchase.started>=35 then
                self.pending=nil
                fail("нет подтверждения покупки "..purchase.name..". Проверь окно игры и включи режим повторно.")
                return self.state
            else
                local confirmed=adapter.confirmPurchase(purchase)
                self.state.message=confirmed or ("Жду подтверждения открытия "..purchase.name.."…")
                return self.state
            end
        end
        -- Не уводим петов даже ради покупки следующей зоны до конца их атаки.
        local activeArea=adapter.activeTargetArea and adapter.activeTargetArea()
        if activeArea then
            self.state.targetArea=activeArea
            local nextDir=nextZone and snapshot.areas[nextZone.name]
            if nextDir and nextDir.gate then
                self.state.price=nextDir.gate.cost;self.state.currency=nextDir.gate.currency
                self.state.balance=snapshot.currency[nextDir.gate.currency]
            end
            local message,near=adapter.farm(activeArea,now)
            self.state.message=message
            self.state.nearChest=activeArea=="Heavens Gate" and near==true
            return self.state
        end
        if nextZone then
            local dir=snapshot.areas[nextZone.name]
            if not dir then fail("нет описания зоны "..nextZone.name);return self.state end
            if snapshot.world~=nextZone.world then
                if not target or target.world==nextZone.world or (target.name=="Cave" or snapshot.owned.Cave) then
                    self.state.message=adapter.travelWorld(nextZone.world,now)
                    return self.state
                end
            end
            if dir.gate then
                local cost,currency=dir.gate.cost,dir.gate.currency
                if type(cost)~="number" or cost<0 or type(currency)~="string" then fail("неизвестная цена зоны");return self.state end
                if currency~="Coins" and currency~="Fantasy Coins" then fail("неожиданная валюта "..currency);return self.state end
                local balance=snapshot.currency[currency]
                if type(balance)~="number" then self.state.message="Жду баланс "..currency;return self.state end
                self.state.price=cost;self.state.currency=currency;self.state.balance=balance
                if balance>=cost and snapshot.world==nextZone.world then
                    local ready,message=adapter.preparePurchase(nextZone.name,now)
                    self.state.message=message
                    if ready then
                        local purchase={name=nextZone.name,cost=cost,currency=currency,started=now}
                        self.pending=purchase
                        local sent,reason=adapter.beginPurchase(purchase)
                        if not sent then self.pending=nil;fail(reason or "не удалось открыть покупку") end
                    end
                    return self.state
                end
            elseif snapshot.world==nextZone.world then
                self.state.message="Жду открытия стартовой зоны "..nextZone.name.." после перехода…"
                return self.state
            end
        else
            self.state.price=nil;self.state.currency=nil;self.state.balance=nil
        end
        if not target then self.state.message="Не открыта начальная зона Town";return self.state end
        if snapshot.world~=target.world then
            self.state.message=adapter.travelWorld(target.world,now)
            return self.state
        end
        local message,near=adapter.farm(target.name,now)
        self.state.message=message
        self.state.nearChest=target.name=="Heavens Gate" and near==true
        self.state.completed=nextZone==nil
        return self.state
    end
    function self.tick(now)
        local ok,result=pcall(tick,now)
        if not ok then fail(tostring(result)) end
        return self.state
    end
    return self
end
return createProgression
end)()
-- END PROGRESSION MODULES
    local adapter=createProgressionAdapter(library,player,workspace,{
        canAct=function()
            return alive and running and farmMode=="progression"
                and not library.Variables.LoadingWorld and not library.Variables.Trading
                and not library.Variables.UsingCannon and not library.Variables.UsingMachine
                and (library.Variables.OpeningEgg or 0)<=0
        end,
        queueButton=queueButton,
        log=function(message) record(message);print(message) end,
    })
    progression=createProgression(adapter)
    local count = 0
    while alive do
        gui:SetAttribute("MainHeartbeat", os.clock())
        if running then
            if farmMode=="progression" then
                progressionState=progression.tick(os.clock())
                updateTripleCoins(progressionState.nearChest)
                if progression.failed then running=false end
                status(progressionState.message)
            else
            local folder = workspace:FindFirstChild("__THINGS")
            local coins = folder and folder:FindFirstChild("Coins")
            local message = coins and "Жду Grand Heaven Chest…" or "Жду загрузки объектов игры…"
            local chestPresent = false
            if coins then
                -- Только отсутствие объекта подтверждает конец цикла.
                -- Изменение здоровья, ID или вложенной модели не снимает блокировку.
                for _, coin in ipairs(coins:GetChildren()) do
                    local name = coin:GetAttribute("Name")
                    if (name == "Heavens Gate Grand Heaven Chest" or name == "Grand Heaven Chest")
                        and coin:GetAttribute("Area") == "Heavens Gate" then
                        chestPresent = true
                        local chestPos = coin:FindFirstChild("POS")
                        if chestPos and chestPos:IsA("BasePart") then
                            lastChestPosition = chestPos.Position
                            lastChestFolder = coins
                            lastChestSeen = os.clock()
                        end
                        break
                    end
                end
                observeChest(cycle, chestPresent, os.clock())
                if cycle.sent then
                    message = "Запрос уже отправлен. Жду исчезновения сундука."
                end
                for _, coin in ipairs(coins:GetChildren()) do
                    local name = coin:GetAttribute("Name")
                    local area = coin:GetAttribute("Area")
                    if (name == "Heavens Gate Grand Heaven Chest" or name == "Grand Heaven Chest")
                        and area == "Heavens Gate" then
                        local id = coin:GetAttribute("ID")
                        local health = coin:GetAttribute("Health")
                        local pos = coin:FindFirstChild("POS")
                        local model = coin:FindFirstChild("Coin")
                        if type(health) == "number" and health <= 0 then
                            -- Ожидаем подтверждённого отсутствия живого сундука.
                        elseif id ~= nil and pos and pos:IsA("BasePart") and model then
                            if not library.WorldCmds.HasArea(area) then
                                message = "Локация Heavens Gate недоступна."
                            elseif not player.Character or not player.Character.PrimaryPart then
                                message = "Жду появления персонажа…"
                            elseif (player.Character.PrimaryPart.Position - pos.Position).Magnitude
                                > library.Settings.CoinGrabDistance then
                                message = "Подойди ближе к сундуку."
                            elseif not cycle.sent then
                                if model:GetAttribute("PreventClick") then
                                    message = "Сундук ещё не готов к атаке…"
                                else
                                    cycle.sent = true
                                    library.Signal.Fire("Group Select Coin", coin)
                                    count = count + 1
                                    message = "Запрос отправки всех петов: " .. count .. ". Жду разрушения."
                                    print("[Сундук] " .. message)
                                end
                            else
                                message = "Запрос уже отправлен. Жду разрушения сундука."
                            end
                            break
                        end
                    end
                end
            else
                -- Выгрузка мира не является подтверждением разрушения сундука.
                cycle.absentSince = nil
            end
            local root = player.Character and player.Character.PrimaryPart
            local nearChest = root and lastChestPosition and coins == lastChestFolder
                and lastChestSeen and os.clock() - lastChestSeen <= 10
                and (root.Position - lastChestPosition).Magnitude <= math.min(library.Settings.CoinGrabDistance, 100)
            updateTripleCoins(nearChest)
            status(message)
            end
        else
            cycle.absentSince = nil
        end
        if not running then status(farmMode=="progression" and progression and progression.failed and progression.state.message or "Фарм на паузе") end
        task.wait(0.25)
    end
end

local ok, err = xpcall(main, function(message)
    return debug.traceback(tostring(message), 2)
end)
if not ok and alive then
    gui:SetAttribute("MainFailed", true)
    record("Ошибка основного цикла: " .. tostring(err))
    running = false
    status("Ошибка: " .. tostring(err))
    warn("[Сундук] " .. tostring(err))
elseif alive then
    record("Основной цикл неожиданно завершился")
else
    record("Основной цикл остановлен")
end
]====]
assert(type(loadstring) == "function", "Автозапуск требует loadstring в Madium")
local player = game:GetService("Players").LocalPlayer
assert(player, "Дождитесь входа в игру")
local playerGui = player:WaitForChild("PlayerGui", 30)
assert(playerGui, "Не найден интерфейс игрока")
-- Проверяем файл до запуска контроллера.
local initialSource = embeddedSource
local compiled, compileError = loadstring(initialSource)
assert(compiled, compileError)
local previous = playerGui:FindFirstChild("HeavenChestAutoStart")
local previousMode=previous and previous:GetAttribute("FarmMode")
local previousRunning=previous and previous:GetAttribute("FarmRunning")
if previous then previous:Destroy() end
-- Повторное выполнение загрузчика должно действительно применять новый код.
local previousHelper=playerGui:FindFirstChild("HeavenChestHelper")
if previousHelper then
    previousHelper:SetAttribute("StopReason","Запущена новая копия скрипта")
    previousHelper:Destroy()
end
local gui = Instance.new("ScreenGui")
gui.Name = "HeavenChestAutoStart"
gui.ResetOnSpawn = false
gui.Parent = playerGui
if previousMode=="chest" or previousMode=="progression" then gui:SetAttribute("FarmMode",previousMode) end
if type(previousRunning)=="boolean" then gui:SetAttribute("FarmRunning",previousRunning) end
local toggle = Instance.new("TextButton")
toggle.Size = UDim2.fromOffset(360, 36)
toggle.Position = UDim2.new(0, 16, 0, 292)
toggle.BackgroundColor3 = Color3.fromRGB(30, 65, 90)
toggle.TextColor3 = Color3.new(1, 1, 1)
toggle.TextSize = 14
toggle.Parent = gui
toggle.Visible = false -- Управление контроллером перенесено в основную панель.
local alive, enabled, launching = true, true, false
local observed, destroyConnection
local restartTimes = {}
local confirmUntil = 0
local function updateText()
    if alive then
        gui:SetAttribute("AutoEnabled", enabled)
        toggle.Text = enabled and "Автозапуск включён — нажми для отключения" or "Автозапуск выключен — нажми для включения"
    end
end
local function observe(helper)
    if observed == helper then return end
    if destroyConnection then destroyConnection:Disconnect(); destroyConnection = nil end
    observed = helper
    if helper then
        destroyConnection = helper.Destroying:Connect(function()
            if helper:GetAttribute("StopReason") == "Остановка подтверждена кнопкой" then
                enabled = false
                updateText()
                print("[Автозапуск] Отключён после ручной остановки основного скрипта.")
            end
        end)
    end
end
gui.Destroying:Connect(function()
    alive = false
    if destroyConnection then destroyConnection:Disconnect() end
end)
toggle.Activated:Connect(function()
    if enabled and os.clock() >= confirmUntil then
        confirmUntil = os.clock() + 3
        toggle.Text = "Нажми ещё раз за 3 секунды, чтобы выключить автозапуск"
        task.delay(3, function() if alive and os.clock() >= confirmUntil then updateText() end end)
        return
    end
    enabled = not enabled
    if enabled then restartTimes = {} end
    updateText()
end)
local function launch()
    if launching then return end
    local now = os.clock()
    while restartTimes[1] and now - restartTimes[1] > 600 do table.remove(restartTimes, 1) end
    if #restartTimes >= 3 then
        enabled = false
        updateText()
        warn("[Автозапуск] Три запуска за 10 минут. Контроллер отключён: проверьте файл диагностики.")
        return
    end
    local ok, fn = pcall(function()
        local result, err = loadstring(embeddedSource)
        assert(result, err)
        return result
    end)
    if not ok then
        enabled = false
        updateText()
        warn("[Автозапуск] Ошибка загрузки: " .. tostring(fn))
        return
    end
    launching = true
    table.insert(restartTimes, now)
    print("[Автозапуск] Запускаю основной скрипт.")
    task.spawn(function()
        local success, err = pcall(fn)
        if not success then warn("[Автозапуск] Ошибка основного скрипта: " .. tostring(err)) end
    end)
    observe(playerGui:FindFirstChild("HeavenChestHelper"))
    -- Только на создание интерфейса; основной цикл может работать бесконечно.
    task.delay(10, function() launching = false end)
end
updateText()
observe(playerGui:FindFirstChild("HeavenChestHelper"))
task.spawn(function()
    while alive do
        local requested = gui:GetAttribute("RequestedEnabled")
        if type(requested) == "boolean" then
            enabled = requested
            if enabled then restartTimes = {} end
            gui:SetAttribute("RequestedEnabled", nil)
            updateText()
        end
        local helper = playerGui:FindFirstChild("HeavenChestHelper")
        observe(helper)
        if enabled and not launching then
            local heartbeat = helper and helper:GetAttribute("MainHeartbeat")
            local stalled = type(heartbeat) == "number" and os.clock() - heartbeat > 90
            if not helper or stalled or helper:GetAttribute("MainFailed") then launch() end
        end
        task.wait(5)
    end
end)
print("[Автозапуск] Контроллер готов. F8 в основном скрипте сохраняет паузу.")
