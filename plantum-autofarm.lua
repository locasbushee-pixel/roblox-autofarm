-- ============================================================
-- 👑 FINAL FIX v6.3 — ULTIMATE MERGED EDITION
-- v6.1 (كامل: رادار + ESP + هجوم) + v6.2 (كهف سيبراني بالإحداثيات الجديدة)
-- ════════════════════════════════════════════════════════════
if _G.__FINAL_STOP then pcall(_G.__FINAL_STOP) end
_G.StopAutoFarm = false

local Players         = game:GetService("Players")
local RS              = game:GetService("ReplicatedStorage")
local VIM             = game:GetService("VirtualInputManager")
local GS              = game:GetService("GuiService")
local PS              = game:GetService("PathfindingService")
local RUN             = game:GetService("RunService")
local VU              = game:GetService("VirtualUser")
local UIS             = game:GetService("UserInputService")
local TextChatService = game:GetService("TextChatService")
local Lighting        = game:GetService("Lighting")
local TS              = game:GetService("TeleportService")

local pl  = Players.LocalPlayer
local pg  = pl:WaitForChild("PlayerGui")
local cam = workspace.CurrentCamera

for i = 47, 260 do
    local o = pg:FindFirstChild("AutoFarmV"..i); if o then o:Destroy() end
    local o2 = pg:FindFirstChild("FinalFix"..i); if o2 then o2:Destroy() end
end
for _, n in ipairs({"FinalFixGui","FinalFixMobileBtn","MobileFlyGui","WeatherAutoGui"}) do
    local o = pg:FindFirstChild(n); if o then o:Destroy() end
end

local CFG = {
    BOARD_POS      = Vector3.new(261.79, 6.93, -297.35),
    WH_RIGHT       = Vector3.new(330.97, 10.19, -178.10),
    WH_FRONT       = Vector3.new(336.0, 10.0, -177.0),
    SAFE_POS       = Vector3.new(261.79, 8.5, -297.35),
    CYBER_CAVE_POS = Vector3.new(419.36, 9.23, -603.11),
    CYBER_LEVER    = Vector3.new(235.92, 6.87, -101.00),
    CYBER_DOOR_OUT = Vector3.new(235.66, 6.23, -155.02),
    CYBER_STAY     = 15,
    CYBER_COOLDOWN = 25,
    CYBER_USE_LEVER= true,
    COOLDOWN       = 150,
    SHOWTARGET_WAIT= 6,
    DROP_NAMES     = {"Airdrop","SecretAirdrop","Drops","Airdrops","ActiveDrops","SecretDrops","SpecialDrop","RareDrop"},
    DROP_FOLDERS   = {"Drops","Airdrops","ActiveDrops","SecretDrops","SpecialDrops","ActiveEventWorkspace"},
}

local ST = {
    autoMission=true, autoDrop=true, autoCyber=true, autoWeather=false, autoPlaytime=true,
    inProgress=false, isPickup=true, boxIndex=0, totalBoxes=5,
    missionOn=false, target=nil, cdExpire=0,
    busyDrop=false, busyCyber=false, handlingDrop=false, busyWeather=false,
    walking=false, walkDest=nil, goalPos=nil, stuckStrikes=0,
    lastEq="", lastCyberLoot=0, lastStartTry=0,
    busyDropSince=0, busyCyberSince=0, score=0,
    busyStart=nil, progressStart=nil, lastPlaytimeClaim=0,
    walkSpeed=16, jumpPower=50, flySpeed=50,
    customSpeedOn=false, superJumpOn=false, infJumpOn=false,
    flyOn=false, noclipOn=false,
    invisOn=false, espPlayers=false, espDrops=false,
    fullbright=false, fov=70, antiFling=false,
    antiCuff=true, autoArmorDefense=true, lastArmorRefill=0,
    antiBullet=true, antiJail=true, hideName=false,
    forceReset=false, lastHeal=0, lastHealLog=0,
    lastSafePos=nil, jailAttempts=0, jailLockedUntil=0, lastJailLog=0, selfCuff=nil,
    clickTpOn=false, antiSitOn=false, fpsBoostOn=false,
    emergencyTpOn=true, lastEmergencyTp=0, lastEmergencyLog=0,
    spectating=false, spectateTarget=nil,
    radarSelectedPlr=nil, aimbotOn=false, killAuraOn=false,
    auraRange=15, autoKillOn=false, autoKillRange=80,
    stats={missions=0,dropsNormal=0,dropsSecret=0,quizzesSolved=0,cyberPoints=0,failed=0},
}

local mobileFlyDir = {W=false, S=false, A=false, D=false, Up=false, Down=false}
local conns = {}
local function addC(c) if c then conns[#conns+1]=c end; return c end

local flyBV, flyBG
local espHL, espTags, espDropHL, espDropTags = {}, {}, {}, {}
local invisSaved = {}
local lightSave = {}

local function restoreVis()
    for obj,orig in pairs(invisSaved) do
        pcall(function()
            if obj:IsA("BasePart") or obj:IsA("Decal") then obj.Transparency=orig
            elseif obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") then obj.Enabled=orig end
        end)
    end
    invisSaved={}
end

local function clearAllESP()
    for _, h in pairs(espHL) do pcall(function() h:Destroy() end) end; espHL = {}
    for _, b in pairs(espTags) do pcall(function() b:Destroy() end) end; espTags = {}
    for _, h in pairs(espDropHL) do pcall(function() h:Destroy() end) end; espDropHL = {}
    for _, b in pairs(espDropTags) do pcall(function() b:Destroy() end) end; espDropTags = {}
end

local logBuf={}
local logLbl, scroll, statusLbl, statsLbl

local function addLog(s)
    if _G.StopAutoFarm then return end
    logBuf[#logBuf+1]=("[%s] %s"):format(os.date("%H:%M:%S"),s)
    if #logBuf>60 then table.remove(logBuf,1) end
    if logLbl then
        logLbl.Text=table.concat(logBuf,"\n")
        task.defer(function()
            if scroll then
                scroll.CanvasSize=UDim2.new(0,0,0,logLbl.AbsoluteSize.Y+10)
                scroll.CanvasPosition=Vector2.new(0,math.max(0,logLbl.AbsoluteSize.Y))
            end
        end)
    end
    print("[v6.3]",s)
end
local function setStatus(s,color) if statusLbl then statusLbl.Text=s; if color then statusLbl.TextColor3=color end end end
local function updateStats()
    if statsLbl then
        statsLbl.Text=("مهام:%d | عادي:%d | سري:%d | حل:%d | سيبراني:%d"):format(
            ST.stats.missions,ST.stats.dropsNormal,ST.stats.dropsSecret,
            ST.stats.quizzesSolved,ST.stats.cyberPoints)
    end
end

task.spawn(function()
    while not _G.StopAutoFarm do
        task.wait(3)
        if ST.busyDrop then
            if not ST.busyStart then ST.busyStart = tick()
            elseif tick() - ST.busyStart > 45 then ST.busyDrop = false; ST.handlingDrop = false; ST.busyStart = nil end
        else ST.busyStart = nil end
        if ST.busyWeather then
            if not ST.busyWeatherSince then ST.busyWeatherSince = tick()
            elseif tick() - ST.busyWeatherSince > 75 then
                ST.busyWeather = false; ST.busyWeatherSince = nil
                print("[v6.3] weather watchdog reset")
            end
        else ST.busyWeatherSince = nil end
        if ST.inProgress then
            if not ST.progressStart then ST.progressStart = tick()
            elseif tick() - ST.progressStart > 120 then ST.inProgress = false; ST.progressStart = nil end
        else ST.progressStart = nil end
    end
end)

local function shutdown()
    _G.StopAutoFarm=true; _G.__FINAL_STOP=nil
    for _,c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    pcall(function()
        clearAllESP(); restoreVis()
        if _G.__restoreName then pcall(_G.__restoreName) end
        if flyBV then flyBV:Destroy(); flyBV=nil end
        if flyBG then flyBG:Destroy(); flyBG=nil end
        local c=pl.Character; if c then for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=true end end end
        local h=c and c:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed=16; if h.UseJumpPower then h.JumpPower=50 else h.JumpHeight=7.2 end; cam.CameraSubject = h end
        for prop,val in pairs(lightSave) do pcall(function() Lighting[prop]=val end) end
        pcall(function() cam.FieldOfView=70 end)
        for _,n in ipairs({"FinalFixGui","FinalFixMobileBtn","MobileFlyGui","WeatherAutoGui"}) do local g=pg:FindFirstChild(n); if g then g:Destroy() end end
    end)
    print("[v6.3] Stopped")
end
_G.__FINAL_STOP=shutdown

local Rem  = RS:FindFirstChild("Remotes")
local Evts = RS:FindFirstChild("Events")
local REM = {
    ShowTarget  = Rem and Rem:FindFirstChild("ShowTarget"),
    ClaimReward = Rem and Rem:FindFirstChild("ClaimMissionReward"),
    StartMission= Rem and Rem:FindFirstChild("StartMissionEvent"),
    StartMissio2= Evts and Evts:FindFirstChild("StartMissio"),
    Quiz        = Rem and Rem:FindFirstChild("AirdropQuizEvent"),
    BringPlayer = Rem and Rem:FindFirstChild("BringPlayerEvent"),
    EquipCuff   = Rem and Rem:FindFirstChild("EquipCuff"),
    GunInput    = Rem and Rem:FindFirstChild("GunInput"),
    AutoJail    = Rem and Rem:FindFirstChild("AutoJail"),
}

local function char() return pl.Character end
local function hum() local c=char(); return c and c:FindFirstChildWhichIsA("Humanoid") end
local function hrp() local c=char(); return c and c:FindFirstChild("HumanoidRootPart") end
local function alive() local h=hum(); return h and h.Health>0 end
local function flatDist(a,b) return math.sqrt((a.X-b.X)^2+(a.Z-b.Z)^2) end

local function groundOf(pos)
    local rp=RaycastParams.new(); rp.FilterType=Enum.RaycastFilterType.Exclude
    if char() then rp.FilterDescendantsInstances={char()} end
    local hit=workspace:Raycast(Vector3.new(pos.X,pos.Y+12,pos.Z),Vector3.new(0,-60,0),rp)
    return hit and Vector3.new(pos.X,hit.Position.Y+3,pos.Z) or pos
end

local function clickBtn(btn)
    if not btn then return false end
    pcall(function()
        if typeof(firesignal)=="function" then firesignal(btn.MouseButton1Click); firesignal(btn.Activated) end
    end)
    local sz=btn.AbsoluteSize; if sz.X<2 or sz.Y<2 then return false end
    local p=btn.AbsolutePosition; local ins=GS:GetGuiInset()
    pcall(function()
        VIM:SendMouseButtonEvent(p.X+sz.X/2, p.Y+sz.Y/2+ins.Y, 0, true, game, 0)
        task.wait(0.02)
        VIM:SendMouseButtonEvent(p.X+sz.X/2, p.Y+sz.Y/2+ins.Y, 0, false, game, 0)
    end)
    return true
end

local function getPart(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart",true) end
    return nil
end

local function touchBoth(a,b)
    if typeof(firetouchinterest)~="function" then return end
    pcall(function() firetouchinterest(a,b,0); task.wait(0.01); firetouchinterest(a,b,1) end)
end

local function touchObj(part)
    local r=hrp(); if not r or not part then return end
    touchBoth(r,part)
    local c=char(); if c then
        for _,limb in ipairs({"Torso","UpperTorso","Right Arm","RightHand","Left Arm","LeftHand"}) do
            local lp=c:FindFirstChild(limb); if lp then touchBoth(lp,part) end
        end
    end
end

local function getPlayerRankInfo(p)
    if not p then return "غير معروف", 0 end
    local ls = p:FindFirstChild("leaderstats")
    if ls then
        for _, v in ipairs(ls:GetChildren()) do
            local vn = v.Name:lower()
            if vn:find("رتب") or vn:find("rank") or vn:find("level") or vn:find("مستوى") then
                return tostring(v.Value), tonumber(tostring(v.Value):match("%d+")) or 0
            end
        end
    end
    if p.Team then return p.Team.Name, tonumber(p.Team.Name:match("%d+")) or 0 end
    return "عضو", 0
end

local BODY={head=1,humanoidrootpart=1,torso=1,uppertorso=1,lowertorso=1,["left arm"]=1,["right arm"]=1,["left leg"]=1,["right leg"]=1,leftupperarm=1,leftlowerarm=1,lefthand=1,rightupperarm=1,rightlowerarm=1,righthand=1,leftupperleg=1,leftlowerleg=1,leftfoot=1,rightupperleg=1,rightlowerleg=1,rightfoot=1}
local WEAPONS={"m4","scar","ak","sniper","cuff","card","laptop","gun","pistol","rifle"}

local function isCrate(item)
    local n=item.Name:lower()
    for _,w in ipairs(WEAPONS) do if n:find(w) then return false end end
    return item:IsA("Tool") or n:find("box") or n:find("crate") or n:find("صندوق") or n:find("union")
end

local function getCrate()
    local c=char(); if not c then return nil end
    for _,item in ipairs(c:GetChildren()) do
        if not BODY[item.Name:lower()] and not item:IsA("Humanoid") and not item:IsA("Shirt") and not item:IsA("Pants") and not item:IsA("ShirtGraphic") and not item:IsA("BodyColors") and not item:IsA("Animate") and not item:IsA("LocalScript") and not item:IsA("Script") and not item:IsA("Accessory") and not item:IsA("CharacterMesh") then
            if isCrate(item) then return item end
        end
    end
    local bp = pl:FindFirstChildOfClass("Backpack")
    if bp then
        for _, item in ipairs(bp:GetChildren()) do
            if item:IsA("Tool") and isCrate(item) then return item end
        end
    end
    return nil
end
local function hasCrate() return getCrate()~=nil end

local function classifyDrop(obj)
    if not obj then return "normal" end
    local n=(obj.Name or ""):lower()
    if n:find("secret") or n:find("سري") or n:find("gold") or n:find("ذهبي") then return "secret" end
    return "normal"
end

local function findActiveDrop()
    for _, n in ipairs(CFG.DROP_NAMES) do
        local obj = workspace:FindFirstChild(n)
        if obj and obj.Parent then
            if obj:IsA("Folder") then
                for _, child in ipairs(obj:GetChildren()) do
                    if (child:IsA("Model") or child:IsA("BasePart")) and child.Parent then return child, classifyDrop(child) end
                end
            else return obj, classifyDrop(obj) end
        end
    end
    for _, fName in ipairs(CFG.DROP_FOLDERS) do
        local f = workspace:FindFirstChild(fName)
        if f and (f:IsA("Folder") or f:IsA("Model")) then
            for _, item in ipairs(f:GetChildren()) do
                if (item:IsA("Model") or item:IsA("BasePart")) and item.Parent then return item, classifyDrop(item) end
            end
        end
    end
    return nil, nil
end

local function getNearbyPrompts(radius)
    local list = {}
    local r = hrp(); if not r then return list end
    radius = radius or 20
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            local parent = obj.Parent; local pp = nil
            if parent and parent:IsA("BasePart") then pp = parent
            elseif parent and parent:IsA("Model") then pp = parent.PrimaryPart or parent:FindFirstChildWhichIsA("BasePart", true) end
            if pp then
                local d = (pp.Position - r.Position).Magnitude
                if d < radius then table.insert(list, {prompt = obj, dist = d, part = pp}) end
            end
        end
    end
    table.sort(list, function(a,b) return a.dist < b.dist end)
    return list
end

local function triggerPrompt(prompt)
    if not prompt or not prompt.Parent then return false end
    pcall(function()
        local hd = prompt.HoldDuration or 0
        prompt:InputHoldBegin(); task.wait(math.max(hd + 0.15, 0.55)); prompt:InputHoldEnd()
    end)
    pcall(function() if typeof(fireproximityprompt) == "function" then fireproximityprompt(prompt) end end)
    return true
end
local function triggerPromptInstantly(prompt) return triggerPrompt(prompt) end

-- فحص سريع: هل استلم الصندوق فعلاً؟ (يفحص كل 0.05 ثانية)
local function waitCrate(timeout)
    local t0 = tick()
    repeat
        if hasCrate() then return true end
        task.wait(0.05)
    until tick() - t0 >= (timeout or 0.8)
    return hasCrate()
end

-- ضغط فوري للبرومبت بدون انتظار HoldDuration (لصندوق المهمة أو التسليم)
local function firePromptFast(prompt)
    if not prompt or not prompt.Parent or not prompt.Enabled then return end
    pcall(function() if typeof(fireproximityprompt) == "function" then fireproximityprompt(prompt) end end)
    pcall(function() prompt:InputHoldBegin(); task.wait(0.05); prompt:InputHoldEnd() end)
end

local AR_MAP = {["٠"]="0",["١"]="1",["٢"]="2",["٣"]="3",["٤"]="4",["٥"]="5",["٦"]="6",["٧"]="7",["٨"]="8",["٩"]="9"}
local function cleanText(t)
    local s = tostring(t or "")
    for ar,en in pairs(AR_MAP) do s = s:gsub(ar,en) end
    return s:gsub("×","*"):gsub("✕","*"):gsub("÷","/"):gsub("＋","+"):gsub("﹢","+"):gsub("➕","+"):gsub("－","-"):gsub("−","-"):gsub("–","-"):gsub("—","-"):gsub("―","-"):gsub("﹣","-"):gsub("＝","="):gsub("؟","?"):gsub("ـ","")
end

local function solveStr(s)
    if type(s) ~= "string" then return nil end
    local nums = {}
    for n in s:gmatch("%d+") do nums[#nums+1] = tonumber(n) end
    if #nums < 2 then return nil end
    local a,b = nums[1],nums[2]
    if     s:find("%+") then return a+b
    elseif s:find("%*") then return a*b
    elseif s:find("/")  then if b~=0 then return math.floor(a/b) end return nil
    elseif s:find("%-") then return math.abs(a-b) end
    return nil
end

local function getDropPassElements()
    local dp = pg:FindFirstChild("DropPass"); if not dp then return nil,nil,nil end
    local quez, txtBox, applyBtn
    for _,d in ipairs(dp:GetDescendants()) do
        if d:IsA("TextLabel") and d.Visible and (d.Name=="Quez" or d.Name:lower():find("quez",1,true)) then quez = d
        elseif d:IsA("TextBox") and d.Visible then txtBox = d
        elseif d:IsA("TextButton") and d.Visible and d.AbsoluteSize.X > 20 then
            local par = d.Parent
            if par and (par.Name=="Apply" or par.Name:lower():find("apply",1,true)) then applyBtn = d end
        end
    end
    if not applyBtn then for _,d in ipairs(dp:GetDescendants()) do if d:IsA("TextButton") and d.Visible and d.AbsoluteSize.X > 50 then applyBtn=d; break end end end
    return quez, txtBox, applyBtn
end

local function isDropPassShown()
    local dp = pg:FindFirstChild("DropPass"); if not dp or not dp.Enabled then return false end
    for _,d in ipairs(dp:GetDescendants()) do if d:IsA("TextLabel") and d.Name=="Quez" and d.Visible and d.AbsoluteSize.X>5 then return true end end
    return false
end

local function writeAnswer(txtBox, value)
    if not txtBox then return false end
    local s = tostring(value)
    pcall(function()
        txtBox:CaptureFocus(); task.wait(0.05); txtBox.Text = ""; task.wait(0.03)
        for i = 1, #s do txtBox.Text = s:sub(1, i); task.wait(math.random(2, 5) / 100) end
        task.wait(0.08); txtBox:ReleaseFocus(true)
    end)
    task.wait(0.05)
    if txtBox.Text == s then return true end
    pcall(function() txtBox.Text = s end); task.wait(0.05)
    return txtBox.Text == s
end

local function goTo(target)
    local part = getPart(target); if not part then return false end
    if not ST.autoDrop then return false end
    local r = hrp(); if not r then return false end
    if (r.Position - part.Position).Magnitude <= 8 then return true end
    pcall(function() r.CFrame = CFrame.new(part.Position + Vector3.new(0,3,0)); r.Velocity = Vector3.zero end)
    task.wait(0.3); r = hrp()
    if not ST.autoDrop then return false end
    if r and (r.Position - part.Position).Magnitude < 12 then return true end
    local h = hum()
    if h then
        h:MoveTo(part.Position)
        local t0 = tick()
        while tick() - t0 < 5 do
            if not ST.autoDrop or _G.StopAutoFarm then return false end
            r = hrp(); if not r or (r.Position - part.Position).Magnitude < 8 then return true end
            task.wait(0.1)
        end
    end
    return false
end

local function handleDrop(target, kind)
    if ST.busyDrop then addLog("⚠️ busyDrop مشغول"); return end
    ST.lastDropObj = target
    ST.busyDrop = true; ST.handlingDrop = true; ST.busyStart = tick()
    local isSecret = (kind == "secret")
    addLog(isSecret and "🏆 دروب سري!" or "📦 دروب عادي!")
    setStatus("دروب...", isSecret and Color3.fromRGB(255,215,0) or Color3.fromRGB(100,200,255))
    local __dp = getPart(target); if __dp then ST.goalPos = __dp.Position end
    if not goTo(target) then
        if ST.autoDrop then addLog("فشل الوصول"); ST.stats.failed = ST.stats.failed + 1 end
        ST.busyDrop = false; ST.handlingDrop = false; ST.busyStart = nil; return
    end
    if not ST.autoDrop then ST.busyDrop = false; ST.handlingDrop = false; ST.busyStart = nil; return end
    addLog("وصلنا"); task.wait(0.1)
    local part = getPart(target); local opened = false
    for attempt = 1, 8 do
        if _G.StopAutoFarm or not ST.autoDrop then break end
        local r = hrp()
        if r and part then pcall(function() r.CFrame = CFrame.new(part.Position); r.Velocity = Vector3.zero end) end
        task.wait(0.08)
        for _, entry in ipairs(getNearbyPrompts(15)) do
            firePromptFast(entry.prompt)
            task.wait(0.05)
            if isDropPassShown() then addLog("DropPass!"); opened = true; break end
        end
        if opened then break end
        pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game); task.wait(0.08); VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game) end)
        task.wait(0.08)
        if isDropPassShown() then addLog("DropPass (E)!"); opened = true; break end
    end
    if not opened and ST.autoDrop then addLog("فشل الفتح") end
    local t0 = tick(); local solved = false
    while tick() - t0 < 15 and not _G.StopAutoFarm and ST.autoDrop do
        task.wait(0.2)
        if isDropPassShown() then
            local quez, txtBox, applyBtn = getDropPassElements()
            if quez and txtBox then
                local raw = quez.Text or ""
                if raw ~= "" and raw ~= "?" and raw ~= ST.lastEq then
                    local cleaned = cleanText(raw); local ok, ans = pcall(solveStr, cleaned)
                    if ok and ans then
                        addLog(("🧮 %s = %d"):format(raw, ans))
                        writeAnswer(txtBox, ans); task.wait(0.1)
                        if applyBtn then clickBtn(applyBtn); task.wait(0.15); if isDropPassShown() then clickBtn(applyBtn) end end
                        if REM.Quiz then pcall(function() REM.Quiz:FireServer(ans) end); pcall(function() REM.Quiz:FireServer(tostring(ans)) end) end
                        ST.lastEq = raw; ST.stats.quizzesSolved = ST.stats.quizzesSolved + 1
                        if isSecret then ST.score = ST.score + 1500; ST.stats.dropsSecret = ST.stats.dropsSecret + 1; addLog("السري حل!")
                        else ST.score = ST.score + 800; ST.stats.dropsNormal = ST.stats.dropsNormal + 1; addLog("العادي حل!") end
                        solved = true; updateStats(); task.wait(0.3); break
                    end
                end
            end
        end
    end
    if not solved and ST.autoDrop then addLog("انتهى الوقت"); ST.stats.failed = ST.stats.failed + 1 end
    ST.busyDrop = false; ST.handlingDrop = false; ST.busyStart = nil
    ST.goalPos = nil
    setStatus("خامل", Color3.fromRGB(120,255,200)); updateStats()
end

local lastHandledDrop = nil
task.spawn(function()
    while not _G.StopAutoFarm do
        task.wait(0.5)
        -- لا نبدأ دروب وإحنا شايلين صندوق أو داخل مهمة أجواء (النقل الفجائي يلغي المهمة)
        if not ST.autoDrop or ST.busyDrop or ST.busyWeather or hasCrate() then continue end
        local activeDrop, kind = findActiveDrop()
        if activeDrop and activeDrop ~= lastHandledDrop then
            lastHandledDrop = activeDrop; addLog(("⚡ Fast: %s!"):format(activeDrop.Name))
            ST.inProgress = false; ST.progressStart = nil; task.spawn(handleDrop, activeDrop, kind)
        end
        local anyDrop = false
        for _, n in ipairs(CFG.DROP_NAMES) do
            local o = workspace:FindFirstChild(n)
            if o then if o:IsA("Folder") then if #o:GetChildren() > 0 then anyDrop = true; break end else anyDrop = true; break end end
        end
        if not anyDrop then lastHandledDrop = nil end
    end
end)

addC(workspace.ChildAdded:Connect(function(c)
    if _G.StopAutoFarm or ST.busyDrop then return end
    local isDrop = false
    for _, n in ipairs(CFG.DROP_NAMES) do if c.Name == n then isDrop = true; break end end
    if not isDrop then return end
    if c:IsA("Folder") then return end
    if not ST.autoDrop then return end
    addLog(("🆕 %s!"):format(c.Name)); task.wait(0.3)
    if _G.StopAutoFarm or ST.busyDrop then return end
    task.spawn(handleDrop, c, classifyDrop(c))
end))

task.spawn(function()
    local dropsF = workspace:WaitForChild("Drops", 10)
    if dropsF then
        addC(dropsF.ChildAdded:Connect(function(c)
            if _G.StopAutoFarm or ST.busyDrop or not ST.autoDrop then return end
            if not (c:IsA("Model") or c:IsA("BasePart")) then return end
            addLog(("🆕 Drops/%s!"):format(c.Name)); task.wait(0.3); if _G.StopAutoFarm or ST.busyDrop then return end
            task.spawn(handleDrop, c, classifyDrop(c))
        end))
    end
end)

-- ═══════════════════════════════════════════════════════════════
--  🌦️ WEATHER MISSION ENGINE
-- ═══════════════════════════════════════════════════════════════
local function slowWalkTo(targetPos)
    local h, r = hum(), hrp()
    if not h or not r then return end
    h.WalkSpeed = 20
    h:MoveTo(targetPos)
    local t0 = tick()
    while (r.Position - targetPos).Magnitude > 8 and tick() - t0 < 15 do
        task.wait(0.2)
        if not hrp() then break end
    end
    h.WalkSpeed = 16
    task.wait(0.5)
end

local weatherBlockedUntil = 0
local weatherMissStreak    = 0
local lastWeatherNotice    = 0

-- عنصر واجهة "ظاهر فعلاً" (الوجود وحده لا يعني أن الموجة نزلت)
-- ملاحظة مهمة: Visible للابن يبقى true حتى لو الأب مخفي — لازم نفحص كل الآباء
local function isGuiReallyShown(g)
    if not g then return false end
    if not g:IsA("GuiObject") then return false end
    if not g.Visible or g.AbsoluteSize.X <= 5 or g.AbsoluteSize.Y <= 5 then return false end
    local p = g.Parent
    while p and p:IsA("GuiObject") do
        if not p.Visible then return false end
        local ps = p.AbsoluteSize
        if ps.X <= 0 or ps.Y <= 0 then return false end
        p = p.Parent
    end
    if p and (p:IsA("ScreenGui") or p:IsA("BillboardGui")) and not p.Enabled then return false end
    return true
end

local function hasVisibleGuiInside(inst)
    if not inst then return false end
    for _, d in ipairs(inst:GetDescendants()) do
        if isGuiReallyShown(d) then return true end
    end
    return false
end

-- كلمات أي نظام طقس (مطر/عاصفة/ثلج/غبار…) — السكربت القديم كان يعرف WorldWeatherMissionHUD فقط
-- مهام الطقس ملغاة بالكامل: الكود محفوظ لكنه معطّل من هنا
local WEATHER_ENABLED = false
local WEATHER_WORDS = {"weather","rain","storm","snow","thunder","climate","forecast","droplet",
    "طقس","أجواء","اجواء","مطر","أمطار","امطار","عاصفة","عاصفه","رياح","ثلج","برد","سحاب","غيم"}

local function nameHasWeather(s)
    s = tostring(s or ""):lower()
    for _, w in ipairs(WEATHER_WORDS) do if s:find(w, 1, true) then return true end end
    return false
end

local weatherHudsCache, weatherHudsCacheAt = {}, 0
local function findWeatherHuds()
    if tick() - weatherHudsCacheAt < 0.7 then return weatherHudsCache end
    weatherHudsCacheAt = tick()
    local list = {}
    for _, g in ipairs(pg:GetChildren()) do
        if g:IsA("ScreenGui") and g.Enabled then
            local ok = nameHasWeather(g.Name)
            if not ok then
                for _, d in ipairs(g:GetDescendants()) do
                    if nameHasWeather(d.Name) then ok = true; break end
                end
            end
            if ok then list[#list+1] = g end
        end
    end
    weatherHudsCache = list
    return list
end

local function weatherCardOf(hud)
    if not hud then return nil end
    local direct = hud:FindFirstChild("MissionCard", true)
    if direct then return direct end
    for _, d in ipairs(hud:GetDescendants()) do
        local n = d.Name:lower()
        if (n:find("mission") or n:find("card") or n:find("panel") or n:find("window") or n:find("frame"))
            and (d:IsA("Frame") or d:IsA("ScrollingFrame") or d:IsA("CanvasGroup")) then
            return d
        end
    end
    return hud
end

local function isWeatherCardShown()
    for _, hud in ipairs(findWeatherHuds()) do
        local card = weatherCardOf(hud)
        if card then
            if card:IsA("GuiObject") then
                if isGuiReallyShown(card) then return true end
            elseif hasVisibleGuiInside(card) then return true end
        end
    end
    return false
end

local function getWeatherScene()
    local best = nil
    for _, s in ipairs(workspace:GetChildren()) do
        if nameHasWeather(s.Name) then
            if s:FindFirstChild("Step1") or s:FindFirstChildWhichIsA("ProximityPrompt", true) then return s end
            best = best or s
        end
    end
    return best
end

local function btnTextOf(btn)
    if not btn then return "" end
    local parts = {}
    if btn:IsA("TextButton") then parts[#parts+1] = btn.Text or "" end
    for _, d in ipairs(btn:GetDescendants()) do
        if d:IsA("TextLabel") or d:IsA("TextButton") then parts[#parts+1] = d.Text or "" end
    end
    return table.concat(parts, " ")
end

local function textHasAny(s, list)
    s = tostring(s or ""):lower()
    for _, w in ipairs(list) do if s:find(w:lower(), 1, true) then return true end end
    return false
end

local START_WORDS = {"ابدأ","ابدا","بدء","start","join","انضم","شارك","قبول","اقبل"}
local STOP_WORDS  = {"إيقاف","ايقاف","إلغاء","الغاء","stop","cancel","إزالة","ازالة","إنهاء","انهاء","退出"}

-- نص كارت أي مهمة طقس (كل العناوين الظاهرة فعلاً — بدون عناصر آباؤها مخفيين)
local function weatherCardText()
    local out = {}
    for _, hud in ipairs(findWeatherHuds()) do
        local card = weatherCardOf(hud)
        if card then
            for _, d in ipairs(card:GetDescendants()) do
                if (d:IsA("TextLabel") or d:IsA("TextButton")) and isGuiReallyShown(d) then
                    out[#out+1] = d.Text or ""
                end
            end
        end
    end
    return table.concat(out, " ")
end

local function hasDigit(s)
    for _, c in utf8.codes(tostring(s or "")) do
        if (c >= 48 and c <= 57) or (c >= 0x0660 and c <= 0x0669) or (c >= 0x06F0 and c <= 0x06F9) then
            return true
        end
    end
    return false
end

-- المهمة "شغالة" فقط عند وجود عدّاد حقيقي ظاهر (كلمة مهمة + رقم) أو زر إيقاف المهمة.
-- لو زر «ابدأ المهمة» ظاهر فعلاً فالمهمة لم تبدأ — مهما كانت النصوص الأخرى.
local ACTIVE_WORDS = {"الخطوة","خطوه","step","progress","الكمية","كمية","quantity","متبقي","المتبقي"}
-- أزرار "إيقاف المهمة" تحديداً (وليس أي زر فيه كلمة إزالة مثل «إزالة الميدالية»)
local HARD_STOP = {"إيقاف المهمة","ايقاف المهمة","إلغاء المهمة","الغاء المهمة","إنهاء المهمة","انهاء المهمة","stop mission","cancel mission"}
local function weatherMissionActive()
    local startShown, stopShown = false, false
    for _, hud in ipairs(findWeatherHuds()) do
        local card = weatherCardOf(hud)
        if card then
            for _, d in ipairs(card:GetDescendants()) do
                if (d:IsA("TextButton") or d:IsA("ImageButton")) and isGuiReallyShown(d) then
                    local txt = btnTextOf(d)
                    if textHasAny(txt, HARD_STOP) then stopShown = true end
                    if textHasAny(txt, START_WORDS) and not textHasAny(txt, STOP_WORDS) then startShown = true end
                end
            end
        end
    end
    if stopShown then return true end
    if startShown then return false end
    -- عدّاد خطوات/كمية ظاهر (كلمة + رقم) — بدون رقم لا نعتبرها شغالة
    local txt = weatherCardText()
    if hasDigit(txt) and textHasAny(txt, ACTIVE_WORDS) then return true end
    return false
end

-- بصمة كل واجهات الطقس: لا نشغّل المهمة إلا عند تغيّر حديث (إعلان جديد)
local lastWeatherSig, lastWeatherSigAt = "", 0
local function weatherHudSignature()
    local out = {}
    for _, hud in ipairs(findWeatherHuds()) do
        out[#out+1] = hud.Name
        for _, d in ipairs(hud:GetDescendants()) do
            if (d:IsA("TextLabel") or d:IsA("TextButton")) and isGuiReallyShown(d) then
                out[#out+1] = d.Text or ""
            end
        end
    end
    return table.concat(out, "|")
end

-- يفتح واجهة الطقس (كانت الأجواء فقط تُفتح) ويضغط بدء المهمة
local OPEN_WORDS = {"mini","open","expand","details","info","عرض","تفاصيل","فتح","تكبير"}
local function openWeatherHud(hud)
    if not hud then return false end
    for _, d in ipairs(hud:GetDescendants()) do
        if (d:IsA("TextButton") or d:IsA("ImageButton")) and isGuiReallyShown(d) then
            local n = (d.Name .. " " .. btnTextOf(d)):lower()
            if textHasAny(n, OPEN_WORDS) and not textHasAny(n, STOP_WORDS) then
                clickBtn(d); task.wait(0.35); return true
            end
        end
    end
    return false
end

-- واجهة مصغّرة (زر Mini ظاهر والكارت مخفي) — لازم نعتبرها ظهور واجهة ونفتحها
local function hasWeatherOpenBtn()
    for _, hud in ipairs(findWeatherHuds()) do
        for _, d in ipairs(hud:GetDescendants()) do
            if (d:IsA("TextButton") or d:IsA("ImageButton")) and isGuiReallyShown(d) then
                local n = (d.Name .. " " .. btnTextOf(d)):lower()
                if textHasAny(n, OPEN_WORDS) and not textHasAny(n, STOP_WORDS) then return true end
            end
        end
    end
    return false
end

-- زر «ابدأ المهمة» في العالم (ProximityPrompt أو ClickDetector + BillboardGui «مهمة الأجواء»)
local weatherGoTo -- تُعرَّف بعد قليل (مشي خاص بمهمة الأجواء)
local WS = {cache = nil, at = 0}

function WS.textOf(part, extra)
    local parts = {extra or "", part.Name}
    local function addBillboards(root)
        if not root then return end
        for _, bb in ipairs(root:GetDescendants()) do
            if bb:IsA("BillboardGui") then
                for _, t in ipairs(bb:GetDescendants()) do
                    if t:IsA("TextLabel") or t:IsA("TextButton") then parts[#parts+1] = t.Text or "" end
                end
            end
        end
    end
    addBillboards(part)
    local host = part.Parent
    if host and not host:IsA("Workspace") then
        parts[#parts+1] = host.Name
        addBillboards(host)
    end
    return table.concat(parts, " ")
end

function WS.find()
    if not WEATHER_ENABLED then WS.cache = nil; return nil end
    if tick() - WS.at < 0.7 then return WS.cache end
    WS.at = tick()
    local r = hrp()
    local best, bestD = nil, math.huge
    local sign, signPart, signD = nil, nil, math.huge
    local actions = {}
    for _, d in ipairs(workspace:GetDescendants()) do
        -- لوحات العرض «مهمة الأجواء / ابدأ المهمة» حتى لو ما كان فيها برومبت
        if d:IsA("BillboardGui") or d:IsA("SurfaceGui") then
            local txt = {}
            for _, t in ipairs(d:GetDescendants()) do
                if t:IsA("TextLabel") or t:IsA("TextButton") then txt[#txt+1] = t.Text or "" end
            end
            local s = table.concat(txt, " ")
            -- لوحة «خذ مهمة الأجواء» قد لا تحمل كلمة ابدأ في نفس اللوحة — نكتفي بمهمة+طقس
            local missionish = textHasAny(s, START_WORDS) or textHasAny(s, {"مهمة","mission","خذ","take","احصل","get"})
            if nameHasWeather(s) and missionish and not textHasAny(s, STOP_WORDS) then
                local part = d.Adornee
                if part and not part:IsA("BasePart") then part = part:FindFirstChildWhichIsA("BasePart", true) end
                if not part and d.Parent then
                    local pp = d.Parent
                    if pp:IsA("BasePart") then part = pp
                    elseif pp:IsA("Model") then part = pp.PrimaryPart or pp:FindFirstChildWhichIsA("BasePart", true)
                    else
                        local model = pp:FindFirstAncestorOfClass("Model")
                        part = model and (model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true))
                    end
                end
                if part then
                    local dist = r and (part.Position - r.Position).Magnitude or 0
                    if dist < signD then signD = dist; sign = d; signPart = part end
                elseif not sign then
                    -- لوحة بدون Adornee/موديل: نحتفظ بها كإشارة ونضغط أزرارها من الشاشة
                    sign = d; signPart = nil; signD = 0
                end
            end
        end
        -- أزرار التفاعل
        local part, kind = nil, nil
        if d:IsA("ProximityPrompt") and d.Enabled and d.Parent then
            if d.Parent:IsA("BasePart") then part = d.Parent
            elseif d.Parent:IsA("Attachment") and d.Parent.Parent and d.Parent.Parent:IsA("BasePart") then part = d.Parent.Parent end
            kind = "prompt"
        elseif d:IsA("ClickDetector") and d.Parent and d.Parent:IsA("BasePart") then
            part = d.Parent; kind = "click"
        end
        if part then
            local dist = r and (part.Position - r.Position).Magnitude or 0
            local a = {kind = kind, obj = d, part = part, dist = dist}
            actions[#actions+1] = a
            local extra = ""
            if kind == "prompt" then extra = (d.ActionText or "") .. " " .. (d.ObjectText or "") .. " " .. d.Name end
            local txt = WS.textOf(part, extra)
            local isStart = textHasAny(txt, START_WORDS) and not textHasAny(txt, STOP_WORDS)
            a.start = isStart
            -- الزر تابع لمجسم/موديل اسمه فيه طقس؟ (مثل WorldWeatherMission...)
            local underWeather = false
            local anc = part
            for _ = 1, 4 do
                if not anc then break end
                if nameHasWeather(anc.Name) then underWeather = true; break end
                anc = anc.Parent
            end
            if isStart and (underWeather or nameHasWeather(txt)) then
                if dist < bestD then bestD = dist; best = a end
            end
        end
    end

    local function nearestToSign(maxD)
        if not signPart then return nil end
        local pick, pd = nil, maxD
        for _, a in ipairs(actions) do
            local ds = (a.part.Position - signPart.Position).Magnitude
            if a.start and ds < pd then pd = ds; pick = a end
        end
        if pick then pick.signPart = signPart end
        return pick
    end

    if signPart then
        local near = nearestToSign(12)
        if near then WS.cache = near; return near end
        if not best then
            WS.cache = {kind = "sign", obj = sign, part = signPart, dist = signD}
            return WS.cache
        end
    elseif sign and not best then
        -- لوحة عرض بدون جزء فعلي: نضغط أزرارها من الواجهة مباشرة
        WS.cache = {kind = "sign", obj = sign, part = nil, dist = 0}
        return WS.cache
    end
    WS.cache = best
    return best
end

function WS.has()
    return WS.find() ~= nil
end

function WS.fire(e)
    if e.kind == "prompt" then
        triggerPromptInstantly(e.obj)
        return
    end
    if e.kind == "click" then
        pcall(function()
            if typeof(fireclickdetector) == "function" then fireclickdetector(e.obj) end
        end)
        pcall(function()
            local conns = getconnections and getconnections(e.obj.MouseClick)
            if conns then for _, c in ipairs(conns) do if c.Fire then c:Fire() end end end
        end)
        task.wait(0.4)
        return
    end
    -- علامة عرض بدون زر معروف: نضغط أزرارها ثم نقترب ونفعّل أي برومبت/كليك قريب
    local firedUi = false
    if e.obj and (e.obj:IsA("BillboardGui") or e.obj:IsA("SurfaceGui") or e.obj:IsA("ScreenGui")) then
        for _, b in ipairs(e.obj:GetDescendants()) do
            if (b:IsA("TextButton") or b:IsA("ImageButton")) and b.Visible then
                local bt = btnTextOf(b)
                if textHasAny(bt, START_WORDS) then
                    clickBtn(b)
                    firedUi = true
                    task.wait(0.25)
                end
            end
        end
    end
    local anchor = e.signPart or e.part
    if not anchor then
        if not firedUi then addLog("⚠️ لوحة مهمة الأجواء بدون جزء تفاعلي معروف") end
        task.wait(0.5)
        return
    end
    local r = hrp()
    if r and (anchor.Position - r.Position).Magnitude > 8 then
        addLog("🏃 التوجه لعلامة مهمة الأجواء...")
        weatherGoTo(anchor.Position, 15)
    end
    for _, entry in ipairs(getNearbyPrompts(18)) do
        local pt = (entry.prompt.ActionText or "") .. " " .. (entry.prompt.ObjectText or "") .. " " .. entry.prompt.Name
        if textHasAny(pt, START_WORDS) and not textHasAny(pt, STOP_WORDS) then
            triggerPromptInstantly(entry.prompt)
            task.wait(0.2)
        end
    end
    local function tiedToAnchor(part)
        if part == anchor or part:IsDescendantOf(anchor) or anchor:IsDescendantOf(part) then return true end
        local m1 = part:FindFirstAncestorOfClass("Model")
        local m2 = anchor:FindFirstAncestorOfClass("Model")
        return m1 ~= nil and m1 == m2
    end
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("ClickDetector") and d.Parent and d.Parent:IsA("BasePart") and tiedToAnchor(d.Parent) then
            pcall(function()
                if typeof(fireclickdetector) == "function" then fireclickdetector(d) end
            end)
            pcall(function()
                local conns = getconnections and getconnections(d.MouseClick)
                if conns then for _, c in ipairs(conns) do if c.Fire then c:Fire() end end end
            end)
        end
    end
    touchObj(anchor)
    task.wait(0.6)
end

function WS.trigger()
    local e = WS.find()
    if not e then return false end
    local label
    if e.kind == "prompt" then
        label = ((e.obj.ObjectText or "") ~= "" and e.obj.ObjectText) or e.obj.ActionText or e.obj.Name
    elseif e.part then
        label = e.part.Name
    else
        label = (e.obj and e.obj.Name) or "لوحة"
    end
    addLog(("🖱️ بدء مهمة طقس من زر العالم: %s"):format(tostring(label)))
    -- نضغط فوراً من أي مسافة (fireproximityprompt / fireclickdetector)
    WS.fire(e)
    task.wait(1.0)
    WS.at = 0
    if weatherMissionActive() then return true end
    if WS.has() then
        -- الزر لسا موجود: نقترب ونضغط مرة ثانية
        local r = hrp()
        if e.part and r and (e.part.Position - r.Position).Magnitude > 6 then
            addLog("🏃 التوجه لزر بدء مهمة الطقس...")
            weatherGoTo(e.part.Position, 12)
        end
        e = WS.find()
        if e then WS.fire(e) end
    end
    WS.at = 0
    return true
end

local function clickStartWeatherMission()
    if not WEATHER_ENABLED then return false end
    if weatherMissionActive() then return false end
    -- أولاً: زر بدء المهمة في العالم (هو الأساسي في مهمة الأجواء/الأمطار)
    if WS.trigger() then return true end
    for _, hud in ipairs(findWeatherHuds()) do
        local card = weatherCardOf(hud)
        -- لا نشغّل شي إذا كانت مهمة شغالة أصلاً (زر الإيقاف موجود)
        if card then
            local hasStop = false
            for _, d in ipairs(card:GetDescendants()) do
                if (d:IsA("TextButton") or d:IsA("ImageButton")) and isGuiReallyShown(d) and textHasAny(btnTextOf(d), HARD_STOP) then hasStop = true; break end
            end
            if not hasStop then
                -- إذا الكارت مقفّل/مصغّر نحاول نفتحه أولاً
                if not isGuiReallyShown(card) or (card:IsA("Frame") and card.AbsoluteSize.X < 50) then openWeatherHud(hud) end
                local candidates = {}
                for _, d in ipairs(card:GetDescendants()) do
                    if (d:IsA("TextButton") or d:IsA("ImageButton")) and isGuiReallyShown(d) and d.AbsoluteSize.X > 20 then candidates[#candidates+1] = d end
                end
                for _, d in ipairs(candidates) do
                    local txt = btnTextOf(d)
                    if textHasAny(txt, START_WORDS) and not textHasAny(txt, STOP_WORDS) then
                        addLog(("🖱️ بدء مهمة طقس: %s"):format(hud.Name))
                        clickBtn(d); task.wait(0.5); return true
                    end
                end
                local actionBtn = card:FindFirstChild("Action", true)
                if actionBtn and (actionBtn:IsA("TextButton") or actionBtn:IsA("ImageButton")) and isGuiReallyShown(actionBtn) then
                    local txt = btnTextOf(actionBtn)
                    if not textHasAny(txt, STOP_WORDS) then
                        addLog(("🖱️ زر إجراء الطقس: %s"):format(actionBtn.Name))
                        clickBtn(actionBtn); task.wait(0.5); return true
                    end
                end
            end
        end
    end
    return false
end

local weatherStarting = false

-- ★ مشي خاص بمهمة الأجواء (بدون مقاطعة WEATHER وبدون اختطاف)
function weatherGoTo(pos, maxT)
    maxT = maxT or 12
    if not ST.autoWeather then return false end
    local h, r = hum(), hrp()
    if not h or not r then return false end
    h.WalkSpeed = 20
    local t0 = tick(); local last = r.Position; local stuckT = 0
    while tick() - t0 < maxT and not _G.StopAutoFarm and ST.autoWeather do
        r, h = hrp(), hum(); if not r or not h then break end
        local flat = (r.Position - Vector3.new(pos.X, r.Position.Y, pos.Z)).Magnitude
        if flat < 4 then h.WalkSpeed = 16; return true end
        if pos.Y - r.Position.Y > 2 then h.Jump = true end
        h:MoveTo(pos)
        task.wait(0.08)
        if (r.Position - last).Magnitude < 0.2 then
            stuckT = stuckT + 0.08
            if stuckT > 0.4 then h.Jump = true end
            if stuckT > 1.6 then
                -- انحشار داخل مهمة الطقس: نقلة قريبة ونتابع بدل ما نستسلم
                if emergencyNudge(pos) then
                    last = (hrp() or r).Position; stuckT = 0
                else
                    break
                end
            end
        else stuckT = 0 end
        last = r.Position
    end
    local h2 = hum(); if h2 then h2.WalkSpeed = 16 end
    return false
end

-- ★ البحث عن صناديق الإمدادات
local SUPPLY_WORDS = {"امداد","إمداد","الامدادات","الإمدادات","صندوق","صناديق","supply","supplies","crate","box","loot"}
local lastSupplyScan, supplyScanCache = 0, {}
local usedSupplies = {}

local function scanSupplies()
    local r = hrp(); if not r then return {} end
    if tick() - lastSupplyScan < 1.2 then return supplyScanCache end
    lastSupplyScan = tick()
    local list = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            local par = obj.Parent
            local pp = nil
            if par then
                if par:IsA("BasePart") then pp = par
                elseif par:IsA("Model") then pp = par.PrimaryPart or par:FindFirstChildWhichIsA("BasePart", true) end
            end
            if pp then
                local dist = (pp.Position - r.Position).Magnitude
                if dist < 140 then
                    local txt = (obj.ActionText or "") .. " " .. (obj.ObjectText or "") .. " " .. obj.Name .. " " .. (par and par.Name or "")
                    local ok = textHasAny(txt, SUPPLY_WORDS)
                    if not ok then
                        local host = (par and par:IsA("Model")) and par or pp
                        for _, d in ipairs(host:GetDescendants()) do
                            if d:IsA("BillboardGui") then
                                for _, t in ipairs(d:GetDescendants()) do
                                    if t:IsA("TextLabel") and textHasAny(t.Text, SUPPLY_WORDS) then ok = true; break end
                                end
                            end
                            if ok then break end
                        end
                    end
                    if ok then list[#list+1] = {prompt = obj, part = pp, dist = dist} end
                end
            end
        end
    end
    table.sort(list, function(a, b) return a.dist < b.dist end)
    supplyScanCache = list
    return list
end

local function handleSupplyMission(force)
    if not WEATHER_ENABLED then return end
    addLog("📦 مهمة الأجواء: جمع الإمدادات")
    setStatus("جمع الإمدادات...", Color3.fromRGB(255, 200, 100))
    local t0 = tick()
    local opened = 0
    local idle = 0
    -- سقف قصير: ممنوع تقفيل نظام المهام أكثر من 40 ثانية
    while tick() - t0 < 40 and not _G.StopAutoFarm and ST.autoWeather do
        if not force and not weatherMissionActive() then break end
        local list = scanSupplies()
        local target = nil
        local now = tick()
        for _, e in ipairs(list) do
            local lastUse = usedSupplies[e.prompt]
            if not lastUse or now - lastUse > 20 then target = e; break end
        end
        if not target then
            idle = idle + 1
            if idle % 8 == 1 then addLog("⏳ ننتظر صندوق إمدادات جديد...") end
            task.wait(0.8)
        else
            idle = 0
            local r = hrp()
            if r and (target.part.Position - r.Position).Magnitude > 6 then
                weatherGoTo(target.part.Position, 12)
            end
            r = hrp()
            local reach = (target.prompt.MaxActivationDistance or 10) + 2
            if r and (target.part.Position - r.Position).Magnitude > reach then
                usedSupplies[target.prompt] = tick()
                addLog("⚠️ صندوق الإمدادات ما انوصل له — نجرّب غيره")
                task.wait(0.5)
            else
                usedSupplies[target.prompt] = tick()
                triggerPromptInstantly(target.prompt)
                opened = opened + 1
                addLog(("📦 فتحنا صندوق إمدادات (%d)"):format(opened))
                task.wait(0.7)
            end
        end
        if opened >= 6 then break end
    end
    ST.weatherSelf = false
    if not ST.autoWeather then
        addLog("⏹️ تم إيقاف جمع الإمدادات")
        setStatus("خامل", Color3.fromRGB(120, 255, 200))
        return
    end
    addLog("✅ خلصنا جمع الإمدادات")
    setStatus("خامل", Color3.fromRGB(120, 255, 200))
end

-- أهداف أي مهمة طقس: أي Step/فرع فيه برومبت (كان يقرأ Step1..6 فقط)
local function collectWeatherTargets(scene)
    local list = {}
    if not scene then return list end
    for _, st in ipairs(scene:GetChildren()) do
        local pr = st:FindFirstChildWhichIsA("ProximityPrompt", true)
        if pr and pr.Enabled then
            local root = st:FindFirstChild("MissionRoot") or st
            local part = nil
            if root:IsA("BasePart") then part = root
            elseif root:IsA("Model") then part = root.PrimaryPart or root:FindFirstChildWhichIsA("BasePart", true)
            else
                local pp = pr.Parent
                part = (pp and pp:IsA("BasePart")) and pp or (pp and pp:FindFirstChildWhichIsA("BasePart", true))
            end
            if part then list[#list+1] = { step = st, root = part, prompt = pr } end
        end
    end
    if #list == 0 then
        for _, pr in ipairs(scene:GetDescendants()) do
            if pr:IsA("ProximityPrompt") and pr.Enabled then
                local pp = pr.Parent
                local part = (pp and pp:IsA("BasePart")) and pp or (pp and pp:FindFirstChildWhichIsA("BasePart", true))
                if part then list[#list+1] = { step = part.Parent or part, root = part, prompt = pr } end
            end
        end
    end
    return list
end

-- تنفيذ خطوات أي مهمة طقس (أمطار/عواصف/إمدادات) — يتعامل مع أي اسم Step
local function runWeatherSteps(scene)
    weatherMissStreak = 0
    ST.inProgress = false; ST.progressStart = nil
    setStatus("مهام الطقس...", Color3.fromRGB(255, 150, 0))
    addLog("✅ مهمة طقس شغالة — تنفيذ الأهداف")
    scene = scene or getWeatherScene()
    local usedPos, usedAt = {}, {}
    local opened = 0
    local t0 = tick()
    local lastProgress = tick()
    -- سقف 40 ثانية: لو ما فيه تقدّم نرجع للمهام العادية فوراً
    while tick() - t0 < 40 and not _G.StopAutoFarm and ST.autoWeather do
        if not scene or not scene.Parent then scene = getWeatherScene() end
        if not scene then break end
        local pick
        for _, t in ipairs(collectWeatherTargets(scene)) do
            local lastPos = usedPos[t.prompt]
            local moved = lastPos and (lastPos - t.root.Position).Magnitude > 5
            local stale = (tick() - (usedAt[t.prompt] or 0)) > 12
            if not lastPos or moved or stale then pick = t; break end
        end
        if not pick then
            -- كل الأهداف الحالية انفتحت: ننتظر هدف جديد أو نهاية المهمة
            if not weatherMissionActive() or tick() - lastProgress > 10 then break end
            task.wait(0.6)
        else
            lastProgress = tick()
            addLog(("🏃 التوجه لهدف %s (سرعة 20)..."):format(tostring(pick.step.Name)))
            weatherGoTo(pick.root.Position, 14)
            local r = hrp()
            local reach = (pick.prompt.MaxActivationDistance or 10) + 2
            usedPos[pick.prompt] = pick.root.Position
            usedAt[pick.prompt] = tick()
            if r and (pick.root.Position - r.Position).Magnitude <= reach then
                addLog("🎯 تنفيذ الهدف...")
                triggerPromptInstantly(pick.prompt)
                opened = opened + 1
                task.wait(1.0)
            else
                addLog("⚠️ ما وصلنا للهدف — نجرب هدف ثاني")
                task.wait(0.4)
            end
        end
    end
    if not ST.autoWeather then
        addLog("⏹️ تم إيقاف مهمة الطقس")
        setStatus("خامل", Color3.fromRGB(120,255,200))
        return
    end
    addLog(("✅ خلصنا مهمة الطقس — نفذنا %d هدف"):format(opened))
    setStatus("خامل", Color3.fromRGB(120,255,200)); task.wait(2)
end

local function runWeatherByType(scene, force)
    if not WEATHER_ENABLED then return end
    -- لا نجمّد بقية الأنظمة إلا إذا كانت مهمة الطقس شغالة فعلاً (بدون لوج مزعج)
    if not force and not weatherMissionActive() then
        weatherStarting = false
        return
    end
    ST.busyWeather = true; ST.busyWeatherSince = tick()
    scene = scene or getWeatherScene()
    local hasPrompts = scene and scene:FindFirstChildWhichIsA("ProximityPrompt", true) ~= nil
    local ok, err
    if hasPrompts then ok, err = pcall(runWeatherSteps, scene)
    else ok, err = pcall(handleSupplyMission, force) end
    ST.busyWeather = false; ST.busyWeatherSince = nil
    ST.weatherSelf = false
    weatherStarting = false
    if not ok then addLog("❌ خطأ بمهمة الطقس: " .. tostring(err)) end
end

-- الإعلان قد يظهر والموجة ما نزلت: نجرّب التشغيل في الخلفية
-- بدون لمس busyWeather (حتى لا يتوقف الأوتوفارم)
local function handleWeatherMission()
    if not WEATHER_ENABLED then weatherStarting = false; return end
    -- المهمة شغالة أصلاً؟ نجمع الإمدادات مباشرة
    if weatherMissionActive() then
        addLog("📦 مهمة الأجواء شغالة — نجمع الإمدادات")
        runWeatherByType(nil)
        return
    end

    addLog("🌦️ محاولة بدء مهمة الطقس...")

    local worldBefore = WS.has()
    local clicked = false
    local t0 = tick()
    while tick() - t0 < 6 and not _G.StopAutoFarm and ST.autoWeather do
        if clickStartWeatherMission() then clicked = true; break end
        task.wait(0.5)
    end
    if not ST.autoWeather then weatherStarting = false; return end

    -- ننتظر بدء المهمة فعلياً. ⚠️ WeatherMissionScene موجود دائماً بالخريطة
    -- فوجوده وحده لا يعني أن المهمة شغالة — نعتمد على نص الكارت/زر الإيقاف
    t0 = tick()
    local lastClick = tick()
    while tick() - t0 < 9 and not _G.StopAutoFarm and ST.autoWeather do
        if weatherMissionActive() then
            local scene = getWeatherScene()
            addLog("📦 مهمة الأجواء بدأت — جمع الإمدادات")
            runWeatherByType(scene)
            return
        end
        -- زر/لوحة العالم اختفت بعد الضغط؟ اعتبرها بدأت حتى لو تأخرت واجهة المهمة
        if clicked and worldBefore and not WS.has() and tick() - t0 > 2.5 then
            local scene = getWeatherScene()
            addLog("📦 مهمة الأجواء بدأت (اختفت لوحة البدء)")
            runWeatherByType(scene, true)
            return
        end
        if tick() - lastClick > 5 and isWeatherCardShown() then
            lastClick = tick()
            clickStartWeatherMission()
        end
        task.wait(0.5)
    end

    if not ST.autoWeather then weatherStarting = false; return end
    weatherMissStreak = weatherMissStreak + 1
    -- تصعيد تدريجي: لو اللوحة موجودة دائماً بدون مهمة فعلية، ما نخنق المهمة العادية
    local block
    if weatherMissStreak >= 5 then block = 300
    elseif weatherMissStreak >= 3 then block = 120
    else block = math.min(15 * weatherMissStreak, 45) end
    weatherBlockedUntil = tick() + block
    addLog(("⚠️ ما بدأت مهمة طقس فعلية — نعيد المحاولة بعد %dث"):format(block))
    weatherStarting = false
    setStatus("خامل", Color3.fromRGB(120,255,200))
end

task.spawn(function()
    if not WEATHER_ENABLED then return end
    while not _G.StopAutoFarm do
        task.wait(1)
        -- تحديث بصمة الكارت: الإعلان الجديد فقط يسمح بمحاولة تشغيل
        local sig = weatherHudSignature()
        if sig ~= lastWeatherSig then lastWeatherSig = sig; lastWeatherSigAt = tick() end
        -- لا نبدأ الطقس وإحنا شايلين صندوق (يخرب التسليم) — ننتظر التسليم فقط
        local carrying = hasCrate()
        if ST.autoWeather and carrying and not ST.busyWeather and not weatherStarting
            and tick() - lastWeatherNotice > 30 then
            if WS.has() or weatherMissionActive() then
                lastWeatherNotice = tick()
                addLog("🌦️ مهمة أجواء متاحة — بانتظار تسليم الحقيبة الحالية")
            end
        end
        if ST.autoWeather and not ST.busyWeather and not ST.busyDrop and not ST.handlingDrop and not ST.busyCyber and not weatherStarting and not carrying then
            local active     = weatherMissionActive()
            local worldStart = WS.has()
            local fresh      = (tick() - lastWeatherSigAt) < 10
            local cardShown  = (isWeatherCardShown() or hasWeatherOpenBtn()) and fresh
            -- مهمة شغالة أو لوحة «ابدأ المهمة» في العالم؟ الطقس له أولوية على المهمة العادية
            if active or (worldStart and tick() >= weatherBlockedUntil) or (cardShown and tick() >= weatherBlockedUntil) then
                if tick() - lastWeatherNotice > 30 then
                    lastWeatherNotice = tick()
                    addLog(active and "🌦️ مهمة أجواء شغالة!" or "📣 مهمة أجواء متاحة — نبدأها الآن")
                end
                -- أولوية الطقس: نوقف مسار المهمة العادية قبل ما نبدأ (بدون حقيبة باليد)
                if ST.inProgress then
                    ST.inProgress = false; ST.progressStart = nil
                    addLog("⏸️ إيقاف المهمة العادية مؤقتاً لأجل مهمة الأجواء")
                end
                weatherStarting = true
                task.spawn(function()
                    local ok, err = pcall(handleWeatherMission)
                    if not ok then
                        weatherStarting = false
                        ST.busyWeather = false; ST.busyWeatherSince = nil
                        addLog("❌ خطأ بمهمة الطقس: " .. tostring(err))
                    end
                end)
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
--  🎁 AUTO CLAIM PLAYTIME REWARDS
-- ═══════════════════════════════════════════════════════════════
local lastNoReward = 0
local function claimPlaytimeRewards(force)
    if not force and not ST.autoPlaytime then return end
    if not force and tick() - ST.lastPlaytimeClaim < 60 then return end
    ST.lastPlaytimeClaim = tick()

    local mainUi = pg:FindFirstChild("MainUi")
    if not mainUi then if force then addLog("⚠️ MainUi غير موجود") end return end

    local quests = mainUi:FindFirstChild("Quests")
    local frame = quests and quests:FindFirstChild("Frame")
    if not frame then if force then addLog("⚠️ Quests/Frame غير موجود") end return end

    local innerFrame = frame:FindFirstChild("Frame")
    local playTimeTab = innerFrame and innerFrame:FindFirstChild("PlayTime")
    if not playTimeTab then if force then addLog("⚠️ تبويب PlayTime غير موجود") end return end

    local tabBtn = playTimeTab:FindFirstChild("TextButton")
    if tabBtn then clickBtn(tabBtn); task.wait(0.3) end

    local scroller = playTimeTab:FindFirstChild("ScrollingFrame")
    if not scroller then if force then addLog("⚠️ ScrollingFrame غير موجود") end return end

    local claimed = 0
    for _, child in ipairs(scroller:GetChildren()) do
        local applyFolder = child:FindFirstChild("Apply")
        if applyFolder then
            local btn = applyFolder:FindFirstChild("TextButton")
            if btn and btn.Visible then
                addLog("🎁 استلام جائزة وقت اللعب...")
                clickBtn(btn)
                claimed = claimed + 1
                task.wait(0.5)
            end
        end
    end
    if claimed > 0 then addLog(("🎁 تم استلام %d جائزة"):format(claimed))
    elseif tick() - lastNoReward > 120 then
        lastNoReward = tick()
        addLog("⏳ لا توجد جوائز وقت لعب جاهزة حالياً.")
    end
end

local function claimRewardsManually()
    task.spawn(function()
        local ok, err = pcall(claimPlaytimeRewards, true)
        if not ok then addLog("❌ خطأ بالاستلام: " .. tostring(err)) end
    end)
end

task.spawn(function()
    while not _G.StopAutoFarm do
        task.wait(10)
        if ST.autoPlaytime then
            pcall(claimPlaytimeRewards)
        end
    end
end)

-- ═══ WALK ENGINE ═══
-- ملاحظة: ممنوع الاختطاف الفجائي (PivotTo) أثناء المشي — يلغي المهمة ويسبب رجّعة مطاطية
-- إنقاذ الطوارئ: نقلة قصيرة (4-8 متر) لمكان قريب فاضي — نفس فكرة السكربت القديم
local function isSpotFree(pos)
    local ok, free = pcall(function()
        local op = OverlapParams.new()
        op.FilterType = Enum.RaycastFilterType.Exclude
        if pl.Character then op.FilterDescendantsInstances = {pl.Character} end
        local parts = workspace:GetPartBoundsInBox(CFrame.new(pos + Vector3.new(0, 1.6, 0)), Vector3.new(2.2, 3.4, 2.2), op)
        for _, p in ipairs(parts) do
            if p.CanCollide then return false end
        end
        return true
    end)
    return ok and free
end

local function findNearbySpot(fromPos, dest)
    local dirs = {}
    local function addDir(v)
        v = Vector3.new(v.X, 0, v.Z)
        if v.Magnitude > 0.1 then dirs[#dirs + 1] = v.Unit end
    end
    local function rot(v, deg)
        local a = math.rad(deg)
        local c, s = math.cos(a), math.sin(a)
        return Vector3.new(v.X * c - v.Z * s, 0, v.X * s + v.Z * c)
    end
    if dest then
        local bd = Vector3.new(dest.X - fromPos.X, 0, dest.Z - fromPos.Z)
        if bd.Magnitude > 0.1 then
            bd = bd.Unit
            addDir(bd)
            -- زوايا مايلة: تلفّ حول السياج/الزاوية بدل ما تصطدم فيه مباشرة
            for _, ang in ipairs({35, -35, 70, -70, 105, -105}) do addDir(rot(bd, ang)) end
        end
    end
    local lv = workspace.CurrentCamera and workspace.CurrentCamera.CFrame.LookVector or Vector3.new(0, 0, -1)
    addDir(lv)
    addDir(Vector3.new(-lv.Z, 0, lv.X))
    addDir(Vector3.new(lv.Z, 0, -lv.X))
    addDir(Vector3.new(-lv.X, 0, -lv.Z))
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    if pl.Character then rp.FilterDescendantsInstances = {pl.Character} end
    for _, dist in ipairs({5, 8, 12, 16, 22}) do
        for _, dir in ipairs(dirs) do
            local base = fromPos + dir * dist
            local hit = workspace:Raycast(base + Vector3.new(0, 10, 0), Vector3.new(0, -30, 0), rp)
            if hit then
                local spot = hit.Position + Vector3.new(0, 3, 0)
                if isSpotFree(spot) then return spot end
            end
        end
    end
    return nil
end

local function emergencyNudge(dest)
    if not ST.emergencyTpOn then return false end
    if tick() - (ST.lastEmergencyTp or 0) < 1.0 then return false end
    local r, h = hrp(), hum()
    if not r or not h or h.Health <= 0 then return false end
    -- تعليق متكرر؟ نوقف القفزات العشوائية وننتقل مباشرة لهدف المرحلة
    if tick() - (ST.lastEmergencyTp or 0) > 6 then ST.stuckStrikes = 0 end
    local goal = dest or ST.goalPos
    if goal and flatDist(r.Position, goal) < 2 then return false end
    local spot = nil
    if (ST.stuckStrikes or 0) < 2 then spot = findNearbySpot(r.Position, goal) end
    if not spot and goal then
        local g = groundOf(goal)
        if isSpotFree(g + Vector3.new(0, 1.6, 0)) then spot = g end
    end
    if not spot and goal then
        -- آخر حل: انتقال مباشر للهدف مهما كان (مطلوب صراحةً)
        spot = groundOf(goal)
    end
    if not spot then
        if tick() - (ST.lastEmergencyLog or 0) > 8 then
            ST.lastEmergencyLog = tick()
            addLog("⚠️ الانتقال التلقائي: ما فيه هدف محدد ولا مكان قريب")
        end
        return false
    end
    local before = r.Position
    ST.lastEmergencyTp = tick()
    ST.stuckStrikes = (ST.stuckStrikes or 0) + 1
    local ok = pcall(function()
        r.CFrame = CFrame.new(spot) * (r.CFrame - r.CFrame.Position)
        r.AssemblyLinearVelocity = Vector3.zero
        h.Jump = true
    end)
    task.wait(0.25)
    local r2 = hrp()
    local moved = (r2 and flatDist(before, r2.Position)) or 0
    if ok and moved >= 1 then
        if tick() - (ST.lastEmergencyLog or 0) > 2 then
            ST.lastEmergencyLog = tick()
            addLog(("🚑 انتقال تلقائي — تعليق 1.5 ثانية (%.0f متر)"):format(moved))
        end
        return true
    end
    if tick() - (ST.lastEmergencyLog or 0) > 4 then
        ST.lastEmergencyLog = tick()
        addLog("⚠️ الانتقال التلقائي ما نجح — نجرّب اتجاه ثاني")
    end
    return false
end

local function walkCore(dest, maxT, isDrop, owner)
    maxT = maxT or 20; local r, h = hrp(), hum()
    if not r or not h or not alive() then return false end
    local tgt = groundOf(dest); local stopD = 2.0
    h.WalkSpeed = ST.customSpeedOn and ST.walkSpeed or 16

    local path = PS:CreatePath({AgentRadius=1.5, AgentHeight=5, AgentCanJump=true, WaypointSpacing=3.5})
    local wpts = nil
    local function buildPath()
        r = hrp() or r
        local ok = pcall(function() path:ComputeAsync(r.Position, tgt) end)
        if ok and path.Status == Enum.PathStatus.Success then
            wpts = path:GetWaypoints(); return true
        end
        wpts = nil; return false
    end

    local function intr()
        if _G.StopAutoFarm then return "STOP" end
        if owner == "mission" and not ST.autoMission then return "OFF" end
        if owner == "drop" and not ST.autoDrop then return "OFF" end
        if owner == "weather" and not ST.autoWeather then return "OFF" end
        if owner == "cyber" and not ST.autoCyber then return "OFF" end
        if ST.busyCyber then return "CYBER" end
        if WEATHER_ENABLED and (ST.busyWeather or weatherStarting) then return "WEATHER" end
        if not isDrop and ST.autoDrop and not ST.busyDrop and findActiveDrop() then return "DROP" end
        return nil
    end

    local function reached() return flatDist(r.Position, tgt) <= stopD end

    -- انتقال فوري بعد 1.5 ثانية تعليق: مكان قريب فاضي أو نقطة المسار الحالية
    local nudges = 0
    local idx = 2
    local function tryNudge()
        if nudges >= 6 then return "GIVEUP" end
        local aim = (wpts and wpts[idx] and wpts[idx].Position) or tgt
        if emergencyNudge(aim) then nudges = nudges + 1; return true end
        return false
    end

    local t0 = tick()
    local lastPos = r.Position
    local stuckT = 0
    local repaths = 0
    local lastDetour = 0
    -- تفادي ذكي: نفحص 7 اتجاهات حول العائق ونختار الأقرب للهدف
    local function freeDirSpot(rad)
        local bd = Vector3.new(tgt.X - r.Position.X, 0, tgt.Z - r.Position.Z)
        if bd.Magnitude < 0.1 then return nil end
        bd = bd.Unit
        local bestSpot, bestD = nil, math.huge
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        if pl.Character then rp.FilterDescendantsInstances = {pl.Character} end
        for _, ang in ipairs({45, -45, 90, -90, 135, -135, 180}) do
            local a = math.rad(ang)
            local dir = Vector3.new(bd.X * math.cos(a) - bd.Z * math.sin(a), 0, bd.X * math.sin(a) + bd.Z * math.cos(a))
            local probe = r.Position + dir * rad
            local hit = workspace:Raycast(probe + Vector3.new(0, 8, 0), Vector3.new(0, -20, 0), rp)
            if hit then
                local spot = hit.Position + Vector3.new(0, 3, 0)
                if isSpotFree(spot) then
                    local remain = (Vector3.new(tgt.X - spot.X, 0, tgt.Z - spot.Z)).Magnitude
                    if remain < bestD then bestD = remain; bestSpot = spot end
                end
            end
        end
        return bestSpot
    end
    buildPath()

    while tick() - t0 < maxT do
        local it = intr(); if it then return it end
        r, h = hrp(), hum(); if not r or not h or not alive() then return false end
        if reached() then return true end

        if not wpts or #wpts < 2 then
            -- مسار مباشر (ما فيه نقاط): نمشي للهدف وننط لو فيه ارتفاع
            if tgt.Y - r.Position.Y > 2 then h.Jump = true end
            h:MoveTo(tgt)
            task.wait(0.06)
            if (r.Position - lastPos).Magnitude < 0.2 then
                stuckT = stuckT + 0.06
                if stuckT > 0.3 then h.Jump = true end
                if stuckT > 0.7 and tick() - lastDetour > 1.2 then
                    lastDetour = tick()
                    local ds = freeDirSpot(6)
                    if ds then h:MoveTo(ds); task.wait(0.25) end
                end
                if stuckT > 1.5 then
                    stuckT = 0
                    local nr = tryNudge()
                    if nr == "GIVEUP" then return false end
                    if nr then
                        repaths = 0
                        r, h = hrp(), hum()
                        lastPos = r and r.Position or lastPos
                        buildPath(); idx = 2
                        continue
                    end
                    -- ما قدرنا ننتقل: خطوة جانبية ذكية ثم إعادة مسار
                    repaths = repaths + 1
                    local rv = r.CFrame.RightVector
                    local sign = (repaths % 2 == 0) and 1 or -1
                    h:MoveTo(groundOf(r.Position + Vector3.new(rv.X, 0, rv.Z) * (6 * sign)))
                    task.wait(0.45)
                    if not buildPath() then wpts = nil end
                    idx = 2
                end
            else stuckT = 0 end
            lastPos = r.Position
            continue
        end

        if idx > #wpts then
            repaths = repaths + 1
            if not buildPath() then
                -- ما فيه مسار: نمشي مباشرة ونعتمد على خطوات الالتفاف
                wpts = nil; idx = 2; repaths = 0
                task.wait(0.1)
                continue
            end
            if repaths > 3 then repaths = 0 end
            idx = 2
            task.wait(0.05)
            continue
        end

        local wp = wpts[idx]
        ST.walkDest = wp.Position
        if wp.Action == Enum.PathWaypointAction.Jump then h.Jump = true end
        -- منحدر/ارتفاع: ننط قبل ما نوصل عشان ما نلصق بالجدار
        if wp.Position.Y - r.Position.Y > 2 then h.Jump = true end
        h:MoveTo(wp.Position)

        local ws = tick()
        local stuckHere = false
        while tick() - ws < 2.5 and tick() - t0 < maxT do
            task.wait(0.04)
            local it2 = intr(); if it2 then return it2 end
            r, h = hrp(), hum(); if not r or not h or not alive() then return false end
            if reached() then return true end
            if flatDist(Vector3.new(r.Position.X, 0, r.Position.Z), Vector3.new(wp.Position.X, 0, wp.Position.Z)) < 3 then break end
            if (r.Position - lastPos).Magnitude < 0.2 then
                stuckT = stuckT + 0.04
                if stuckT > 0.3 then h.Jump = true end
                if stuckT > 0.7 and tick() - lastDetour > 1.2 then
                    lastDetour = tick()
                    local ds = freeDirSpot(6)
                    if ds then h:MoveTo(ds); task.wait(0.2) end
                end
                if stuckT > 1.5 then stuckT = 0; stuckHere = true; break end
            else stuckT = 0 end
            lastPos = r.Position
        end

        if stuckHere then
            -- تعليق 1.5 ثانية: انتقال فوري أولاً، وبعدها خطوة جانبية وإعادة مسار
            pcall(function() r.AssemblyLinearVelocity = Vector3.zero end)
            h.Jump = true
            task.wait(0.15)
            local nr = tryNudge()
            if nr == "GIVEUP" then return false end
            if nr then
                repaths = 0; idx = 2
                r, h = hrp(), hum()
                lastPos = r and r.Position or lastPos
                buildPath()
                continue
            end
            repaths = repaths + 1
            local rv = r.CFrame.RightVector
            local sign = (repaths % 2 == 0) and 1 or -1
            h:MoveTo(groundOf(r.Position + Vector3.new(rv.X, 0, rv.Z) * (5 * sign)))
            task.wait(0.4)
            if not buildPath() then
                wpts = nil; repaths = 0
            end
            idx = 2
        else
            idx = idx + 1
        end
    end
    return reached()
end

local function walk(dest, maxT, isDrop, owner)
    ST.walking = true
    ST.walkDest = dest
    local ok, res = pcall(walkCore, dest, maxT, isDrop, owner)
    ST.walking = false
    ST.walkDest = nil
    if not ok then
        if tick() - (ST.lastEmergencyLog or 0) > 5 then
            ST.lastEmergencyLog = tick()
            addLog("⚠️ خطأ بالمشي: " .. tostring(res))
        end
        return false
    end
    return res
end

local function handleWalkInterrupt(res)
    if res == "DROP" then
        local d, k = findActiveDrop()
        if d and not ST.busyDrop then addLog("⚡ مقاطعة: دروب!"); ST.inProgress = false; task.spawn(handleDrop, d, k) end
        return true
    end
    if res == "WEATHER" then return true end
    if res == "STOP" or res == "CYBER" or res == "OFF" then return true end
    return false
end

-- مراقب التعليق العام: لو اللاعب ثابت 1.5 ثانية أثناء مشي/مهمة/دروب → انتقال فوري
task.spawn(function()
    local lastPos, lastMoveAt = nil, tick()
    while not _G.StopAutoFarm do
        task.wait(0.25)
        local r = hrp()
        local h = hum()
        local busy = ST.walking or ST.inProgress or ST.busyWeather or ST.busyCyber or ST.busyDrop
        -- أثناء المشي أو مراحل المهمة نتحقق دائماً
        local trying = ST.walking or ST.inProgress or (h and h.MoveDirection.Magnitude > 0.1)
        if r and alive() and busy and trying then
            if not lastPos or (r.Position - lastPos).Magnitude > 0.6 then
                lastPos = r.Position; lastMoveAt = tick()
            elseif tick() - lastMoveAt >= 1.5 then
                if emergencyNudge(ST.walkDest or ST.goalPos) then
                    lastMoveAt = tick(); lastPos = (hrp() or r).Position
                end
            end
        else
            lastPos = r and r.Position or nil; lastMoveAt = tick()
        end
    end
end)

local function grabCyberLoot()
    local r = hrp(); if not r then return end
    for _, p in ipairs(workspace:GetDescendants()) do
        if p:IsA("BasePart") and (p.Position - r.Position).Magnitude < 14 then
            local pn = p.Name:lower()
            if pn:find("handle") or pn:find("lever") or pn:find("مقبض") or pn:find("cyber") or pn:find("switch") or pn:find("point") or pn:find("coin") then touchObj(p) end
        elseif p:IsA("ProximityPrompt") and p.Enabled and p.Parent and p.Parent:IsA("BasePart") then
            local pp = p.Parent
            if (pp.Position - r.Position).Magnitude < 14 then triggerPromptInstantly(p) end
        end
    end
end

-- ريستارت اللاعب بعد 50 نقطة: نقتله وننتظر الريسباون الحقيقي قبل أي حركة
-- (القفز بالـCFrame وقت الريسباون هو سبب «المطاطية» وتعليق المهمة)
local function cyberResetForPoints()
    addLog("🔄 ريستارت اللاعب بعد 50 نقطة (لتثبيت النقاط)...")
    setStatus("ريستارت النقاط...", Color3.fromRGB(255, 180, 80))
    ST.inProgress = false; ST.progressStart = nil
    ST.forceReset = true
    local oldChar = char()
    local t0 = tick()
    while tick() - t0 < 3 do
        local h = hum()
        if not h or h.Health <= 0 then break end
        pcall(function() h.Health = 0 end)
        task.wait(0.3)
        h = hum()
        if h and h.Health > 0 then pcall(function() if oldChar and oldChar.Parent then oldChar:BreakJoints() end end) end
        task.wait(0.2)
    end
    -- ننتظر الريسباون الفعلي (شخصية جديدة + صحة > 0)
    t0 = tick()
    while tick() - t0 < 15 do
        task.wait(0.3)
        local c = char()
        local nh = hum()
        if c and c ~= oldChar and nh and nh.Health > 0 and hrp() then break end
    end
    task.wait(1.5)
    ST.forceReset = false
    ST.lastSafePos = nil
    ST.inProgress = false; ST.progressStart = nil
    ST.missionOn = false; ST.target = nil; ST.isPickup = true
    addLog("✅ رجع اللاعب بعد الريستارت")
    setStatus("خامل", Color3.fromRGB(120,255,200))
end

local function lootCyberCave(force)
    if _G.StopAutoFarm then return end
    if ST.busyCyber then return end
    if not force and tick() - ST.lastCyberLoot < CFG.CYBER_COOLDOWN then
        addLog(("⏳ الكهف في كولداون (%d ث)"):format(math.ceil(CFG.CYBER_COOLDOWN - (tick() - ST.lastCyberLoot))))
        return
    end

    -- لا نقاطع دروب قيد التنفيذ: ننتظره قليلاً ثم نقرر
    local w0 = tick()
    while ST.busyDrop and tick() - w0 < 10 do task.wait(0.3) end
    if ST.busyDrop or _G.StopAutoFarm then addLog("⚠️ تم إلغاء الكهف (دروب قيد التنفيذ)"); return end

    -- ولا نختطف مهمة الصندوق أو الأجواء (الانتقال الفجائي يلغي المهمة)
    if ST.busyWeather then addLog("⚠️ تم تأجيل الكهف (مهمة الأجواء شغالة)"); return end
    local wm = tick()
    while (ST.inProgress or hasCrate()) and tick() - wm < 25 and ST.autoCyber do task.wait(0.5) end
    if not ST.autoCyber then return end
    if ST.inProgress or hasCrate() or _G.StopAutoFarm then addLog("⚠️ تم تأجيل الكهف (مهمة شغالة)"); return end

    ST.busyCyber = true; ST.busyCyberSince = tick(); ST.lastCyberLoot = tick()
    ST.inProgress = false; ST.progressStart = nil
    addLog("🌐 الباب انفتح! انتقال فوري لكهف السيبراني...")
    setStatus("كهف السيبراني...", Color3.fromRGB(0, 255, 255))

    local c = char(); local r = hrp()
    if not c or not r then
        ST.busyCyber = false; ST.busyCyberSince = 0
        setStatus("خامل", Color3.fromRGB(120,255,200))
        return
    end

    local returnPos = r.Position
    local wasNoclip = ST.noclipOn
    ST.noclipOn = true

    local function tpTo(pos)
        local cc = char(); if not cc then return end
        pcall(function()
            cc:PivotTo(CFrame.new(pos))
            local rp = hrp()
            if rp then rp.AssemblyLinearVelocity = Vector3.zero; rp.AssemblyAngularVelocity = Vector3.zero end
        end)
    end

    tpTo(CFG.CYBER_CAVE_POS)
    task.wait(0.4)

    local t0 = tick()
    while tick() - t0 < CFG.CYBER_STAY and not _G.StopAutoFarm and ST.autoCyber do
        task.wait(0.75)
        local rp = hrp(); if not rp then break end
        -- تثبيت داخل الكهف ضد أي دفع/فلينج
        if (rp.Position - CFG.CYBER_CAVE_POS).Magnitude > 30 then tpTo(CFG.CYBER_CAVE_POS) end
        pcall(function() rp.AssemblyLinearVelocity = Vector3.zero end)
        pcall(grabCyberLoot)
    end

    if not ST.autoCyber then
        addLog("⏹️ الكهف: إيقاف فوري")
        if not _G.StopAutoFarm then tpTo(returnPos + Vector3.new(0, 3, 0)); task.wait(0.3) end
        ST.noclipOn = wasNoclip
        if not wasNoclip then
            local cc = char()
            if cc then for _, p in ipairs(cc:GetDescendants()) do
                if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.CanCollide = true end
            end end
        end
        ST.busyCyber = false; ST.busyCyberSince = 0
        setStatus("خامل", Color3.fromRGB(120,255,200))
        return
    end

    ST.stats.cyberPoints = ST.stats.cyberPoints + 50
    ST.score = ST.score + 50
    updateStats()

    local didReset = false
    if not _G.StopAutoFarm then
        addLog("✅ انتهى وقت الكهف! +50 نقطة")
        didReset = true
        cyberResetForPoints()
    end
    task.wait(0.4)

    -- ═══ المرحلة الثانية: روتين الرافعة (من v6.1 — مُبقّى كما هو) ═══
    if CFG.CYBER_USE_LEVER and not _G.StopAutoFarm then
        addLog("🔧 تحرّي الرافعة السيبرانية...")
        setStatus("الرافعة السيبرانية...", Color3.fromRGB(0, 220, 255))
        tpTo(CFG.CYBER_LEVER)
        task.wait(0.2)
        local t1 = tick()
        while tick() - t1 < 3.5 and not _G.StopAutoFarm and ST.autoCyber do
            task.wait(0.08)
            local r1 = hrp(); if not r1 then break end
            for _, p in ipairs(workspace:GetDescendants()) do
                if p:IsA("BasePart") and (p.Position - r1.Position).Magnitude < 10 then
                    local pn = p.Name:lower()
                    if pn:find("handle") or pn:find("lever") or pn:find("مقبض") or pn:find("cyber") or pn:find("switch") then touchObj(p) end
                end
            end
            pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game); task.wait(0.12); VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game) end)
        end
        ST.stats.cyberPoints = ST.stats.cyberPoints + 50
        ST.score = ST.score + 50
        updateStats()
        if not _G.StopAutoFarm then
            didReset = true
            cyberResetForPoints()
        end
        task.wait(0.4)
    end

    -- العودة للموقع الأصلي — ممنوعة بعد ريستارت (تسبب رجوع مطاطي وتعليق المهمة)
    if not _G.StopAutoFarm and not didReset then
        tpTo(returnPos + Vector3.new(0, 3, 0))
        task.wait(0.4)
    end

    -- إعادة التصادم لطبيعته (noclip كان مفعلاً مؤقتاً)
    ST.noclipOn = wasNoclip
    if not wasNoclip then
        local cc = char()
        if cc then for _, p in ipairs(cc:GetDescendants()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.CanCollide = true end
        end end
    end

    ST.busyCyber = false; ST.busyCyberSince = 0
    setStatus("خامل", Color3.fromRGB(120,255,200))
end

-- ═══ مشغّلات الكهف: رسالة الشات + تغيّر شفافية باب الأمن ═══
local recentMsgs = {}
local function checkCyberMsg(txt)
    if not txt or type(txt) ~= "string" or txt == "" then return false end
    if recentMsgs[txt] and (tick() - recentMsgs[txt] < 45) then return false end
    local s = txt:lower()
    local hasDoor = s:find("باب") or s:find("door") or s:find("فتح")
    local hasCyber = s:find("امن") or s:find("أمن") or s:find("سبران") or s:find("سيبران") or s:find("cyber")
    if (hasDoor and hasCyber) or s:find("تم فتح باب الامن") or s:find("تم فتح باب الأمن") then recentMsgs[txt] = tick(); return true end
    return false
end
addC(TextChatService.MessageReceived:Connect(function(msg)
    if _G.StopAutoFarm or not ST.autoCyber then return end
    pcall(function()
        if checkCyberMsg(msg.Text) then addLog("💬 رسالة فتح الباب"); task.spawn(lootCyberCave) end
    end)
end))

task.spawn(function()
    local security = workspace:WaitForChild("Security", 20)
    local door = security and security:WaitForChild("Door", 10)
    if not door then return end
    local lastFire = 0
    addC(door:GetPropertyChangedSignal("Transparency"):Connect(function()
        if _G.StopAutoFarm or not ST.autoCyber or ST.busyCyber then return end
        if tick() - lastFire < 6 then return end
        lastFire = tick()
        addLog(("🚪 تغيّر باب الأمن (Transparency=%.2f)"):format(door.Transparency))
        task.spawn(lootCyberCave)
    end))
end)

if REM.ShowTarget then
    addC(REM.ShowTarget.OnClientEvent:Connect(function(tp,_,_,cnt,tot,isPick)
        if _G.StopAutoFarm then return end
        if not tp then ST.missionOn=false; ST.target=nil; ST.cdExpire=tick()+CFG.COOLDOWN; addLog("اكتملت المهمة"); return end
        ST.target=tp; ST.isPickup=(isPick==true); ST.boxIndex=cnt or ST.boxIndex; ST.totalBoxes=tot or 5; ST.missionOn=true
    end))
end

-- أزرار لا نضغطها أبداً من محرّك المهام (طقس/إيقاف/إلغاء/متجر)
local function skipStartText(txt)
    local t = tostring(txt or ""):lower()
    return t:find("طقس") or t:find("أجواء") or t:find("اجواء") or t:find("weather")
        or t:find("إيقاف") or t:find("ايقاف") or t:find("إلغاء") or t:find("الغاء")
        or t:find("stop") or t:find("cancel") or t:find("إزالة") or t:find("ازالة")
        or t:find("شراء") or t:find("buy") or t:find("متجر") or t:find("shop")
end

local function findAndClickStartBtn()
    local clicked = false
    for _, g in ipairs(pg:GetChildren()) do
        if not g:IsA("ScreenGui") or not g.Enabled or g.Name:find("FinalFix") or g.Name:find("AutoFarm") then continue end
        for _, b in ipairs(g:GetDescendants()) do
            if (b:IsA("TextButton") or b:IsA("ImageButton")) and b.Visible and b.AbsoluteSize.X > 25 then
                local t = (b:IsA("TextButton") and b.Text or "")
                for _, sub in ipairs(b:GetChildren()) do if sub:IsA("TextLabel") then t = t .. " " .. (sub.Text or "") end end
                local tl = t:lower()
                local isStart = t:find("أبدا") or t:find("ابدأ") or t:find("ابدا") or t:find("بدء") or t:find("قبول")
                    or tl:find("start") or tl:find("join") or tl:find("accept")
                if isStart and not skipStartText(t) then clickBtn(b); clicked = true; task.wait(0.12) end
            end
        end
    end
    return clicked
end

local function triggerMissionStart()
    -- نضغط فقط برومبتات لوحة المهام (كان يضغط برومبتات الأجواء والأبواب ويخرّب المهمة)
    for _, entry in ipairs(getNearbyPrompts(18)) do
        local p = entry.prompt
        local host = p.Parent
        local txt = ((p.ActionText or "") .. " " .. (p.ObjectText or "") .. " " .. (host and host.Name or "")):lower()
        local isMission = txt:find("مهم") or txt:find("لوح") or txt:find("board") or txt:find("mission")
            or txt:find("أبدا") or txt:find("ابدأ") or txt:find("start") or txt:find("قبول")
        if isMission and not txt:find("طقس") and not txt:find("أجواء") and not txt:find("اجواء") then
            triggerPromptInstantly(p)
        end
    end
    pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game); task.wait(0.3); VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game) end)
    task.wait(0.15)
    local r = hrp()
    if r then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and (obj.Position - r.Position).Magnitude < 12 then
                local on = obj.Name:lower()
                if on:find("board") or on:find("mission") or on:find("لوحة") then touchObj(obj) end
            end
        end
    end
    if REM.StartMission then pcall(function() REM.StartMission:FireServer() end) end
    if REM.StartMissio2 then pcall(function() REM.StartMissio2:FireServer() end) end
    if findAndClickStartBtn() then return true end
    for _, g in ipairs(pg:GetChildren()) do
        if g:IsA("ScreenGui") and g.Enabled and not g.Name:find("FinalFix") then
            for _, b in ipairs(g:GetDescendants()) do
                if (b:IsA("TextButton") or b:IsA("ImageButton")) and b.Visible then
                    local t = ((b:IsA("TextButton") and b.Text or "") .. " " .. b.Name):lower()
                    if t:find("المهام") or t:find("mission") then clickBtn(b); task.wait(0.35); break end
                end
            end
        end
    end
    findAndClickStartBtn()
    return false
end

local function runMissionCycle()
    if not ST.autoMission then return end
    if ST.inProgress or ST.busyCyber or ST.handlingDrop or ST.busyDrop or ST.busyWeather or weatherStarting then return end
    if ST.autoDrop and not hasCrate() then
        local d, k = findActiveDrop()
        if d and d.Parent and d ~= ST.lastDropObj then
            ST.inProgress = false; task.spawn(handleDrop, d, k); return
        end
    end

    ST.inProgress = true
    local carrying = hasCrate(); ST.isPickup = not carrying
    local h, r = hum(), hrp()
    if not h or not r or not alive() then ST.inProgress = false; task.wait(1); return end
    if carrying then getCrate() end
    local cdLeft = math.ceil(ST.cdExpire - tick())
    ST.goalPos = CFG.BOARD_POS
    if cdLeft > 0 then
        setStatus(("كول داون: %ds"):format(cdLeft), Color3.fromRGB(200,200,100))
        if flatDist(r.Position, CFG.BOARD_POS) > 6 then if handleWalkInterrupt(walk(CFG.BOARD_POS, 12, false, "mission")) then ST.inProgress = false; return end end
        task.wait(0.8); ST.inProgress = false; return
    end
    if not ST.missionOn then
        if tick() - ST.lastStartTry < 2.0 then ST.inProgress = false; task.wait(0.5); return end
        ST.lastStartTry = tick()
        addLog("بدء مهمة جديدة..."); setStatus("التوجه للوحة...", Color3.fromRGB(150,220,255))
        if flatDist(r.Position, CFG.BOARD_POS) > 5 then
            if handleWalkInterrupt(walk(CFG.BOARD_POS, 14, false, "mission")) then ST.inProgress = false; return end
            pcall(function() char():PivotTo(CFrame.new(CFG.BOARD_POS + Vector3.new(0, 1.2, 0))) end); task.wait(0.2)
        end
        triggerMissionStart()
        local wt = tick()
        local accepted = false
        while tick() - wt < CFG.SHOWTARGET_WAIT do
            task.wait(0.15)
            if not ST.autoMission or _G.StopAutoFarm then break end
            if ST.missionOn and ST.target then accepted = true; addLog("تم قبول المهمة"); break end
        end
        if not ST.autoMission then ST.inProgress = false; return end
        if accepted then ST.startFails = 0
        else
            ST.startFails = (ST.startFails or 0) + 1
            if ST.startFails >= 3 then
                ST.startFails = 0
                addLog("⚠️ اللوحة ما قبلت المهمة — تأكد إنك مو في كول داون، أو ابدأها بيدك مرة")
            end
        end
        ST.inProgress = false; return
    end
    if ST.isPickup then
        ST.goalPos = CFG.WH_RIGHT
        addLog("التوجه للمستودع"); setStatus("استلام صندوق...", Color3.fromRGB(255,200,100))
        if handleWalkInterrupt(walk(CFG.WH_RIGHT, 16, false, "mission")) then ST.inProgress = false; return end
        local pickupOK = false
        for att = 1, 10 do
            if waitCrate(0.05) then pickupOK = true; break end
            if _G.StopAutoFarm or not ST.autoMission or ST.busyCyber or ST.handlingDrop or ST.busyDrop or ST.busyWeather then break end
            h, r = hum(), hrp(); if not h or not r then break end
            local spot = (att % 2 == 0) and CFG.WH_RIGHT or (CFG.WH_RIGHT + Vector3.new(1.5, 0, 1.5))
            -- ممنوع CFrame أثناء المهمة (يلغيها) — نتحرك خطوة صغيرة فقط
            pcall(function() h:MoveTo(spot); r.AssemblyLinearVelocity = Vector3.zero end); task.wait(0.15)
            local near = getNearbyPrompts(20)
            for pi = 1, math.min(#near, 3) do firePromptFast(near[pi].prompt) end
            if waitCrate(0.3) then pickupOK = true; break end
            if ST.target then touchObj(ST.target) end
            local bf = workspace:FindFirstChild("BoxFolder"); if bf then for _, z in ipairs(bf:GetChildren()) do if z:IsA("BasePart") then touchObj(z) end end end
            pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game); task.wait(0.08); VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game) end)
            if waitCrate(0.35) then pickupOK = true; break end
            task.wait(0.1)
        end
        if not ST.autoMission then ST.inProgress = false; return end
        if hasCrate() or pickupOK or waitCrate(0.8) then
            local crate = getCrate()
            if crate and crate:IsA("Tool") and crate.Parent ~= char() then
                pcall(function() h:EquipTool(crate) end)
                task.wait(0.25)
            end
            addLog("تم حمل الصندوق"); ST.isPickup = false
            -- انتقال فوري لمرحلة التسليم (بدون وقفة عند المستودع)
            if not ST.autoMission then ST.inProgress = false; return end
            task.wait(0.1); ST.stats.missions = ST.stats.missions + 1; updateStats()
        else task.wait(0.5) end
    else
        -- الهدف القديم قد يُحذف بعد التسليم؛ نتأكد أنه موجود فعلاً
        local targetObj = ST.target
        if not targetObj or not targetObj.Parent then
            targetObj = nil; ST.target = nil
            local mt = workspace:FindFirstChild("MissionTargets")
            if mt then
                for _, t in ipairs(mt:GetChildren()) do
                    if (t:IsA("BasePart") or t:IsA("Model")) and t.Parent then targetObj = t; break end
                end
            end
            ST.target = targetObj
        end
        if not hasCrate() then task.wait(0.3); ST.isPickup = true; ST.inProgress = false; return end
        if not targetObj then
            ST.lostTargetAt = ST.lostTargetAt or tick()
            if tick() - ST.lostTargetAt > 15 then
                ST.lostTargetAt = nil
                addLog("⚠️ هدف التسليم اختفى — إعادة محاولة المهمة")
                ST.missionOn = false; ST.cdExpire = tick() + 10
            end
            ST.inProgress = false; task.wait(0.5); return
        end
        ST.lostTargetAt = nil
        local tp = targetObj:IsA("BasePart") and targetObj or targetObj:FindFirstChildWhichIsA("BasePart", true)
        if not tp then task.wait(0.3); ST.inProgress = false; return end
        addLog("التوجه لنقطة التسليم"); setStatus("تسليم...", Color3.fromRGB(120,255,150))
        local bPos = tp.Position; pcall(function() tp.CanTouch = true end)
        local gPos = groundOf(bPos)
        ST.goalPos = Vector3.new(bPos.X, gPos.Y, bPos.Z)
        if handleWalkInterrupt(walk(Vector3.new(bPos.X, gPos.Y, bPos.Z), 20, false, "mission")) then ST.inProgress = false; return end
        r, h = hrp(), hum(); if not r or not h then ST.inProgress = false; return end
        h.WalkSpeed = 16
        local delivered = false; local t0 = tick()
        while tick() - t0 < 12 do
            if not hasCrate() then delivered = true; break end
            if _G.StopAutoFarm or not ST.autoMission or not ST.missionOn or ST.busyCyber or ST.handlingDrop or ST.busyDrop or ST.busyWeather then break end
            r, h = hrp(), hum(); if not r or not h then break end
            h:MoveTo(Vector3.new(bPos.X, r.Position.Y, bPos.Z))
            touchObj(tp)
            local mt = workspace:FindFirstChild("MissionTargets"); if mt then for _, t in ipairs(mt:GetChildren()) do if t:IsA("BasePart") then pcall(function() t.CanTouch = true end); touchObj(t) end end end
            local crate = getCrate(); if crate then
                if crate:IsA("BasePart") then touchBoth(crate, tp)
                elseif crate:IsA("Model") then for _, p in ipairs(crate:GetDescendants()) do if p:IsA("BasePart") then touchBoth(p, tp) end end end
                if crate:IsA("Tool") then pcall(function() crate:Activate() end) end
            end
            local near = getNearbyPrompts(15)
            for pi = 1, math.min(#near, 3) do firePromptFast(near[pi].prompt) end
            task.wait(0.12)
            if not hasCrate() then delivered = true; break end
            pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game); task.wait(0.12); VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game) end)
            task.wait(0.15)
        end
        if not ST.autoMission then ST.inProgress = false; return end
        if delivered or not hasCrate() then ST.isPickup = true; addLog("تم التسليم")
        elseif ST.autoMission then ST.stats.failed = ST.stats.failed + 1 end
        h = hum(); if h then h.WalkSpeed = ST.customSpeedOn and ST.walkSpeed or 16 end
    end
    ST.inProgress = false
    ST.goalPos = nil
end

local function startFly()
    local r=hrp(); if not r then return end
    if flyBV then flyBV:Destroy() end; if flyBG then flyBG:Destroy() end
    flyBV=Instance.new("BodyVelocity",r); flyBV.MaxForce=Vector3.new(1e6,1e6,1e6); flyBV.Velocity=Vector3.zero
    flyBG=Instance.new("BodyGyro",r); flyBG.MaxTorque=Vector3.new(1e6,1e6,1e6); flyBG.P=9000
    ST.flyOn=true; ST.noclipOn=true
    if pg:FindFirstChild("MobileFlyGui") then pg.MobileFlyGui.Enabled = true end
end
local function stopFly()
    ST.flyOn=false; ST.noclipOn=false
    if flyBV then flyBV:Destroy(); flyBV=nil end
    if flyBG then flyBG:Destroy(); flyBG=nil end
    if pg:FindFirstChild("MobileFlyGui") then pg.MobileFlyGui.Enabled = false end
end

local function setNoclip(on)
    ST.noclipOn=on
    if not on then
        local c=char(); if c then for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") and p.Name~="HumanoidRootPart" then p.CanCollide=true end end end
    end
end

local function updateInvis()
    local c=char(); if not c then return end
    if ST.invisOn then
        for _,d in ipairs(c:GetDescendants()) do
            if d:IsA("BasePart") and d.Name~="HumanoidRootPart" then if invisSaved[d]==nil then invisSaved[d]=d.Transparency end; d.Transparency=1
            elseif d:IsA("Decal") then if invisSaved[d]==nil then invisSaved[d]=d.Transparency end; d.Transparency=1
            elseif d:IsA("BillboardGui") or d:IsA("SurfaceGui") then if invisSaved[d]==nil then invisSaved[d]=d.Enabled end; d.Enabled=false end
        end
    else restoreVis() end
end

local function updatePlayerESP()
    local myHrp = hrp()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= pl and p.Character then
            local c = p.Character; local th = c:FindFirstChild("HumanoidRootPart"); local hum2 = c:FindFirstChildWhichIsA("Humanoid")
            if th and hum2 and hum2.Health > 0 then
                if not espHL[p] or espHL[p].Parent ~= pg then
                    if espHL[p] then espHL[p]:Destroy() end
                    local hl = Instance.new("Highlight", pg); hl.Name = "AutoFarmPlayerHL"; hl.FillColor = Color3.fromRGB(255, 40, 40); hl.FillTransparency = 0.55; hl.OutlineColor = Color3.fromRGB(255, 255, 0); hl.OutlineTransparency = 0; hl.Adornee = c; espHL[p] = hl
                end
                if not espTags[p] or espTags[p].Parent ~= pg then
                    if espTags[p] then espTags[p]:Destroy() end
                    local tag = Instance.new("BillboardGui", pg); tag.Name = "AutoFarmPlayerTag"; tag.Size = UDim2.new(0, 160, 0, 48); tag.StudsOffset = Vector3.new(0, 3.5, 0); tag.AlwaysOnTop = true; tag.Adornee = th
                    local nameLbl = Instance.new("TextLabel", tag); nameLbl.Name = "NameLbl"; nameLbl.Size = UDim2.new(1, 0, 0, 16); nameLbl.BackgroundTransparency = 1; nameLbl.TextColor3 = Color3.fromRGB(255, 230, 100); nameLbl.Font = Enum.Font.GothamBold; nameLbl.TextSize = 12; nameLbl.TextStrokeTransparency = 0.2
                    local infoLbl = Instance.new("TextLabel", tag); infoLbl.Name = "InfoLbl"; infoLbl.Size = UDim2.new(1, 0, 0, 14); infoLbl.Position = UDim2.new(0, 0, 0, 16); infoLbl.BackgroundTransparency = 1; infoLbl.TextColor3 = Color3.fromRGB(180, 230, 255); infoLbl.Font = Enum.Font.Gotham; infoLbl.TextSize = 10; infoLbl.TextStrokeTransparency = 0.2
                    local hpBg = Instance.new("Frame", tag); hpBg.Name = "HpBg"; hpBg.Size = UDim2.new(0.8, 0, 0, 4); hpBg.Position = UDim2.new(0.1, 0, 0, 32); hpBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40); Instance.new("UICorner", hpBg).CornerRadius = UDim.new(0, 2)
                    local hpFill = Instance.new("Frame", hpBg); hpFill.Name = "HpFill"; hpFill.Size = UDim2.new(1, 0, 1, 0); hpFill.BackgroundColor3 = Color3.fromRGB(0, 255, 120); Instance.new("UICorner", hpFill).CornerRadius = UDim.new(0, 2)
                    espTags[p] = tag
                end
                local tag = espTags[p]
                if tag then
                    local dist = myHrp and (th.Position - myHrp.Position).Magnitude or 0
                    local rName = getPlayerRankInfo(p); local nameL = tag:FindFirstChild("NameLbl"); local infoL = tag:FindFirstChild("InfoLbl"); local hpBg = tag:FindFirstChild("HpBg"); local hpFill = hpBg and hpBg:FindFirstChild("HpFill")
                    if nameL then nameL.Text = ("%s"):format(p.DisplayName) end
                    if infoL then infoL.Text = ("[%s] %.0fm"):format(rName, dist) end
                    if hpFill and hum2.MaxHealth > 0 then
                        local pct = math.clamp(hum2.Health / hum2.MaxHealth, 0, 1)
                        hpFill.Size = UDim2.new(pct, 0, 1, 0)
                        hpFill.BackgroundColor3 = pct > 0.5 and Color3.fromRGB(0, 255, 120) or (pct > 0.25 and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(255, 50, 50))
                    end
                end
            else
                if espHL[p] then espHL[p]:Destroy(); espHL[p] = nil end
                if espTags[p] then espTags[p]:Destroy(); espTags[p] = nil end
            end
        end
    end
end

local function updateDropESP()
    local myHrp = hrp(); local seen = {}
    local function handleDropObj(obj)
        if not obj or seen[obj] then return end; seen[obj] = true
        local part = getPart(obj); if not part then return end
        if not espDropHL[obj] or espDropHL[obj].Parent ~= pg then
            if espDropHL[obj] then espDropHL[obj]:Destroy() end
            local isSec = classifyDrop(obj) == "secret"
            local hl = Instance.new("Highlight", pg); hl.Name = "AutoFarmDropHL"; hl.FillColor = isSec and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(0, 200, 255); hl.FillTransparency = 0.4; hl.OutlineColor = Color3.fromRGB(255, 255, 255); hl.Adornee = obj; espDropHL[obj] = hl
        end
        if not espDropTags[obj] or espDropTags[obj].Parent ~= pg then
            if espDropTags[obj] then espDropTags[obj]:Destroy() end
            local tag = Instance.new("BillboardGui", pg); tag.Name = "AutoFarmDropTag"; tag.Size = UDim2.new(0, 140, 0, 30); tag.StudsOffset = Vector3.new(0, 3, 0); tag.AlwaysOnTop = true; tag.Adornee = part
            local lbl = Instance.new("TextLabel", tag); lbl.Name = "DropLbl"; lbl.Size = UDim2.new(1, 0, 1, 0); lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 12; lbl.TextStrokeTransparency = 0.2
            espDropTags[obj] = tag
        end
        local tag = espDropTags[obj]
        if tag then
            local isSec = classifyDrop(obj) == "secret"; local dist = myHrp and (part.Position - myHrp.Position).Magnitude or 0; local lbl = tag:FindFirstChild("DropLbl")
            if lbl then lbl.Text = ("%s (%.0fm)"):format(isSec and "🏆 دروب سري" or "📦 دروب جوي", dist); lbl.TextColor3 = isSec and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(0, 230, 255) end
        end
    end
    for _, n in ipairs(CFG.DROP_NAMES) do
        local obj = workspace:FindFirstChild(n)
        if obj then if obj:IsA("Folder") then for _, child in ipairs(obj:GetChildren()) do handleDropObj(child) end else handleDropObj(obj) end end
    end
    for obj, _ in pairs(espDropHL) do if not obj.Parent then if espDropHL[obj] then espDropHL[obj]:Destroy(); espDropHL[obj]=nil end; if espDropTags[obj] then espDropTags[obj]:Destroy(); espDropTags[obj]=nil end end end
end

task.spawn(function() while not _G.StopAutoFarm do task.wait(0.6); if ST.espPlayers then pcall(updatePlayerESP) end; if ST.espDrops then pcall(updateDropESP) end end end)

local function enableFullbright()
    lightSave.Brightness=Lighting.Brightness; lightSave.ClockTime=Lighting.ClockTime; lightSave.FogEnd=Lighting.FogEnd; lightSave.GlobalShadows=Lighting.GlobalShadows
    Lighting.Brightness=2; Lighting.ClockTime=14; Lighting.FogEnd=1e6; Lighting.GlobalShadows=false
    for _,e in ipairs(Lighting:GetDescendants()) do if e:IsA("Atmosphere") or e:IsA("BloomEffect") or e:IsA("BlurEffect") or e:IsA("ColorCorrectionEffect") then e.Enabled=false end end
end
local function disableFullbright()
    for prop,val in pairs(lightSave) do pcall(function() Lighting[prop]=val end) end
    for _,e in ipairs(Lighting:GetDescendants()) do if e:IsA("Atmosphere") or e:IsA("BloomEffect") or e:IsA("BlurEffect") or e:IsA("ColorCorrectionEffect") then e.Enabled=true end end
end

-- ═══════════════════════════════════════════════════════════════
--  🛡️ حماية حقيقية: كلبشة / رصاص / سجن / إخفاء الاسم
-- ═══════════════════════════════════════════════════════════════
local CUFF_WORDS = {"cuff","handcuff","arrest","restrain","zip","taze","stun","freeze","مصفاد","كلبش","تقييد","قيد","أغلال","اغلال","زنجير","تكتيف","ربط"}

local function isCuffName(s)
    s = tostring(s or ""):lower()
    for _, w in ipairs(CUFF_WORDS) do if s:find(w, 1, true) then return true end end
    return false
end

-- إزالة أي أداة/قيد انزرع داخل الشخصية
local function purgeCuffInst(inst)
    if not inst or not inst.Parent then return 0 end
    local c = char(); if not c or not inst:IsDescendantOf(c) then return 0 end
    if inst:IsA("Tool") and isCuffName(inst.Name) then
        -- لا تلمس الكلبشة اللي نستخدمها بأنفسنا
        if ST.selfCuff and tick() - ST.selfCuff < 6 then return 0 end
        pcall(function() inst.Parent = nil end)
        pcall(function() inst:Destroy() end)
        return 1
    end
    if (inst:IsA("Weld") or inst:IsA("WeldConstraint") or inst:IsA("Motor6D")
        or inst:IsA("BodyPosition") or inst:IsA("BodyVelocity") or inst:IsA("BodyGyro")
        or inst:IsA("AlignPosition") or inst:IsA("AlignOrientation")) and isCuffName(inst.Name) then
        pcall(function() inst:Destroy() end)
        return 1
    end
    if (inst:IsA("Weld") or inst:IsA("WeldConstraint")) and not tostring(inst.Name):lower():find("seat") then
        -- لصق لاعب آخر فينا (طريقة الكلبشة بالتوجيه)
        local function otherOwner(p)
            if not p then return false end
            local m = p:FindFirstAncestorOfClass("Model")
            local op = m and Players:GetPlayerFromCharacter(m)
            return op ~= nil and op ~= pl
        end
        if otherOwner(inst.Part0) or otherOwner(inst.Part1) then
            pcall(function() inst:Destroy() end)
            return 1
        end
    end
    if (inst:IsA("BoolValue") or inst:IsA("StringValue")) and isCuffName(inst.Name) then
        pcall(function()
            if inst:IsA("BoolValue") then inst.Value = false else inst.Value = "" end
        end)
        pcall(function() inst:Destroy() end)
        return 1
    end
    return 0
end

local lastAnimSweep = 0
local function restoreHumanoid(h)
    if not h then return end
    if h.PlatformStand then pcall(function() h.PlatformStand = false end) end
    if h.Sit then pcall(function() h.Sit = false end) end
    if h.WalkSpeed < 10 and h.WalkSpeed >= 0 then pcall(function() h.WalkSpeed = ST.customSpeedOn and ST.walkSpeed or 16 end) end
    if h.UseJumpPower then
        if h.JumpPower < 20 then pcall(function() h.JumpPower = ST.jumpPower or 50 end) end
    elseif h.JumpHeight < 3 then
        pcall(function() h.JumpHeight = 7.2 end)
    end
    local st = h:GetState()
    if st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown then
        pcall(function() h:ChangeState(Enum.HumanoidStateType.GettingUp) end)
    end
    if tick() - lastAnimSweep > 1 then
        lastAnimSweep = tick()
        pcall(function()
            for _, t in ipairs(h:GetPlayingAnimationTracks()) do
                local tn = (t.Name or ""):lower()
                if isCuffName(tn) or tn:find("arrest") or tn:find("surrender") then t:Stop() end
            end
        end)
    end
end

local function runAntiCuff()
    local c = char(); if not c then return end
    for _, d in ipairs(c:GetDescendants()) do
        if d:IsA("Weld") or d:IsA("WeldConstraint") or d:IsA("Motor6D") or d:IsA("BodyVelocity") or d:IsA("BodyPosition") then
            local dn = d.Name:lower()
            if dn:find("cuff") or dn:find("arrest") or dn:find("handcuff") or dn:find("freeze") or dn:find("taze") or dn:find("كلبش") then pcall(function() d:Destroy() end) end
        end
    end
    local h = hum()
    if h then
        if h.PlatformStand then h.PlatformStand = false end
        if h.Sit then h.Sit = false end
        if h.WalkSpeed < 10 and not ST.handlingDrop and not ST.busyWeather then h.WalkSpeed = ST.customSpeedOn and ST.walkSpeed or 16 end
    end
    restoreHumanoid(h)
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") and p.Anchored then pcall(function() p.Anchored = false end) end
        if p:IsA("ProximityPrompt") then local at = (p.ActionText or "") .. " " .. (p.ObjectText or ""); if at:find("كلبشة") or at:find("Arrest") or at:lower():find("cuff") then p.Enabled = false end end
    end
end

-- ═══ إخفاء الاسم (فوق الرأس) ═══
local nameHiddenBillboards = {}

local function applyHideName()
    local c, h = char(), hum()
    if h then pcall(function() h.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end) end
    if not c then return end
    for _, d in ipairs(c:GetDescendants()) do
        if d:IsA("BillboardGui") then
            local n = d.Name:lower()
            if n:find("name") or n:find("tag") or n:find("label") then
                if nameHiddenBillboards[d] == nil then nameHiddenBillboards[d] = d.Enabled end
                if d.Enabled then pcall(function() d.Enabled = false end) end
            end
        end
    end
end

local function restoreName()
    local h = hum()
    if h then pcall(function() h.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer end) end
    for obj, val in pairs(nameHiddenBillboards) do
        pcall(function() if obj.Parent then obj.Enabled = val end end)
    end
    nameHiddenBillboards = {}
end
_G.__restoreName = restoreName

-- ═══ منع الرصاص (إرجاع الصحة فوراً) ═══
local function healNow(reason)
    local h = hum(); if not h or h.Health <= 0 then return end
    if ST.forceReset then return end
    if tick() - ST.lastHeal < 0.08 then return end
    ST.lastHeal = tick()
    pcall(function() h.Health = h.MaxHealth end)
    if tick() - ST.lastHealLog > 6 then
        ST.lastHealLog = tick()
        addLog("💉 " .. reason)
    end
end

local function runAntiBullet()
    if not ST.antiBullet or ST.forceReset then return end
    local h = hum(); if not h then return end
    if h.Health <= 0 then
        pcall(function() h.Health = h.MaxHealth end)
        return
    end
    if h.Health < h.MaxHealth - 1 then healNow("تم إرجاع الصحة بعد إصابة") end
    local st = h:GetState()
    if st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown then
        pcall(function() h:ChangeState(Enum.HumanoidStateType.GettingUp) end)
    end
end

-- ═══ منع السجن ═══
local JAIL_WORDS = {"jail","prison","cell","detention","سجن","زنزانة","معتقل","حبس"}
local jailCache, jailCacheAt = {}, 0

local function nameIsJail(n)
    n = tostring(n or ""):lower()
    for _, w in ipairs(JAIL_WORDS) do if n:find(w, 1, true) then return true end end
    return false
end

local function refreshJailCache()
    jailCache = {}; jailCacheAt = tick()
    local function walk(inst, depth)
        if depth > 3 then return end
        for _, d in ipairs(inst:GetChildren()) do
            if d:IsA("BasePart") and nameIsJail(d.Name) then jailCache[#jailCache+1] = d end
            if d:IsA("Model") or d:IsA("Folder") then
                if nameIsJail(d.Name) then
                    for _, p in ipairs(d:GetDescendants()) do
                        if p:IsA("BasePart") then jailCache[#jailCache+1] = p end
                    end
                else
                    walk(d, depth + 1)
                end
            end
        end
    end
    pcall(walk, workspace, 0)
end

local function detectJail(pos)
    if tick() - jailCacheAt > 60 then refreshJailCache() end
    for _, jp in ipairs(jailCache) do
        if jp.Parent and (jp.Position - pos).Magnitude < 45 then return true end
    end
    return false
end

local function runAntiJail()
    if not ST.antiJail then return end
    local r, h = hrp(), hum()
    if not r or not h or h.Health <= 0 then return end
    if tick() < ST.jailLockedUntil then return end
    if ST.busyDrop or ST.busyCyber or ST.busyWeather or ST.flyOn or ST.inProgress or ST.clickTpOn or ST.spectating then
        ST.lastSafePos = r.Position
        return
    end
    local pos = r.Position
    if not ST.lastSafePos then ST.lastSafePos = pos; return end
    local moved = (pos - ST.lastSafePos).Magnitude
    if moved < 120 then ST.lastSafePos = pos; ST.jailAttempts = 0; return end
    if not detectJail(pos) then ST.lastSafePos = pos; return end

    if tick() - ST.lastJailLog > 5 then
        ST.lastJailLog = tick()
        addLog("🚔 كشفنا سجن — محاولة هروب")
    end
    local back = ST.lastSafePos + Vector3.new(0, 3, 0)
    pcall(function() r.CFrame = CFrame.new(back); r.AssemblyLinearVelocity = Vector3.zero end)
    restoreHumanoid(h)
    ST.jailAttempts = ST.jailAttempts + 1
    if ST.jailAttempts >= 4 then
        ST.jailAttempts = 0
        ST.jailLockedUntil = tick() + 15
        addLog("⚠️ السجن متكرر — توقفنا 15 ثانية")
    end
    task.wait(0.25)
end

-- تثبيت الحماية على الشخصية (كل ما ينضاف شيء مشبوه ينتزع فوراً)
local function hookCharacterDefense(c)
    if not c then return end
    addC(c.DescendantAdded:Connect(function(inst)
        if _G.StopAutoFarm or not ST.antiCuff then return end
        task.defer(function()
            if purgeCuffInst(inst) > 0 then
                addLog("🛡️ صدّينا كلبشة/قيد")
                restoreHumanoid(c:FindFirstChildOfClass("Humanoid"))
            end
        end)
    end))
    local h = c:FindFirstChildOfClass("Humanoid")
    if h then
        addC(h.HealthChanged:Connect(function(nh)
            if _G.StopAutoFarm or not ST.antiBullet or ST.forceReset then return end
            if nh > 0 and nh < h.MaxHealth - 1 then healNow("درع مضاد للرصاص") end
        end))
        addC(h.Died:Connect(function()
            if _G.StopAutoFarm or not ST.antiBullet or ST.forceReset then return end
            task.defer(function() pcall(function() h.Health = h.MaxHealth end) end)
        end))
        for _, prop in ipairs({"WalkSpeed","JumpPower","JumpHeight","PlatformStand","Sit"}) do
            pcall(function()
                addC(h:GetPropertyChangedSignal(prop):Connect(function()
                    if _G.StopAutoFarm or not ST.antiCuff then return end
                    task.defer(function() restoreHumanoid(h) end)
                end))
            end)
        end
    end
    if ST.hideName then task.defer(applyHideName) end
end

hookCharacterDefense(char())
addC(pl.CharacterAdded:Connect(function(c)
    task.wait(0.6)
    hookCharacterDefense(c)
    ST.lastSafePos = nil
end))

local function runAutoArmorRefill()
    local h = hum(); if not h or h.Health <= 0 then return end
    if h.Health < 90 and (tick() - ST.lastArmorRefill > 4) then
        ST.lastArmorRefill = tick()
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("ProximityPrompt") then
                local at = (d.ActionText or "") .. " " .. (d.ObjectText or "") .. " " .. d.Name
                if at:lower():find("armor") or at:find("درع") then triggerPromptInstantly(d); addLog("🛡️ تفعيل الدرع التلقائي!"); break end
            end
        end
    end
end

addC(RUN.Heartbeat:Connect(function() if _G.StopAutoFarm then return end; if ST.antiCuff then pcall(runAntiCuff) end; if ST.autoArmorDefense then pcall(runAutoArmorRefill) end; if ST.antiBullet then pcall(runAntiBullet) end end))

task.spawn(function()
    while not _G.StopAutoFarm do
        task.wait(0.4)
        if ST.antiJail then pcall(runAntiJail) end
        if ST.hideName then pcall(applyHideName) end
    end
end)

local function cuffPlayer(targetPlr)
    if not targetPlr or not targetPlr.Character then addLog("اللاعب غير موجود للكلبشة") return end
    ST.selfCuff = tick()
    local tc = targetPlr.Character; local th = tc:FindFirstChild("HumanoidRootPart"); if not th then addLog("اللاعب ليس له موقع") return end
    local bp = pl:FindFirstChild("Backpack"); local cuffTool = (bp and bp:FindFirstChild("Cuffs")) or (char() and char():FindFirstChild("Cuffs"))
    if not cuffTool and bp then for _, item in ipairs(bp:GetChildren()) do if item:IsA("Tool") and (item.Name:lower():find("cuff") or item.Name:find("كلبش") or item.Name:find("مصفاد")) then cuffTool = item; break end end end
    if cuffTool and cuffTool.Parent == bp then local h = hum(); if h then h:EquipTool(cuffTool); task.wait(0.12) end end
    pcall(function() char():PivotTo(CFrame.new(th.Position + (th.CFrame.LookVector * -2.5) + Vector3.new(0, 0.5, 0))) end)
    task.wait(0.12)
    if cuffTool and cuffTool:IsA("Tool") then pcall(function() cuffTool:Activate() end) end
    touchObj(th)
    if REM.EquipCuff then pcall(function() REM.EquipCuff:FireServer(targetPlr) end) end
    addLog(("👮‍♂️ محاولة كلبشة: %s"):format(targetPlr.DisplayName))
end

local function toggleSpectate(targetPlr)
    local h = hum()
    if ST.spectating then ST.spectating = false; ST.spectateTarget = nil; if h then cam.CameraSubject = h end; addLog("إلغاء المراقبة")
    else
        if not targetPlr or not targetPlr.Character then addLog("اللاعب غير موجود") return end
        local th = targetPlr.Character:FindFirstChildWhichIsA("Humanoid"); if th then cam.CameraSubject = th; ST.spectating = true; ST.spectateTarget = targetPlr; addLog(("👁️ جاري مراقبة: %s"):format(targetPlr.DisplayName)) end
    end
end

local function takeArmor()
    local found = false
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") then local at = (d.ActionText or "") .. " " .. (d.ObjectText or "") .. " " .. d.Name; if at:lower():find("armor") or at:find("درع") then triggerPromptInstantly(d); found = true end end
    end
    addLog(found and "🛡️ تم أخذ الدرع" or "لم يتم العثور على درع")
end

local function grabWeapons()
    local count = 0; local bp = pl:FindFirstChild("Backpack")
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Tool") and bp then
            local tn = obj.Name:lower()
            if tn:find("scar") or tn:find("ak") or tn:find("قناص") or tn:find("sniper") or tn:find("m4") or tn:find("gun") then pcall(function() obj.Parent = bp end); count = count + 1 end
        elseif obj:IsA("ProximityPrompt") then
            local at = (obj.ActionText or ""):lower()
            if at:find("gun") or at:find("weapon") or at:find("سلاح") or at:find("take") then triggerPromptInstantly(obj); count = count + 1 end
        end
    end
    addLog(("🔫 تم سحب %d سلاح/برومبت"):format(count))
end

local function openAllGates()
    local count = 0
    for _, cd in ipairs(workspace:GetDescendants()) do
        if cd:IsA("ClickDetector") then local pn = cd.Parent and cd.Parent.Name:lower() or ""; if pn:find("open") or pn:find("out") or pn:find("gate") or pn:find("door") or pn:find("system") then pcall(function() if typeof(fireclickdetector) == "function" then fireclickdetector(cd); count = count + 1 end end) end end
    end
    addLog(("🚪 تم إرسال أمر فتح لـ %d بوابة"):format(count))
end

local function toggleOfficeDoors()
    local count = 0
    for _, pr in ipairs(workspace:GetDescendants()) do if pr:IsA("ProximityPrompt") and pr.Parent and (pr.Parent.Name == "On" or pr.Parent.Name == "Off") then triggerPromptInstantly(pr); count = count + 1 end end
    addLog(("🔓 تم تبديل %d مفتاح"):format(count))
end

local function wearUniform(uniformName)
    local found = false; local cs = workspace:FindFirstChild("ClothingSystem") or workspace:FindFirstChild("UNIFORMS", true)
    if cs then for _, pr in ipairs(cs:GetDescendants()) do if pr:IsA("ProximityPrompt") then local txt = (pr.ActionText or "") .. " " .. (pr.ObjectText or "") .. " " .. (pr.Parent and pr.Parent.Name or ""); if txt:find(uniformName) then triggerPromptInstantly(pr); found = true end end end end
    addLog(found and ("👔 تم ارتداء: %s"):format(uniformName) or ("لم يتم العثور على: %s"):format(uniformName))
end

local function toggleFpsBoost()
    ST.fpsBoostOn = not ST.fpsBoostOn
    pcall(function()
        Lighting.GlobalShadows = not ST.fpsBoostOn
        for _, v in ipairs(workspace:GetDescendants()) do if v:IsA("BasePart") and v.Parent and not v.Parent:FindFirstChildWhichIsA("Humanoid") then v.Material = ST.fpsBoostOn and Enum.Material.SmoothPlastic or Enum.Material.Plastic end end
    end)
    addLog(ST.fpsBoostOn and "🚀 FPS Boost ON" or "إعادة الجرافيكس")
end

local function copyPos()
    local r = hrp(); if r then local s = ("Vector3.new(%.2f, %.2f, %.2f)"):format(r.Position.X, r.Position.Y, r.Position.Z); pcall(function() setclipboard(s) end); addLog("📋 نسخ: " .. s) end
end

addC(UIS.InputBegan:Connect(function(input, gp) if gp or not ST.clickTpOn then return end; if input.UserInputType == Enum.UserInputType.MouseButton1 and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then local mouse = pl:GetMouse(); if mouse and mouse.Hit and hrp() then pcall(function() char():PivotTo(CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))) end); addLog("انتقال بنقرة") end end end))

addC(RUN.Heartbeat:Connect(function()
    if ST.antiSitOn then local h = hum(); if h then if h.Sit then h.Sit = false end; local st = h:GetState(); if st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown then h:ChangeState(Enum.HumanoidStateType.GettingUp) end end end
end))

addC(RUN.Heartbeat:Connect(function()
    if _G.StopAutoFarm then return end
    local h, r = hum(), hrp(); if not h or not r or not alive() then return end
    if r.Position.Y < -100 then pcall(function() r.AssemblyLinearVelocity = Vector3.zero; r.AssemblyAngularVelocity = Vector3.zero; char():PivotTo(CFrame.new(CFG.SAFE_POS)) end) end
    if ST.customSpeedOn and not ST.handlingDrop and not ST.flyOn and not ST.busyWeather then h.WalkSpeed = ST.walkSpeed end
    if ST.superJumpOn then if h.UseJumpPower then h.JumpPower = ST.jumpPower else h.JumpHeight = ST.jumpPower*0.15 end end
    if ST.flyOn and flyBV and flyBG then
        flyBG.CFrame = cam.CFrame; local mv = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) or mobileFlyDir.W then mv = mv + cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) or mobileFlyDir.S then mv = mv - cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) or mobileFlyDir.A then mv = mv - cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) or mobileFlyDir.D then mv = mv + cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) or mobileFlyDir.Up then mv = mv + Vector3.new(0, 1, 0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or mobileFlyDir.Down then mv = mv - Vector3.new(0, 1, 0) end
        flyBV.Velocity = mv.Magnitude > 0 and mv.Unit * ST.flySpeed or Vector3.zero
    end
    if ST.noclipOn then local c = char(); if c then for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end end
    if ST.invisOn then local c = char(); if c then for _, d in ipairs(c:GetDescendants()) do if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" and d.Transparency < 1 then d.Transparency = 1 elseif d:IsA("BillboardGui") and d.Enabled then d.Enabled = false end end end end
    pcall(function() cam.FieldOfView = ST.fov end)
    if ST.antiFling then local vel = r.AssemblyLinearVelocity; if vel.Magnitude > 120 then r.AssemblyLinearVelocity = Vector3.zero; r.AssemblyAngularVelocity = Vector3.zero end end
    if ST.busyDrop and ST.busyDropSince > 0 and (tick() - ST.busyDropSince) > 60 then ST.busyDrop = false; ST.handlingDrop = false end
    if ST.busyCyber and ST.busyCyberSince > 0 and (tick() - ST.busyCyberSince) > 45 then ST.busyCyber = false; ST.busyCyberSince = 0 end
end))

addC(UIS.JumpRequest:Connect(function() if ST.infJumpOn and alive() then local h = hum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end end))
addC(pl.Idled:Connect(function() pcall(function() VU:CaptureController(); VU:ClickButton2(Vector2.zero) end) end))

local function getPlayerByName(name)
    if not name or name == "" then return nil end; name = name:lower()
    for _, p in ipairs(Players:GetPlayers()) do if p ~= pl and (p.Name:lower():find(name) or p.DisplayName:lower():find(name)) then return p end end
    return nil
end

local function aimbotLoop()
    task.spawn(function()
        while ST.aimbotOn and not _G.StopAutoFarm do
            task.wait(); local myHrp = hrp()
            if myHrp then
                local closest = nil; local dist = 2000
                for _, p in ipairs(Players:GetPlayers()) do if p ~= pl and p.Character then local head = p.Character:FindFirstChild("Head"); if head then local d = (head.Position - myHrp.Position).Magnitude; if d < dist then dist = d; closest = head end end end end
                if closest then cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = CFrame.new(cam.CFrame.Position, closest.Position) end
            end
        end
        cam.CameraType = Enum.CameraType.Custom
    end)
end

local function killAuraLoop()
    task.spawn(function()
        while ST.killAuraOn and not _G.StopAutoFarm do
            task.wait(0.1); local myHrp = hrp(); local c = char()
            if myHrp and c then
                local range = ST.auraRange or 15
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= pl and p.Character then
                        local th = p.Character:FindFirstChild("HumanoidRootPart"); local hum2 = p.Character:FindFirstChildWhichIsA("Humanoid")
                        if th and hum2 and hum2.Health > 0 and (th.Position - myHrp.Position).Magnitude < range then touchBoth(myHrp, th); if REM.GunInput then pcall(function() REM.GunInput:FireServer(th) end) end end
                    end
                end
            end
        end
    end)
end

-- هجوم تلقائي: يطلق على أقرب هدف بالسلاح (بدون لمس)
local function autoKillLoop()
    task.spawn(function()
        while ST.autoKillOn and not _G.StopAutoFarm do
            task.wait(0.1)
            local myHrp = hrp()
            if myHrp and REM.GunInput then
                local target, best = nil, ST.autoKillRange or 80
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= pl and p.Character then
                        local th = p.Character:FindFirstChild("HumanoidRootPart")
                        local hh = p.Character:FindFirstChildWhichIsA("Humanoid")
                        if th and hh and hh.Health > 0 then
                            local d = (th.Position - myHrp.Position).Magnitude
                            if d < best then best = d; target = th end
                        end
                    end
                end
                if target then pcall(function() REM.GunInput:FireServer(target) end) end
            end
        end
    end)
end

-- بناء الواجهة داخل دالة: يحل تجاوز حد 200 local register في النطاق الرئيسي
local function buildGui()
-- لوحة «الجليد الداكن»: كحلي هادئ + أزرق سماوي + لمسات نعناعية
local P = {
    bg      = Color3.fromRGB(9, 12, 20),
    panel   = Color3.fromRGB(15, 21, 34),
    card    = Color3.fromRGB(19, 27, 43),
    row     = Color3.fromRGB(27, 37, 56),
    accent  = Color3.fromRGB(59, 130, 246),
    cyan    = Color3.fromRGB(56, 189, 248),
    mint    = Color3.fromRGB(52, 211, 153),
    text    = Color3.fromRGB(231, 238, 249),
    muted   = Color3.fromRGB(139, 155, 180),
    rose    = Color3.fromRGB(244, 63, 94),
    gold    = Color3.fromRGB(250, 204, 21),
    off     = Color3.fromRGB(55, 68, 92),
    stroke  = Color3.fromRGB(45, 62, 90),
}
local function grad(parent, c1, c2, rot)
    local g = Instance.new("UIGradient", parent)
    g.Color = ColorSequence.new(c1, c2)
    g.Rotation = rot or 90
    return g
end
local gui = Instance.new("ScreenGui"); gui.Name = "FinalFixGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.Parent = pg
local mobGui = Instance.new("ScreenGui"); mobGui.Name = "FinalFixMobileBtn"; mobGui.ResetOnSpawn = false; mobGui.IgnoreGuiInset = true; mobGui.Parent = pg

local mobileFlyGui = Instance.new("ScreenGui", pg); mobileFlyGui.Name = "MobileFlyGui"; mobileFlyGui.ResetOnSpawn = false; mobileFlyGui.IgnoreGuiInset = true; mobileFlyGui.Enabled = false
local function mkFlyBtn(txt, x, y, key)
    local b = Instance.new("TextButton", mobileFlyGui); b.Size = UDim2.new(0, 50, 0, 50); b.Position = UDim2.new(0, x, 1, y); b.BackgroundColor3 = Color3.fromRGB(20, 30, 50); b.Text = txt; b.TextColor3 = Color3.fromRGB(125, 211, 252); b.Font = Enum.Font.GothamBold; b.TextSize = 18; b.BackgroundTransparency = 0.3
    Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
    b.MouseButton1Down:Connect(function() mobileFlyDir[key] = true end); b.MouseButton1Up:Connect(function() mobileFlyDir[key] = false end); b.MouseLeave:Connect(function() mobileFlyDir[key] = false end)
end
mkFlyBtn("↑", 80, -200, "W"); mkFlyBtn("↓", 80, -120, "S"); mkFlyBtn("←", 20, -160, "A"); mkFlyBtn("→", 140, -160, "D"); mkFlyBtn("⬆", 300, -200, "Up"); mkFlyBtn("⬇", 300, -120, "Down")

local floatBtn = Instance.new("TextButton", mobGui); floatBtn.Size = UDim2.new(0, 54, 0, 54); floatBtn.Position = UDim2.new(0, 14, 0.45, 0)
floatBtn.BackgroundColor3 = Color3.fromRGB(14, 24, 38); floatBtn.BackgroundTransparency = 0.15
floatBtn.Text = "v6.3"; floatBtn.TextSize = 12; floatBtn.TextColor3 = Color3.fromRGB(120, 235, 215)
floatBtn.Font = Enum.Font.GothamBold; floatBtn.Active = true; floatBtn.Draggable = true
Instance.new("UICorner", floatBtn).CornerRadius = UDim.new(1, 0)
local fStroke = Instance.new("UIStroke", floatBtn); fStroke.Thickness = 1.5; fStroke.Transparency = 0.15

local frame = Instance.new("Frame", gui); frame.Size = UDim2.new(0, 580, 0, 470); frame.Position = UDim2.new(0.5, -290, 0.5, -235)
frame.BackgroundColor3 = Color3.new(1, 1, 1); frame.BackgroundTransparency = 0.06
frame.BorderSizePixel = 0; frame.Active = true; frame.Draggable = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 16)
grad(frame, Color3.fromRGB(16, 22, 36), Color3.fromRGB(9, 12, 20), 90)
local mStroke = Instance.new("UIStroke", frame); mStroke.Thickness = 1.5; mStroke.Transparency = 0.25
mStroke.Color = P.stroke
addC(RUN.RenderStepped:Connect(function()
    -- نبضة خفيفة جداً على الحدود (بدون ألوان صارخة)
    local c = P.cyan:Lerp(P.accent, 0.5 + 0.5 * math.sin(tick() * 0.8))
    mStroke.Color = c:Lerp(P.stroke, 0.45); fStroke.Color = c
end))

local header = Instance.new("Frame", frame); header.Size = UDim2.new(1, 0, 0, 46)
header.BackgroundColor3 = Color3.new(1, 1, 1); header.BackgroundTransparency = 0.2
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 16)
grad(header, Color3.fromRGB(22, 31, 50), Color3.fromRGB(13, 18, 30), 0)
local title = Instance.new("TextLabel", header); title.Size = UDim2.new(1, -230, 0, 22); title.Position = UDim2.new(0, 16, 0, 7)
title.BackgroundTransparency = 1; title.Text = "AUTOFARM  v6.3"; title.TextColor3 = P.text
title.Font = Enum.Font.GothamBold; title.TextSize = 14; title.TextXAlignment = Enum.TextXAlignment.Left
local subtitle = Instance.new("TextLabel", header); subtitle.Size = UDim2.new(1, -230, 0, 14); subtitle.Position = UDim2.new(0, 16, 0, 26)
subtitle.BackgroundTransparency = 1; subtitle.Text = "LOCAS  •  Farm • Radar • Defense"; subtitle.TextColor3 = P.muted
subtitle.Font = Enum.Font.Gotham; subtitle.TextSize = 9; subtitle.TextXAlignment = Enum.TextXAlignment.Left

-- زر الدليل: يساعد اللاعب ما يتوه بين التبويبات
local helpBtn = Instance.new("TextButton", header); helpBtn.Size = UDim2.new(0, 28, 0, 28); helpBtn.Position = UDim2.new(1, -206, 0, 9)
helpBtn.BackgroundColor3 = P.row; helpBtn.BackgroundTransparency = 0.15; helpBtn.Text = "؟"
helpBtn.TextColor3 = P.cyan; helpBtn.Font = Enum.Font.GothamBold; helpBtn.TextSize = 15; helpBtn.BorderSizePixel = 0
Instance.new("UICorner", helpBtn).CornerRadius = UDim.new(0, 8)
local hStroke = Instance.new("UIStroke", helpBtn); hStroke.Color = P.stroke; hStroke.Thickness = 1; hStroke.Transparency = 0.3

local ytBtn = Instance.new("TextButton", header); ytBtn.Size = UDim2.new(0, 122, 0, 28); ytBtn.Position = UDim2.new(1, -172, 0, 9)
ytBtn.BackgroundColor3 = P.row; ytBtn.BackgroundTransparency = 0.1
ytBtn.Text = "▶ LocasBushee"; ytBtn.TextColor3 = Color3.fromRGB(255, 214, 226)
ytBtn.Font = Enum.Font.GothamBold; ytBtn.TextSize = 11; ytBtn.BorderSizePixel = 0
Instance.new("UICorner", ytBtn).CornerRadius = UDim.new(0, 8)
local ytStroke = Instance.new("UIStroke", ytBtn); ytStroke.Color = P.rose; ytStroke.Thickness = 1; ytStroke.Transparency = 0.35
ytBtn.MouseButton1Click:Connect(function()
    local url = "https://www.youtube.com/@LocasBushee"
    pcall(function() setclipboard(url) end)
    pcall(function() if typeof(openbrowser) == "function" then openbrowser(url) end end)
    addLog("📺 قناة يوتيوب: " .. url)
end)

local closeX = Instance.new("TextButton", header); closeX.Size = UDim2.new(0, 28, 0, 28); closeX.Position = UDim2.new(1, -36, 0, 9)
closeX.BackgroundColor3 = Color3.fromRGB(120, 34, 48); closeX.BackgroundTransparency = 0.25; closeX.Text = "✕"; closeX.TextColor3 = Color3.fromRGB(255, 205, 214)
closeX.Font = Enum.Font.GothamBold; closeX.TextSize = 13; Instance.new("UICorner", closeX).CornerRadius = UDim.new(0, 8)

local tabBar = Instance.new("Frame", frame); tabBar.Size = UDim2.new(1, -20, 0, 34); tabBar.Position = UDim2.new(0, 10, 0, 52)
tabBar.BackgroundColor3 = P.panel; tabBar.BackgroundTransparency = 0.25
Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", tabBar).Color = P.stroke

local tabNames = {"🏠 فارم", "🏃 حركة", "👁 كشف", "🗺 خريطة", "🧰 أدوات", "⚔ هجوم"}
local tabBtns = {}; local tabs = {}

for i, name in ipairs(tabNames) do
    local b = Instance.new("TextButton", tabBar); b.Size = UDim2.new(1/#tabNames - 0.006, 0, 1, -8); b.Position = UDim2.new((i-1)/#tabNames, 0, 0, 4)
    b.BackgroundColor3 = P.accent; b.BackgroundTransparency = 1
    b.Text = name; b.TextColor3 = P.muted; b.AutoButtonColor = false
    b.Font = Enum.Font.GothamBold; b.TextSize = 11; b.BorderSizePixel = 0; tabBtns[i] = b
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
    local t = Instance.new("ScrollingFrame", frame); t.Size = UDim2.new(1, -20, 1, -98); t.Position = UDim2.new(0, 10, 0, 88)
    t.BackgroundTransparency = 1; t.Visible = (i == 1); t.ScrollBarThickness = 3; t.CanvasSize = UDim2.new(0, 0, 0, 0)
    t.ScrollBarImageTransparency = 0.5; t.AutomaticCanvasSize = Enum.AutomaticSize.Y; tabs[i] = t
end

local function selectTab(n)
    for i = 1, #tabNames do
        tabs[i].Visible = (i == n)
        tabBtns[i].TextColor3 = (i == n) and P.text or P.muted
        tabBtns[i].BackgroundTransparency = (i == n) and 0.78 or 1
    end
end
for i, b in ipairs(tabBtns) do b.MouseButton1Click:Connect(function() selectTab(i) end) end
selectTab(1)

local function mkCard(parent, h, yOff, accent)
    local c = Instance.new("Frame", parent); c.Size = UDim2.new(1, 0, 0, h); c.Position = UDim2.new(0, 0, 0, yOff)
    c.BackgroundColor3 = P.card; c.BackgroundTransparency = 0.12
    c.BorderSizePixel = 0
    Instance.new("UICorner", c).CornerRadius = UDim.new(0, 12)
    local st = Instance.new("UIStroke", c); st.Color = accent or P.stroke; st.Thickness = 1; st.Transparency = 0.45
    local bar = Instance.new("Frame", c); bar.Size = UDim2.new(0, 2, 1, -16); bar.Position = UDim2.new(0, 7, 0, 8)
    bar.BackgroundColor3 = accent or P.accent; bar.BackgroundTransparency = 0.2; bar.BorderSizePixel = 0
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
    return c
end
local function mkLabel(parent, txt, x, y, w, h, sz)
    local l = Instance.new("TextLabel", parent); l.Size = UDim2.new(0, w, 0, h or 24); l.Position = UDim2.new(0, x, 0, y)
    l.BackgroundTransparency = 1; l.Text = txt; l.TextColor3 = P.text; l.Font = Enum.Font.GothamBold; l.TextSize = sz or 12
    l.TextXAlignment = Enum.TextXAlignment.Left; l.TextWrapped = false; l.TextTruncate = Enum.TextTruncate.AtEnd
    return l
end
-- مفتاح تشغيل أنيق: صف داكن + مفتاح صغير على اليمين (بدون تعبئة خضراء صارخة)
local function mkToggle(parent, txt, x, y, w, h, initOn, cb)
    local b = Instance.new("TextButton", parent); b.Size = UDim2.new(0, w, 0, h or 30); b.Position = UDim2.new(0, x, 0, y)
    b.BackgroundColor3 = P.row; b.BackgroundTransparency = 0.15
    b.Text = ""; b.AutoButtonColor = false; b.BorderSizePixel = 0; b.ClipsDescendants = true
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 9)
    local st = Instance.new("UIStroke", b); st.Thickness = 1; st.Color = P.stroke; st.Transparency = 0.35
    local lbl = Instance.new("TextLabel", b); lbl.Size = UDim2.new(1, -54, 1, 0); lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = txt; lbl.TextColor3 = P.text
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 11; lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextTruncate = Enum.TextTruncate.AtEnd
    local track = Instance.new("Frame", b); track.Size = UDim2.new(0, 34, 0, 18); track.Position = UDim2.new(1, -44, 0.5, -9)
    track.BorderSizePixel = 0; Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    local knob = Instance.new("Frame", track); knob.Size = UDim2.new(0, 14, 0, 14); knob.BorderSizePixel = 0
    knob.BackgroundColor3 = Color3.fromRGB(248, 250, 255)
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    local state = initOn
    local function apply()
        track.BackgroundColor3 = state and P.mint or P.off
        track.BackgroundTransparency = state and 0.05 or 0.4
        knob.Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
        lbl.TextColor3 = state and P.text or P.muted
        st.Color = state and P.mint or P.stroke
        st.Transparency = state and 0.6 or 0.35
    end
    apply()
    b.MouseButton1Click:Connect(function() state = not state; apply(); if cb then cb(state) end end)
end
local function mkAction(parent, txt, x, y, w, h, col, cb)
    local b = Instance.new("TextButton", parent); b.Size = UDim2.new(0, w, 0, h or 30); b.Position = UDim2.new(0, x, 0, y)
    b.BackgroundColor3 = col; b.BackgroundTransparency = 0.05; b.Text = txt; b.TextColor3 = Color3.fromRGB(248, 250, 255)
    b.Font = Enum.Font.GothamBold; b.TextSize = 11; b.BorderSizePixel = 0; b.AutoButtonColor = true
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 9)
    grad(b, col:Lerp(Color3.new(1, 1, 1), 0.14), col:Lerp(Color3.new(0, 0, 0), 0.3), 90)
    local st = Instance.new("UIStroke", b); st.Color = col:Lerp(Color3.new(1, 1, 1), 0.45); st.Thickness = 1; st.Transparency = 0.75
    if cb then b.MouseButton1Click:Connect(cb) end; return b
end

local t1 = tabs[1]
local c1a = mkCard(t1, 28, 0)
statsLbl = mkLabel(c1a, "جاهز", 12, 0, 530, 28, 11)
statsLbl.TextColor3 = P.cyan; statsLbl.Font = Enum.Font.GothamBold; statsLbl.TextSize = 10
statusLbl = Instance.new("TextLabel", t1); statusLbl.Size = UDim2.new(1, 0, 0, 20); statusLbl.Position = UDim2.new(0, 0, 0, 34)
statusLbl.BackgroundColor3 = P.panel; statusLbl.BackgroundTransparency = 0.1; statusLbl.Text = "خامل"; statusLbl.TextColor3 = P.mint
local stStroke = Instance.new("UIStroke", statusLbl); stStroke.Color = P.stroke; stStroke.Thickness = 1; stStroke.Transparency = 0.3
statusLbl.Font = Enum.Font.GothamBold; statusLbl.TextSize = 11; Instance.new("UICorner", statusLbl).CornerRadius = UDim.new(0, 7)

scroll = Instance.new("ScrollingFrame", t1); scroll.Size = UDim2.new(1, 0, 0, 132); scroll.Position = UDim2.new(0, 0, 0, 58)
scroll.BackgroundColor3 = Color3.fromRGB(7, 10, 17); scroll.BackgroundTransparency = 0.15
scroll.BorderSizePixel = 0; scroll.ScrollBarThickness = 3; scroll.ScrollBarImageTransparency = 0.5
Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 10)
local lgStroke = Instance.new("UIStroke", scroll); lgStroke.Color = P.stroke; lgStroke.Thickness = 1; lgStroke.Transparency = 0.45
logLbl = Instance.new("TextLabel", scroll); logLbl.Size = UDim2.new(1, -10, 0, 1); logLbl.Position = UDim2.new(0, 6, 0, 6)
logLbl.AutomaticSize = Enum.AutomaticSize.Y; logLbl.BackgroundTransparency = 1; logLbl.Text = ""; logLbl.TextColor3 = Color3.fromRGB(186, 205, 228); logLbl.Font = Enum.Font.Code; logLbl.TextSize = 12
logLbl.TextXAlignment = Enum.TextXAlignment.Left; logLbl.TextYAlignment = Enum.TextYAlignment.Top; logLbl.TextWrapped = true

local c1b = mkCard(t1, 146, 196)
mkToggle(c1b, "المهام", 8, 6, 266, 30, true, function(v)
    ST.autoMission = v
    if not v then
        ST.inProgress = false; ST.progressStart = nil
        setStatus("خامل", Color3.fromRGB(120,255,200))
        addLog("⏹️ المهام: إيقاف فوري")
    else addLog("▶️ المهام: تشغيل") end
end)
mkToggle(c1b, "الدروبات", 286, 6, 266, 30, true, function(v)
    ST.autoDrop = v
    if not v then
        ST.busyDrop = false; ST.handlingDrop = false; ST.busyStart = nil; ST.lastDropObj = nil
        addLog("⏹️ الدروبات: إيقاف فوري")
    else addLog("▶️ الدروبات: تشغيل") end
end)
mkToggle(c1b, "كهف السيبراني", 8, 40, 266, 30, true, function(v)
    ST.autoCyber = v
    if not v then
        ST.busyCyber = false; ST.busyCyberSince = nil
        addLog("⏹️ الكهف: إيقاف فوري")
    else addLog("▶️ الكهف: تشغيل") end
end)
mkToggle(c1b, "الانتقال التلقائي عند التعليق", 286, 40, 266, 30, true, function(v)
    ST.emergencyTpOn = v
    if not v then
        addLog("⏹️ الانتقال التلقائي: إيقاف")
    else addLog("▶️ الانتقال التلقائي: تشغيل (انتقال فوري بعد 1.5 ثانية)") end
end)
mkToggle(c1b, "جوائز وقت اللعب", 8, 74, 266, 30, true, function(v) ST.autoPlaytime = v end)
mkAction(c1b, "🌐 دخول الكهف (يدوي)", 286, 74, 266, 30, Color3.fromRGB(37, 70, 130), function() task.spawn(function() lootCyberCave(true) end) end)
mkAction(c1b, "🎁 استلام جوائز", 8, 108, 266, 30, Color3.fromRGB(30, 92, 74), claimRewardsManually)
mkAction(c1b, "⏹ إيقاف السكربت", 286, 108, 266, 30, Color3.fromRGB(132, 40, 52), shutdown)

local credit = mkLabel(t1, "📺 youtube.com/@LocasBushee", 0, 346, 560, 26, 11)
credit.TextColor3 = Color3.fromRGB(255, 205, 220)
credit.TextXAlignment = Enum.TextXAlignment.Center
credit.BackgroundTransparency = 0.15
credit.BackgroundColor3 = Color3.fromRGB(70, 26, 44)
credit.Size = UDim2.new(1, 0, 0, 26)
Instance.new("UICorner", credit).CornerRadius = UDim.new(0, 9)
local crStroke = Instance.new("UIStroke", credit); crStroke.Color = P.rose; crStroke.Thickness = 1; crStroke.Transparency = 0.65
local creditBtn = Instance.new("TextButton", credit); creditBtn.Size = UDim2.new(1, 0, 1, 0); creditBtn.BackgroundTransparency = 1; creditBtn.Text = ""
creditBtn.MouseButton1Click:Connect(function()
    local url = "https://www.youtube.com/@LocasBushee"
    pcall(function() setclipboard(url) end)
    pcall(function() if typeof(openbrowser) == "function" then openbrowser(url) end end)
    addLog("📺 قناة يوتيوب: " .. url)
end)

-- تبويب 2
local t2 = tabs[2]
local c2a = mkCard(t2, 74, 0)
mkLabel(c2a, "السرعة", 10, 4, 80, 24, 13)
local spdInput = Instance.new("TextBox", c2a); spdInput.Size = UDim2.new(0, 65, 0, 26); spdInput.Position = UDim2.new(0, 80, 0, 3)
spdInput.BackgroundColor3 = Color3.fromRGB(16, 23, 37); spdInput.Text = "16"; spdInput.TextColor3 = Color3.fromRGB(125, 211, 252)
spdInput.Font = Enum.Font.GothamBold; spdInput.TextSize = 14; spdInput.PlaceholderText = "رقم"; spdInput.ClearTextOnFocus = false
Instance.new("UICorner", spdInput).CornerRadius = UDim.new(0, 6); Instance.new("UIStroke", spdInput).Color = Color3.fromRGB(50, 65, 90)

local spdStat = mkLabel(c2a, "معطلة", 155, 4, 70, 24, 10); spdStat.TextColor3 = Color3.fromRGB(140, 150, 170)
mkToggle(c2a, "تثبيت", 420, 3, 120, 26, false, function(v)
    ST.customSpeedOn = v
    if v then local n = tonumber(spdInput.Text); if n and n >= 1 and n <= 500 then ST.walkSpeed = n; spdStat.Text = ("(%d)"):format(n); spdStat.TextColor3 = Color3.fromRGB(125, 211, 252)
    else ST.walkSpeed = 16 end
    else local h2 = hum(); if h2 then h2.WalkSpeed = 16 end; spdStat.Text = "معطلة"; spdStat.TextColor3 = Color3.fromRGB(140, 150, 170) end
end)
spdInput.FocusLost:Connect(function(enter) if enter then
    local n = tonumber(spdInput.Text); if n and n >= 1 and n <= 500 then
        ST.walkSpeed = n; ST.customSpeedOn = true; spdStat.Text = ("(%d)"):format(n); spdStat.TextColor3 = Color3.fromRGB(125, 211, 252); addLog(("سرعة: %d"):format(n))
end end end)
local spdRow = Instance.new("Frame", c2a); spdRow.Size = UDim2.new(1, -20, 0, 24); spdRow.Position = UDim2.new(0, 10, 0, 38); spdRow.BackgroundTransparency = 1
for idx, val in ipairs({16, 32, 48, 75, 100}) do
    local b = Instance.new("TextButton", spdRow); b.Size = UDim2.new(0.18, 0, 1, 0); b.Position = UDim2.new((idx-1)*0.205, 0, 0, 0)
    b.BackgroundColor3 = Color3.fromRGB(32, 43, 64); b.Text = tostring(val); b.TextColor3 = Color3.fromRGB(190, 208, 230)
    b.Font = Enum.Font.GothamBold; b.TextSize = 12; Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.MouseButton1Click:Connect(function() spdInput.Text = tostring(val); ST.walkSpeed = val; ST.customSpeedOn = true
        spdStat.Text = ("(%d)"):format(val); spdStat.TextColor3 = Color3.fromRGB(125, 211, 252); addLog(("سرعة: %d"):format(val)) end)
end

local c2b = mkCard(t2, 74, 82)
mkLabel(c2b, "سوبر جمب", 10, 4, 120, 24, 13)
local jmpStat = mkLabel(c2b, "(50)", 130, 4, 60, 24, 10); jmpStat.TextColor3 = Color3.fromRGB(140, 150, 170)
mkToggle(c2b, "سوبر جمب", 420, 3, 120, 26, false, function(v) ST.superJumpOn = v
    if not v then local h2 = hum(); if h2 then if h2.UseJumpPower then h2.JumpPower = 50 else h2.JumpHeight = 7.2 end end end
end)
local jmpRow = Instance.new("Frame", c2b); jmpRow.Size = UDim2.new(1, -20, 0, 24); jmpRow.Position = UDim2.new(0, 10, 0, 38); jmpRow.BackgroundTransparency = 1
for idx, val in ipairs({50, 80, 120, 160, 200}) do
    local b = Instance.new("TextButton", jmpRow); b.Size = UDim2.new(0.18, 0, 1, 0); b.Position = UDim2.new((idx-1)*0.205, 0, 0, 0)
    b.BackgroundColor3 = Color3.fromRGB(32, 43, 64); b.Text = tostring(val); b.TextColor3 = Color3.fromRGB(190, 208, 230)
    b.Font = Enum.Font.GothamBold; b.TextSize = 12; Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.MouseButton1Click:Connect(function() ST.jumpPower = val; ST.superJumpOn = true
        jmpStat.Text = ("(%d)"):format(val); jmpStat.TextColor3 = Color3.fromRGB(125, 211, 252); addLog(("قفز: %d"):format(val)) end)
end

local c2c = mkCard(t2, 36, 164)
mkLabel(c2c, "الطيران + Noclip (يدعم الجوال)", 10, 6, 260, 24, 12)
mkToggle(c2c, "طيران", 420, 4, 120, 26, false, function(v) if v then startFly() else stopFly() end; addLog(v and "طيران: ON" or "طيران: OFF") end)

local c2d = mkCard(t2, 36, 208)
mkLabel(c2d, "اختراق الجدران (Noclip)", 10, 6, 260, 24, 12)
mkToggle(c2d, "Noclip", 420, 4, 120, 26, false, function(v) setNoclip(v); addLog(v and "Noclip: ON" or "Noclip: OFF") end)

local c2e = mkCard(t2, 36, 252)
mkLabel(c2e, "قفز لا نهائي", 10, 6, 260, 24, 12)
mkToggle(c2e, "Inf Jump", 420, 4, 120, 26, false, function(v) ST.infJumpOn = v; addLog(v and "Inf Jump: ON" or "Inf Jump: OFF") end)

local c2f = mkCard(t2, 40, 296)
mkLabel(c2f, "انتقال لإحداثيات", 10, 8, 140, 24, 12)
local tpX = Instance.new("TextBox", c2f); tpX.Size = UDim2.new(0, 55, 0, 24); tpX.Position = UDim2.new(0, 160, 0, 8)
tpX.BackgroundColor3 = Color3.fromRGB(16, 23, 37); tpX.Text = "0"; tpX.TextColor3 = Color3.fromRGB(125, 211, 252)
tpX.Font = Enum.Font.Code; tpX.TextSize = 11; tpX.PlaceholderText = "X"; Instance.new("UICorner", tpX).CornerRadius = UDim.new(0, 4)
local tpY = tpX:Clone(); tpY.Parent = c2f; tpY.Position = UDim2.new(0, 225, 0, 8); tpY.PlaceholderText = "Y"; tpY.Text = "10"
local tpZ = tpX:Clone(); tpZ.Parent = c2f; tpZ.Position = UDim2.new(0, 290, 0, 8); tpZ.PlaceholderText = "Z"; tpZ.Text = "0"
mkAction(c2f, "انتقال", 420, 6, 120, 28, Color3.fromRGB(35, 80, 140), function()
    local x, y, z = tonumber(tpX.Text), tonumber(tpY.Text), tonumber(tpZ.Text)
    if x and y and z then pcall(function() char():PivotTo(CFrame.new(x, y, z)) end); addLog(("انتقال: %.0f,%.0f,%.0f"):format(x, y, z))
    else addLog("إحداثيات خاطئة") end
end)

local c2g = mkCard(t2, 40, 342, P.gold)
mkLabel(c2g, "الانتقال التلقائي عند التعليق (فوري بعد 1.5 ثانية — ثم مباشرة للهدف)", 10, 8, 350, 24, 11)
mkToggle(c2g, "انتقال", 420, 6, 120, 28, true, function(v)
    ST.emergencyTpOn = v
    addLog(v and "🚑 الانتقال التلقائي: ON" or "الانتقال التلقائي: OFF")
end)

-- تبويب 3
local t3 = tabs[3]
local c3a = mkCard(t3, 44, 0)
mkLabel(c3a, "كشف اللاعبين (ESP)", 10, 10, 360, 24, 12)
mkToggle(c3a, "ESP لاعبين", 390, 8, 160, 28, false, function(v)
    ST.espPlayers = v
    if v then task.spawn(updatePlayerESP); addLog("ESP لاعبين: ON")
    else for _, h in pairs(espHL) do pcall(function() h:Destroy() end) end; espHL = {}; for _, b in pairs(espTags) do pcall(function() b:Destroy() end) end; espTags = {}; addLog("ESP لاعبين: OFF") end
end)

local c3b = mkCard(t3, 44, 52)
mkLabel(c3b, "كشف الدروبات (يدعم الفولدرات)", 10, 10, 360, 24, 12)
mkToggle(c3b, "ESP دروبات", 390, 8, 160, 28, false, function(v)
    ST.espDrops = v
    if v then task.spawn(updateDropESP); addLog("ESP دروبات: ON")
    else for _, h in pairs(espDropHL) do pcall(function() h:Destroy() end) end; espDropHL = {}; for _, b in pairs(espDropTags) do pcall(function() b:Destroy() end) end; espDropTags = {}; addLog("ESP دروبات: OFF") end
end)

local c3d = mkCard(t3, 44, 104)
mkLabel(c3d, "إضاءة كاملة (Fullbright)", 10, 10, 360, 24, 12)
mkToggle(c3d, "Fullbright", 390, 8, 160, 28, false, function(v) ST.fullbright = v; if v then enableFullbright() else disableFullbright() end; addLog(v and "Fullbright: ON" or "Fullbright: OFF") end)

local c3e = mkCard(t3, 62, 156)
mkLabel(c3e, "مجال الرؤية (FOV)", 10, 6, 160, 24, 12)
local fovLbl = mkLabel(c3e, "70", 170, 6, 40, 24, 12); fovLbl.TextColor3 = Color3.fromRGB(125, 211, 252)
local fovRow = Instance.new("Frame", c3e); fovRow.Size = UDim2.new(1, -20, 0, 24); fovRow.Position = UDim2.new(0, 10, 0, 32); fovRow.BackgroundTransparency = 1
for idx, val in ipairs({70, 90, 100, 110, 120}) do
    local b = Instance.new("TextButton", fovRow); b.Size = UDim2.new(0.18, 0, 1, 0); b.Position = UDim2.new((idx-1)*0.205, 0, 0, 0)
    b.BackgroundColor3 = Color3.fromRGB(32, 43, 64); b.Text = tostring(val); b.TextColor3 = Color3.fromRGB(190, 208, 230)
    b.Font = Enum.Font.GothamBold; b.TextSize = 12; Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.MouseButton1Click:Connect(function() ST.fov = val; fovLbl.Text = tostring(val); addLog(("FOV: %d"):format(val)) end)
end

local c3f = mkCard(t3, 44, 226)
mkLabel(c3f, "الاختفاء التام", 10, 10, 360, 24, 12)
mkToggle(c3f, "اختفاء", 390, 8, 160, 28, false, function(v) ST.invisOn = v; updateInvis(); addLog(v and "اختفاء: ON" or "اختفاء: OFF") end)

-- تبويب 4 (الرادار كامل)
local t4 = tabs[4]
local radarCard = mkCard(t4, 250, 0)
local radarFrame = Instance.new("Frame", radarCard)
radarFrame.Size = UDim2.new(0, 240, 0, 240); radarFrame.Position = UDim2.new(0, 6, 0, 5)
radarFrame.BackgroundColor3 = Color3.fromRGB(7, 11, 19); radarFrame.ClipsDescendants = true
Instance.new("UICorner", radarFrame).CornerRadius = UDim.new(0, 10)
local rdrStroke = Instance.new("UIStroke", radarFrame); rdrStroke.Color = P.cyan; rdrStroke.Thickness = 1.2; rdrStroke.Transparency = 0.25

local crossH = Instance.new("Frame", radarFrame); crossH.Size = UDim2.new(1, 0, 0, 1); crossH.Position = UDim2.new(0, 0, 0.5, 0); crossH.BackgroundColor3 = Color3.fromRGB(32, 56, 82); crossH.BorderSizePixel = 0
local crossV = Instance.new("Frame", radarFrame); crossV.Size = UDim2.new(0, 1, 1, 0); crossV.Position = UDim2.new(0.5, 0, 0, 0); crossV.BackgroundColor3 = Color3.fromRGB(32, 56, 82); crossV.BorderSizePixel = 0
local circleRing = Instance.new("Frame", radarFrame); circleRing.Size = UDim2.new(0, 150, 0, 150); circleRing.Position = UDim2.new(0.5, -75, 0.5, -75); circleRing.BackgroundTransparency = 1
Instance.new("UICorner", circleRing).CornerRadius = UDim.new(1, 0); local crk = Instance.new("UIStroke", circleRing); crk.Color = Color3.fromRGB(40, 68, 96); crk.Thickness = 1

local myBlip = Instance.new("Frame", radarFrame); myBlip.Size = UDim2.new(0, 8, 0, 8); myBlip.Position = UDim2.new(0.5, -4, 0.5, -4)
myBlip.BackgroundColor3 = P.mint; myBlip.ZIndex = 5; Instance.new("UICorner", myBlip).CornerRadius = UDim.new(1, 0)

local inspectCard = Instance.new("Frame", radarCard); inspectCard.Size = UDim2.new(1, -260, 1, -10); inspectCard.Position = UDim2.new(0, 254, 0, 5)
inspectCard.BackgroundColor3 = P.card; inspectCard.BackgroundTransparency = 0.2; Instance.new("UICorner", inspectCard).CornerRadius = UDim.new(0, 10)
local insStk = Instance.new("UIStroke", inspectCard); insStk.Color = P.stroke

local targetNameLbl = mkLabel(inspectCard, "اختر لاعباً...", 10, 4, 290, 22, 12); targetNameLbl.TextColor3 = P.cyan
local rankTextLbl = mkLabel(inspectCard, "الرتبة: --", 10, 28, 290, 20, 11); rankTextLbl.TextColor3 = Color3.fromRGB(206, 219, 238)

local rankCompBadge = Instance.new("TextLabel", inspectCard); rankCompBadge.Size = UDim2.new(1, -20, 0, 24); rankCompBadge.Position = UDim2.new(0, 10, 0, 52)
rankCompBadge.BackgroundColor3 = P.row; rankCompBadge.Text = "⚖️ مقارنة الرتبة: --"; rankCompBadge.TextColor3 = P.muted
rankCompBadge.Font = Enum.Font.GothamBold; rankCompBadge.TextSize = 11; Instance.new("UICorner", rankCompBadge).CornerRadius = UDim.new(0, 7)

local distLbl = mkLabel(inspectCard, "المسافة: -- متر", 10, 80, 290, 18, 10); distLbl.TextColor3 = P.muted

local actY = 104
mkAction(inspectCard, "🚀 انتقال إليه", 8, actY, 135, 28, Color3.fromRGB(30, 85, 145), function()
    local p = ST.radarSelectedPlr; local tc = p and p.Character; local th = tc and tc:FindFirstChild("HumanoidRootPart")
    if th and char() then pcall(function() char():PivotTo(CFrame.new(th.Position + Vector3.new(0, 0, 3))) end); addLog(("🚀 انتقال إلى: %s"):format(p.DisplayName))
    else addLog("اللاعب غير متواجد") end
end)
mkAction(inspectCard, "👮‍♂️ كلبشة", 150, actY, 135, 28, Color3.fromRGB(140, 70, 25), function() cuffPlayer(ST.radarSelectedPlr) end)
mkAction(inspectCard, "👁️ مراقبة", 8, actY + 34, 135, 28, Color3.fromRGB(70, 40, 130), function() toggleSpectate(ST.radarSelectedPlr) end)
mkAction(inspectCard, "📍 تتبع", 150, actY + 34, 135, 28, Color3.fromRGB(30, 110, 80), function()
    local p = ST.radarSelectedPlr
    if p and p.Character then
        local oldHl = p.Character:FindFirstChild("RadarTrackHL")
        if oldHl then oldHl:Destroy(); addLog("إلغاء تتبع: "..p.DisplayName)
        else local h = Instance.new("Highlight"); h.Name = "RadarTrackHL"; h.FillColor = Color3.fromRGB(0, 255, 255); h.FillTransparency = 0.4; h.OutlineColor = Color3.fromRGB(255, 255, 0); h.Adornee = p.Character; h.Parent = p.Character; addLog("📍 تتبع: "..p.DisplayName) end
    end
end)

local pQuickFrame = Instance.new("ScrollingFrame", t4); pQuickFrame.Size = UDim2.new(1, 0, 0, 112); pQuickFrame.Position = UDim2.new(0, 0, 0, 256)
pQuickFrame.BackgroundColor3 = P.panel; pQuickFrame.BackgroundTransparency = 0.1; pQuickFrame.ScrollBarThickness = 3; Instance.new("UICorner", pQuickFrame).CornerRadius = UDim.new(0, 8)

local function updateInspectorForPlayer(targetPlr)
    if not targetPlr then return end
    ST.radarSelectedPlr = targetPlr; targetNameLbl.Text = ("%s (@%s)"):format(targetPlr.DisplayName, targetPlr.Name)
    local myRankText, myRankNum = getPlayerRankInfo(pl); local tRankText, tRankNum = getPlayerRankInfo(targetPlr)
    rankTextLbl.Text = ("رتبته: %s (رتبتك: %s)"):format(tRankText, myRankText)
    if tRankNum > myRankNum then rankCompBadge.Text = "🔺 أعلى منك رتبة!"; rankCompBadge.TextColor3 = Color3.fromRGB(255, 80, 80); rankCompBadge.BackgroundColor3 = Color3.fromRGB(50, 15, 20)
    elseif tRankNum < myRankNum and tRankNum > 0 then rankCompBadge.Text = "🔻 أقل منك رتبة"; rankCompBadge.TextColor3 = Color3.fromRGB(100, 255, 120); rankCompBadge.BackgroundColor3 = Color3.fromRGB(15, 45, 25)
    else rankCompBadge.Text = "⚖️ نفس رتبتك"; rankCompBadge.TextColor3 = Color3.fromRGB(255, 220, 100); rankCompBadge.BackgroundColor3 = Color3.fromRGB(45, 40, 15) end
    local tc = targetPlr.Character; local th = tc and tc:FindFirstChild("HumanoidRootPart"); local r = hrp()
    if th and r then distLbl.Text = ("المسافة: %.0f متر"):format((th.Position - r.Position).Magnitude) else distLbl.Text = "المسافة: غير معروف" end
end

local function refreshRadarPlayerList()
    for _, c in ipairs(pQuickFrame:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    local yOff = 4
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= pl then
            local tRankText = getPlayerRankInfo(other)
            local b = Instance.new("TextButton", pQuickFrame); b.Size = UDim2.new(1, -10, 0, 26); b.Position = UDim2.new(0, 5, 0, yOff)
            b.BackgroundColor3 = P.row; b.BackgroundTransparency = 0.2; b.Text = ("%s | رتبة: %s"):format(other.DisplayName, tRankText)
            b.TextColor3 = Color3.fromRGB(214, 226, 244); b.Font = Enum.Font.Gotham; b.TextSize = 11; b.TextXAlignment = Enum.TextXAlignment.Left
            Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
            b.MouseButton1Click:Connect(function() updateInspectorForPlayer(other) end)
            yOff = yOff + 30
        end
    end
    pQuickFrame.CanvasSize = UDim2.new(0, 0, 0, yOff + 6)
end
refreshRadarPlayerList(); addC(Players.PlayerAdded:Connect(refreshRadarPlayerList)); addC(Players.PlayerRemoving:Connect(refreshRadarPlayerList))

local blipPool = {}
local dropBlips = {}

task.spawn(function()
    while not _G.StopAutoFarm do
        task.wait(0.1); if not tabs[4].Visible then continue end
        local r = hrp(); if not r then continue end
        local cx, cy = 120, 120; local radarScale = 0.35; local maxRange = 320
        for _, other in ipairs(Players:GetPlayers()) do
            if other ~= pl then
                local tc = other.Character; local th = tc and tc:FindFirstChild("HumanoidRootPart"); local blip = blipPool[other]
                local otherHum = tc and tc:FindFirstChildWhichIsA("Humanoid")
                if th and otherHum and otherHum.Health > 0 then
                    local dx = th.Position.X - r.Position.X; local dz = th.Position.Z - r.Position.Z
                    local dist = math.sqrt(dx*dx + dz*dz)
                    if dist <= maxRange then
                        local px = math.clamp(cx + (dx * radarScale), 6, 230); local py = math.clamp(cy + (dz * radarScale), 6, 230)
                        if not blip then blip = Instance.new("TextButton", radarFrame); blip.Size = UDim2.new(0, 8, 0, 8); blip.BackgroundColor3 = Color3.fromRGB(0, 170, 255); blip.Text = ""; blip.BorderSizePixel = 0; Instance.new("UICorner", blip).CornerRadius = UDim.new(0, 2); blip.MouseButton1Click:Connect(function() updateInspectorForPlayer(other) end); blipPool[other] = blip end
                        blip.Position = UDim2.new(0, px - 4, 0, py - 4); blip.Visible = true; blip.BackgroundColor3 = (ST.radarSelectedPlr == other) and P.gold or P.accent
                    elseif blip then blip.Visible = false end
                elseif blip then blip.Visible = false end
            end
        end
        local function addDropBlip(obj)
            local part = getPart(obj); if not part then return end
            local dx = part.Position.X - r.Position.X; local dz = part.Position.Z - r.Position.Z
            local px = math.clamp(cx + (dx * radarScale), 6, 230); local py = math.clamp(cy + (dz * radarScale), 6, 230)
            local dBlip = dropBlips[obj]
            if not dBlip then dBlip = Instance.new("Frame", radarFrame); dBlip.Size = UDim2.new(0, 8, 0, 8); dBlip.BackgroundColor3 = P.gold; Instance.new("UICorner", dBlip).CornerRadius = UDim.new(0, 2); dropBlips[obj] = dBlip end
            dBlip.Position = UDim2.new(0, px - 4, 0, py - 4); dBlip.Visible = true
        end
        for _, n in ipairs(CFG.DROP_NAMES) do
            local dropObj = workspace:FindFirstChild(n)
            if dropObj then if dropObj:IsA("Folder") then for _, ch in ipairs(dropObj:GetChildren()) do addDropBlip(ch) end else addDropBlip(dropObj) end end
        end
    end
end)

-- تبويب 5 (الأدوات - كل شي)
local t5 = tabs[5]
local c5_def = mkCard(t5, 78, 0)
mkLabel(c5_def, "🛡️ أنظمة الحماية", 10, 6, 320, 20, 12)
mkToggle(c5_def, "مضاد الكلبشة", 10, 36, 170, 30, true, function(v) ST.antiCuff = v; addLog(v and "🛡️ مضاد الكلبشة ON" or "إيقاف") end)
mkToggle(c5_def, "درع تلقائي", 190, 36, 170, 30, true, function(v) ST.autoArmorDefense = v; addLog(v and "🛡️ درع تلقائي ON" or "إيقاف") end)
mkAction(c5_def, "🛡️ أخذ درع الآن", 370, 36, 175, 30, Color3.fromRGB(30, 100, 140), takeArmor)

local c5a = mkCard(t5, 78, 86)
mkLabel(c5a, "🔫 أزرار الماب", 10, 6, 320, 20, 12)
mkAction(c5a, "🔫 سحب أسلحة", 10, 36, 170, 30, Color3.fromRGB(130, 80, 25), grabWeapons)
mkAction(c5a, "🚪 فتح البوابات", 190, 36, 170, 30, Color3.fromRGB(25, 110, 65), openAllGates)
mkAction(c5a, "🔓 فتح المكاتب", 370, 36, 175, 30, Color3.fromRGB(90, 45, 120), toggleOfficeDoors)

local c5b = mkCard(t5, 78, 172)
mkLabel(c5b, "👔 تغيير الملابس", 10, 6, 320, 20, 12)
mkAction(c5b, "👔 زي مستشار الملك", 10, 36, 260, 30, Color3.fromRGB(110, 85, 25), function() wearUniform("مستشار الملك") end)
mkAction(c5b, "👔 زي الضباط", 280, 36, 265, 30, Color3.fromRGB(40, 75, 120), function() wearUniform("ضباط") end)

local c5c = mkCard(t5, 38, 258)
mkLabel(c5c, "انتقال بالماوس (Ctrl + كليك)", 10, 7, 350, 24, 11)
mkToggle(c5c, "Click TP", 390, 5, 160, 26, false, function(v) ST.clickTpOn = v; addLog(v and "Click TP: ON" or "Click TP: OFF") end)

local c5d = mkCard(t5, 38, 304)
mkLabel(c5d, "Anti-Fling", 10, 7, 350, 24, 11)
mkToggle(c5d, "Anti-Fling", 390, 5, 160, 26, false, function(v) ST.antiFling = v; addLog(v and "Anti-Fling: ON" or "Anti-Fling: OFF") end)

local c5e = mkCard(t5, 38, 350)
mkLabel(c5e, "منع الجلوس (Anti-Sit)", 10, 7, 350, 24, 11)
mkToggle(c5e, "Anti-Sit", 390, 5, 160, 26, false, function(v) ST.antiSitOn = v; addLog(v and "Anti-Sit: ON" or "Anti-Sit: OFF") end)

local c5f = mkCard(t5, 38, 396)
mkLabel(c5f, "FPS Boost", 10, 7, 350, 24, 11)
mkAction(c5f, "🚀 FPS Boost", 420, 5, 120, 26, Color3.fromRGB(30, 100, 70), toggleFpsBoost)

local c5g = mkCard(t5, 38, 442)
mkLabel(c5g, "أدوات مساعدة", 10, 7, 350, 24, 11)
mkAction(c5g, "📋 نسخ الموقع", 290, 5, 120, 26, Color3.fromRGB(45, 75, 130), copyPos)
mkAction(c5g, "🔄 ريسباون", 420, 5, 120, 26, Color3.fromRGB(130, 35, 35), function() ST.forceReset = true; task.delay(8, function() ST.forceReset = false end); local h = hum(); if h then h.Health = 0; addLog("Reset") end end)

local c5h = mkCard(t5, 38, 488)
mkLabel(c5h, "السيرفرات", 10, 7, 250, 24, 11)
mkAction(c5h, "سيرفر جديد", 290, 5, 120, 26, Color3.fromRGB(100, 70, 20), function() addLog("جاري الانتقال..."); task.wait(0.5); pcall(function() TS:Teleport(game.PlaceId) end) end)
mkAction(c5h, "Rejoin", 420, 5, 120, 26, Color3.fromRGB(60, 80, 120), function() addLog("إعادة دخول..."); task.wait(0.5); pcall(function() TS:TeleportToPlaceInstance(game.PlaceId, game.JobId) end) end)

local c5i = mkCard(t5, 118, 534, P.mint)
mkLabel(c5i, "🚫 الحماية المتقدمة", 10, 6, 320, 20, 12)
mkToggle(c5i, "منع الرصاص", 10, 36, 170, 30, true, function(v) ST.antiBullet = v; addLog(v and "🚫 منع الرصاص ON" or "منع الرصاص: OFF") end)
mkToggle(c5i, "منع السجن", 190, 36, 170, 30, true, function(v)
    ST.antiJail = v; ST.lastSafePos = nil; ST.jailAttempts = 0; jailCacheAt = 0
    addLog(v and "🚫 منع السجن ON" or "منع السجن: OFF")
end)
mkToggle(c5i, "إخفاء الاسم", 370, 36, 175, 30, false, function(v)
    ST.hideName = v
    if v then applyHideName() else restoreName() end
    addLog(v and "🕵️ إخفاء الاسم: ON (فوق الرأس فقط)" or "إخفاء الاسم: OFF")
end)
mkAction(c5i, "🔎 فحص الحماية الآن", 10, 76, 260, 30, Color3.fromRGB(50, 90, 150), function()
    local h = hum(); local c = char(); local bad = 0
    if c then
        for _, d in ipairs(c:GetDescendants()) do
            if (d:IsA("Tool") or d:IsA("Weld") or d:IsA("WeldConstraint") or d:IsA("BodyVelocity") or d:IsA("BodyPosition")) and isCuffName(d.Name) then bad = bad + 1 end
        end
    end
    addLog(("🛡️ كلبشة: %s | قيود حالية: %d"):format(ST.antiCuff and "ON" or "OFF", bad))
    addLog(("💉 رصاص: %s | الصحة: %.0f/%.0f"):format(ST.antiBullet and "ON" or "OFF", h and h.Health or 0, h and h.MaxHealth or 0))
    addLog(("🚔 سجن: %s | فرار آمن: %s"):format(ST.antiJail and "ON" or "OFF", ST.lastSafePos and "جاهز" or "--"))
end)
mkAction(c5i, "🧹 تنظيف وإصلاح فوري", 280, 76, 265, 30, Color3.fromRGB(30, 120, 100), function()
    pcall(runAntiCuff); pcall(restoreHumanoid, hum()); pcall(healNow, "فحص يدوي")
    addLog("✅ تم تنظيف القيود وإصلاح الشخصية")
end)

-- تبويب 6: الهجوم (10 ميزات)
local t6 = tabs[6]
local c6a = mkCard(t6, 80, 0)
mkLabel(c6a, "🎯 إعدادات الهدف (الاسم)", 10, 6, 250, 20, 12)
local targetInput = Instance.new("TextBox", c6a); targetInput.Size = UDim2.new(0, 180, 0, 30); targetInput.Position = UDim2.new(0, 10, 0, 30)
targetInput.BackgroundColor3 = Color3.fromRGB(16, 23, 37); targetInput.Text = ""; targetInput.PlaceholderText = "اسم اللاعب..."
targetInput.TextColor3 = Color3.fromRGB(125, 211, 252); targetInput.Font = Enum.Font.GothamBold; targetInput.TextSize = 14
Instance.new("UICorner", targetInput).CornerRadius = UDim.new(0, 6)

mkAction(c6a, "🔫 كلبشة بالاسم", 200, 30, 160, 30, Color3.fromRGB(140, 70, 25), function()
    local p = getPlayerByName(targetInput.Text)
    if p then cuffPlayer(p) else addLog("لم يتم العثور على اللاعب") end
end)
mkAction(c6a, "🚀 سحب اللاعب", 370, 30, 175, 30, Color3.fromRGB(30, 85, 145), function()
    local p = getPlayerByName(targetInput.Text)
    if p and REM.BringPlayer then pcall(function() REM.BringPlayer:FireServer(p) end); addLog("سحب "..p.DisplayName) end
end)

local c6b = mkCard(t6, 80, 88)
mkLabel(c6b, "⚔️ ميزات الهجوم التلقائي", 10, 6, 250, 20, 12)
mkToggle(c6b, "Aimbot (تصويب)", 10, 30, 180, 30, false, function(v) ST.aimbotOn = v; if v then aimbotLoop(); addLog("🎯 Aimbot ON") end end)
mkToggle(c6b, "Kill Aura (قتل قريب)", 200, 30, 180, 30, false, function(v) ST.killAuraOn = v; if v then killAuraLoop(); addLog("⚔️ Kill Aura ON") end end)
mkAction(c6b, "☠️ سجن الكل", 390, 30, 155, 30, Color3.fromRGB(160, 30, 30), function()
    for _, p in ipairs(Players:GetPlayers()) do if p ~= pl and REM.AutoJail then pcall(function() REM.AutoJail:FireServer(p) end) end end
    addLog("☠️ سجن الكل")
end)

local c6c = mkCard(t6, 80, 176)
mkLabel(c6c, "🌪️ تخريب / إزعاج", 10, 6, 250, 20, 12)
mkAction(c6c, "🔄 سحب الكل", 10, 30, 130, 30, Color3.fromRGB(90, 45, 120), function()
    for _, p in ipairs(Players:GetPlayers()) do if p ~= pl and REM.BringPlayer then pcall(function() REM.BringPlayer:FireServer(p) end) end end
    addLog("سحب الكل")
end)
mkAction(c6c, "🔥 تفجير الكل (Spam)", 150, 30, 180, 30, Color3.fromRGB(200, 50, 50), function()
    task.spawn(function()
        for i=1,20 do
            local myHrp = hrp(); if not myHrp then break end
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= pl and p.Character then
                    local th = p.Character:FindFirstChild("HumanoidRootPart")
                    if th then touchBoth(myHrp, th); if REM.GunInput then pcall(function() REM.GunInput:FireServer(th) end) end end
                end
            end
            task.wait(0.1)
        end
    end)
    addLog("🔥 تفجير الكل")
end)
mkAction(c6c, "👮‍♂️ Spam كلبشة", 340, 30, 205, 30, Color3.fromRGB(140, 70, 25), function()
    task.spawn(function()
        for i=1,10 do
            for _, p in ipairs(Players:GetPlayers()) do if p ~= pl and REM.EquipCuff then pcall(function() REM.EquipCuff:FireServer(p) end) end end
            task.wait(0.1)
        end
    end)
    addLog("👮‍♂️ Spam كلبشة")
end)

local c6d = mkCard(t6, 80, 264)
mkLabel(c6d, "🎁 إضافي: سحب اللاعبين والمراقبة", 10, 6, 320, 20, 12)
mkAction(c6d, "🚀 سحب الكل فوري", 10, 30, 180, 30, Color3.fromRGB(50, 100, 180), function()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= pl and p.Character then local th = p.Character:FindFirstChild("HumanoidRootPart"); if th and hrp() then pcall(function() p.Character:PivotTo(CFrame.new(hrp().Position + Vector3.new(0, 0, -5))) end) end end
    end
    addLog("🚀 سحب كامل")
end)
mkAction(c6d, "👁️ مراقبة الكاميرا", 200, 30, 180, 30, Color3.fromRGB(70, 40, 130), function()
    local p = ST.radarSelectedPlr
    if p then toggleSpectate(p) else addLog("اختر لاعباً من الرادار") end
end)
mkAction(c6d, "💀 Kill القريب", 390, 30, 155, 30, Color3.fromRGB(120, 20, 20), function()
    local myHrp = hrp()
    if myHrp then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= pl and p.Character then
                local th = p.Character:FindFirstChild("HumanoidRootPart")
                if th and (th.Position - myHrp.Position).Magnitude < 20 then touchBoth(myHrp, th); if REM.GunInput then pcall(function() REM.GunInput:FireServer(th) end) end end
            end
        end
    end
    addLog("💀 Kill القريب")
end)

-- ⚔️ بطاقة الهجوم المتقدم (جديدة)
local c6e = mkCard(t6, 116, 352, P.rose)
mkLabel(c6e, "⚔️ هجوم متقدم", 10, 6, 250, 20, 12)
mkToggle(c6e, "Auto Kill (أقرب هدف)", 10, 30, 205, 30, false, function(v)
    ST.autoKillOn = v
    if v then task.spawn(autoKillLoop); addLog("⚔️ Auto Kill ON") else addLog("Auto Kill: OFF") end
end)
mkLabel(c6e, "مدى الأورا:", 225, 34, 80, 22, 11)
local auraLbl = mkLabel(c6e, tostring(ST.auraRange), 305, 34, 30, 22, 12); auraLbl.TextColor3 = P.gold
for idx, rv in ipairs({10, 15, 25, 40}) do
    local pb = Instance.new("TextButton", c6e); pb.Size = UDim2.new(0, 50, 0, 24); pb.Position = UDim2.new(0, 340 + (idx - 1) * 54, 0, 33)
    pb.BackgroundColor3 = Color3.fromRGB(32, 43, 64); pb.BackgroundTransparency = 0.25; pb.Text = tostring(rv)
    pb.TextColor3 = P.text; pb.Font = Enum.Font.GothamBold; pb.TextSize = 12; pb.BorderSizePixel = 0
    Instance.new("UICorner", pb).CornerRadius = UDim.new(0, 6)
    pb.MouseButton1Click:Connect(function()
        ST.auraRange = rv; auraLbl.Text = tostring(rv); addLog(("⚔️ مدى الأورا: %d"):format(rv))
    end)
end
mkAction(c6e, "🎯 استهدف أقرب لاعب", 10, 70, 220, 30, Color3.fromRGB(100, 60, 180), function()
    local myHrp = hrp(); if not myHrp then return end
    local best, bd = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= pl and p.Character then
            local th = p.Character:FindFirstChild("HumanoidRootPart")
            local hh = p.Character:FindFirstChildWhichIsA("Humanoid")
            if th and hh and hh.Health > 0 then
                local d = (th.Position - myHrp.Position).Magnitude
                if d < bd then bd = d; best = p end
            end
        end
    end
    if best then updateInspectorForPlayer(best); selectTab(4); addLog(("🎯 أقرب هدف: %s (%.0f متر)"):format(best.DisplayName, bd))
    else addLog("ما فيه لاعب قريب") end
end)
mkAction(c6e, "⚡ ضربة فورية (كل من حولك)", 240, 70, 305, 30, Color3.fromRGB(160, 35, 60), function()
    local myHrp = hrp(); if not myHrp then return end
    local n = 0
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= pl and p.Character then
            local th = p.Character:FindFirstChild("HumanoidRootPart")
            local hh = p.Character:FindFirstChildWhichIsA("Humanoid")
            if th and hh and hh.Health > 0 and (th.Position - myHrp.Position).Magnitude < (ST.auraRange or 15) + 10 then
                touchBoth(myHrp, th)
                if REM.GunInput then pcall(function() REM.GunInput:FireServer(th) end) end
                n = n + 1
            end
        end
    end
    addLog(("⚡ ضربة فورية على %d لاعب"):format(n))
end)

-- دليل سريع داخل الواجهة (ما يخليك تتوه)
local help = Instance.new("Frame", frame); help.Size = UDim2.new(0, 420, 0, 330); help.Position = UDim2.new(0.5, -210, 0.5, -165)
help.BackgroundColor3 = P.bg; help.BackgroundTransparency = 0.03; help.Visible = false; help.ZIndex = 60; help.Active = true
Instance.new("UICorner", help).CornerRadius = UDim.new(0, 14)
local hs = Instance.new("UIStroke", help); hs.Color = P.accent; hs.Thickness = 1.5; hs.Transparency = 0.2
local ht = Instance.new("TextLabel", help); ht.Size = UDim2.new(1, -20, 0, 30); ht.Position = UDim2.new(0, 10, 0, 8)
ht.BackgroundTransparency = 1; ht.Text = "🧭 دليل سريع"; ht.TextColor3 = P.cyan; ht.Font = Enum.Font.GothamBold; ht.TextSize = 15; ht.TextXAlignment = Enum.TextXAlignment.Left
local hb = Instance.new("TextLabel", help); hb.Size = UDim2.new(1, -24, 0, 220); hb.Position = UDim2.new(0, 12, 0, 42)
hb.BackgroundTransparency = 1; hb.TextColor3 = P.text; hb.Font = Enum.Font.Code; hb.TextSize = 11; hb.TextXAlignment = Enum.TextXAlignment.Left; hb.TextYAlignment = Enum.TextYAlignment.Top; hb.TextWrapped = true
hb.Text = "Home : إظهار / إخفاء الواجهة\nEnd : إيقاف السكربت\nCtrl + 1..6 : تبديل التبويبات بسرعة\n\n🏠 فارم : المهام + الدروبات + اللوج\n🏃 حركة : سرعة، جمب، طيران، Noclip، انتقال\n👁 كشف : ESP لاعبين ودروبات + FOV + اختفاء\n🗺 خريطة : رادار اللاعبين + فحص الرتبة\n🧰 أدوات : حماية (كلبشة/رصاص/سجن) + أدوات الماب\n⚔ هجوم : Aimbot، Aura، Auto Kill، ضربة فورية\n\nنصيحة: زر (؟) بأعلى النافذة يرجعك لهذا الدليل."
mkAction(help, "✔ فهمت", 135, 272, 140, 34, P.accent, function() help.Visible = false end)
helpBtn.MouseButton1Click:Connect(function() help.Visible = not help.Visible end)

local tabKeys = {[Enum.KeyCode.One]=1, [Enum.KeyCode.Two]=2, [Enum.KeyCode.Three]=3, [Enum.KeyCode.Four]=4, [Enum.KeyCode.Five]=5, [Enum.KeyCode.Six]=6}

floatBtn.MouseButton1Click:Connect(function() frame.Visible = not frame.Visible end)
closeX.MouseButton1Click:Connect(function() frame.Visible = false end)
addC(UIS.InputBegan:Connect(function(input, gp) if gp then return end
    if input.KeyCode == Enum.KeyCode.End then shutdown()
    elseif input.KeyCode == Enum.KeyCode.Home then frame.Visible = not frame.Visible end
    if (UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.RightControl)) and tabKeys[input.KeyCode] then
        selectTab(tabKeys[input.KeyCode])
    end
end))
end
buildGui()

-- حلقة المهمات
local missionCycleRunning = false
task.spawn(function() while not _G.StopAutoFarm do
    task.wait(0.15)
    if not pl.Character or not alive() then task.wait(1); continue end
    if ST.busyCyber or ST.handlingDrop or ST.busyDrop or ST.busyWeather then continue end
    if ST.autoMission and not ST.inProgress and not missionCycleRunning then
        missionCycleRunning = true
        task.spawn(function()
            pcall(runMissionCycle)
            ST.inProgress = false
            missionCycleRunning = false
        end)
    end
    updateStats()
end end)

addLog("AUTOFARM v6.3 جاهز 👑")
addLog("✅ مهام + دروبات + رادار + هجوم")
addLog("✅ كهف السيبراني: انتقال فوري بالإحداثيات الجديدة")
addLog("✅ مشغّلان للكهف: باب الأمن + رسالة الشات")
addLog("✅ استلام جوائز وقت اللعب (تلقائي + زر يدوي يعمل)")
addLog("✅ إصلاح المهام: لا تختطفها الدروبات/الكهف أثناء التسليم")
addLog("Home = إخفاء/إظهار | End = إيقاف")
updateStats()
print("[v6.3] Ready — Ultimate Merged Edition (v6.1 features + v6.2 Cyber Cave)")
