-- ============================================================
-- 👑 FINAL FIX v4.7 — ZERO-DEADLOCK PERSISTENT AIRDROP & COMBAT
-- ════════════════════════════════════════════════════════════
--  1. محرك الدروبات مأخوذ بالكامل من نسخة v1.3.1 المثبتة والمجربة
--  2. انتظار هبوط الدروب والوقوف المباشر فوقه r.CFrame = part.Position
--  3. ضغط ProximityPrompt بمدة HoldDuration كاملة + محاكاة زر E لـ 0.5 ثانية
--  4. حل معادلة DropPass وتأكيدها فوراً
--  5. حماية كاملة من الكلبشة (Anti-Cuff) وتجديد الدرع التلقائي عند الضرر
--  6. رادار v4.2 التكتيكي مع قائمة اللاعبين وفاحص الرتب والمراقبة
--  7. أزرار يدوية كاملة: أسلحة، دروع، فتح البوابات والمكاتب، الملابس
-- ============================================================

if _G.__FINAL_STOP then pcall(_G.__FINAL_STOP) end
_G.StopAutoFarm = false

-- ═══ SERVICES ═══
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

-- مسح واجهات قديمة
for i = 47, 260 do
    local o = pg:FindFirstChild("AutoFarmV"..i); if o then o:Destroy() end
    local o2 = pg:FindFirstChild("FinalFix"..i); if o2 then o2:Destroy() end
end
for _, n in ipairs({"FinalFixGui","FinalFixMobileBtn","AirdropHunterGui","AirdropGodGui","MapScannerGui"}) do
    local o = pg:FindFirstChild(n); if o then o:Destroy() end
end

-- ═══ CONFIG ═══
local CFG = {
    BOARD_POS      = Vector3.new(276.87, 5.8, -278.1),
    WH_RIGHT       = Vector3.new(336, 10, -177),
    WH_FRONT       = Vector3.new(331, 10, -173),
    SAFE_POS       = Vector3.new(276.87, 7.5, -278.1),
    CYBER_LEVER    = Vector3.new(235.92, 6.87, -101.00),
    CYBER_DOOR_OUT = Vector3.new(235.66, 6.23, -155.02),
    COOLDOWN       = 150,
    SHOWTARGET_WAIT= 6,
    DROP_NAMES     = {"Airdrop","SecretAirdrop","Drops","Airdrops",
                      "ActiveDrops","SecretDrops","SpecialDrop","RareDrop"},
}

-- ═══ STATE ═══
local ST = {
    autoMission=true, autoDrop=true, autoCyber=true, autoCollect=false,
    inProgress=false, isPickup=true, boxIndex=0, totalBoxes=5,
    missionOn=false, target=nil, cdExpire=0,
    busyDrop=false, busyCyber=false, handlingDrop=false,
    lastEq="", lastCyberLoot=0, lastStartTry=0,
    busyDropSince=0, busyCyberSince=0, score=0,
    busyStart=nil, progressStart=nil,
    -- حركة
    walkSpeed=16, jumpPower=50, flySpeed=50,
    customSpeedOn=false, superJumpOn=false, infJumpOn=false,
    flyOn=false, noclipOn=false,
    -- كشف (ESP)
    invisOn=false, espPlayers=false, espDrops=false, espItems=false,
    fullbright=false, fov=70, antiFling=false,
    -- حماية وقتال
    antiCuff=true, autoArmorDefense=true, lastArmorRefill=0,
    -- أدوات ورادار
    clickTpOn=false, antiSitOn=false, fpsBoostOn=false,
    spectating=false, spectateTarget=nil,
    selectedPlr=nil, radarSelectedPlr=nil,
    stats={missions=0,dropsNormal=0,dropsSecret=0,quizzesSolved=0,cyberPoints=0,failed=0},
}

-- ═══ CONNECTIONS ═══
local conns = {}
local function addC(c) if c then conns[#conns+1]=c end; return c end

-- ═══ FLY ═══
local flyBV, flyBG

-- ═══ ESP STORAGE ═══
local espHL = {}
local espTags = {}
local espDropHL = {}
local espDropTags = {}
local espItemHL = {}

-- ═══ INVIS ═══
local invisSaved = {}
local function restoreVis()
    for obj,orig in pairs(invisSaved) do
        pcall(function()
            if obj:IsA("BasePart") or obj:IsA("Decal") then obj.Transparency=orig
            elseif obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") then obj.Enabled=orig end
        end)
    end
    invisSaved={}
end

-- ═══ FULLBRIGHT SAVE ═══
local lightSave = {}

-- ═══ CLEANUP ESP ═══
local function clearAllESP()
    for _, h in pairs(espHL) do pcall(function() h:Destroy() end) end; espHL = {}
    for _, b in pairs(espTags) do pcall(function() b:Destroy() end) end; espTags = {}
    for _, h in pairs(espDropHL) do pcall(function() h:Destroy() end) end; espDropHL = {}
    for _, b in pairs(espDropTags) do pcall(function() b:Destroy() end) end; espDropTags = {}
    for _, h in pairs(espItemHL) do pcall(function() h:Destroy() end) end; espItemHL = {}
end

-- WATCHDOG (من v1.3.1)
task.spawn(function()
    while not _G.StopAutoFarm do
        task.wait(3)
        if ST.busyDrop then
            if not ST.busyStart then ST.busyStart = tick()
            elseif tick() - ST.busyStart > 45 then
                addLog("⚠️ busyDrop reset")
                ST.busyDrop = false; ST.handlingDrop = false; ST.busyStart = nil
            end
        else ST.busyStart = nil end
        if ST.inProgress then
            if not ST.progressStart then ST.progressStart = tick()
            elseif tick() - ST.progressStart > 120 then
                addLog("⚠️ inProgress reset")
                ST.inProgress = false; ST.progressStart = nil
            end
        else ST.progressStart = nil end
    end
end)

-- ═══ SHUTDOWN ═══
local function shutdown()
    _G.StopAutoFarm=true; _G.__FINAL_STOP=nil
    for _,c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    pcall(function()
        clearAllESP()
        restoreVis()
        if flyBV then flyBV:Destroy(); flyBV=nil end
        if flyBG then flyBG:Destroy(); flyBG=nil end
        local c=pl.Character; if c then
            for _,p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide=true end
            end
        end
        local h=c and c:FindFirstChildOfClass("Humanoid")
        if h then
            h.WalkSpeed=16
            if h.UseJumpPower then h.JumpPower=50 else h.JumpHeight=7.2 end
            cam.CameraSubject = h
        end
        for prop,val in pairs(lightSave) do pcall(function() Lighting[prop]=val end) end
        pcall(function() cam.FieldOfView=70 end)
        local g=pg:FindFirstChild("FinalFixGui"); if g then g:Destroy() end
        local f=pg:FindFirstChild("FinalFixMobileBtn"); if f then f:Destroy() end
    end)
    print("[v4.7] Stopped")
end
_G.__FINAL_STOP=shutdown

-- ═══ LOG ═══
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
    print("[v4.7]",s)
end
local function setStatus(s,color) if statusLbl then statusLbl.Text=s; if color then statusLbl.TextColor3=color end end end
local function updateStats()
    if statsLbl then
        statsLbl.Text=("مهام:%d | عادي:%d | سري:%d | حل:%d | سيبراني:%d"):format(
            ST.stats.missions,ST.stats.dropsNormal,ST.stats.dropsSecret,
            ST.stats.quizzesSolved,ST.stats.cyberPoints)
    end
end

-- ═══ REMOTES ═══
local Rem  = RS:FindFirstChild("Remotes")
local Evts = RS:FindFirstChild("Events")
local REM = {
    ShowTarget  = Rem and Rem:FindFirstChild("ShowTarget"),
    ClaimReward = Rem and Rem:FindFirstChild("ClaimMissionReward"),
    StartMission= Rem and Rem:FindFirstChild("StartMissionEvent"),
    StartMissio2= Evts and Evts:FindFirstChild("StartMissio"),
    Quiz        = Rem and Rem:FindFirstChild("AirdropQuizEvent"),
}

-- ═══ HELPERS ═══
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
        if typeof(firesignal)=="function" then
            firesignal(btn.MouseButton1Click)
            firesignal(btn.Activated)
        end
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

-- ═══ فحص الرتبة ومقارنتها ═══
local function getPlayerRankInfo(p)
    if not p then return "غير معروف", 0 end
    local ls = p:FindFirstChild("leaderstats")
    if ls then
        for _, v in ipairs(ls:GetChildren()) do
            local vn = v.Name:lower()
            if vn:find("رتب") or vn:find("rank") or vn:find("level") or vn:find("مستوى") then
                local num = tonumber(tostring(v.Value):match("%d+")) or 0
                return tostring(v.Value), num
            end
        end
    end
    if p.Team then
        local num = tonumber(p.Team.Name:match("%d+")) or 0
        return p.Team.Name, num
    end
    return "عضو", 0
end

-- ═══ CRATE DETECTION ═══
local BODY={head=1,humanoidrootpart=1,torso=1,uppertorso=1,lowertorso=1,
    ["left arm"]=1,["right arm"]=1,["left leg"]=1,["right leg"]=1,
    leftupperarm=1,leftlowerarm=1,lefthand=1,rightupperarm=1,
    rightlowerarm=1,righthand=1,leftupperleg=1,leftlowerleg=1,
    leftfoot=1,rightupperleg=1,rightlowerleg=1,rightfoot=1}
local WEAPONS={"m4","scar","ak","sniper","cuff","card","laptop","gun","pistol","rifle"}

local function isCrate(item)
    local n=item.Name:lower()
    for _,w in ipairs(WEAPONS) do if n:find(w) then return false end end
    if item:IsA("Tool") then return true end
    if n:find("box") or n:find("crate") or n:find("صندوق") or n:find("union") then return true end
    return false
end

local function getCrate()
    local c=char(); if not c then return nil end
    for _,item in ipairs(c:GetChildren()) do
        if not BODY[item.Name:lower()] and not item:IsA("Humanoid") and not item:IsA("Shirt")
        and not item:IsA("Pants") and not item:IsA("ShirtGraphic") and not item:IsA("BodyColors")
        and not item:IsA("Animate") and not item:IsA("LocalScript") and not item:IsA("Script")
        and not item:IsA("Accessory") and not item:IsA("CharacterMesh") then
            if isCrate(item) then
                pcall(function()
                    if item:IsA("BasePart") then item.CanCollide=false; item.Massless=true end
                    for _,d in ipairs(item:GetDescendants()) do if d:IsA("BasePart") then d.CanCollide=false; d.Massless=true end end
                end)
                return item
            end
        end
    end
    return nil
end
local function hasCrate() return getCrate()~=nil end

-- ═══ DROP CLASSIFIER ═══
local function classifyDrop(obj)
    if not obj then return "normal" end
    local n=(obj.Name or ""):lower()
    if n:find("secret") or n:find("سري") or n:find("gold") or n:find("ذهبي") then return "secret" end
    return "normal"
end

-- ═══════════════════════════════════════════════════════════════
--  🎁 DROP ENGINE (مأخوذ بالكامل من نسخة v1.3.1 المثبتة)
-- ═══════════════════════════════════════════════════════════════
local function findActiveDrop()
    for _, n in ipairs(CFG.DROP_NAMES) do
        local obj = workspace:FindFirstChild(n)
        if obj and obj.Parent then return obj, classifyDrop(obj) end
    end
    for _, fn in ipairs({"Drops","Airdrops","ActiveDrops","SecretDrops","SpecialDrops"}) do
        local f = workspace:FindFirstChild(fn)
        if f then
            for _, item in ipairs(f:GetChildren()) do
                if (item:IsA("Model") or item:IsA("BasePart")) and item.Parent then
                    return item, classifyDrop(item)
                end
            end
        end
    end
    return nil, nil
end

local function getNearbyPrompts(radius)
    local list = {}
    local r = hrp()
    if not r then return list end
    radius = radius or 20
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            local parent = obj.Parent
            local pp = nil
            if parent and parent:IsA("BasePart") then pp = parent
            elseif parent and parent:IsA("Model") then
                pp = parent.PrimaryPart or parent:FindFirstChildWhichIsA("BasePart", true)
            end
            if pp then
                local d = (pp.Position - r.Position).Magnitude
                if d < radius then
                    table.insert(list, {prompt = obj, dist = d, part = pp})
                end
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
        prompt:InputHoldBegin()
        task.wait(math.max(hd + 0.15, 0.55))
        prompt:InputHoldEnd()
    end)
    pcall(function()
        if typeof(fireproximityprompt) == "function" then
            fireproximityprompt(prompt)
        end
    end)
    return true
end

local function triggerPromptInstantly(prompt)
    return triggerPrompt(prompt)
end

-- QUIZ SOLVER
local AR_MAP = {["٠"]="0",["١"]="1",["٢"]="2",["٣"]="3",["٤"]="4",
                ["٥"]="5",["٦"]="6",["٧"]="7",["٨"]="8",["٩"]="9"}
local function cleanText(t)
    local s = tostring(t or "")
    for ar,en in pairs(AR_MAP) do s = s:gsub(ar,en) end
    s = s:gsub("×","*"):gsub("✕","*"):gsub("÷","/")
         :gsub("＋","+"):gsub("﹢","+"):gsub("➕","+")
         :gsub("－","-"):gsub("−","-"):gsub("–","-")
         :gsub("—","-"):gsub("―","-"):gsub("﹣","-"):gsub("＝","=")
         :gsub("؟","?"):gsub("ـ","")
    s = s:gsub("(%d)%s*[xX]%s*(%d)","%1*%2")
    return s
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
    local dp = pg:FindFirstChild("DropPass")
    if not dp then return nil,nil,nil end
    local quez, txtBox, applyBtn
    for _,d in ipairs(dp:GetDescendants()) do
        if d:IsA("TextLabel") and d.Visible and (d.Name=="Quez" or d.Name:lower():find("quez",1,true)) then
            quez = d
        elseif d:IsA("TextBox") and d.Visible then
            txtBox = d
        elseif d:IsA("TextButton") and d.Visible and d.AbsoluteSize.X > 20 then
            local par = d.Parent
            if par and (par.Name=="Apply" or par.Name:lower():find("apply",1,true)) then
                applyBtn = d
            end
        end
    end
    if not applyBtn then
        for _,d in ipairs(dp:GetDescendants()) do
            if d:IsA("TextButton") and d.Visible and d.AbsoluteSize.X > 50 then applyBtn=d; break end
        end
    end
    return quez, txtBox, applyBtn
end

local function isDropPassShown()
    local dp = pg:FindFirstChild("DropPass")
    if not dp or not dp.Enabled then return false end
    for _,d in ipairs(dp:GetDescendants()) do
        if d:IsA("TextLabel") and d.Name=="Quez" and d.Visible and d.AbsoluteSize.X>5 then return true end
    end
    return false
end

local function writeAnswer(txtBox, value)
    if not txtBox then return false end
    local s = tostring(value)
    pcall(function()
        txtBox:CaptureFocus(); task.wait(0.08)
        txtBox.Text = ""; task.wait(0.03)
        txtBox.Text = s; task.wait(0.08)
        txtBox:ReleaseFocus(true)
    end)
    task.wait(0.1)
    if txtBox.Text == s then return true end
    pcall(function() txtBox.Text = s end)
    task.wait(0.1)
    if txtBox.Text == s then return true end
    pcall(function() txtBox.Text = s; if firesignal then firesignal(txtBox.FocusLost,true) end end)
    task.wait(0.1)
    return txtBox.Text == s
end

local function isGoldenPart(part)
    if not part or not part:IsA("BasePart") then return false end
    local c = part.Color
    return c.R > 0.6 and c.G > 0.4 and c.B < 0.4 and c.R > c.B * 1.5
end

local function goTo(target)
    local part = getPart(target)
    if not part then return false end
    local r = hrp(); if not r then return false end
    if (r.Position - part.Position).Magnitude <= 8 then return true end
    pcall(function()
        r.CFrame = CFrame.new(part.Position + Vector3.new(0,3,0))
        r.Velocity = Vector3.zero
    end)
    task.wait(0.3)
    r = hrp()
    if r and (r.Position - part.Position).Magnitude < 12 then return true end
    local h = hum()
    if h then
        h:MoveTo(part.Position)
        local t0 = tick()
        while tick() - t0 < 5 do
            r = hrp()
            if not r or (r.Position - part.Position).Magnitude < 8 then return true end
            task.wait(0.1)
        end
    end
    return false
end

-- DROP HANDLER (من v1.3.1 المجربة)
local function handleDrop(target, kind)
    if ST.busyDrop then
        addLog("⚠️ busyDrop مشغول")
        return
    end
    ST.busyDrop = true
    ST.handlingDrop = true
    ST.busyStart = tick()

    local isSecret = (kind == "secret")
    addLog(isSecret and "🏆 دروب سري!" or "📦 دروب عادي!")
    setStatus("دروب...", isSecret and Color3.fromRGB(255,215,0) or Color3.fromRGB(100,200,255))

    if not goTo(target) then
        addLog("فشل الوصول")
        ST.stats.failed = ST.stats.failed + 1
        ST.busyDrop = false; ST.handlingDrop = false; ST.busyStart = nil
        return
    end
    addLog("وصلنا")
    task.wait(0.4)

    local part = getPart(target)
    local opened = false

    for attempt = 1, 8 do
        if _G.StopAutoFarm then break end
        local r = hrp()
        if r and part then
            pcall(function()
                r.CFrame = CFrame.new(part.Position)
                r.Velocity = Vector3.zero
            end)
        end
        task.wait(0.15)

        local prompts = getNearbyPrompts(15)
        for _, entry in ipairs(prompts) do
            triggerPrompt(entry.prompt)
            task.wait(0.15)
            if isDropPassShown() then
                addLog("DropPass!")
                opened = true
                break
            end
        end
        if opened then break end

        pcall(function()
            VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait(0.5)
            VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        end)
        task.wait(0.3)
        if isDropPassShown() then
            addLog("DropPass (E)!")
            opened = true
            break
        end
    end

    if not opened then addLog("فشل الفتح") end

    local t0 = tick(); local solved = false
    while tick() - t0 < 15 and not _G.StopAutoFarm do
        task.wait(0.2)
        if isDropPassShown() then
            local quez, txtBox, applyBtn = getDropPassElements()
            if quez and txtBox then
                local raw = quez.Text or ""
                if raw ~= "" and raw ~= "?" and raw ~= ST.lastEq then
                    local cleaned = cleanText(raw)
                    local ok, ans = pcall(solveStr, cleaned)
                    if ok and ans then
                        addLog(("🧮 %s = %d"):format(raw, ans))
                        writeAnswer(txtBox, ans)
                        task.wait(0.15)
                        if applyBtn then
                            for _ = 1, 5 do
                                clickBtn(applyBtn)
                                task.wait(0.12)
                            end
                        end
                        if REM.Quiz then
                            pcall(function() REM.Quiz:FireServer(ans) end)
                            pcall(function() REM.Quiz:FireServer(tostring(ans)) end)
                        end
                        ST.lastEq = raw
                        ST.stats.quizzesSolved = ST.stats.quizzesSolved + 1
                        if isSecret then
                            ST.score = ST.score + 1500
                            ST.stats.dropsSecret = ST.stats.dropsSecret + 1
                            addLog("السري حل!")
                        else
                            ST.score = ST.score + 800
                            ST.stats.dropsNormal = ST.stats.dropsNormal + 1
                            addLog("العادي حل!")
                        end
                        solved = true
                        updateStats()
                        task.wait(1.5)
                        break
                    end
                end
            end
        end
    end

    if not solved then
        addLog("انتهى الوقت")
        ST.stats.failed = ST.stats.failed + 1
    end

    ST.busyDrop = false; ST.handlingDrop = false; ST.busyStart = nil
    setStatus("خامل", Color3.fromRGB(120,255,200))
    updateStats()
end

-- FAST DROP DETECTION (من v1.3.1)
local lastHandledDrop = nil
task.spawn(function()
    while not _G.StopAutoFarm do
        task.wait(0.5)
        if not ST.autoDrop then continue end
        if ST.busyDrop then continue end
        for _, n in ipairs(CFG.DROP_NAMES) do
            local obj = workspace:FindFirstChild(n)
            if obj and obj ~= lastHandledDrop then
                lastHandledDrop = obj
                local kind = classifyDrop(obj)
                addLog(("⚡ Fast: %s!"):format(n))
                ST.inProgress = false
                ST.progressStart = nil
                task.spawn(handleDrop, obj, kind)
                break
            end
        end
        local stillThere = false
        for _, n in ipairs(CFG.DROP_NAMES) do
            if workspace:FindFirstChild(n) then stillThere = true; break end
        end
        if not stillThere then lastHandledDrop = nil end
    end
end)

addC(workspace.ChildAdded:Connect(function(c)
    if _G.StopAutoFarm or ST.busyDrop then return end
    local name = c.Name
    local isDrop = false
    for _, n in ipairs(CFG.DROP_NAMES) do
        if name == n then isDrop = true; break end
    end
    if not isDrop then return end
    if not ST.autoDrop then return end
    addLog(("🆕 %s!"):format(name))
    task.wait(0.3)
    if _G.StopAutoFarm or ST.busyDrop then return end
    local kind = classifyDrop(c)
    task.spawn(handleDrop, c, kind)
end))

-- ═══ WALK ENGINE ═══
local function walk(dest, maxT, isDrop)
    maxT = maxT or 20
    local r, h = hrp(), hum()
    if not r or not h or not alive() then return false end
    local tgt = groundOf(dest)
    local stopD = 1.8
    local runSpd = ST.customSpeedOn and ST.walkSpeed or 16
    h.WalkSpeed = runSpd
    local path = PS:CreatePath({AgentRadius=2, AgentHeight=5, AgentCanJump=true, WaypointSpacing=4.5})
    local ok = pcall(function() path:ComputeAsync(r.Position, tgt) end)
    local wpts = (ok and path.Status==Enum.PathStatus.Success) and path:GetWaypoints() or nil
    local t0 = tick(); local last = r.Position; local stuck = 0

    local function intr()
        if _G.StopAutoFarm then return "STOP" end
        if ST.busyCyber then return "CYBER" end
        if not isDrop and ST.autoDrop and not ST.busyDrop then
            for _, n in ipairs(CFG.DROP_NAMES) do
                if workspace:FindFirstChild(n) then return "DROP" end
            end
        end
        return nil
    end

    local function stuckChk(wp)
        if (r.Position - last).Magnitude < 0.25 then
            stuck = stuck + 0.05
            if stuck >= 0.4 then h.Jump = true end
            if stuck >= 1.8 then
                r.AssemblyLinearVelocity = Vector3.zero
                char():PivotTo(CFrame.new(wp + Vector3.new(0, 2, 0)))
                stuck = 0; return true
            end
        else stuck = 0 end
        last = r.Position; return false
    end

    if wpts and #wpts > 1 then
        for i = 2, #wpts do
            local wp = wpts[i]
            local it = intr(); if it then return it end
            r, h = hrp(), hum(); if not r or not h or not alive() then return false end
            if flatDist(r.Position, tgt) <= stopD then return true end
            h.WalkSpeed = runSpd; h:MoveTo(wp.Position)
            if wp.Action == Enum.PathWaypointAction.Jump then h.Jump = true end
            local ws = tick()
            while flatDist(r.Position, wp.Position) > 2.8 do
                task.wait(0.04)
                local it2 = intr(); if it2 then return it2 end
                if flatDist(r.Position, tgt) <= stopD then return true end
                if tick() - t0 > maxT then return false end
                r, h = hrp(), hum(); if not r or not h then return false end
                if stuckChk(wp.Position) then break end
                if tick() - ws > 1.4 then break end
            end
        end
    else
        h:MoveTo(tgt)
        local td = tick()
        while flatDist(r.Position, tgt) > stopD do
            task.wait(0.05)
            local it = intr(); if it then return it end
            if tick() - td > maxT then break end
            r, h = hrp(), hum(); if not r or not h then return false end
            h.WalkSpeed = runSpd; h:MoveTo(tgt); stuckChk(tgt)
        end
    end
    return true
end

local function handleWalkInterrupt(res)
    if res == "DROP" then
        local d = nil
        for _, n in ipairs(CFG.DROP_NAMES) do
            d = workspace:FindFirstChild(n)
            if d then break end
        end
        if d and not ST.busyDrop then
            addLog("⚡ مقاطعة فورية: دروب ظهر أثناء المشي!")
            ST.inProgress = false
            task.spawn(handleDrop, d, classifyDrop(d))
        end
        return true
    end
    if res == "STOP" or res == "CYBER" then return true end
    return false
end

-- ═══ CYBER CAVE ═══
local function lootCyberCave()
    if ST.busyCyber then return end
    if tick() - ST.lastCyberLoot < 25 then return end
    ST.busyCyber = true; ST.busyCyberSince = tick(); ST.lastCyberLoot = tick()
    addLog("دخول كهف السيبراني"); setStatus("كهف السيبراني...", Color3.fromRGB(0,220,255))
    local r = hrp(); if not r then ST.busyCyber = false; return end
    pcall(function() char():PivotTo(CFrame.new(CFG.CYBER_LEVER)); r = hrp(); if r then r.AssemblyLinearVelocity = Vector3.zero; r.AssemblyAngularVelocity = Vector3.zero end end)
    task.wait(0.2)
    local t0 = tick()
    while tick() - t0 < 3.5 and not _G.StopAutoFarm do
        task.wait(0.08); r = hrp(); if not r then break end
        for _, p in ipairs(workspace:GetDescendants()) do
            if p:IsA("BasePart") and (p.Position - r.Position).Magnitude < 10 then
                local pn = p.Name:lower()
                if pn:find("handle") or pn:find("lever") or pn:find("مقبض") or pn:find("cyber") or pn:find("switch") then touchObj(p) end
            end
        end
        pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game); task.wait(0.12); VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game) end)
    end
    ST.stats.cyberPoints = ST.stats.cyberPoints + 50; ST.score = ST.score + 50
    addLog("سيبراني +50 نقطة"); updateStats()
    pcall(function() char():PivotTo(CFrame.new(CFG.CYBER_DOOR_OUT + Vector3.new(0, 1.5, -4))) end)
    task.wait(0.4); ST.busyCyber = false; setStatus("خامل", Color3.fromRGB(120,255,200))
end

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
pcall(function() TextChatService.MessageReceived:Connect(function(msg)
    if ST.autoCyber and checkCyberMsg(msg.Text) then addLog("رسالة فتح الباب — دخول الكهف"); task.spawn(lootCyberCave) end
end) end)
pcall(function()
    local dcs = RS:FindFirstChild("DefaultChatSystemChatEvents")
    local omdf = dcs and dcs:FindFirstChild("OnMessageDoneFiltering")
    if omdf then omdf.OnClientEvent:Connect(function(data) if ST.autoCyber and data and checkCyberMsg(data.Message) then task.spawn(lootCyberCave) end end) end
end)

-- ═══ MISSION LOGIC ═══
if REM.ShowTarget then
    addC(REM.ShowTarget.OnClientEvent:Connect(function(tp,_,_,cnt,tot,isPick)
        if _G.StopAutoFarm then return end
        if not tp then ST.missionOn=false; ST.target=nil; ST.boxIndex=0; ST.cdExpire=tick()+CFG.COOLDOWN; addLog("اكتملت المهمة — كول داون"); return end
        ST.target=tp; ST.isPickup=(isPick==true); ST.boxIndex=cnt or ST.boxIndex; ST.totalBoxes=tot or 5; ST.missionOn=true
        addLog(("%s (%d/%d)"):format(ST.isPickup and "التقاط" or "تسليم",ST.boxIndex,ST.totalBoxes))
    end))
end

local function findAndClickStartBtn()
    local clicked = false
    for _, g in ipairs(pg:GetChildren()) do
        if not g:IsA("ScreenGui") or not g.Enabled or g.Name:find("FinalFix") or g.Name:find("AutoFarm") then continue end
        for _, b in ipairs(g:GetDescendants()) do
            if (b:IsA("TextButton") or b:IsA("ImageButton")) and b.Visible and b.AbsoluteSize.X > 25 then
                local t = (b:IsA("TextButton") and b.Text or "")
                for _, sub in ipairs(b:GetChildren()) do if sub:IsA("TextLabel") then t = t .. " " .. (sub.Text or "") end end
                if t:find("أبدا") or t:find("ابدأ") or t:find("ابدا") or t:lower():find("start") or t:find("بدء") or t:find("قبول") then
                    clickBtn(b); clicked = true; task.wait(0.1)
                end
            end
        end
    end
    return clicked
end

local function triggerMissionStart()
    local prompts = getNearbyPrompts(18)
    for _, entry in ipairs(prompts) do triggerPromptInstantly(entry.prompt) end
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
    for _, g in ipairs(pg:GetChildren()) do
        if g:IsA("ScreenGui") and g.Enabled and not g.Name:find("FinalFix") then
            for _, b in ipairs(g:GetDescendants()) do
                if (b:IsA("TextButton") or b:IsA("ImageButton")) and b.Visible then
                    local txt = (b:IsA("TextButton") and b.Text or "")
                    if txt:find("صناديق") or txt:find("المستودع") then clickBtn(b); task.wait(0.1) end
                end
            end
        end
    end
    return findAndClickStartBtn()
end

local function runMissionCycle()
    if ST.inProgress or ST.busyCyber or ST.handlingDrop or ST.busyDrop then return end
    if ST.autoDrop then
        local activeDrop, activeKind = findActiveDrop()
        if activeDrop and activeDrop.Parent then
            ST.inProgress = false
            task.spawn(handleDrop, activeDrop, activeKind)
            return
        end
    end

    ST.inProgress = true
    local carrying = hasCrate(); ST.isPickup = not carrying
    local h, r = hum(), hrp()
    if not h or not r or not alive() then ST.inProgress = false; task.wait(1); return end
    if carrying then getCrate() end
    local cdLeft = math.ceil(ST.cdExpire - tick())
    if cdLeft > 0 then
        setStatus(("كول داون: %ds"):format(cdLeft), Color3.fromRGB(200,200,100))
        if flatDist(r.Position, CFG.BOARD_POS) > 6 then
            local res = walk(CFG.BOARD_POS, 12, false)
            if handleWalkInterrupt(res) then ST.inProgress = false; return end
        end
        task.wait(0.8); ST.inProgress = false; return
    end
    if not ST.missionOn then
        if tick() - ST.lastStartTry < 2.0 then ST.inProgress = false; task.wait(0.5); return end
        ST.lastStartTry = tick()
        addLog("بدء مهمة جديدة..."); setStatus("التوجه للوحة المهمة...", Color3.fromRGB(150,220,255))
        if flatDist(r.Position, CFG.BOARD_POS) > 5 then
            local res = walk(CFG.BOARD_POS, 14, false)
            if handleWalkInterrupt(res) then ST.inProgress = false; return end
            pcall(function() char():PivotTo(CFrame.new(CFG.BOARD_POS + Vector3.new(0, 1.2, 0))) end); task.wait(0.2)
        end
        triggerMissionStart()
        local wt = tick()
        while tick() - wt < CFG.SHOWTARGET_WAIT do
            task.wait(0.15)
            if ST.missionOn and ST.target then addLog("تم قبول المهمة"); break end
        end
        ST.inProgress = false; return
    end
    if ST.isPickup then
        addLog("التوجه للمستودع"); setStatus("استلام صندوق...", Color3.fromRGB(255,200,100))
        local res = walk(CFG.WH_RIGHT, 16, false)
        if handleWalkInterrupt(res) then ST.inProgress = false; return end
        local pickupOK = false
        for att = 1, 10 do
            if hasCrate() then pickupOK = true; break end
            if _G.StopAutoFarm or ST.busyCyber or ST.handlingDrop or ST.busyDrop then break end
            h, r = hum(), hrp(); if not h or not r then break end
            local spot = (att % 2 == 0) and CFG.WH_RIGHT or (CFG.WH_RIGHT + Vector3.new(1.5, 0, 1.5))
            pcall(function() r.CFrame = CFrame.new(spot); r.Velocity = Vector3.zero end); task.wait(0.15)
            local prompts = getNearbyPrompts(20)
            for _, entry in ipairs(prompts) do triggerPromptInstantly(entry.prompt); task.wait(0.15); if hasCrate() then pickupOK = true; break end end
            if pickupOK then break end
            if ST.target then touchObj(ST.target) end
            local bf = workspace:FindFirstChild("BoxFolder"); if bf then for _, z in ipairs(bf:GetChildren()) do if z:IsA("BasePart") then touchObj(z) end end end
            pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game); task.wait(0.35); VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game) end)
            task.wait(0.15)
        end
        if hasCrate() or pickupOK then
            addLog("تم حمل الصندوق"); ST.isPickup = false
            pcall(function() char():PivotTo(CFrame.new(CFG.WH_FRONT + Vector3.new(0, 2.5, 0))); local rp = hrp(); if rp then rp.Velocity = Vector3.zero end end)
            task.wait(0.3); ST.stats.missions = ST.stats.missions + 1; updateStats()
        else
            pcall(function() char():PivotTo(CFrame.new(CFG.WH_FRONT + Vector3.new(0, 2, 0))) end); task.wait(0.5)
        end
    else
        if not ST.target then
            local mt = workspace:FindFirstChild("MissionTargets")
            if mt then for _, t in ipairs(mt:GetChildren()) do if t:IsA("BasePart") or t:IsA("Model") then ST.target = t; break end end end
        end
        if not ST.target or not hasCrate() then task.wait(0.3); if not hasCrate() then ST.isPickup = true; ST.inProgress = false; return end end
        local tp = ST.target and (ST.target:IsA("BasePart") and ST.target or ST.target:FindFirstChildWhichIsA("BasePart", true))
        if not tp then task.wait(0.3); ST.inProgress = false; return end
        addLog("التوجه لنقطة التسليم"); setStatus("تسليم...", Color3.fromRGB(120,255,150))
        local bPos = tp.Position; pcall(function() tp.CanTouch = true end)
        local gPos = groundOf(bPos)
        local res = walk(Vector3.new(bPos.X, gPos.Y, bPos.Z), 20, false)
        if handleWalkInterrupt(res) then ST.inProgress = false; return end
        r, h = hrp(), hum(); if not r or not h then ST.inProgress = false; return end
        h.WalkSpeed = 16
        local delivered = false; local t0 = tick()
        while tick() - t0 < 12 do
            if not hasCrate() then delivered = true; break end
            if _G.StopAutoFarm or not ST.missionOn or ST.busyCyber or ST.handlingDrop or ST.busyDrop then break end
            r, h = hrp(), hum(); if not r or not h then break end
            h:MoveTo(Vector3.new(bPos.X, r.Position.Y, bPos.Z))
            touchObj(tp)
            local mt = workspace:FindFirstChild("MissionTargets"); if mt then for _, t in ipairs(mt:GetChildren()) do if t:IsA("BasePart") then pcall(function() t.CanTouch = true end); touchObj(t) end end end
            local crate = getCrate(); if crate then
                if crate:IsA("BasePart") then touchBoth(crate, tp)
                elseif crate:IsA("Model") then for _, p in ipairs(crate:GetDescendants()) do if p:IsA("BasePart") then touchBoth(p, tp) end end end
                if crate:IsA("Tool") then pcall(function() crate:Activate() end) end
            end
            local prompts = getNearbyPrompts(15); for _, entry in ipairs(prompts) do triggerPromptInstantly(entry.prompt); task.wait(0.1); if not hasCrate() then break end end
            if not hasCrate() then delivered = true; break end
            pcall(function() VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game); task.wait(0.12); VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game) end)
            task.wait(0.15)
        end
        if delivered or not hasCrate() then ST.isPickup = true; addLog("تم التسليم")
        else ST.stats.failed = ST.stats.failed + 1 end
        h = hum(); if h then h.WalkSpeed = ST.customSpeedOn and ST.walkSpeed or 16 end
    end
    ST.inProgress = false
end

-- ═══ FLY SYSTEM ═══
local function startFly()
    local r=hrp(); if not r then return end
    if flyBV then flyBV:Destroy() end; if flyBG then flyBG:Destroy() end
    flyBV=Instance.new("BodyVelocity",r); flyBV.MaxForce=Vector3.new(1e6,1e6,1e6); flyBV.Velocity=Vector3.zero
    flyBG=Instance.new("BodyGyro",r); flyBG.MaxTorque=Vector3.new(1e6,1e6,1e6); flyBG.P=9000
    ST.flyOn=true
end
local function stopFly()
    ST.flyOn=false
    if flyBV then flyBV:Destroy(); flyBV=nil end
    if flyBG then flyBG:Destroy(); flyBG=nil end
end

-- ═══ NOCLIP ═══
local function setNoclip(on)
    ST.noclipOn=on
    if not on then
        local c=char(); if c then for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") and p.Name~="HumanoidRootPart" then p.CanCollide=true end end end
    end
end

-- ═══ INVISIBILITY ═══
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

-- ═══════════════════════════════════════════════════════════════
--  👁️ نظام الكشف الخارق (ESP Pro — لاعبين، دروبات، أسلحة ودروع)
-- ═══════════════════════════════════════════════════════════════

-- 1) كشف اللاعبين الاحترافي (لوحة عائمة + هايلايت + رتبة وصحة ومسافة)
local function updatePlayerESP()
    local myHrp = hrp()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= pl and p.Character then
            local c = p.Character
            local th = c:FindFirstChild("HumanoidRootPart")
            local hum2 = c:FindFirstChildWhichIsA("Humanoid")

            if th and hum2 and hum2.Health > 0 then
                -- Highlight
                local hl = espHL[p]
                if not hl or hl.Parent ~= pg then
                    if hl then hl:Destroy() end
                    hl = Instance.new("Highlight")
                    hl.Name = "AutoFarmPlayerHL"
                    hl.FillColor = Color3.fromRGB(255, 40, 40)
                    hl.FillTransparency = 0.55
                    hl.OutlineColor = Color3.fromRGB(255, 255, 0)
                    hl.OutlineTransparency = 0
                    hl.Adornee = c
                    hl.Parent = pg
                    espHL[p] = hl
                end

                -- BillboardTag
                local tag = espTags[p]
                if not tag or tag.Parent ~= pg then
                    if tag then tag:Destroy() end
                    tag = Instance.new("BillboardGui")
                    tag.Name = "AutoFarmPlayerTag"
                    tag.Size = UDim2.new(0, 160, 0, 48)
                    tag.StudsOffset = Vector3.new(0, 3.5, 0)
                    tag.AlwaysOnTop = true
                    tag.Adornee = th

                    local nameLbl = Instance.new("TextLabel", tag)
                    nameLbl.Name = "NameLbl"
                    nameLbl.Size = UDim2.new(1, 0, 0, 16)
                    nameLbl.BackgroundTransparency = 1
                    nameLbl.TextColor3 = Color3.fromRGB(255, 230, 100)
                    nameLbl.Font = Enum.Font.GothamBold
                    nameLbl.TextSize = 12
                    nameLbl.TextStrokeTransparency = 0.2

                    local infoLbl = Instance.new("TextLabel", tag)
                    infoLbl.Name = "InfoLbl"
                    infoLbl.Size = UDim2.new(1, 0, 0, 14)
                    infoLbl.Position = UDim2.new(0, 0, 0, 16)
                    infoLbl.BackgroundTransparency = 1
                    infoLbl.TextColor3 = Color3.fromRGB(180, 230, 255)
                    infoLbl.Font = Enum.Font.Gotham
                    infoLbl.TextSize = 10
                    infoLbl.TextStrokeTransparency = 0.2

                    local hpBarBg = Instance.new("Frame", tag)
                    hpBarBg.Name = "HpBg"
                    hpBarBg.Size = UDim2.new(0.8, 0, 0, 4)
                    hpBarBg.Position = UDim2.new(0.1, 0, 0, 32)
                    hpBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                    Instance.new("UICorner", hpBarBg).CornerRadius = UDim.new(0, 2)

                    local hpFill = Instance.new("Frame", hpBarBg)
                    hpFill.Name = "HpFill"
                    hpFill.Size = UDim2.new(1, 0, 1, 0)
                    hpFill.BackgroundColor3 = Color3.fromRGB(0, 255, 120)
                    Instance.new("UICorner", hpFill).CornerRadius = UDim.new(0, 2)

                    tag.Parent = pg
                    espTags[p] = tag
                end

                -- تحديث البيانات في الوقت الحقيقي
                if tag then
                    local dist = myHrp and (th.Position - myHrp.Position).Magnitude or 0
                    local rName = getPlayerRankInfo(p)
                    local nameL = tag:FindFirstChild("NameLbl")
                    local infoL = tag:FindFirstChild("InfoLbl")
                    local hpBg = tag:FindFirstChild("HpBg")
                    local hpFill = hpBg and hpBg:FindFirstChild("HpFill")

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
        else
            if espHL[p] then espHL[p]:Destroy(); espHL[p] = nil end
            if espTags[p] then espTags[p]:Destroy(); espTags[p] = nil end
        end
    end
end

-- 2) كشف الدروبات الاحترافي (لوحة عائمة + هايلايت نيون أزرق/ذهبي)
local function updateDropESP()
    local myHrp = hrp()
    for _, n in ipairs(CFG.DROP_NAMES) do
        local obj = workspace:FindFirstChild(n)
        if obj then
            local part = getPart(obj)
            if part then
                local hl = espDropHL[obj]
                if not hl or hl.Parent ~= pg then
                    if hl then hl:Destroy() end
                    local isSec = classifyDrop(obj) == "secret"
                    hl = Instance.new("Highlight")
                    hl.Name = "AutoFarmDropHL"
                    hl.FillColor = isSec and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(0, 200, 255)
                    hl.FillTransparency = 0.4
                    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                    hl.Adornee = obj
                    hl.Parent = pg
                    espDropHL[obj] = hl
                end

                local tag = espDropTags[obj]
                if not tag or tag.Parent ~= pg then
                    if tag then tag:Destroy() end
                    tag = Instance.new("BillboardGui")
                    tag.Name = "AutoFarmDropTag"
                    tag.Size = UDim2.new(0, 140, 0, 30)
                    tag.StudsOffset = Vector3.new(0, 3, 0)
                    tag.AlwaysOnTop = true
                    tag.Adornee = part

                    local lbl = Instance.new("TextLabel", tag)
                    lbl.Name = "DropLbl"
                    lbl.Size = UDim2.new(1, 0, 1, 0)
                    lbl.BackgroundTransparency = 1
                    lbl.Font = Enum.Font.GothamBold
                    lbl.TextSize = 12
                    lbl.TextStrokeTransparency = 0.2
                    tag.Parent = pg
                    espDropTags[obj] = tag
                end

                if tag then
                    local isSec = classifyDrop(obj) == "secret"
                    local dist = myHrp and (part.Position - myHrp.Position).Magnitude or 0
                    local lbl = tag:FindFirstChild("DropLbl")
                    if lbl then
                        lbl.Text = ("%s (%.0fm)"):format(isSec and "🏆 دروب سري" or "📦 دروب جوي", dist)
                        lbl.TextColor3 = isSec and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(0, 230, 255)
                    end
                end
            end
        else
            if espDropHL[obj] then espDropHL[obj]:Destroy(); espDropHL[obj] = nil end
            if espDropTags[obj] then espDropTags[obj]:Destroy(); espDropTags[obj] = nil end
        end
    end
end

-- 3) كشف الأسلحة والدروع (Item ESP)
local function updateItemESP()
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            local at = (d.ActionText or "") .. " " .. (d.ObjectText or "") .. " " .. d.Name
            local atl = at:lower()
            if atl:find("armor") or atl:find("درع") or atl:find("gun") or atl:find("سلاح") or atl:find("scar") or atl:find("ak") then
                local par = d.Parent
                if par and not espItemHL[par] then
                    local h = Instance.new("Highlight")
                    h.Name = "AutoFarmItemHL"
                    h.FillColor = Color3.fromRGB(50, 255, 120)
                    h.FillTransparency = 0.5
                    h.OutlineColor = Color3.fromRGB(0, 255, 200)
                    h.Adornee = par
                    h.Parent = par
                    espItemHL[par] = h
                end
            end
        end
    end
end

-- حلقة التحديث المستمر لخانة الكشف (ESP Loop — بدون أي لاق)
task.spawn(function()
    while not _G.StopAutoFarm do
        task.wait(0.6)
        if ST.espPlayers then pcall(updatePlayerESP) end
        if ST.espDrops then pcall(updateDropESP) end
        if ST.espItems then pcall(updateItemESP) end
    end
end)

-- ═══ FULLBRIGHT ═══
local function enableFullbright()
    lightSave.Brightness=Lighting.Brightness; lightSave.ClockTime=Lighting.ClockTime
    lightSave.FogEnd=Lighting.FogEnd; lightSave.GlobalShadows=Lighting.GlobalShadows
    Lighting.Brightness=2; Lighting.ClockTime=14; Lighting.FogEnd=1e6; Lighting.GlobalShadows=false
    for _,e in ipairs(Lighting:GetDescendants()) do
        if e:IsA("Atmosphere") or e:IsA("BloomEffect") or e:IsA("BlurEffect") or e:IsA("ColorCorrectionEffect") then e.Enabled=false end
    end
end
local function disableFullbright()
    for prop,val in pairs(lightSave) do pcall(function() Lighting[prop]=val end) end
    for _,e in ipairs(Lighting:GetDescendants()) do
        if e:IsA("Atmosphere") or e:IsA("BloomEffect") or e:IsA("BlurEffect") or e:IsA("ColorCorrectionEffect") then e.Enabled=true end
    end
end

-- ═══════════════════════════════════════════════════════════════
--  🛡️ نظام الحماية من الكلبشة والطلقات (Combat Defense System)
-- ═══════════════════════════════════════════════════════════════

-- 1) مضاد الكلبشة الفوري (Anti-Cuff): كسر وتفكيك أي محاولة كلبشة فوراً
local function runAntiCuff()
    local c = char()
    if not c then return end
    for _, d in ipairs(c:GetDescendants()) do
        if d:IsA("Weld") or d:IsA("WeldConstraint") or d:IsA("Motor6D") or d:IsA("BodyVelocity") or d:IsA("BodyPosition") then
            local dn = d.Name:lower()
            if dn:find("cuff") or dn:find("arrest") or dn:find("handcuff") or dn:find("freeze") or dn:find("taze") or dn:find("كلبش") then
                pcall(function() d:Destroy() end)
            end
        end
    end
    local h = hum()
    if h then
        if h.PlatformStand then h.PlatformStand = false end
        if h.Sit then h.Sit = false end
        if h.WalkSpeed < 10 and not ST.handlingDrop then
            h.WalkSpeed = ST.customSpeedOn and ST.walkSpeed or 16
        end
    end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("ProximityPrompt") then
            local at = (p.ActionText or "") .. " " .. (p.ObjectText or "")
            if at:find("كلبشة") or at:find("Arrest") or at:lower():find("cuff") then
                p.Enabled = false
            end
        end
    end
end

-- 2) أخذ الدرع التلقائي عند الإصابة وتجديد الصحة (Auto-Armor Defense)
local function runAutoArmorRefill()
    local h = hum()
    if not h or h.Health <= 0 then return end
    if h.Health < 90 and (tick() - ST.lastArmorRefill > 4) then
        ST.lastArmorRefill = tick()
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("ProximityPrompt") then
                local at = (d.ActionText or "") .. " " .. (d.ObjectText or "") .. " " .. d.Name
                if at:lower():find("armor") or at:find("درع") then
                    triggerPromptInstantly(d)
                    addLog("🛡️ تفعيل الدرع التلقائي لحمايتك من الطلقات!")
                    break
                end
            end
        end
    end
end

addC(RUN.Heartbeat:Connect(function()
    if _G.StopAutoFarm then return end
    if ST.antiCuff then pcall(runAntiCuff) end
    if ST.autoArmorDefense then pcall(runAutoArmorRefill) end
end))

-- ═══ AUTO-CUFF (كلبشة لاعب آخر) ═══
local function cuffPlayer(targetPlr)
    if not targetPlr or not targetPlr.Character then addLog("اللاعب غير موجود للكلبشة") return end
    local tc = targetPlr.Character; local th = tc:FindFirstChild("HumanoidRootPart")
    if not th then addLog("اللاعب ليس له موقع") return end

    local bp = pl:FindFirstChild("Backpack")
    local cuffTool = (bp and bp:FindFirstChild("Cuffs")) or (char() and char():FindFirstChild("Cuffs"))
    if not cuffTool and bp then
        for _, item in ipairs(bp:GetChildren()) do
            if item:IsA("Tool") and (item.Name:lower():find("cuff") or item.Name:find("كلبش") or item.Name:find("مصفاد")) then
                cuffTool = item; break
            end
        end
    end

    if cuffTool and cuffTool.Parent == bp then
        local h = hum()
        if h then h:EquipTool(cuffTool); task.wait(0.12) end
    end

    pcall(function()
        char():PivotTo(CFrame.new(th.Position + (th.CFrame.LookVector * -2.5) + Vector3.new(0, 0.5, 0)))
    end)
    task.wait(0.12)

    if cuffTool and cuffTool:IsA("Tool") then
        pcall(function() cuffTool:Activate() end)
    end
    touchObj(th)
    addLog(("👮‍♂️ محاولة كلبشة: %s"):format(targetPlr.DisplayName))
end

-- ═══ SPECTATE (مراقبة الكاميرا) ═══
local function toggleSpectate(targetPlr)
    local h = hum()
    if ST.spectating then
        ST.spectating = false
        ST.spectateTarget = nil
        if h then cam.CameraSubject = h end
        addLog("إلغاء المراقبة — العودة لكاميرتك")
    else
        if not targetPlr or not targetPlr.Character then addLog("اللاعب غير موجود") return end
        local th = targetPlr.Character:FindFirstChildWhichIsA("Humanoid")
        if th then
            cam.CameraSubject = th
            ST.spectating = true
            ST.spectateTarget = targetPlr
            addLog(("👁️ جاري مراقبة: %s"):format(targetPlr.DisplayName))
        end
    end
end

-- ═══ ميزات الماب اليدوية (بنقرة زر) ═══
local function takeArmor()
    local found = false
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            local at = (d.ActionText or "") .. " " .. (d.ObjectText or "") .. " " .. d.Name
            if at:lower():find("armor") or at:find("درع") then
                triggerPromptInstantly(d)
                found = true
            end
        end
    end
    addLog(found and "🛡️ تم إرسال أمر أخذ الدرع" or "لم يتم العثور على برومبت درع قريب")
end

local function grabWeapons()
    local count = 0
    local bp = pl:FindFirstChild("Backpack")
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Tool") and bp then
            local tn = obj.Name:lower()
            if tn:find("scar") or tn:find("ak") or tn:find("قناص") or tn:find("sniper") or tn:find("m4") or tn:find("gun") then
                pcall(function() obj.Parent = bp end)
                count = count + 1
            end
        elseif obj:IsA("ProximityPrompt") then
            local at = (obj.ActionText or ""):lower()
            if at:find("gun") or at:find("weapon") or at:find("سلاح") or at:find("take") then
                triggerPromptInstantly(obj)
                count = count + 1
            end
        end
    end
    addLog(("🔫 تم سحب وتجهيز %d سلاح/برومبت"):format(count))
end

local function openAllGates()
    local count = 0
    for _, cd in ipairs(workspace:GetDescendants()) do
        if cd:IsA("ClickDetector") then
            local pn = cd.Parent and cd.Parent.Name:lower() or ""
            if pn:find("open") or pn:find("out") or pn:find("gate") or pn:find("door") or pn:find("system") then
                pcall(function()
                    if typeof(fireclickdetector) == "function" then
                        fireclickdetector(cd)
                        count = count + 1
                    end
                end)
            end
        end
    end
    addLog(("🚪 تم إرسال أمر فتح لـ %d بوابة"):format(count))
end

local function toggleOfficeDoors()
    local count = 0
    for _, pr in ipairs(workspace:GetDescendants()) do
        if pr:IsA("ProximityPrompt") and pr.Parent and (pr.Parent.Name == "On" or pr.Parent.Name == "Off") then
            triggerPromptInstantly(pr)
            count = count + 1
        end
    end
    addLog(("🔓 تم تبديل %d مفتاح أبواب مكاتب"):format(count))
end

local function wearUniform(uniformName)
    local found = false
    local cs = workspace:FindFirstChild("ClothingSystem") or workspace:FindFirstChild("Clothes", true)
    if cs then
        for _, pr in ipairs(cs:GetDescendants()) do
            if pr:IsA("ProximityPrompt") then
                local txt = (pr.ActionText or "") .. " " .. (pr.ObjectText or "") .. " " .. pr.Parent.Name
                if txt:find(uniformName) then
                    triggerPromptInstantly(pr)
                    found = true
                end
            end
        end
    end
    addLog(found and ("👔 تم ارتداء: %s"):format(uniformName) or ("لم يتم العثور على: %s بالقرب منك"):format(uniformName))
end

local function claimRewardsManually()
    local count = 0
    for _, g in ipairs(pg:GetChildren()) do
        if g:IsA("ScreenGui") and not g.Name:find("FinalFix") and not g.Name:find("AutoFarm") then
            for _, b in ipairs(g:GetDescendants()) do
                if (b:IsA("TextButton") or b:IsA("ImageButton")) and b.Visible then
                    local t = (b:IsA("TextButton") and b.Text or "")
                    for _, sub in ipairs(b:GetChildren()) do if sub:IsA("TextLabel") then t = t .. " " .. (sub.Text or "") end end
                    local tl = t:lower()
                    if tl:find("claim") or tl:find("استلام") or tl:find("مكافأة") or tl:find("daily") or tl:find("playtime") then
                        clickBtn(b); count = count + 1; task.wait(0.08)
                    end
                end
            end
        end
    end
    if REM.ClaimReward then pcall(function() REM.ClaimReward:FireServer() end) end
    addLog(("🎁 تم المطالبة بـ %d جوائز"):format(count))
end

-- ═══ Click TP ═══
addC(UIS.InputBegan:Connect(function(input, gp)
    if gp or not ST.clickTpOn then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
        local mouse = pl:GetMouse()
        if mouse and mouse.Hit and hrp() then
            pcall(function() char():PivotTo(CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))) end)
            addLog("انتقال بنقرة ماوس (Ctrl+Click)")
        end
    end
end))

-- ═══ Anti-Sit ═══
addC(RUN.Heartbeat:Connect(function()
    if ST.antiSitOn then
        local h = hum()
        if h then
            if h.Sit then h.Sit = false end
            if h:GetState() == Enum.HumanoidStateType.Ragdoll or h:GetState() == Enum.HumanoidStateType.FallingDown then
                h:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
    end
end))

local function toggleFpsBoost()
    ST.fpsBoostOn = not ST.fpsBoostOn
    pcall(function()
        Lighting.GlobalShadows = not ST.fpsBoostOn
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and not v.Parent:FindFirstChildWhichIsA("Humanoid") then
                v.Material = ST.fpsBoostOn and Enum.Material.SmoothPlastic or Enum.Material.Plastic
            end
        end
    end)
    addLog(ST.fpsBoostOn and "🚀 تم تفعيل تسريع الفريمات" or "إعادة الجرافيكس الطبيعي")
end

local function copyPos()
    local r = hrp()
    if r then
        local s = ("Vector3.new(%.2f, %.2f, %.2f)"):format(r.Position.X, r.Position.Y, r.Position.Z)
        pcall(function() setclipboard(s) end)
        addLog("📋 تم نسخ الإحداثيات للحافظة")
    end
end

-- ═══ HEARTBEAT ═══
addC(RUN.Heartbeat:Connect(function()
    if _G.StopAutoFarm then return end
    local h, r = hum(), hrp(); if not h or not r or not alive() then return end
    if r.Position.Y < -100 then pcall(function() r.AssemblyLinearVelocity = Vector3.zero; r.AssemblyAngularVelocity = Vector3.zero; char():PivotTo(CFrame.new(CFG.SAFE_POS)) end) end
    if ST.customSpeedOn and not ST.handlingDrop and not ST.flyOn then h.WalkSpeed = ST.walkSpeed end
    if ST.superJumpOn then if h.UseJumpPower then h.JumpPower = ST.jumpPower else h.JumpHeight = ST.jumpPower*0.15 end end
    if ST.flyOn and flyBV and flyBG then
        flyBG.CFrame = cam.CFrame
        local mv = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then mv = mv + cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then mv = mv - cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then mv = mv - cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then mv = mv + cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then mv = mv + Vector3.new(0, 1, 0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then mv = mv - Vector3.new(0, 1, 0) end
        flyBV.Velocity = mv.Magnitude > 0 and mv.Unit * ST.flySpeed or Vector3.zero
    end
    if ST.noclipOn then local c = char(); if c then for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end end
    if ST.invisOn then for _, d in ipairs(char():GetDescendants()) do
        if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" and d.Transparency < 1 then d.Transparency = 1
        elseif d:IsA("BillboardGui") and d.Enabled then d.Enabled = false end
    end end
    pcall(function() cam.FieldOfView = ST.fov end)
    if ST.antiFling then
        local vel = r.AssemblyLinearVelocity; if vel.Magnitude > 120 then r.AssemblyLinearVelocity = Vector3.zero; r.AssemblyAngularVelocity = Vector3.zero end
    end
    if ST.busyDrop and ST.busyDropSince > 0 and (tick() - ST.busyDropSince) > 60 then ST.busyDrop = false; ST.handlingDrop = false; addLog("reset drop flag (timeout)") end
    if ST.busyCyber and ST.busyCyberSince > 0 and (tick() - ST.busyCyberSince) > 30 then ST.busyCyber = false; addLog("reset cyber flag (timeout)") end
end))

addC(UIS.JumpRequest:Connect(function() if ST.infJumpOn and alive() then local h = hum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end end))
addC(pl.Idled:Connect(function() pcall(function() VU:CaptureController(); VU:ClickButton2(Vector2.zero) end) end))

-- ═══════════════════════════════════════════════════════════
--  الواجهة — 5 تبويبات كاملة نيون (v4.6)
-- ═══════════════════════════════════════════════════════════
local gui = Instance.new("ScreenGui"); gui.Name = "FinalFixGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.Parent = pg
local mobGui = Instance.new("ScreenGui"); mobGui.Name = "FinalFixMobileBtn"; mobGui.ResetOnSpawn = false; mobGui.IgnoreGuiInset = true; mobGui.Parent = pg

local floatBtn = Instance.new("TextButton", mobGui); floatBtn.Size = UDim2.new(0, 52, 0, 52); floatBtn.Position = UDim2.new(0, 14, 0.45, 0)
floatBtn.BackgroundColor3 = Color3.fromRGB(14, 16, 26); floatBtn.Text = "v4.6"; floatBtn.TextSize = 13; floatBtn.TextColor3 = Color3.fromRGB(0, 255, 200)
floatBtn.Font = Enum.Font.GothamBold; floatBtn.Active = true; floatBtn.Draggable = true
Instance.new("UICorner", floatBtn).CornerRadius = UDim.new(1, 0)
local fStroke = Instance.new("UIStroke", floatBtn); fStroke.Thickness = 2.5

local frame = Instance.new("Frame", gui); frame.Size = UDim2.new(0, 580, 0, 450); frame.Position = UDim2.new(0.5, -290, 0.5, -225)
frame.BackgroundColor3 = Color3.fromRGB(10, 12, 18); frame.BorderSizePixel = 0; frame.Active = true; frame.Draggable = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
local mStroke = Instance.new("UIStroke", frame); mStroke.Thickness = 2

addC(RUN.RenderStepped:Connect(function() local c = Color3.fromHSV((tick()*0.2)%1, 0.8, 1); mStroke.Color = c; fStroke.Color = c end))

local header = Instance.new("Frame", frame); header.Size = UDim2.new(1, 0, 0, 38); header.BackgroundColor3 = Color3.fromRGB(14, 18, 28)
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 12)
local title = Instance.new("TextLabel", header); title.Size = UDim2.new(1, -80, 1, 0); title.Position = UDim2.new(0, 14, 0, 0)
title.BackgroundTransparency = 1; title.Text = "AUTOFARM v4.7 — ULTIMATE EDITION"; title.TextColor3 = Color3.fromRGB(210, 230, 255)
title.Font = Enum.Font.GothamBold; title.TextSize = 13; title.TextXAlignment = Enum.TextXAlignment.Left

local closeX = Instance.new("TextButton", header); closeX.Size = UDim2.new(0, 28, 0, 28); closeX.Position = UDim2.new(1, -34, 0, 5)
closeX.BackgroundColor3 = Color3.fromRGB(200, 40, 40); closeX.Text = "X"; closeX.TextColor3 = Color3.new(1, 1, 1)
closeX.Font = Enum.Font.GothamBold; closeX.TextSize = 14; Instance.new("UICorner", closeX).CornerRadius = UDim.new(0, 8)

local tabBar = Instance.new("Frame", frame); tabBar.Size = UDim2.new(1, -16, 0, 30); tabBar.Position = UDim2.new(0, 8, 0, 42)
tabBar.BackgroundColor3 = Color3.fromRGB(14, 18, 28); Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0, 8)

local tabNames = {"الأوتوفارم", "الحركة", "الكشف", "الخريطة الحية", "الأدوات"}
local tabBtns = {}; local tabs = {}

for i, name in ipairs(tabNames) do
    local b = Instance.new("TextButton", tabBar); b.Size = UDim2.new(0.2, 0, 1, 0); b.Position = UDim2.new((i-1)*0.2, 0, 0, 0)
    b.BackgroundTransparency = 1; b.Text = name; b.TextColor3 = Color3.fromRGB(140, 160, 190)
    b.Font = Enum.Font.GothamBold; b.TextSize = 11; tabBtns[i] = b
    local t = Instance.new("ScrollingFrame", frame); t.Size = UDim2.new(1, -16, 1, -84); t.Position = UDim2.new(0, 8, 0, 78)
    t.BackgroundTransparency = 1; t.Visible = (i == 1); t.ScrollBarThickness = 3; t.CanvasSize = UDim2.new(0, 0, 0, 0)
    t.AutomaticCanvasSize = Enum.AutomaticSize.Y; tabs[i] = t
end

local function selectTab(n)
    for i = 1, #tabNames do
        tabs[i].Visible = (i == n)
        tabBtns[i].TextColor3 = (i == n) and Color3.fromRGB(0, 255, 200) or Color3.fromRGB(140, 160, 190)
    end
end
for i, b in ipairs(tabBtns) do b.MouseButton1Click:Connect(function() selectTab(i) end) end
selectTab(1)

-- ═══ UI HELPERS ═══
local function mkCard(parent, h, yOff)
    local c = Instance.new("Frame", parent); c.Size = UDim2.new(1, 0, 0, h); c.Position = UDim2.new(0, 0, 0, yOff)
    c.BackgroundColor3 = Color3.fromRGB(16, 20, 32); Instance.new("UICorner", c).CornerRadius = UDim.new(0, 10); return c
end
local function mkLabel(parent, txt, x, y, w, h, sz)
    local l = Instance.new("TextLabel", parent); l.Size = UDim2.new(0, w, 0, h or 24); l.Position = UDim2.new(0, x, 0, y)
    l.BackgroundTransparency = 1; l.Text = txt; l.TextColor3 = Color3.fromRGB(200, 220, 240)
    l.Font = Enum.Font.GothamBold; l.TextSize = sz or 12; l.TextXAlignment = Enum.TextXAlignment.Left; l.TextWrapped = true; return l
end
local function mkToggle(parent, txt, x, y, w, h, initOn, cb)
    local b = Instance.new("TextButton", parent); b.Size = UDim2.new(0, w, 0, h or 28); b.Position = UDim2.new(0, x, 0, y)
    b.BackgroundColor3 = initOn and Color3.fromRGB(25, 110, 65) or Color3.fromRGB(60, 65, 80)
    b.Text = txt .. (initOn and ": ON" or ": OFF"); b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold; b.TextSize = 11; b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
    local state = initOn
    b.MouseButton1Click:Connect(function()
        state = not state
        b.Text = txt .. (state and ": ON" or ": OFF")
        b.BackgroundColor3 = state and Color3.fromRGB(25, 110, 65) or Color3.fromRGB(60, 65, 80)
        if cb then cb(state) end
    end)
    return b, function() return state end
end
local function mkAction(parent, txt, x, y, w, h, col, cb)
    local b = Instance.new("TextButton", parent); b.Size = UDim2.new(0, w, 0, h or 28); b.Position = UDim2.new(0, x, 0, y)
    b.BackgroundColor3 = col; b.Text = txt; b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold; b.TextSize = 11; b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
    if cb then b.MouseButton1Click:Connect(cb) end; return b
end

-- ════════════════════════════════════════════
--  تبويب 1: الأوتوفارم
-- ════════════════════════════════════════════
local t1 = tabs[1]
local c1a = mkCard(t1, 32, 0)
statsLbl = mkLabel(c1a, "جاهز", 8, 0, 540, 32, 11)
statusLbl = Instance.new("TextLabel", t1); statusLbl.Size = UDim2.new(1, 0, 0, 22); statusLbl.Position = UDim2.new(0, 0, 0, 38)
statusLbl.BackgroundColor3 = Color3.fromRGB(10, 24, 20); statusLbl.Text = "خامل"; statusLbl.TextColor3 = Color3.fromRGB(120, 255, 200)
statusLbl.Font = Enum.Font.Code; statusLbl.TextSize = 11; Instance.new("UICorner", statusLbl).CornerRadius = UDim.new(0, 6)

scroll = Instance.new("ScrollingFrame", t1); scroll.Size = UDim2.new(1, 0, 0, 160); scroll.Position = UDim2.new(0, 0, 0, 64)
scroll.BackgroundColor3 = Color3.fromRGB(6, 8, 14); scroll.ScrollBarThickness = 3; Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 8)
logLbl = Instance.new("TextLabel", scroll); logLbl.Size = UDim2.new(1, -8, 0, 1); logLbl.Position = UDim2.new(0, 4, 0, 4)
logLbl.AutomaticSize = Enum.AutomaticSize.Y; logLbl.BackgroundTransparency = 1; logLbl.Text = ""
logLbl.TextColor3 = Color3.fromRGB(170, 210, 245); logLbl.Font = Enum.Font.Code; logLbl.TextSize = 10
logLbl.TextXAlignment = Enum.TextXAlignment.Left; logLbl.TextYAlignment = Enum.TextYAlignment.Top; logLbl.TextWrapped = true

local y1 = 232
mkToggle(t1, "مهام", 0, y1, 180, 30, true, function(v) ST.autoMission = v end)
mkToggle(t1, "دروبات (سريعة)", 186, y1, 180, 30, true, function(v) ST.autoDrop = v end)
mkToggle(t1, "كاشف السيبراني", 372, y1, 188, 30, true, function(v) ST.autoCyber = v end)
mkToggle(t1, "جمع تلقائي", 0, y1 + 36, 180, 30, false, function(v) ST.autoCollect = v end)
mkAction(t1, "استلام الجائزة", 186, y1 + 36, 180, 30, Color3.fromRGB(110, 85, 25), function()
    if REM.ClaimReward then pcall(function() REM.ClaimReward:FireServer() end) end; addLog("طلب استلام الجائزة")
end)
mkAction(t1, "دخول الكهف", 372, y1 + 36, 188, 30, Color3.fromRGB(35, 70, 140), function() task.spawn(lootCyberCave) end)
mkAction(t1, "🎁 استلام جوائز وقت اللعب واليومية", 0, y1 + 72, 276, 30, Color3.fromRGB(35, 100, 75), claimRewardsManually)
mkAction(t1, "ايقاف السكربت", 284, y1 + 72, 276, 30, Color3.fromRGB(160, 30, 30), shutdown)

-- ════════════════════════════════════════════
--  تبويب 2: الحركة
-- ════════════════════════════════════════════
local t2 = tabs[2]
local c2a = mkCard(t2, 74, 0)
mkLabel(c2a, "السرعة", 10, 4, 80, 24, 13)
local spdInput = Instance.new("TextBox", c2a); spdInput.Size = UDim2.new(0, 65, 0, 26); spdInput.Position = UDim2.new(0, 80, 0, 3)
spdInput.BackgroundColor3 = Color3.fromRGB(28, 34, 50); spdInput.Text = "16"; spdInput.TextColor3 = Color3.fromRGB(0, 255, 200)
spdInput.Font = Enum.Font.GothamBold; spdInput.TextSize = 14; spdInput.PlaceholderText = "رقم"; spdInput.ClearTextOnFocus = false
Instance.new("UICorner", spdInput).CornerRadius = UDim.new(0, 6); Instance.new("UIStroke", spdInput).Color = Color3.fromRGB(50, 65, 90)

local spdStat = mkLabel(c2a, "معطلة", 155, 4, 70, 24, 10); spdStat.TextColor3 = Color3.fromRGB(140, 150, 170)
mkToggle(c2a, "تثبيت", 420, 3, 120, 26, false, function(v)
    ST.customSpeedOn = v
    if v then local n = tonumber(spdInput.Text); if n and n >= 1 and n <= 500 then ST.walkSpeed = n; spdStat.Text = ("(%d)"):format(n); spdStat.TextColor3 = Color3.fromRGB(0, 255, 200)
    else ST.walkSpeed = 16 end
    else local h2 = hum(); if h2 then h2.WalkSpeed = 16 end; spdStat.Text = "معطلة"; spdStat.TextColor3 = Color3.fromRGB(140, 150, 170) end
end)
spdInput.FocusLost:Connect(function(enter) if enter then
    local n = tonumber(spdInput.Text); if n and n >= 1 and n <= 500 then
        ST.walkSpeed = n; ST.customSpeedOn = true; spdStat.Text = ("(%d)"):format(n); spdStat.TextColor3 = Color3.fromRGB(0, 255, 200)
        addLog(("سرعة: %d"):format(n))
end end end)
local spdRow = Instance.new("Frame", c2a); spdRow.Size = UDim2.new(1, -20, 0, 24); spdRow.Position = UDim2.new(0, 10, 0, 38); spdRow.BackgroundTransparency = 1
for idx, val in ipairs({16, 32, 48, 75, 100}) do
    local b = Instance.new("TextButton", spdRow); b.Size = UDim2.new(0.18, 0, 1, 0); b.Position = UDim2.new((idx-1)*0.205, 0, 0, 0)
    b.BackgroundColor3 = Color3.fromRGB(24, 32, 48); b.Text = tostring(val); b.TextColor3 = Color3.fromRGB(170, 210, 240)
    b.Font = Enum.Font.GothamBold; b.TextSize = 12; Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.MouseButton1Click:Connect(function() spdInput.Text = tostring(val); ST.walkSpeed = val; ST.customSpeedOn = true
        spdStat.Text = ("(%d)"):format(val); spdStat.TextColor3 = Color3.fromRGB(0, 255, 200); addLog(("سرعة: %d"):format(val)) end)
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
    b.BackgroundColor3 = Color3.fromRGB(24, 32, 48); b.Text = tostring(val); b.TextColor3 = Color3.fromRGB(170, 210, 240)
    b.Font = Enum.Font.GothamBold; b.TextSize = 12; Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.MouseButton1Click:Connect(function() ST.jumpPower = val; ST.superJumpOn = true
        jmpStat.Text = ("(%d)"):format(val); jmpStat.TextColor3 = Color3.fromRGB(0, 255, 200); addLog(("قفز: %d"):format(val)) end)
end

local c2c = mkCard(t2, 36, 164)
mkLabel(c2c, "الطيران — WASD + Space/Shift", 10, 6, 260, 24, 12)
mkToggle(c2c, "طيران", 420, 4, 120, 26, false, function(v) if v then startFly() else stopFly() end; addLog(v and "طيران: ON" or "طيران: OFF") end)

local c2d = mkCard(t2, 36, 208)
mkLabel(c2d, "اختراق الجدران (Noclip)", 10, 6, 260, 24, 12)
mkToggle(c2d, "Noclip", 420, 4, 120, 26, false, function(v) setNoclip(v); addLog(v and "Noclip: ON" or "Noclip: OFF") end)

local c2e = mkCard(t2, 36, 252)
mkLabel(c2e, "قفز لا نهائي في الهواء", 10, 6, 260, 24, 12)
mkToggle(c2e, "Inf Jump", 420, 4, 120, 26, false, function(v) ST.infJumpOn = v; addLog(v and "Inf Jump: ON" or "Inf Jump: OFF") end)

local c2f = mkCard(t2, 40, 296)
mkLabel(c2f, "انتقال لإحداثيات", 10, 8, 140, 24, 12)
local tpX = Instance.new("TextBox", c2f); tpX.Size = UDim2.new(0, 55, 0, 24); tpX.Position = UDim2.new(0, 160, 0, 8)
tpX.BackgroundColor3 = Color3.fromRGB(28, 34, 50); tpX.Text = "0"; tpX.TextColor3 = Color3.fromRGB(0, 255, 200)
tpX.Font = Enum.Font.Code; tpX.TextSize = 11; tpX.PlaceholderText = "X"; Instance.new("UICorner", tpX).CornerRadius = UDim.new(0, 4)
local tpY = tpX:Clone(); tpY.Parent = c2f; tpY.Position = UDim2.new(0, 225, 0, 8); tpY.PlaceholderText = "Y"; tpY.Text = "10"
local tpZ = tpX:Clone(); tpZ.Parent = c2f; tpZ.Position = UDim2.new(0, 290, 0, 8); tpZ.PlaceholderText = "Z"; tpZ.Text = "0"
mkAction(c2f, "انتقال", 420, 6, 120, 28, Color3.fromRGB(35, 80, 140), function()
    local x, y, z = tonumber(tpX.Text), tonumber(tpY.Text), tonumber(tpZ.Text)
    if x and y and z then pcall(function() char():PivotTo(CFrame.new(x, y, z)) end); addLog(("انتقال: %.0f,%.0f,%.0f"):format(x, y, z))
    else addLog("إحداثيات خاطئة") end
end)

-- ════════════════════════════════════════════
--  تبويب 3: الكشف المطور (ESP Pro)
-- ════════════════════════════════════════════
local t3 = tabs[3]

local c3a = mkCard(t3, 44, 0)
mkLabel(c3a, "كشف اللاعبين (ESP) — هايلايت + رتبة وصحة ومسافة", 10, 10, 360, 24, 12)
mkToggle(c3a, "ESP لاعبين", 420, 8, 120, 28, false, function(v)
    ST.espPlayers = v
    if v then task.spawn(updatePlayerESP); addLog("ESP لاعبين: ON")
    else
        for _, h in pairs(espHL) do pcall(function() h:Destroy() end) end; espHL = {}
        for _, b in pairs(espTags) do pcall(function() b:Destroy() end) end; espTags = {}
        addLog("ESP لاعبين: OFF")
    end
end)

local c3b = mkCard(t3, 44, 52)
mkLabel(c3b, "كشف الدروبات — هايلايت عبر الجدران مع المسافة", 10, 10, 360, 24, 12)
mkToggle(c3b, "ESP دروبات", 420, 8, 120, 28, false, function(v)
    ST.espDrops = v
    if v then task.spawn(updateDropESP); addLog("ESP دروبات: ON")
    else
        for _, h in pairs(espDropHL) do pcall(function() h:Destroy() end) end; espDropHL = {}
        for _, b in pairs(espDropTags) do pcall(function() b:Destroy() end) end; espDropTags = {}
        addLog("ESP دروبات: OFF")
    end
end)

local c3c = mkCard(t3, 44, 104)
mkLabel(c3c, "كشف الأسلحة والدروع — إطارات نيون لمواقع العتاد", 10, 10, 360, 24, 12)
mkToggle(c3c, "ESP عتاد", 420, 8, 120, 28, false, function(v)
    ST.espItems = v
    if v then task.spawn(updateItemESP); addLog("ESP عتاد وأسلحة: ON")
    else
        for _, h in pairs(espItemHL) do pcall(function() h:Destroy() end) end; espItemHL = {}
        addLog("ESP عتاد: OFF")
    end
end)

local c3d = mkCard(t3, 44, 156)
mkLabel(c3d, "إضاءة كاملة (Fullbright) — إزالة الظلام والضباب", 10, 10, 360, 24, 12)
mkToggle(c3d, "Fullbright", 420, 8, 120, 28, false, function(v)
    ST.fullbright = v
    if v then enableFullbright() else disableFullbright() end
    addLog(v and "Fullbright: ON" or "Fullbright: OFF")
end)

local c3e = mkCard(t3, 62, 208)
mkLabel(c3e, "مجال الرؤية (FOV)", 10, 6, 160, 24, 12)
local fovLbl = mkLabel(c3e, "70", 170, 6, 40, 24, 12); fovLbl.TextColor3 = Color3.fromRGB(0, 255, 200)
local fovRow = Instance.new("Frame", c3e); fovRow.Size = UDim2.new(1, -20, 0, 24); fovRow.Position = UDim2.new(0, 10, 0, 32); fovRow.BackgroundTransparency = 1
for idx, val in ipairs({70, 90, 100, 110, 120}) do
    local b = Instance.new("TextButton", fovRow); b.Size = UDim2.new(0.18, 0, 1, 0); b.Position = UDim2.new((idx-1)*0.205, 0, 0, 0)
    b.BackgroundColor3 = Color3.fromRGB(24, 32, 48); b.Text = tostring(val); b.TextColor3 = Color3.fromRGB(170, 210, 240)
    b.Font = Enum.Font.GothamBold; b.TextSize = 12; Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.MouseButton1Click:Connect(function() ST.fov = val; fovLbl.Text = tostring(val); addLog(("FOV: %d"):format(val)) end)
end

local c3f = mkCard(t3, 44, 278)
mkLabel(c3f, "الاختفاء التام — إخفاء الشخصية والرتبة عن الجميع", 10, 10, 360, 24, 12)
mkToggle(c3f, "اختفاء", 420, 8, 120, 28, false, function(v) ST.invisOn = v; updateInvis(); addLog(v and "اختفاء: ON" or "اختفاء: OFF") end)

-- ════════════════════════════════════════════
--  تبويب 4: الخريطة الحية (رادار v4.2 التكتيكي الأصلي)
-- ════════════════════════════════════════════
local t4 = tabs[4]

local radarCard = mkCard(t4, 250, 0)
local radarFrame = Instance.new("Frame", radarCard)
radarFrame.Size = UDim2.new(0, 240, 0, 240); radarFrame.Position = UDim2.new(0, 6, 0, 5)
radarFrame.BackgroundColor3 = Color3.fromRGB(6, 10, 16); radarFrame.ClipsDescendants = true
Instance.new("UICorner", radarFrame).CornerRadius = UDim.new(0, 8)
local rdrStroke = Instance.new("UIStroke", radarFrame); rdrStroke.Color = Color3.fromRGB(0, 255, 180); rdrStroke.Thickness = 1.5

local crossH = Instance.new("Frame", radarFrame); crossH.Size = UDim2.new(1, 0, 0, 1); crossH.Position = UDim2.new(0, 0, 0.5, 0); crossH.BackgroundColor3 = Color3.fromRGB(0, 100, 70); crossH.BorderSizePixel = 0
local crossV = Instance.new("Frame", radarFrame); crossV.Size = UDim2.new(0, 1, 1, 0); crossV.Position = UDim2.new(0.5, 0, 0, 0); crossV.BackgroundColor3 = Color3.fromRGB(0, 100, 70); crossV.BorderSizePixel = 0
local circleRing = Instance.new("Frame", radarFrame); circleRing.Size = UDim2.new(0, 150, 0, 150); circleRing.Position = UDim2.new(0.5, -75, 0.5, -75); circleRing.BackgroundTransparency = 1
Instance.new("UICorner", circleRing).CornerRadius = UDim.new(1, 0); local crk = Instance.new("UIStroke", circleRing); crk.Color = Color3.fromRGB(0, 80, 55); crk.Thickness = 1

local myBlip = Instance.new("Frame", radarFrame); myBlip.Size = UDim2.new(0, 8, 0, 8); myBlip.Position = UDim2.new(0.5, -4, 0.5, -4)
myBlip.BackgroundColor3 = Color3.fromRGB(0, 255, 120); myBlip.ZIndex = 5; Instance.new("UICorner", myBlip).CornerRadius = UDim.new(1, 0)

local inspectCard = Instance.new("Frame", radarCard); inspectCard.Size = UDim2.new(1, -260, 1, -10); inspectCard.Position = UDim2.new(0, 254, 0, 5)
inspectCard.BackgroundColor3 = Color3.fromRGB(12, 16, 26); Instance.new("UICorner", inspectCard).CornerRadius = UDim.new(0, 8)
local insStk = Instance.new("UIStroke", inspectCard); insStk.Color = Color3.fromRGB(40, 60, 90)

local targetNameLbl = mkLabel(inspectCard, "اختر بكسل أو لاعباً...", 8, 4, 280, 22, 12); targetNameLbl.TextColor3 = Color3.fromRGB(0, 255, 200)
local rankTextLbl = mkLabel(inspectCard, "الرتبة: --", 8, 28, 280, 20, 11); rankTextLbl.TextColor3 = Color3.fromRGB(200, 220, 255)

local rankCompBadge = Instance.new("TextLabel", inspectCard); rankCompBadge.Size = UDim2.new(1, -16, 0, 24); rankCompBadge.Position = UDim2.new(0, 8, 0, 52)
rankCompBadge.BackgroundColor3 = Color3.fromRGB(20, 28, 44); rankCompBadge.Text = "⚖️ مقارنة الرتبة: --"; rankCompBadge.TextColor3 = Color3.fromRGB(160, 180, 210)
rankCompBadge.Font = Enum.Font.GothamBold; rankCompBadge.TextSize = 11; Instance.new("UICorner", rankCompBadge).CornerRadius = UDim.new(0, 6)

local distLbl = mkLabel(inspectCard, "المسافة: -- متر", 8, 80, 280, 18, 10); distLbl.TextColor3 = Color3.fromRGB(140, 160, 180)

local actY = 104
mkAction(inspectCard, "🚀 انتقال إليه", 8, actY, 135, 28, Color3.fromRGB(30, 85, 145), function()
    local p = ST.radarSelectedPlr
    local tc = p and p.Character; local th = tc and tc:FindFirstChild("HumanoidRootPart")
    if th and char() then pcall(function() char():PivotTo(CFrame.new(th.Position + Vector3.new(0, 0, 3))) end); addLog(("🚀 انتقال إلى: %s"):format(p.DisplayName))
    else addLog("اللاعب غير متواجد") end
end)
mkAction(inspectCard, "👮‍♂️ كلبشة تلقائية", 150, actY, 135, 28, Color3.fromRGB(140, 70, 25), function() cuffPlayer(ST.radarSelectedPlr) end)
mkAction(inspectCard, "👁️ مراقبة الكاميرا", 8, actY + 34, 135, 28, Color3.fromRGB(70, 40, 130), function() toggleSpectate(ST.radarSelectedPlr) end)
mkAction(inspectCard, "📍 تتبع (ESP)", 150, actY + 34, 135, 28, Color3.fromRGB(30, 110, 80), function()
    local p = ST.radarSelectedPlr
    if p and p.Character then
        local oldHl = p.Character:FindFirstChild("RadarTrackHL")
        if oldHl then oldHl:Destroy(); addLog("إلغاء تتبع: "..p.DisplayName)
        else
            local h = Instance.new("Highlight"); h.Name = "RadarTrackHL"; h.FillColor = Color3.fromRGB(0, 255, 255); h.FillTransparency = 0.4
            h.OutlineColor = Color3.fromRGB(255, 255, 0); h.Adornee = p.Character; h.Parent = p.Character; addLog("📍 تم تثبيت تتبع مضيء على: "..p.DisplayName)
        end
    end
end)

local pQuickFrame = Instance.new("ScrollingFrame", t4); pQuickFrame.Size = UDim2.new(1, 0, 0, 120); pQuickFrame.Position = UDim2.new(0, 0, 0, 258)
pQuickFrame.BackgroundColor3 = Color3.fromRGB(12, 16, 24); pQuickFrame.ScrollBarThickness = 3; Instance.new("UICorner", pQuickFrame).CornerRadius = UDim.new(0, 8)

local function updateInspectorForPlayer(targetPlr)
    if not targetPlr then return end
    ST.radarSelectedPlr = targetPlr
    targetNameLbl.Text = ("%s (@%s)"):format(targetPlr.DisplayName, targetPlr.Name)

    local myRankText, myRankNum = getPlayerRankInfo(pl)
    local tRankText, tRankNum = getPlayerRankInfo(targetPlr)
    rankTextLbl.Text = ("رتبته: %s (رتبتك: %s)"):format(tRankText, myRankText)

    if tRankNum > myRankNum then
        rankCompBadge.Text = "🔺 أعلى منك رتبة!"
        rankCompBadge.TextColor3 = Color3.fromRGB(255, 80, 80)
        rankCompBadge.BackgroundColor3 = Color3.fromRGB(50, 15, 20)
    elseif tRankNum < myRankNum and tRankNum > 0 then
        rankCompBadge.Text = "🔻 أقل منك رتبة"
        rankCompBadge.TextColor3 = Color3.fromRGB(100, 255, 120)
        rankCompBadge.BackgroundColor3 = Color3.fromRGB(15, 45, 25)
    else
        rankCompBadge.Text = "⚖️ نفس رتبتك"
        rankCompBadge.TextColor3 = Color3.fromRGB(255, 220, 100)
        rankCompBadge.BackgroundColor3 = Color3.fromRGB(45, 40, 15)
    end

    local tc = targetPlr.Character; local th = tc and tc:FindFirstChild("HumanoidRootPart")
    local r = hrp()
    if th and r then distLbl.Text = ("المسافة: %.0f متر"):format((th.Position - r.Position).Magnitude)
    else distLbl.Text = "المسافة: غير معروف" end
end

local function refreshRadarPlayerList()
    for _, c in ipairs(pQuickFrame:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    local yOff = 4
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= pl then
            local tRankText, tRankNum = getPlayerRankInfo(other)
            local b = Instance.new("TextButton", pQuickFrame); b.Size = UDim2.new(1, -10, 0, 26); b.Position = UDim2.new(0, 5, 0, yOff)
            b.BackgroundColor3 = Color3.fromRGB(200, 26, 40); b.Text = ("%s | رتبة: %s"):format(other.DisplayName, tRankText)
            b.TextColor3 = Color3.fromRGB(200, 220, 245); b.Font = Enum.Font.Gotham; b.TextSize = 11; b.TextXAlignment = Enum.TextXAlignment.Left
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
        task.wait(0.1)
        if not tabs[4].Visible then continue end
        local r = hrp(); if not r then continue end
        local cx, cy = 120, 120; local radarScale = 0.35; local maxRange = 320

        for _, other in ipairs(Players:GetPlayers()) do
            if other ~= pl then
                local tc = other.Character; local th = tc and tc:FindFirstChild("HumanoidRootPart")
                local blip = blipPool[other]
                if th and tc:FindFirstChildWhichIsA("Humanoid") and tc:FindFirstChildWhichIsA("Humanoid").Health > 0 then
                    local dx = th.Position.X - r.Position.X; local dz = th.Position.Z - r.Position.Z
                    local dist = math.sqrt(dx*dx + dz*dz)
                    if dist <= maxRange then
                        local px = math.clamp(cx + (dx * radarScale), 6, 230)
                        local py = math.clamp(cy + (dz * radarScale), 6, 230)
                        if not blip then
                            blip = Instance.new("TextButton", radarFrame); blip.Size = UDim2.new(0, 8, 0, 8)
                            blip.BackgroundColor3 = Color3.fromRGB(0, 170, 255); blip.Text = ""; blip.BorderSizePixel = 0
                            Instance.new("UICorner", blip).CornerRadius = UDim.new(0, 2)
                            blip.MouseButton1Click:Connect(function() updateInspectorForPlayer(other) end)
                            blipPool[other] = blip
                        end
                        blip.Position = UDim2.new(0, px - 4, 0, py - 4); blip.Visible = true
                        blip.BackgroundColor3 = (ST.radarSelectedPlr == other) and Color3.fromRGB(255, 230, 0) or Color3.fromRGB(0, 170, 255)
                    elseif blip then blip.Visible = false end
                elseif blip then blip.Visible = false end
            end
        end

        for _, n in ipairs(CFG.DROP_NAMES) do
            local dropObj = workspace:FindFirstChild(n)
            if dropObj then
                local part = getPart(dropObj)
                if part then
                    local dx = part.Position.X - r.Position.X; local dz = part.Position.Z - r.Position.Z
                    local px = math.clamp(cx + (dx * radarScale), 6, 230)
                    local py = math.clamp(cy + (dz * radarScale), 6, 230)
                    local dBlip = dropBlips[dropObj]
                    if not dBlip then
                        dBlip = Instance.new("Frame", radarFrame); dBlip.Size = UDim2.new(0, 8, 0, 8)
                        dBlip.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
                        Instance.new("UICorner", dBlip).CornerRadius = UDim.new(0, 2)
                        dropBlips[dropObj] = dBlip
                    end
                    dBlip.Position = UDim2.new(0, px - 4, 0, py - 4); dBlip.Visible = true
                end
            end
        end
    end
end)

-- ════════════════════════════════════════════
--  تبويب 5: الأدوات والعتاد والحماية (يدوي 100%)
-- ════════════════════════════════════════════
local t5 = tabs[5]

-- 1) حماية القتال من الكلبشة والطلقات
local c5_def = mkCard(t5, 78, 0)
mkLabel(c5_def, "🛡️ أنظمة الحماية القتالية (Anti-Cuff & Defense)", 10, 6, 320, 20, 12)
mkToggle(c5_def, "مضاد الكلبشة", 10, 36, 170, 30, true, function(v)
    ST.antiCuff = v; addLog(v and "🛡️ تم تفعيل مضاد الكلبشة (Anti-Cuff)" or "إيقاف مضاد الكلبشة")
end)
mkToggle(c5_def, "درع تلقائي عند الضرر", 190, 36, 170, 30, true, function(v)
    ST.autoArmorDefense = v; addLog(v and "🛡️ تم تفعيل الدرع التلقائي عند الضرر" or "إيقاف الدرع التلقائي")
end)
mkAction(c5_def, "🛡️ أخذ درع الآن", 370, 36, 175, 30, Color3.fromRGB(30, 100, 140), takeArmor)

-- 2) أزرار عتاد الماب
local c5a = mkCard(t5, 78, 86)
mkLabel(c5a, "🔫 أزرار الأسلحة والبوابات (يدوياً بنقرة زر)", 10, 6, 320, 20, 12)
mkAction(c5a, "🔫 سحب أسلحة الماب", 10, 36, 170, 30, Color3.fromRGB(130, 80, 25), grabWeapons)
mkAction(c5a, "🚪 فتح جميع البوابات", 190, 36, 170, 30, Color3.fromRGB(25, 110, 65), openAllGates)
mkAction(c5a, "🔓 فتح غرف الضباط", 370, 36, 175, 30, Color3.fromRGB(90, 45, 120), toggleOfficeDoors)

-- 3) أزرار الملابس
local c5b = mkCard(t5, 78, 172)
mkLabel(c5b, "👔 تغيير الملابس (يدوياً بنقرة زر)", 10, 6, 320, 20, 12)
mkAction(c5b, "👔 زي مستشار الملك", 10, 36, 260, 30, Color3.fromRGB(110, 85, 25), function() wearUniform("مستشار الملك") end)
mkAction(c5b, "👔 زي الضباط", 280, 36, 265, 30, Color3.fromRGB(40, 75, 120), function() wearUniform("ضباط") end)

-- 4) أدوات مساعدة
local c5c = mkCard(t5, 38, 258)
mkLabel(c5c, "انتقال بالماوس — اضغط (Ctrl + كليك يسار) للتيليبورت", 10, 7, 350, 24, 11)
mkToggle(c5c, "Click TP", 420, 5, 120, 26, false, function(v) ST.clickTpOn = v; addLog(v and "Click TP: ON (اضغط Ctrl+Click)" or "Click TP: OFF") end)

local c5d = mkCard(t5, 38, 304)
mkLabel(c5d, "مضاد الطرد (Anti-Fling) — تثبيت اللاعب ضد الصدمات", 10, 7, 350, 24, 11)
mkToggle(c5d, "Anti-Fling", 420, 5, 120, 26, false, function(v) ST.antiFling = v; addLog(v and "Anti-Fling: ON" or "Anti-Fling: OFF") end)

local c5e = mkCard(t5, 38, 350)
mkLabel(c5e, "منع السقوط والجلوس (Anti-Sit & Anti-Ragdoll)", 10, 7, 350, 24, 11)
mkToggle(c5e, "Anti-Sit", 420, 5, 120, 26, false, function(v) ST.antiSitOn = v; addLog(v and "Anti-Sit: ON" or "Anti-Sit: OFF") end)

local c5f = mkCard(t5, 38, 396)
mkLabel(c5f, "تسريع الفريمات وتقليل اللاق (FPS Boost)", 10, 7, 350, 24, 11)
mkAction(c5f, "🚀 FPS Boost", 420, 5, 120, 26, Color3.fromRGB(30, 100, 70), toggleFpsBoost)

local c5g = mkCard(t5, 38, 442)
mkLabel(c5g, "أدوات مساعدة: نسخ إحداثياتك الحالية أو ريسباون سريع", 10, 7, 350, 24, 11)
mkAction(c5g, "📋 نسخ الموقع", 290, 5, 120, 26, Color3.fromRGB(45, 75, 130), copyPos)
mkAction(c5g, "🔄 انتحار/ريسباون", 420, 5, 120, 26, Color3.fromRGB(130, 35, 35), function() local h = hum(); if h then h.Health = 0; addLog("تمت إعادة التعيين (Reset)") end end)

local c5h = mkCard(t5, 38, 488)
mkLabel(c5h, "إدارة السيرفرات", 10, 7, 250, 24, 11)
mkAction(c5h, "سيرفر جديد", 290, 5, 120, 26, Color3.fromRGB(100, 70, 20), function() addLog("الانتقال لسيرفر جديد..."); task.wait(0.5); pcall(function() TS:Teleport(game.PlaceId) end) end)
mkAction(c5h, "Rejoin", 420, 5, 120, 26, Color3.fromRGB(60, 80, 120), function() addLog("إعادة الدخول..."); task.wait(0.5); pcall(function() TS:TeleportToPlaceInstance(game.PlaceId, game.JobId) end) end)

-- فتح/غلق
floatBtn.MouseButton1Click:Connect(function() frame.Visible = not frame.Visible end)
closeX.MouseButton1Click:Connect(function() frame.Visible = false end)
addC(UIS.InputBegan:Connect(function(input, gp) if gp then return end
    if input.KeyCode == Enum.KeyCode.End then shutdown()
    elseif input.KeyCode == Enum.KeyCode.Home then frame.Visible = not frame.Visible end
end))

-- ═══ حلقة المهمات ═══
task.spawn(function() while not _G.StopAutoFarm do
    task.wait(0.3)
    if not pl.Character or not alive() then task.wait(1); continue end
    if ST.busyCyber or ST.handlingDrop or ST.busyDrop then continue end
    if ST.autoMission and not ST.inProgress then task.spawn(function() pcall(runMissionCycle) end) end
    updateStats()
end end)

-- ═══ الإطلاق ═══
addLog("AUTOFARM v4.7 جاهز 👑")
addLog("الكشف: ESP متطور للاعبين والدروبات والعتاد عبر الجدران")
addLog("الحماية: مضاد الكلبشة + درع تلقائي نشط لحمايتك")
addLog("Home = إظهار/إخفاء | End = إيقاف")
updateStats()
print("[v4.7] Ready — Ultimate ESP & Combat Defense Edition")
