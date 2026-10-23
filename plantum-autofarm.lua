-- ============================================================
-- 👑 AUTOFARM v7.1 (Locas) — مبني على v9.0 + استرجاع كل شيء ناقص
-- ════════════════════════════════════════════════════════════
-- [الإصلاحات الجوهرية]
--   [1] كشف الصندوق: اسم موجب + تعلّم ذاتي (يصلح "ما يكشف دروبات")
--   [2] الدروب: انتقال فوري فوق الدروب (بلا مشي) + برومبت الدروب نفسه + E + لمس
--   [3] الدروب: مالك واحد ينفّذ — خلاص مع «مقاطعة» متكررة وإعادة المهمة كل ثانية
--   [4] الكويز: قراءة أي لايبل فيه معادلة (مو بس اسم Quez) + كتابة + تأكيد + ريموت
--   [5] الكهف: رجّع اللمّ + الرافعة + الريستارت ضد المطاطية + زر يدوي
--   [6] باب الأمن: دخول ببرومبت "فتح / امن سيبراني" الحقيقي + استطلاع حالته
--   [7] HardUnstuck بلا قفز عشوائي + سناب للأرض بالري كاست
--   [8] GUI: بطاقة الفارم 5 صفوف + مفتاح «دروب بلا مشي» + زر تجربة الدروب
-- ── v7.1b (تصحيحات الميدان) ─────────────────────────────────
--   [9] المهام: حالة المهمة تُقرأ من واجهة اللعبة (BoxMission) ومن ريموتات
--       MissionComplete / UpdateMissionProgress / MissionUpdate — ما يبدأ
--       مهمة فوق مهمة شغالة، ويوقف دوامة MISSION_START zFAIL
--  [10] الكهف: إحداثيات الكهف الصحيحة من الماب (داخل الكهف 432,10,-602) و(خارج
--       الباب 387,8,-589) — الوقوف السابق كان على Door/Win الشفاف فيغوص ويموت
--  [11] الكهف: دخول من فتحة الباب على أرض صلبة + رفض الزجاج + انسحاب فوري
--       عند نزول الصحة + ما يسوي ريستارت النقاط إلا بعد دخول مؤكد
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

-- تنظيف الواجهات القديمة
for i = 47, 260 do
  local o = pg:FindFirstChild("AutoFarmV"..i); if o then o:Destroy() end
  local o2 = pg:FindFirstChild("FinalFix"..i); if o2 then o2:Destroy() end
end
for _, n in ipairs({"FinalFixGui","FinalFixMobileBtn","MobileFlyGui","WeatherAutoGui"}) do
  local o = pg:FindFirstChild(n); if o then o:Destroy() end
end

-- [بيانات حقيقية من فحص الماب 2026-10-22]
local CFG = {
  BOARD_POS      = Vector3.new(261.79, 6.93, -297.35),
  WH_RIGHT       = Vector3.new(330.97, 10.19, -178.10),
  WH_FRONT       = Vector3.new(336.0, 10.0, -177.0),
  SAFE_POS       = Vector3.new(261.79, 8.5, -297.35),
  -- v7.1b: من خريطة الماب الحقيقية — Door@(396,12,-602) و Win@(418,9,-602) زجاج،
  -- وداخل الكهف برومبت Security2@(432,10,-602) وخارجها Security1@(387,8,-589)
  CYBER_CAVE_POS = Vector3.new(432, 10, -602),
  CYBER_DOOR_POS = Vector3.new(396, 12, -602),
  CYBER_LEVER    = Vector3.new(235.92, 6.87, -101.00),
  CYBER_DOOR_OUT = Vector3.new(387, 8, -589),
  CYBER_MIN_HP   = 35,
  CYBER_USE_LEVER= true,
  CYBER_STAY     = 15,
  CYBER_COOLDOWN = 25,
  COOLDOWN       = 150,
  SHOWTARGET_WAIT= 2.5,
  DROP_NAMES     = {"Airdrop","SecretAirdrop","Drops","Airdrops","ActiveDrops","SecretDrops","SpecialDrop","RareDrop"},
  DROP_FOLDERS   = {"Drops","Airdrops","ActiveDrops","SecretDrops","SpecialDrops","ActiveEventWorkspace"},
  CYBER_DOOR_PATH = {"Security.Door","Security.DoorPart","Security.ExitDoor","Security.Security2"},
  CYBER_DOOR_OPEN = 0.5,
  CYBER_RETRY_MS  = 90,
  QUIZ_TIMEOUT    = 15,
  QUIZ_GUI        = "DropPass",
  QUIZ_LABEL      = "Quez",
  DROP_WORDS      = {"drop","airdrop","دروب","supply","إسقاط","اسقاط"},
  CRATE_WORDS     = {"box","crate","صندوق","union","supply"},
  -- v7.1: الدروب ما يمشي له — ينتقل فوقه وينزل تحته ويضغط
  DROP_TP         = true,
  DROP_TP_ABOVE   = 5,
  DROP_OPEN_MS    = 7,
  DROP_RETRY_CD   = 8,
}

local ST = {
  autoMission=true, autoDrop=true, autoCyber=true, autoPlaytime=true,
  inProgress=false, isPickup=true, boxIndex=0, totalBoxes=5, crateName=nil,
  missionOn=false, target=nil, cdExpire=0, missionAliveAt=0, adoptedAt=0,
  busyDrop=false, busyCyber=false, handlingDrop=false, cyberPending=false,
  dropRequested=false, dropQueued=nil, dropQueueKind=nil, lastDropAt=0,
  busyWeather=false, weatherStarting=false,
  cyberRetryUntil=0, cyberSignalAt=0, cyberBusySpawned=false,
  lastCyberLog=0, lastCyberSkipLog=0,
  walking=false, walkDest=nil, goalPos=nil, stuckStrikes=0,
  lastEq="", lastCyberLoot=0, lastStartTry=0, startBlockUntil=0,
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
  print("[v7.1]",s)
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
      elseif tick() - ST.busyStart > 45 then ST.busyDrop = false; ST.handlingDrop = false; ST.busyStart = nil; ST.dropRequested = false end
    else ST.busyStart = nil end
    if ST.inProgress then
      if not ST.progressStart then ST.progressStart = tick()
      elseif tick() - ST.progressStart > 120 then ST.inProgress = false; ST.progressStart = nil end
    else ST.progressStart = nil end
    if ST.busyCyber and ST.busyCyberSince > 0 and (tick() - ST.busyCyberSince) > 45 then ST.busyCyber = false; ST.busyCyberSince = 0 end
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
  print("[v7.1] Stopped")
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
  -- v7.1b: إشارات حالة المهمة من اللعبة نفسها
  MissionUpdate    = RS:FindFirstChild("MissionUpdate"),
  MissionComplete  = RS:FindFirstChild("MissionComplete"),
  UpdateProgress   = Rem and Rem:FindFirstChild("UpdateMissionProgress"),
  BringPlayer = Rem and Rem:FindFirstChild("BringPlayerEvent"),
  EquipCuff   = RS:FindFirstChild("EquipCuff"),
  GunInput    = Rem and Rem:FindFirstChild("GunInput"),
  AutoJail    = RS:FindFirstChild("AutoJail"),
}

local function char() return pl.Character end
local function hum() local c=char(); return c and c:FindFirstChildWhichIsA("Humanoid") end
local function hrp() local c=char(); return c and c:FindFirstChild("HumanoidRootPart") end
local function alive() local h=hum(); return h and h.Health>0 end
local function flatDist(a,b) return math.sqrt((a.X-b.X)^2+(a.Z-b.Z)^2) end

-- [إصلاح 1] HardUnstuck: تصفير فيزياء كامل (+ سناب للأرض بالري كاست إذا مرّر موقع)
local function groundOf(pos)
  local rp=RaycastParams.new(); rp.FilterType=Enum.RaycastFilterType.Exclude
  if char() then rp.FilterDescendantsInstances={char()} end
  local hit=workspace:Raycast(Vector3.new(pos.X,pos.Y+12,pos.Z),Vector3.new(0,-60,0),rp)
  return hit and Vector3.new(pos.X,hit.Position.Y+3,pos.Z) or pos
end

local function HardUnstuck(pos)
  local c, r, h = char(), hrp(), hum()
  if not c or not r or not h or h.Health<=0 then return end
  if pos then
    pcall(function() r.AssemblyLinearVelocity = Vector3.zero; r.AssemblyAngularVelocity = Vector3.zero end)
    pcall(function() c:PivotTo(CFrame.new(groundOf(pos))) end)
  end
  pcall(function()
    r.AssemblyLinearVelocity = Vector3.zero
    r.AssemblyAngularVelocity = Vector3.zero
  end)
  pcall(function()
    local st = h:GetState()
    local recovering = (st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown or st == Enum.HumanoidStateType.Physics)
    if recovering then h:ChangeState(Enum.HumanoidStateType.GettingUp) end
    if h.PlatformStand then h.PlatformStand = false end
    if h.Sit then h.Sit = false end
    -- v7.1: القفز كان يُرسل في كل نداء = قفزات عشوائية أثناء المشي. الحين فقط عند نهوض فعلية.
    if recovering then h.Jump = true end
  end)
end

-- v7.1: انتقل قبل الكهف والدروب — السناب للأرض بالري كاست + تصفير فيزياء
local function tpTo(pos, snap)
  local c = char(); if not c then return false end
  local target = pos
  if snap ~= false then target = groundOf(pos) end
  local ok = pcall(function()
    c:PivotTo(CFrame.new(target))
    local rp = hrp()
    if rp then rp.AssemblyLinearVelocity = Vector3.zero; rp.AssemblyAngularVelocity = Vector3.zero end
  end)
  HardUnstuck()
  return ok
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
local WEAPONS={"m4","scar","ak","sniper","cuff","card","laptop","gun","pistol","rifle","uzi","mp5","glock","awm","m1911","revolver","shotgun","knife","skin","golden","clan"}
local function isBoxName(n)
  n = tostring(n or ""):lower()
  if ST.crateName and n == ST.crateName then return true end
  for _, w in ipairs(CFG.CRATE_WORDS) do if n:find(w, 1, true) then return true end end
  return false
end
-- v7.1: السلاح العادي كان يُحسب صندوق = hasCrate() صحيح للأبد = كشف الدروب ميت.
-- الحين: اسم صندوق صريح، أو أداة غريبة فقط طالما السيرفر يقول إننا شايلين.
local function isCrate(item)
  local n = item.Name:lower()
  if isBoxName(n) then return true end
  for _, w in ipairs(WEAPONS) do if n:find(w, 1, true) then return false end end
  if ST.missionOn and ST.isPickup == false then return item:IsA("Tool") end
  return false
end
local function carriedNames()
  local t = {}
  local c = char()
  if c then for _, it in ipairs(c:GetChildren()) do if it:IsA("Tool") then t[it.Name] = true end end end
  local bp = pl:FindFirstChildOfClass("Backpack")
  if bp then for _, it in ipairs(bp:GetChildren()) do if it:IsA("Tool") then t[it.Name] = true end end end
  return t
end
local function learnCrate(before)
  local found, count = nil, 0
  for n in pairs(carriedNames()) do if not before[n] then count = count + 1; found = n end end
  if count == 1 and found then
    if not isBoxName(found) then
      ST.crateName = found:lower()
      addLog(("zCRATE learned=%s"):format(found))
    end
    return true
  end
  return false
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

local dropCache = {obj = nil, kind = nil, at = 0}
local function findActiveDrop(force)
  if dropCache.obj and dropCache.obj.Parent and not force and tick() - dropCache.at < 0.35 then
    return dropCache.obj, dropCache.kind
  end
  local function hit(item)
    dropCache.obj, dropCache.kind, dropCache.at = item, classifyDrop(item), tick()
    return dropCache.obj, dropCache.kind
  end
  for _, n in ipairs(CFG.DROP_NAMES) do
    local obj = workspace:FindFirstChild(n)
    if obj and obj.Parent then
      if obj:IsA("Folder") then
        for _, child in ipairs(obj:GetChildren()) do
          if (child:IsA("Model") or child:IsA("BasePart")) and child.Parent and child.Name ~= "RainDrop" then return hit(child) end
        end
      else return hit(obj) end
    end
  end
  for _, fName in ipairs(CFG.DROP_FOLDERS) do
    local f = workspace:FindFirstChild(fName)
    if f and (f:IsA("Folder") or f:IsA("Model")) then
      for _, item in ipairs(f:GetChildren()) do
        if (item:IsA("Model") or item:IsA("BasePart")) and item.Parent and item.Name ~= "RainDrop" then return hit(item) end
      end
    end
  end
  -- v7.1: الماب يغيّر أسماء الدروب بين الأحداث — نلاحق الكلمات بدل قائمة ثابتة
  local function dynName(obj)
    local n = (obj.Name or ""):lower()
    if n == "raindrop" or obj:IsA("Tool") then return false end
    for _, w in ipairs(CFG.DROP_WORDS) do if n:find(w, 1, true) then return true end end
    return false
  end
  for _, obj in ipairs(workspace:GetChildren()) do
    if (obj:IsA("Model") or obj:IsA("BasePart")) and dynName(obj) then return hit(obj) end
  end
  dropCache.obj, dropCache.kind, dropCache.at = nil, nil, tick()
  return nil, nil
end
local function dropCacheClear() dropCache.obj, dropCache.kind, dropCache.at = nil, nil, 0 end

local promptSet, promptDirty = {}, true
local function promptHost(obj)
  local parent = obj.Parent
  if not parent then return nil end
  if parent:IsA("BasePart") then return parent end
  if parent:IsA("Model") then return parent.PrimaryPart or parent:FindFirstChildWhichIsA("BasePart", true) end
  local top = parent:FindFirstAncestorOfClass("Model")
  if top then return top.PrimaryPart or top:FindFirstChildWhichIsA("BasePart", true) end
  return nil
end
local function scanPromptsOnce()
  for _, obj in ipairs(workspace:GetDescendants()) do
    if obj:IsA("ProximityPrompt") and not promptSet[obj] then
      promptSet[obj] = {p = obj, h = promptHost(obj)}
    end
  end
  promptDirty = false
end
addC(workspace.DescendantAdded:Connect(function(obj)
  if obj:IsA("ProximityPrompt") then
    promptSet[obj] = {p = obj, h = promptHost(obj)}
  end
end))
addC(workspace.DescendantRemoving:Connect(function(obj)
  if obj:IsA("ProximityPrompt") then promptSet[obj] = nil end
end))
task.spawn(function()
  task.wait(0.5)
  scanPromptsOnce()
  while not _G.StopAutoFarm do
    task.wait(2)
    if promptDirty then scanPromptsOnce() end
  end
end)

local function activePrompts(radius, onlyEnabled)
  local out = {}
  local r = hrp(); if not r then return out end
  radius = radius or 20
  for _, e in pairs(promptSet) do
    local p = e.p
    if p.Parent and (not onlyEnabled or p.Enabled) then
      local host = e.h
      if not host or not host.Parent then host = promptHost(p); e.h = host end
      if host then
        local d = (host.Position - r.Position).Magnitude
        if d < 1.5 then d = 0 end
        if d < radius then out[#out+1] = {prompt = p, dist = d, part = host} end
      end
    end
  end
  table.sort(out, function(a, b) return a.dist < b.dist end)
  return out
end
local function getNearbyPrompts(radius) return activePrompts(radius, true) end

local BLOCK_WORDS = {"شراء","متجر","إيقاف","ايقاف","إلغاء","الغاء","طقس","أجواء","اجواء","buy","shop","stop","cancel","weather"}
local function isBlockedPrompt(p)
  if not p then return true end
  local txt = ((p.ActionText or "") .. " " .. (p.ObjectText or "") .. " " .. (p.Parent and p.Parent.Name or "")):lower()
  for _, w in ipairs(BLOCK_WORDS) do if txt:find(w, 1, true) then return true end end
  return false
end

local function activatePrompt(p, withHold, maxHold)
  if not p or not p.Parent then return false end
  pcall(function()
    if typeof(fireproximityprompt) == "function" then fireproximityprompt(p) end
  end)
  local enabled = false
  pcall(function() enabled = (p.Enabled == true) and (p.Parent ~= nil) end)
  if withHold then
    local hd = 0
    pcall(function() hd = tonumber(p.HoldDuration) or 0 end)
    if hd > 0 then
      if maxHold then hd = math.min(hd, maxHold) end
      pcall(function()
        p:InputHoldBegin()
        task.wait(hd + 0.06)
        p:InputHoldEnd()
      end)
    elseif not enabled then
      pcall(function() p:InputHoldBegin(); task.wait(0.08); p:InputHoldEnd() end)
    end
  end
  return enabled
end
local function triggerPrompt(prompt) return activatePrompt(prompt, true) end
local function triggerPromptInstantly(prompt) return activatePrompt(prompt, false) end

local function waitCrate(timeout)
  local t0 = tick()
  repeat
    if hasCrate() then return true end
    task.wait(0.04)
  until tick() - t0 >= (timeout or 0.8)
  return hasCrate()
end
local function firePromptFast(prompt) return activatePrompt(prompt, false) end

local function pressE(holdTime)
  holdTime = holdTime or 0.12
  pcall(function()
    VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(holdTime)
    VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
  end)
end

local function partsNear(pos, radius)
  local out = {}
  local ok, parts = pcall(function()
    local op = OverlapParams.new()
    op.FilterType = Enum.RaycastFilterType.Exclude
    if pl.Character then op.FilterDescendantsInstances = {pl.Character} end
    return workspace:GetPartBoundsInBox(CFrame.new(pos), Vector3.new(radius*2, radius*2, radius*2), op)
  end)
  if ok and parts then
    for _, p in ipairs(parts) do out[#out+1] = p end
    return out
  end
  local r = hrp(); if not r then return out end
  for _, p in ipairs(workspace:GetChildren()) do
    if p:IsA("BasePart") and (p.Position - r.Position).Magnitude < radius then out[#out+1] = p end
  end
  return out
end

-- v7.1: الدروب الحقيقي مو المجلد — ننزل لأعمق جزء عليه برومبت ونجمع برومبتاته كلها
local function dropFocus(obj)
  local prompts = {}
  if not obj then return nil, prompts end
  if obj:IsA("ProximityPrompt") then prompts[1] = obj
  else
    for _, d in ipairs(obj:GetDescendants()) do
      if d:IsA("ProximityPrompt") then prompts[#prompts+1] = d end
    end
  end
  local host
  for _, p in ipairs(prompts) do
    local hst = promptHost(p)
    if hst then host = hst; break end
  end
  local part = host or getPart(obj)
  if not part then
    for _, d in ipairs(obj:GetDescendants()) do
      if d:IsA("BasePart") then part = d; break end
    end
  end
  return part, prompts
end

local function logMs(tag, t0, extra)
  if _G.StopAutoFarm then return end
  local ms = math.floor((tick() - t0) * 1000 + 0.5)
  addLog(("zTIME %-10s = %dms %s"):format(tag, ms, extra or ""))
end

local AR_MAP = {["٠"]="0",["١"]="1",["٢"]="2",["٣"]="3",["٤"]="4",["٥"]="5",["٦"]="6",["٧"]="7",["٨"]="8",["٩"]="9"}
local function cleanText(t)
  local s = tostring(t or "")
  for ar,en in pairs(AR_MAP) do s = s:gsub(ar,en) end
  return s:gsub("×","*"):gsub("✕","*"):gsub("÷","/"):gsub("＋","+"):gsub("﹢","+"):gsub("","+"):gsub("－","-"):gsub("−","-"):gsub("–","-"):gsub("—","-"):gsub("―","-"):gsub("","-"):gsub("＝","="):gsub("؟","?"):gsub("ـ","")
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

-- v7.1: المعادلة تُقرأ من أي لايبل، مو من اسم "Quez" ثابت (سبب «ما يحل الكويز»)
local function parseEq(t)
  local s = cleanText(t)
  local a, op, b = s:match("(%d+)%s*([+%-%*/])%s*(%d+)")
  if not a then return nil end
  a, b = tonumber(a), tonumber(b)
  if not (a and b) then return nil end
  if op == "+" then return a + b
  elseif op == "-" then return a - b
  elseif op == "*" then return a * b
  elseif op == "/" then if b ~= 0 then return math.floor(a / b) end end
  return nil
end

local quizScan = {at = -1, gui = nil, lbl = nil, box = nil, btns = nil, joined = ""}
local function scanQuiz(force)
  -- v7.1: كاش للنتيجة الفارغة أيضاً — لوب الضغط يناديها كل 0.08s و GetDescendants ثقيل
  if not force and quizScan.at >= 0 and (tick() - quizScan.at < (quizScan.gui and 0.2 or 0.15)) then return quizScan end
  quizScan.at = tick()
  quizScan.gui, quizScan.lbl, quizScan.box, quizScan.btns, quizScan.joined = nil, nil, nil, {}, ""
  local best = 0
  local function consider(g)
    if not g then return end
    local ok = pcall(function() return g.Enabled end)
    if ok == false then return end
    if g.Enabled == false then return end
    local rootVis = true
    for _, c in ipairs(g:GetChildren()) do
      if c:IsA("Frame") or c:IsA("CanvasGroup") then rootVis = c.Visible ~= false; break end
    end
    if not rootVis then return end
    local lbl, box, btns, n, eq = nil, nil, {}, 0, {}
    local okd, desc = pcall(function() return g:GetDescendants() end)
    if not okd or not desc then return end
    for _, d in ipairs(desc) do
      local vis = false
      pcall(function() vis = d.Visible and d.AbsoluteSize.X > 4 and d.AbsoluteSize.Y > 4 end)
      if vis then
        if d:IsA("TextBox") then
          if not box then box = d end
        elseif d:IsA("TextButton") then
          n = n + 1; btns[#btns+1] = d
          if not lbl then local e = parseEq(d.Text); if e then lbl = d end end
          if d.Text and d.Text:match("%d") then eq[#eq+1] = d.Text end
        elseif d:IsA("TextLabel") then
          if not lbl and parseEq(d.Text) then lbl = d end
          if d.Text and d.Text:match("%d") then eq[#eq+1] = d.Text end
        end
      end
    end
    local score = (lbl and 4 or 0) + (box and 2 or 0) + (n > 0 and 1 or 0)
    if score > best then
      best = score; quizScan.gui, quizScan.lbl, quizScan.box, quizScan.btns = g, lbl, box, btns
      quizScan.joined = table.concat(eq, " ")
    end
  end
  for _, g in ipairs(pg:GetChildren()) do if g:IsA("ScreenGui") then consider(g) end end
  if best < 4 then
    local cg
    pcall(function() cg = gethui and gethui() or game:GetService("CoreGui") end)
    if cg then pcall(function() for _, g in ipairs(cg:GetChildren()) do if g:IsA("ScreenGui") then consider(g) end end end) end
  end
  return quizScan
end

local APPLY_WORDS = {"تأكيد","تاكد","أكد","اكد","apply","submit","confirm","ok","نعم","عمل","إرسال","ارسال","حل"}
local function pickApplyBtn(btns)
  if not btns then return nil end
  for _, b in ipairs(btns) do
    local t = ((b.Name or "") .. " " .. (b.Text or "")):lower()
    for _, w in ipairs(APPLY_WORDS) do if t:find(w, 1, true) then return b end end
  end
  local big
  for _, b in ipairs(btns) do
    if not big or b.AbsoluteSize.X * b.AbsoluteSize.Y > big.AbsoluteSize.X * big.AbsoluteSize.Y then big = b end
  end
  return big
end

local function getDropPassElements()
  local s = scanQuiz()
  local quez = s.lbl
  if not quez then
    local dp = pg:FindFirstChild(CFG.QUIZ_GUI)
    if dp then for _, d in ipairs(dp:GetDescendants()) do
      if d:IsA("TextLabel") and d.Visible and (d.Name == CFG.QUIZ_LABEL or d.Name:lower():find("quez", 1, true)) then quez = d; break end
    end end
  end
  return quez, s.box, pickApplyBtn(s.btns)
end

local function isDropPassShown()
  local s = scanQuiz()
  if s.gui and (s.lbl or s.box or parseEq(s.joined or "")) then return true end
  local dp = pg:FindFirstChild(CFG.QUIZ_GUI)
  if dp and dp.Enabled then
    for _, d in ipairs(dp:GetDescendants()) do
      if d:IsA("TextLabel") and d.Name == CFG.QUIZ_LABEL and d.Visible and d.AbsoluteSize.X > 5 then return true end
    end
  end
  return false
end

local function writeAnswer(txtBox, value)
  if not txtBox then return false end
  local s = tostring(value)
  pcall(function() txtBox.Text = s end)
  task.wait(0.04)
  if txtBox.Text == s then return true end
  pcall(function()
    txtBox:CaptureFocus(); task.wait(0.05); txtBox.Text = ""; task.wait(0.03)
    for i = 1, #s do txtBox.Text = s:sub(1, i); task.wait(0.02) end
    task.wait(0.05); txtBox:ReleaseFocus(true)
  end)
  task.wait(0.04)
  if txtBox.Text == s then return true end
  pcall(function() txtBox.Text = s end); task.wait(0.04)
  return txtBox.Text == s
end

-- [نظام المشي]
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
  if tick() - (ST.lastEmergencyTp or 0) > 6 then ST.stuckStrikes = 0 end
  local goal = dest or ST.goalPos
  if goal and flatDist(r.Position, goal) < 2 then return false end
  local spot = nil
  if (ST.stuckStrikes or 0) < 2 then spot = findNearbySpot(r.Position, goal) end
  if not spot and goal then
    local g = groundOf(goal)
    if isSpotFree(g + Vector3.new(0, 1.6, 0)) then spot = g end
  end
  if not spot and goal then spot = groundOf(goal) end
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
    HardUnstuck()
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
    if owner == "cyber" and not ST.autoCyber then return "OFF" end
    if ST.busyCyber then return "CYBER" end
    -- v7.1: نقاطع المشي لدروب موجود فعلاً فقط — لا لمجرد flag عالق (سبب إعادة المهمة كل ثانية)
    if not isDrop and ST.autoDrop and not ST.busyDrop and not hasCrate() and findActiveDrop() then return "DROP" end
    return nil
  end
  local function reached() return flatDist(r.Position, tgt) <= stopD end
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

local requestDrop, forceDropNow   -- تُسندان في قسم الدروبات (تصريح أمامي عشان المشي وواجهة الفارم)
local function handleWalkInterrupt(res)
  if res == "DROP" then
    local d, k = findActiveDrop()
    if d then ST.inProgress = false; requestDrop(d, k, "مشي"); return true end
    -- الدروب اختفى: نكمل عادي بدل ما نعيد المهمة من الصفر كل ثانية
    ST.dropRequested = false
    return false
  end
  if res == "STOP" or res == "CYBER" or res == "OFF" then return true end
  return false
end

task.spawn(function()
  local lastPos, lastMoveAt = nil, tick()
  while not _G.StopAutoFarm do
    task.wait(0.25)
    local r = hrp()
    local h = hum()
    local busy = ST.walking or ST.inProgress or ST.busyCyber or ST.busyDrop
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

-- [نظام الدروبات v7.1]
-- مالك واحد ينفّذ + انتقال فوري فوق الدروب + ضغط على برومبت الدروب نفسه. لا مشي للدروب.

-- v7.1: الكويز يُحسب محلول فقط لما الواجهة تختفي فعلياً (عشان لا يعدّ نفسه نجاح كاذب)
local function solveQuizPass(isSecret)
  local s = scanQuiz()
  local quez, txtBox, applyBtn = getDropPassElements()
  local raw = quez and cleanText(quez.Text or "") or ""
  if raw == "" and s.joined then raw = cleanText(s.joined) end
  if raw == "" then return false end
  if raw == ST.lastEq then return false end
  ST.lastEq = raw
  local ans = parseEq(raw)
  if not ans then local ok, v = pcall(solveStr, raw); if ok and v then ans = v end end
  if not ans then
    addLog(("zQUIZ noparse=[%s]"):format(raw:sub(1, 28)))
    return false
  end
  addLog(("✏️ %s = %s"):format(raw, tostring(ans)))
  local gone = false
  for round = 1, 4 do
    if txtBox then writeAnswer(txtBox, ans) end
    if REM.Quiz then
      pcall(function() REM.Quiz:FireServer(ans) end)
      pcall(function() REM.Quiz:FireServer(tostring(ans)) end)
    end
    if applyBtn then clickBtn(applyBtn) else pressE(0.06) end
    task.wait(0.22)
    if not isDropPassShown() then gone = true; break end
    if applyBtn then
      pcall(function() applyBtn:Activate() end)
      pcall(function() firesignal(applyBtn.MouseButton1Click) end)
      task.wait(0.2)
      if not isDropPassShown() then gone = true; break end
    end
  end
  if not gone then ST.lastEq = ""; return false end
  ST.stats.quizzesSolved = ST.stats.quizzesSolved + 1
  if isSecret then ST.score = ST.score + 1500; ST.stats.dropsSecret = ST.stats.dropsSecret + 1; addLog("✅ السري حل!")
  else ST.score = ST.score + 800; ST.stats.dropsNormal = ST.stats.dropsNormal + 1; addLog("✅ العادي حل!") end
  updateStats()
  return true
end

local function clearDropFlags()
  ST.busyDrop = false; ST.handlingDrop = false; ST.busyStart = nil
  ST.dropRequested = false; ST.goalPos = nil
  setStatus("خامل", Color3.fromRGB(120,255,200))
end

local function handleDrop(target, kind)
  if ST.busyDrop then return end
  local dropT0 = tick()
  ST.lastDropObj = target
  ST.busyDrop = true; ST.handlingDrop = true; ST.busyStart = tick()
  ST.lastEq = ""
  local isSecret = (kind == "secret")
  addLog(isSecret and "🏆 دروب سري!" or "📦 دروب عادي!")
  setStatus("دروب...", isSecret and Color3.fromRGB(255,215,0) or Color3.fromRGB(100,200,255))

  local part, prompts = dropFocus(target)
  local rStart = hrp()
  addLog(("zDROP obj=%s cls=%s part=%s pr=%s d=%s"):format(
    tostring(target.Name), target.ClassName, part and part.Name or "none", tostring(#prompts),
    (part and rStart) and ("%.0f"):format((rStart.Position - part.Position).Magnitude) or "?"))

  if not part then
    addLog("zDROP fail=no-part")
    ST.lastDropAt = tick(); dropCacheClear(); clearDropFlags(); updateStats()
    return
  end
  ST.goalPos = part.Position

  -- 1) انتقال فوري: نقف فوق الدروب مباشرة (ري كاست يحدد سطح الصندوق) — بلا PathfindingService
  if CFG.DROP_TP then
    tpTo(part.Position + Vector3.new(0, CFG.DROP_TP_ABOVE + 2, 0), false)
    task.wait(0.1)
    tpTo(part.Position)
    task.wait(0.15)
  else
    walk(part.Position, 14, true, "drop")
  end
  if _G.StopAutoFarm or not ST.autoDrop then
    ST.lastDropAt = tick(); clearDropFlags(); return
  end

  -- 2) الضغط: برومبتات الدروب نفسه أولاً، ثم أي برومبت قريب، مع E ولمس
  local opened, why = false, "timeout"
  local openT0 = tick()
  local tries = 0
  while (tick() - openT0) * 1000 < CFG.DROP_OPEN_MS * 1000 and not _G.StopAutoFarm and ST.autoDrop do
    tries = tries + 1
    if not target.Parent and not part.Parent then opened = true; why = "gone"; break end
    local rr = hrp(); if not rr then why = "no-hrp"; break end
    if tries % 3 == 1 then
      pcall(function()
        rr.CFrame = CFrame.new(groundOf(part.Position))
        rr.AssemblyLinearVelocity = Vector3.zero
      end)
    end
    for i = 1, #prompts do
      local p = prompts[i]
      if p and p.Parent then activatePrompt(p, tries > 2, 0.8) end
    end
    if #prompts == 0 or tries > 3 then
      for _, entry in ipairs(getNearbyPrompts(12)) do
        local pp = entry.prompt
        if pp and pp.Parent and not isBlockedPrompt(pp) then activatePrompt(pp, tries > 3, 1.0) end
      end
    end
    if isDropPassShown() then opened = true; why = "quiz"; break end
    touchObj(part)
    if isDropPassShown() then opened = true; why = "touch"; break end
    if hasCrate() then opened = true; why = "crate"; break end
    if tries % 2 == 0 then pressE(0.16) end
    if isDropPassShown() then opened = true; why = "E"; break end
    task.wait(0.08)
  end
  logMs("DROP_OPEN", openT0, (opened and "zOK" or "zFAIL") .. (" zWhy=%s zTries=%d"):format(why, tries))

  -- 3) الكويز
  local t0 = tick(); local solved = false
  local solveWindow = opened and CFG.QUIZ_TIMEOUT or 2.0
  while (tick() - t0) < solveWindow and not _G.StopAutoFarm and ST.autoDrop do
    if isDropPassShown() then
      local ok, did = pcall(solveQuizPass, isSecret)
      if ok and did then solved = true; break end
      task.wait(0.3)
    else
      if (not opened) or (tick() - t0 > 2.5) then break end
      task.wait(0.2)
    end
  end
  if not solved and opened and ST.autoDrop and isDropPassShown() then
    ST.pendingQuiz = { secret = isSecret, expiry = tick() + 25 }
    addLog("⏳ الكويز لسه ظاهر — مشغّل متأخر يتولاه")
  elseif not solved and opened and ST.autoDrop then
    addLog("انتهى الوقت"); ST.stats.failed = ST.stats.failed + 1
  end
  logMs(solved and "DROP_FULL" or (ST.pendingQuiz and "DROP_PENDING" or "DROP_FAIL"), dropT0, ("zWhy=%s"):format(why))
  dropCacheClear()
  HardUnstuck()
  ST.lastDropAt = tick()
  clearDropFlags(); updateStats()
end

-- v7.1: الكل «يطلب» دروب والمنفّذ وحده ينفّذ — يخلص تضارب النسخ المتزامنة
local dropSeen = setmetatable({}, {__mode = "k"})
local lastDropScanLog = 0
requestDrop = function(obj, kind, why)
  if _G.StopAutoFarm or not ST.autoDrop then return end
  if not obj or not obj.Parent then return end
  if ST.busyDrop then ST.dropRequested = true; return end
  if obj == ST.lastDropObj and (tick() - ST.lastDropAt) < CFG.DROP_RETRY_CD then return end
  local seen = dropSeen[obj]
  if seen and (tick() - seen) < CFG.DROP_RETRY_CD then return end
  dropSeen[obj] = tick()
  ST.dropQueued = obj; ST.dropQueueKind = kind or classifyDrop(obj)
  ST.dropRequested = true
  ST.inProgress = false; ST.progressStart = nil
  if why then addLog(("⚡ دروب (%s): %s"):format(why, tostring(obj.Name))) end
end

-- v7.1: زر التجربة اليدوي — يتجاوز كولداون الكائن لكنه يمشي بنفس مسار الدروب المعتاد
forceDropNow = function()
  if _G.StopAutoFarm then return end
  local d, k = findActiveDrop(true)
  if not d then addLog("zDROP none-now") return end
  dropSeen[d] = nil
  ST.autoDrop = true
  ST.dropQueued = d; ST.dropQueueKind = k or classifyDrop(d); ST.dropRequested = true
  addLog(("⚡ دروب يدوي: %s"):format(tostring(d.Name)))
end

task.spawn(function()
  while not _G.StopAutoFarm do
    task.wait(0.3)
    if not ST.autoDrop or ST.busyDrop or ST.busyCyber then continue end
    -- ما نقاطع مرحلة التسليم — كان يمسح المهمة ويخليك واقف
    if ST.missionOn and ST.isPickup == false then continue end
    if hasCrate() then
      if tick() - lastDropScanLog > 30 then
        lastDropScanLog = tick()
        local cr = getCrate(); cr = cr and cr.Name or "?"
        addLog(("zDROP skip: crate=%s"):format(cr))
      end
      continue
    end
    local obj = ST.dropQueued
    if obj and obj.Parent then
      ST.dropQueued = nil
      local ok, err = pcall(handleDrop, obj, ST.dropQueueKind or classifyDrop(obj))
      if not ok then addLog(("zDROP error=%s"):format(tostring(err))) end
    else
      ST.dropQueued = nil
      local d, k = findActiveDrop()
      if d then requestDrop(d, k, nil)
      elseif tick() - lastDropScanLog > 60 then
        lastDropScanLog = tick()
        local f = workspace:FindFirstChild("Drops")
        addLog(("zDROP scan: Drops=%s"):format(f and tostring(#f:GetChildren()) or "none"))
      end
    end
  end
end)

local function looksLikeDropName(n)
  n = (n or ""):lower()
  for _, x in ipairs(CFG.DROP_NAMES) do if n == x:lower() then return true end end
  for _, w in ipairs(CFG.DROP_WORDS) do if n:find(w, 1, true) then return true end end
  return false
end

addC(workspace.ChildAdded:Connect(function(c)
  if _G.StopAutoFarm or not ST.autoDrop or ST.busyDrop then return end
  if c:IsA("Folder") or not looksLikeDropName(c.Name) then return end
  addLog(("🆕 %s!"):format(c.Name)); task.wait(0.25)
  if ST.missionOn and ST.isPickup == false then return end
  requestDrop(c, classifyDrop(c), "child")
end))

task.spawn(function()
  local dropsF = workspace:WaitForChild("Drops", 10)
  if dropsF then
    addC(dropsF.ChildAdded:Connect(function(c)
      if _G.StopAutoFarm or not ST.autoDrop or ST.busyDrop then return end
      if not (c:IsA("Model") or c:IsA("BasePart")) then return end
      if c.Name == "RainDrop" then return end
      addLog(("🆕 Drops/%s!"):format(c.Name)); task.wait(0.25)
      if ST.missionOn and ST.isPickup == false then return end
      requestDrop(c, classifyDrop(c), "drops")
    end))
  end
end)

-- [مشغّل الكويز المتأخر: DropPass قد يظهر بعد انتهاء handleDrop]
task.spawn(function()
  while not _G.StopAutoFarm do
    task.wait(0.35)
    local q = ST.pendingQuiz
    if q then
      if tick() > q.expiry or not ST.autoDrop or not isDropPassShown() then
        ST.pendingQuiz = nil
      else
        local ok, did = pcall(solveQuizPass, q.secret)
        if ok and did then ST.pendingQuiz = nil; addLog("✅ الكويز المتأخر انحلت") end
      end
    end
  end
end)

-- [جوائز وقت اللعب]
local lastNoReward = 0
local function claimPlaytimeRewards(force)
  if not force and not ST.autoPlaytime then return end
  if not force and tick() - ST.lastPlaytimeClaim < 60 then return end
  ST.lastPlaytimeClaim = tick()
  local mainUi = pg:FindFirstChild("MainUi")
  if not mainUi then if force then addLog("️ MainUi غير موجود") end return end
  local quests = mainUi:FindFirstChild("Quests")
  local frame = quests and quests:FindFirstChild("Frame")
  if not frame then if force then addLog("️ Quests/Frame غير موجود") end return end
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
    addLog(" لا توجد جوائز وقت لعب جاهزة حالياً.")
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
    if ST.autoPlaytime then pcall(claimPlaytimeRewards) end
  end
end)

-- [الكهف السيبراني]
-- v7.1: tpTo انُقلت للأعلى عشان الدروب يستخدمها أيضاً

-- الباب الحقيقي: Security/Door (Part) — ونرجّع BasePart دائماً مو Model
local function findSecurityDoor()
  local sec = workspace:FindFirstChild("Security")
  if not sec then return nil, nil end
  for _, path in ipairs(CFG.CYBER_DOOR_PATH) do
    local cur, ok = sec, true
    for seg in path:gmatch("[^%.]+") do
      if seg == "Security" then cur = sec
      else cur = cur and cur:FindFirstChild(seg); if not cur then ok = false; break end end
    end
    if ok and cur then
      if not cur:IsA("BasePart") then cur = cur:FindFirstChildWhichIsA("BasePart", true) end
      if cur then return cur, path end
    end
  end
  local d = sec:FindFirstChild("Door") or sec:FindFirstChild("DoorPart") or sec:FindFirstChildWhichIsA("BasePart", true)
  return d, d and ("Security." .. d.Name) or nil
end

-- البرومبت الرسمي للباب: ActionText=فتح / ObjectText=امن سيبراني (Hold = 0.0)
local function cyberPromptsNear(radius)
  local out = {}
  for _, entry in ipairs(activePrompts(radius or 30, true)) do
    local p = entry.prompt
    local txt = ((p.ActionText or "") .. " " .. (p.ObjectText or "") .. " " .. (p.Parent and p.Parent.Name or "")):lower()
    if txt:find("سيبر") or txt:find("cyber") or txt:find("security") then out[#out+1] = p end
  end
  return out
end

-- v7.1b: نقطتا الدخول تُقرآن من برومبتات Security نفسها (خارج الباب / داخله) بدل إحداثيات عمياء
local function cyberDoorAnchors()
  local outP, inP, outPrompt, inPrompt
  local sec = workspace:FindFirstChild("Security")
  if sec then
    for _, d in ipairs(sec:GetDescendants()) do
      if d:IsA("ProximityPrompt") then
        local txt = ((d.ActionText or "") .. " " .. (d.ObjectText or "") .. " " .. d.Name):lower()
        if txt:find("سيبر") or txt:find("cyber") or txt:find("security") or txt:find("فتح") then
          local host = promptHost(d)
          if host then
            local pos = host.Position
            if pos.X < CFG.CYBER_DOOR_POS.X then
              if not outP or pos.X > outP.X then outP, outPrompt = pos, d end
            else
              if not inP or pos.X < inP.X then inP, inPrompt = pos, d end
            end
          end
        end
      end
    end
  end
  return outP or CFG.CYBER_DOOR_OUT, inP or CFG.CYBER_CAVE_POS, outPrompt, inPrompt
end

local function isDoorOpen(door)
  if not door then return false end
  local open = false
  pcall(function() if door.Transparency >= CFG.CYBER_DOOR_OPEN then open = true end end)
  if not open then pcall(function() if door.Anchored == false then open = true end end) end
  return open
end

-- v7.1b: ما يقف فوق الزجاج — Door/Win مرفوضان، ولا فراغ تحت القدمين
local function floorAt(pos)
  local hit
  pcall(function()
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local c = char(); rp.FilterDescendantsInstances = c and { c } or {}
    hit = workspace:Raycast(pos + Vector3.new(0, 30, 0), Vector3.new(0, -70, 0), rp)
  end)
  if not hit then return nil, nil end
  local n = (hit.Instance and hit.Instance.Name or ""):lower()
  return hit.Position + Vector3.new(0, 3, 0), n
end

local function grabCyberLoot()
  local r = hrp(); if not r then return end
  for _, p in ipairs(partsNear(r.Position, 14)) do
    local pn = p.Name:lower()
    if pn:find("handle") or pn:find("lever") or pn:find("مقبض") or pn:find("cyber")
      or pn:find("switch") or pn:find("point") or pn:find("coin") then touchObj(p) end
  end
  for _, entry in ipairs(activePrompts(14, true)) do
    if not isBlockedPrompt(entry.prompt) then triggerPromptInstantly(entry.prompt) end
  end
end

-- الريستارت هو اللي يثبّت النقاط ويمنع الرجوع المطاطي بعد الكهف
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
  ST.missionOn = false; ST.target = nil; ST.isPickup = true; ST.missionAliveAt = 0
  addLog("✅ رجع اللاعب بعد الريستارت")
  setStatus("خامل", Color3.fromRGB(120,255,200))
end

local function lootCyberCave(force)
  if _G.StopAutoFarm then return end
  if ST.busyCyber then return end
  if not ST.autoCyber and not force then return end
  -- الإشارة ما تُرمى: تُجرّب لأجل CYBER_RETRY_MS ولازم تكون أحدث من نهاية آخر جولة
  local freshSignal = ST.cyberSignalAt > 0
    and ST.cyberSignalAt >= (ST.lastCyberLoot + 5)
    and (tick() - ST.cyberSignalAt < CFG.CYBER_RETRY_MS)
  local inCooldown = (tick() - ST.lastCyberLoot < CFG.CYBER_COOLDOWN)
  if not force and inCooldown then
    ST.cyberPending = false
    if not freshSignal then
      if tick() - (ST.lastCyberLog or 0) > 20 then
        ST.lastCyberLog = tick()
        addLog(("⏳ الكهف في كولداون (%d ث)"):format(math.ceil(CFG.CYBER_COOLDOWN - (tick() - ST.lastCyberLoot))))
      end
      return
    end
    if tick() - (ST.lastCyberLog or 0) > 20 then
      ST.lastCyberLog = tick()
      addLog("📡 إشارة فتح باب جديدة أثناء الكولداون — بنجرّبها الحين")
    end
  end
  local signaled = force or freshSignal

  -- لا نقاطع دروباً قيد التنفيذ ولا مهمة الأجواء ولا التسليم (الإشارة تُصفَّف لو تأخر)
  ST.cyberPending = true
  local w0 = tick()
  while ST.busyDrop and tick() - w0 < (signaled and 20 or 10) do task.wait(0.3) end
  if ST.busyDrop or _G.StopAutoFarm or (not ST.autoCyber and not force) then
    if ST.autoCyber and not _G.StopAutoFarm and tick() - (ST.lastCyberSkipLog or 0) > 12 then
      ST.lastCyberSkipLog = tick()
      addLog("⚠️ الكهف مؤجل: دروب قيد التنفيذ")
    end
    return
  end
  if ST.busyWeather then
    if tick() - (ST.lastCyberSkipLog or 0) > 12 then
      ST.lastCyberSkipLog = tick()
      addLog("⚠️ الكهف مؤجل: مهمة الأجواء شغالة")
    end
    return
  end
  local wm = tick()
  local waitLimit = signaled and 40 or 25
  while (ST.inProgress or hasCrate()) and tick() - wm < waitLimit and (ST.autoCyber or force) do task.wait(0.5) end
  if not ST.autoCyber and not force then ST.cyberPending = false; return end
  if ST.inProgress or hasCrate() or _G.StopAutoFarm then
    if ST.autoCyber and not _G.StopAutoFarm and tick() - (ST.lastCyberSkipLog or 0) > 12 then
      ST.lastCyberSkipLog = tick()
      addLog("⚠️ الكهف مؤجل: المهمة ما انتهت (بنحاول مرة ثانية)")
    end
    return
  end

  ST.busyCyber = true; ST.busyCyberSince = tick(); ST.lastCyberLoot = tick()
  ST.cyberPending = false; ST.cyberRetryUntil = tick() + CFG.CYBER_RETRY_MS
  ST.cyberSignalAt = 0
  dropCacheClear()
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

  local function endCyberVisit(msg)
    if msg then addLog(msg) end
    if not _G.StopAutoFarm then
      local safe, safeFloor = floorAt(returnPos)
      tpTo(safe or (returnPos + Vector3.new(0, 3, 0)))
      task.wait(0.3)
      if not safe or safeFloor == "door" or safeFloor == "win" then
        tpTo(CFG.SAFE_POS + Vector3.new(0, 3, 0))
      end
    end
    ST.noclipOn = wasNoclip
    if not wasNoclip then
      local cc = char()
      if cc then for _, p in ipairs(cc:GetDescendants()) do
        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.CanCollide = true end
      end end
    end
    ST.busyCyber = false; ST.busyCyberSince = 0; ST.cyberPending = false
    setStatus("خامل", Color3.fromRGB(120,255,200))
  end

  -- 1) الدخول الرسمي: وقفة بره الباب (مو فوقه) وإطلاق برومبته، ثم دخول من فتحة الباب
  local door, doorPath = findSecurityDoor()
  local outPos, inPos, outPrompt = cyberDoorAnchors()
  local stand, standFloor = floorAt(outPos)
  tpTo(stand or (outPos + Vector3.new(0, 3, 0)))
  task.wait(0.25)
  local cps = cyberPromptsNear(30)
  for _, p in ipairs(cps) do
    triggerPromptInstantly(p); activatePrompt(p, true, 1.0); pressE(0.12)
  end
  if outPrompt then triggerPromptInstantly(outPrompt) end
  addLog(("zCAVE door=%s prompts=%d stand=%s"):format(
    tostring(doorPath or "none"), #cps, tostring(standFloor or "none")))

  local ot0 = tick()
  while not isDoorOpen(door) and (tick() - ot0) < 2.5 and not _G.StopAutoFarm do
    if outPrompt then triggerPromptInstantly(outPrompt) end
    pressE(0.1)
    task.wait(0.25)
  end
  local doorOpen = isDoorOpen(door)

  -- v7.1b: ما ننزل فوق الزجاج (Door/Win) ولا في فراغ — لو الأرض مو مؤكدة نرجع بدل ما نموت
  local inStand, inFloor = floorAt(inPos)
  if not inStand or inFloor == "door" or inFloor == "win" then
    logMs("CYBER_ENTER", ot0, ("zFAIL zFloor=%s zOpen=%s"):format(tostring(inFloor or "none"), tostring(doorOpen)))
    endCyberVisit("zCAVE abort: لا أرضية آمنة داخل الكهف — رجعت للخارج")
    return
  end
  tpTo(inStand)
  task.wait(0.3)
  local ra = hrp()
  logMs("CYBER_ENTER", ot0, ("zOK zFloor=%s zOpen=%s zD=%s"):format(
    tostring(inFloor), tostring(doorOpen),
    ra and ("%.0f"):format((ra.Position - CFG.CYBER_CAVE_POS).Magnitude) or "?"))
  addLog("zCAVE entry=through-door")

  -- v7.1b: بعد الدخول نرجّع الكولجن — النوحكلب فوق الزجاج هو اللي يخلّه يغوص ويموت
  ST.noclipOn = wasNoclip
  if not wasNoclip then
    local cc = char()
    if cc then for _, p in ipairs(cc:GetDescendants()) do
      if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.CanCollide = true end
    end end
  end

  -- 2) داخل الكهف: لمّ الجوائز طول مدة البقاء
  local t0 = tick()
  while tick() - t0 < CFG.CYBER_STAY and not _G.StopAutoFarm and (ST.autoCyber or force) do
    task.wait(0.4)
    local rp = hrp(); if not rp then break end
    if (rp.Position - CFG.CYBER_CAVE_POS).Magnitude > 30 then
      local back, backFloor = floorAt(CFG.CYBER_CAVE_POS)
      tpTo(back or CFG.CYBER_CAVE_POS)
      if backFloor == "door" or backFloor == "win" then
        endCyberVisit("zCAVE exit: وقفت على زجاج — خرجت")
        return
      end
    end
    local hh = hum()
    if hh and hh.Health < CFG.CYBER_MIN_HP then
      logMs("CYBER_CAVE", t0, "zFAIL zWhy=low-hp")
      endCyberVisit("⚠️ صحتك نازلة داخل الكهف — انسحب فوراً")
      return
    end
    pcall(function() rp.AssemblyLinearVelocity = Vector3.zero end)
    pcall(grabCyberLoot)
  end
  logMs("CYBER_CAVE", t0)

  if not ST.autoCyber and not force then
    addLog("⏹️ الكهف: إيقاف فوري")
    if not _G.StopAutoFarm then tpTo(returnPos + Vector3.new(0, 3, 0)); task.wait(0.3) end
    ST.noclipOn = wasNoclip
    if not wasNoclip then
      local cc = char()
      if cc then for _, p in ipairs(cc:GetDescendants()) do
        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.CanCollide = true end
      end end
    end
    ST.busyCyber = false; ST.busyCyberSince = 0; ST.cyberPending = false
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

  -- 3) مرحلة الرافعة السيبرانية
  if CFG.CYBER_USE_LEVER and not _G.StopAutoFarm then
    addLog("🔧 تحرّي الرافعة السيبرانية...")
    setStatus("الرافعة السيبرانية...", Color3.fromRGB(0, 220, 255))
    tpTo(CFG.CYBER_LEVER)
    task.wait(0.2)
    local t1 = tick()
    local leverTouched = 0
    while tick() - t1 < 6 and not _G.StopAutoFarm and (ST.autoCyber or force) do
      local r1 = hrp(); if not r1 then break end
      for _, p in ipairs(partsNear(r1.Position, 10)) do
        local pn = p.Name:lower()
        if pn:find("handle") or pn:find("lever") or pn:find("مقبض") or pn:find("cyber") or pn:find("switch") then
          touchObj(p); leverTouched = leverTouched + 1
        end
      end
      for _, entry in ipairs(activePrompts(12, true)) do
        if not isBlockedPrompt(entry.prompt) then activatePrompt(entry.prompt, leverTouched == 0, 2.5) end
      end
      pressE(leverTouched == 0 and 0.5 or 0.12)
      task.wait(0.06)
    end
    logMs("CYBER_LEVER", t1, ("zTouch=%d"):format(leverTouched))
    ST.stats.cyberPoints = ST.stats.cyberPoints + 50
    ST.score = ST.score + 50
    updateStats()
    if not _G.StopAutoFarm then didReset = true; cyberResetForPoints() end
    task.wait(0.4)
  end

  -- العودة للموقع ممنوعة بعد الريستارت — هي سبب الرجوع المطاطي
  if not _G.StopAutoFarm and not didReset then
    tpTo(returnPos + Vector3.new(0, 3, 0))
    task.wait(0.4)
  end

  ST.noclipOn = wasNoclip
  if not wasNoclip then
    local cc = char()
    if cc then for _, p in ipairs(cc:GetDescendants()) do
      if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.CanCollide = true end
    end end
  end

  ST.busyCyber = false; ST.busyCyberSince = 0; ST.cyberPending = false
  setStatus("خامل", Color3.fromRGB(120,255,200))
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
local function cyberSignal(reason)
  if _G.StopAutoFarm or not ST.autoCyber then return end
  ST.cyberSignalAt = tick()
  ST.cyberPending = true
  addLog((" إشارة كهف: %s"):format(reason))
end
local function cyberTick()
  if _G.StopAutoFarm or not ST.autoCyber then return end
  if ST.busyCyber then return end
  if not (ST.cyberPending or (ST.cyberSignalAt > 0 and tick() - ST.cyberSignalAt < CFG.CYBER_RETRY_MS)) then return end
  -- v7.1: لا يقذفنا للكهف وسط دروب أو تسليم أو مهمة أجواء
  if ST.inProgress or ST.busyDrop or ST.busyWeather or hasCrate() then return end
  if ST.cyberBusySpawned then return end
  ST.cyberPending = true
  ST.cyberBusySpawned = true
  task.spawn(function()
    local ok, err = pcall(lootCyberCave)
    ST.cyberBusySpawned = false
    if not ok then addLog(("❌ خطأ الكهف: %s"):format(tostring(err))) end
    if ST.busyCyber then ST.cyberSignalAt = 0 end
  end)
end
addC(TextChatService.MessageReceived:Connect(function(msg)
  pcall(function()
    if checkCyberMsg(msg.Text) then cyberSignal("chat") end
  end)
end))
task.spawn(function()
  local chats = pl:FindFirstChild("Chats") or pl:WaitForChild("Chats", 15)
  if not chats then return end
  local con = chats.ChildAdded:Connect(function(channel)
    pcall(function()
      channel:GetPropertyChangedSignal("Text"):Connect(function()
        if checkCyberMsg(channel.Text) then cyberSignal("chat-legacy") end
      end)
      if checkCyberMsg(channel.Text) then cyberSignal("chat-legacy") end
    end)
  end)
  addC(con)
  for _, channel in ipairs(chats:GetChildren()) do
    pcall(function()
      channel:GetPropertyChangedSignal("Text"):Connect(function()
        if checkCyberMsg(channel.Text) then cyberSignal("chat-legacy") end
      end)
    end)
  end
end)

task.spawn(function()
  local lastCollide, lastPos, lastTr, announced = nil, nil, nil, false
  while not _G.StopAutoFarm do
    task.wait(0.25)
    if ST.autoCyber and not ST.busyCyber then
      local door, path = findSecurityDoor()
      if door then
        if not announced then
          announced = true
          addLog(("zCYBER door=%s Tr=%.2f Collide=%s Pos=%s"):format(tostring(path or door.Name), door.Transparency or 0,
            tostring(door.CanCollide), string.format("%.0f,%.0f,%.0f", door.Position.X, door.Position.Y, door.Position.Z)))
          local sec = workspace:FindFirstChild("Security")
          local names = {}
          if sec then for _, k in ipairs(sec:GetChildren()) do names[#names+1] = k.Name end end
          addLog(("zCYBER Security children: %s"):format(#names > 0 and table.concat(names, ",") or "none"))
          addLog(("zCYBER cyberPrompts=%d"):format(#cyberPromptsNear(250)))
        end
        local tr = tonumber(door.Transparency) or 0
        local openedByTr = (lastTr ~= nil and lastTr < CFG.CYBER_DOOR_OPEN and tr >= CFG.CYBER_DOOR_OPEN)
        local openedByCollide = (lastCollide == true and door.CanCollide == false)
        local openedByMove = (lastPos and (door.Position - lastPos).Magnitude > 2)
        if openedByTr or openedByCollide or openedByMove then
          cyberSignal(("door: Tr=%.2f Collide=%s"):format(tr, tostring(door.CanCollide)))
        end
        lastTr = tr; lastCollide = door.CanCollide; lastPos = door.Position
      elseif tick() - (ST.lastCyberLog or 0) > 60 then
        ST.lastCyberLog = tick()
        addLog("zCYBER warn: no Security/Door in workspace — use manual cave button")
      end
    end
  end
end)

task.spawn(function()
  while not _G.StopAutoFarm do
    task.wait(0.3)
    local ok, err = pcall(cyberTick)
    if not ok then addLog(("❌ cyberTick: %s"):format(tostring(err))) end
  end
end)

if REM.ShowTarget then
  addC(REM.ShowTarget.OnClientEvent:Connect(function(tp,_,_,cnt,tot,isPick)
    if _G.StopAutoFarm then return end
    if not tp then ST.missionOn=false; ST.target=nil; ST.cdExpire=tick()+0.3; ST.missionAliveAt=0; addLog("اكتملت المهمة — جاهز للمهمة التالية"); return end
    ST.target=tp; ST.isPickup=(isPick==true); ST.boxIndex=cnt or ST.boxIndex; ST.totalBoxes=tot or 5; ST.missionOn=true
    local pp = tp:IsA("BasePart") and tp or tp:FindFirstChildWhichIsA("BasePart", true)
    addLog(("zTARGET pick=%s box=%s/%s pos=%s"):format(tostring(isPick), tostring(cnt), tostring(tot),
      pp and string.format("%.0f,%.0f,%.0f", pp.Position.X, pp.Position.Y, pp.Position.Z) or "nil"))
  end))
end

-- v7.1b: نسمع لإشارات المهمة الرسمية — «مهمة شغالة» مو شي نخمّنه من ShowTarget وحده
if REM.MissionComplete then
  addC(REM.MissionComplete.OnClientEvent:Connect(function()
    if _G.StopAutoFarm then return end
    if ST.missionOn then addLog("zMISSION signal=complete") end
    ST.missionOn = false; ST.target = nil; ST.cdExpire = tick() + 0.3; ST.missionAliveAt = 0
  end))
end
if REM.UpdateProgress then
  addC(REM.UpdateProgress.OnClientEvent:Connect(function(a, b, c)
    if _G.StopAutoFarm then return end
    ST.missionAliveAt = tick()
    local n1, n2
    for _, v in ipairs({a, b, c}) do
      if type(v) == "number" then
        if not n1 then n1 = v elseif not n2 then n2 = v end
      elseif typeof(v) == "Instance" and (v:IsA("BasePart") or v:IsA("Model")) then
        -- نحدّث الهدف فقط إذا المهمة أصلاً شغالة — وإلا أي جزء عابر يقفل دورة المهام
        if ST.missionOn then ST.target = v end
      end
    end
    if n1 then ST.boxIndex = n1 end
    if n2 then ST.totalBoxes = n2 end
    addLog(("zMISSION signal=progress %s/%s"):format(tostring(n1 or "?"), tostring(n2 or "?")))
  end))
end
if REM.MissionUpdate then
  addC(REM.MissionUpdate.OnClientEvent:Connect(function()
    if _G.StopAutoFarm then return end
    ST.missionAliveAt = tick()
  end))
end

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
        if isStart and not skipStartText(t) then clickBtn(b); clicked = true; task.wait(0.1) end
      end
    end
  end
  return clicked
end

-- v7.1b: شارة المهمة تُقرأ من واجهة اللعبة نفسها (BoxMission: «1 / 5» + تخطي).
-- بدون هذي كان يبدأ مهمة فوق مهمة شغالة ويغرق اللوق بـ MISSION_START zFAIL
local function isMissionUIActive()
  local g = pg:FindFirstChild("BoxMission")
  if not g then return false end
  local on = false
  pcall(function()
    if g.Enabled == false then return end
    for _, d in ipairs(g:GetDescendants()) do
      local vis = false
      pcall(function() vis = d.Visible and d.AbsoluteSize.X > 4 and d.AbsoluteSize.Y > 4 end)
      if vis and (d:IsA("TextLabel") or d:IsA("TextButton")) then
        local t = cleanText(d.Text or "")
        local a, b = t:match("(%d+)%s*/%s*(%d+)")
        if a and tonumber(a) > 0 then on = true; return end
        if d:IsA("TextButton") and (t:find("تخطي") or t:lower():find("skip")) then on = true; return end
      end
    end
  end)
  return on
end

local missionHoldTried = false
local function triggerMissionStart()
  for _, entry in ipairs(getNearbyPrompts(18)) do
    local p = entry.prompt
    local host = p.Parent
    local txt = ((p.ActionText or "") .. " " .. (p.ObjectText or "") .. " " .. (host and host.Name or "")):lower()
    local isMission = txt:find("مهم") or txt:find("لوح") or txt:find("board") or txt:find("mission")
    or txt:find("أبدا") or txt:find("ابدأ") or txt:find("start") or txt:find("قبول")
    if isMission and not txt:find("طقس") and not txt:find("أجواء") and not txt:find("اجواء") then
      triggerPromptInstantly(p)
      if missionHoldTried then activatePrompt(p, true, 1.5) end
    end
  end
  if missionHoldTried then pressE(0.5) else pressE(0.2) end
  task.wait(0.08)
  local r = hrp()
  if r then
    for _, obj in ipairs(partsNear(r.Position, 12)) do
      local on = obj.Name:lower()
      if on:find("board") or on:find("mission") or on:find("لوحة") then touchObj(obj) end
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
          if t:find("المهام") or t:find("mission") then clickBtn(b); task.wait(0.2); break end
        end
      end
    end
  end
  findAndClickStartBtn()
  return false
end

-- [دورة المهام]
local function runMissionCycle()
  if not ST.autoMission then return end
  if ST.inProgress or ST.busyCyber or ST.handlingDrop or ST.busyDrop or ST.busyWeather or ST.weatherStarting then return end
  -- v7.1b: التبنّي بدون هدف 40 ثانية = خلاص، وإلا يقفل دورة المهام للأبد
  if ST.missionOn and not ST.target and (ST.adoptedAt or 0) > 0 and tick() - ST.adoptedAt > 40 then
    ST.adoptedAt = 0; ST.missionOn = false; ST.missionAliveAt = 0
    addLog("zMISSION adopt expired: لا هدف — نبدأ مهمة جديدة")
  end
  if ST.autoDrop and not hasCrate() then
    local d, k = findActiveDrop()
    if d and d.Parent then requestDrop(d, k, "دورة المهام"); return end
  end
  ST.inProgress = true
  local carrying = hasCrate()
  if not ST.missionOn then ST.isPickup = not carrying end
  local h, r = hum(), hrp()
  if not h or not r or not alive() then ST.inProgress = false; task.wait(0.5); return end
  if carrying then getCrate() end
  local cdLeft = math.ceil(ST.cdExpire - tick())
  ST.goalPos = CFG.BOARD_POS
  if cdLeft > 0 then
    setStatus(("كول داون: %ds"):format(cdLeft), Color3.fromRGB(200,200,100))
    if flatDist(r.Position, CFG.BOARD_POS) > 6 then if handleWalkInterrupt(walk(CFG.BOARD_POS, 8, false, "mission")) then ST.inProgress = false; return end end
    task.wait(0.3); ST.inProgress = false; return
  end
  if not ST.missionOn then
    -- v7.1b: الواجهة أو إشارة اللعبة تقول إن فيه مهمة شغالة؟ لا نبدأ وحدة فوقها — نتبنّاها وبس
    if isMissionUIActive() or (tick() - (ST.missionAliveAt or 0) < 20) then
      ST.missionOn = true; ST.isPickup = not hasCrate(); ST.startFails = 0
      ST.adoptedAt = tick()
      addLog("zMISSION adopt: المهمة شغالة — بنكمل عليها بدل بدء جديدة")
      ST.inProgress = false; return
    end
    if tick() < (ST.startBlockUntil or 0) then
      setStatus(("انتظار اللوحة: %ds"):format(math.ceil((ST.startBlockUntil or 0) - tick())), Color3.fromRGB(200,200,100))
      ST.inProgress = false; task.wait(0.5); return
    end
    if tick() - ST.lastStartTry < 0.8 then ST.inProgress = false; task.wait(0.3); return end
    ST.lastStartTry = tick()
    addLog("بدء مهمة جديدة..."); setStatus("التوجه للوحة...", Color3.fromRGB(150,220,255))
    if flatDist(r.Position, CFG.BOARD_POS) > 5 then
      if handleWalkInterrupt(walk(CFG.BOARD_POS, 10, false, "mission")) then ST.inProgress = false; return end
      pcall(function() char():PivotTo(CFrame.new(CFG.BOARD_POS + Vector3.new(0, 1.2, 0))) end); task.wait(0.15)
    end
    triggerMissionStart()
    local wt = tick()
    local accepted = false
    local retryAt = 0
    while tick() - wt < CFG.SHOWTARGET_WAIT do
      task.wait(0.08)
      if not ST.autoMission or _G.StopAutoFarm then break end
      if ST.missionOn and ST.target then accepted = true; addLog("تم قبول المهمة"); break end
      -- v7.1b: القبول قد يظهر بالواجهة فقط (مهمة صناديق بدون ShowTarget)
      if isMissionUIActive() then
        ST.missionOn = true; ST.isPickup = not hasCrate()
        accepted = true; addLog("zMISSION accepted=ui"); break
      end
      if tick() - wt > retryAt then
        retryAt = tick() - wt + 0.8
        missionHoldTried = true
        triggerMissionStart()
      end
    end
    missionHoldTried = false
    logMs("MISSION_START", wt, accepted and "zOK" or ("zFAIL zOn=%s zTgt=%s zUI=%s"):format(
      tostring(ST.missionOn), ST.target and "y" or "n", tostring(isMissionUIActive())))
    if not ST.autoMission then ST.inProgress = false; return end
    if accepted then ST.startFails = 0
    else
      ST.startFails = (ST.startFails or 0) + 1
      if ST.startFails >= 2 then
        ST.startFails = 0
        ST.startBlockUntil = tick() + 25
        addLog("⚠️ اللوحة ما قبلت المهمة — راحة 25ث (كول داون أو هدف غير متاح)")
      end
    end
    ST.inProgress = false; return
  end
  local pickupT0 = tick()
  if ST.isPickup then
    ST.goalPos = CFG.WH_RIGHT
    addLog("التوجه للمستودع"); setStatus("استلام صندوق...", Color3.fromRGB(255,200,100))
    if handleWalkInterrupt(walk(CFG.WH_RIGHT, 14, false, "mission")) then ST.inProgress = false; return end
    local beforePick = carriedNames()
    local pickupOK = false
    for att = 1, 8 do
      if hasCrate() then pickupOK = true; break end
      if _G.StopAutoFarm or not ST.autoMission or ST.busyCyber or ST.handlingDrop or ST.busyDrop or ST.busyWeather then break end
      h, r = hum(), hrp(); if not h or not r then break end
      local spot = (att % 2 == 0) and (CFG.WH_RIGHT + Vector3.new(1.5, 0, 1.5)) or CFG.WH_RIGHT
      pcall(function() h:MoveTo(spot); r.AssemblyLinearVelocity = Vector3.zero end)
      local near = getNearbyPrompts(20)
      if att == 1 then
        for pi = 1, math.min(#near, 4) do
          if not isBlockedPrompt(near[pi].prompt) then firePromptFast(near[pi].prompt) end
        end
        task.wait(0.08)
      else
        local maxHold = (att >= 4) and 2.0 or 1.0
        local any = false
        for pi = 1, math.min(#near, 3) do
          if not isBlockedPrompt(near[pi].prompt) then
            activatePrompt(near[pi].prompt, true, maxHold); any = true
          end
        end
        if not any then task.wait(0.1) end
      end
      if hasCrate() then pickupOK = true; break end
      if ST.target then touchObj(ST.target) end
      local bf = workspace:FindFirstChild("BoxFolder")
      if bf then for _, z in ipairs(bf:GetChildren()) do if z:IsA("BasePart") then touchObj(z) end end end
      pressE(att <= 2 and 0.1 or 0.4)
      if waitCrate(0.12) then pickupOK = true; break end
      if learnCrate(beforePick) then pickupOK = true; break end
    end
    if not ST.autoMission then ST.inProgress = false; return end
    if hasCrate() or pickupOK or waitCrate(0.3) then
      local crate = getCrate()
      if crate and crate:IsA("Tool") and crate.Parent ~= char() then
        pcall(function() h:EquipTool(crate) end)
        task.wait(0.08)
      end
      ST.isPickup = false
      logMs("PICKUP", pickupT0, ("zCrate=%s"):format(crate and crate.Name or "?"))
      addLog(("تم حمل الصندوق (%.1fث)"):format(tick() - pickupT0))
      if not ST.autoMission then ST.inProgress = false; return end
      ST.stats.missions = ST.stats.missions + 1; updateStats()
    else
      logMs("PICKUP_FAIL", pickupT0)
      task.wait(0.1); ST.inProgress = false; return
    end
  end
  if not ST.isPickup then
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
    if not hasCrate() then
      if not targetObj then
        ST.isPickup = true
        ST.inProgress = false; task.wait(0.05); return
      end
      ST.reDeliverTries = (ST.reDeliverTries or 0) + 1
      if ST.reDeliverTries > 4 then
        ST.reDeliverTries = 0; ST.isPickup = true
        ST.missionOn = false
        ST.target = nil
        ST.missionAliveAt = 0
        ST.cdExpire = tick() + 2
        addLog("⚠️ الصندوق ما انمسك رغم وجود العلامة — رجوع للمستودع")
      else
        ST.inProgress = false
        logMs("DELIVER_RETRY", ST.deliverPhaseT0 or tick())
        task.wait(0.06); return
      end
    end
    ST.reDeliverTries = 0
    if not targetObj then
      ST.lostTargetAt = ST.lostTargetAt or tick()
      if tick() - ST.lostTargetAt > 15 then
        ST.lostTargetAt = nil; ST.waitLogged = nil
        addLog("⚠️ هدف التسليم اختفى — إعادة محاولة المهمة")
        ST.missionOn = false; ST.cdExpire = tick() + 5; ST.missionAliveAt = 0
      elseif tick() - ST.lostTargetAt > 0.7 and not ST.waitLogged then
        ST.waitLogged = true
        addLog("⏳ بانتظار علامة التسليم من اللعبة...")
      end
      ST.inProgress = false; task.wait(0.05); return
    end
    if ST.lostTargetAt then
      addLog(("🎯 ظهرت علامة التسليم بعد %.1fث"):format(tick() - ST.lostTargetAt))
      ST.lostTargetAt = nil; ST.waitLogged = nil
    end
    local tp = targetObj:IsA("BasePart") and targetObj or targetObj:FindFirstChildWhichIsA("BasePart", true)
    if not tp then task.wait(0.08); ST.inProgress = false; return end
    addLog(("التوجه لنقطة التسليم (%.0f متر)"):format(flatDist(hrp().Position, tp.Position))); setStatus("تسليم...", Color3.fromRGB(120,255,150))
    local bPos = tp.Position; pcall(function() tp.CanTouch = true end)
    local gPos = groundOf(bPos)
    ST.goalPos = Vector3.new(bPos.X, gPos.Y, bPos.Z)
    ST.deliverPhaseT0 = tick()
    local deliverT0 = tick()
    if handleWalkInterrupt(walk(Vector3.new(bPos.X, gPos.Y, bPos.Z), 18, false, "mission")) then ST.inProgress = false; return end
    r, h = hrp(), hum(); if not r or not h then ST.inProgress = false; return end
    h.WalkSpeed = 16
    local didHold, delivered = false, false; local t0 = tick()
    local mtChecked, mtParts = false, nil
    while tick() - t0 < 8 do
      if not hasCrate() then delivered = true; break end
      if _G.StopAutoFarm or not ST.autoMission or not ST.missionOn or ST.busyCyber or ST.handlingDrop or ST.busyDrop or ST.busyWeather then break end
      r, h = hrp(), hum(); if not r or not h then break end
      h:MoveTo(Vector3.new(bPos.X, r.Position.Y, bPos.Z))
      touchObj(tp)
      if not mtChecked then
        mtChecked = true
        local mt = workspace:FindFirstChild("MissionTargets")
        if mt then
          mtParts = {}
          for _, t in ipairs(mt:GetChildren()) do
            if t:IsA("BasePart") then pcall(function() t.CanTouch = true end); mtParts[#mtParts+1] = t end
          end
        end
      end
      if mtParts then for _, t in ipairs(mtParts) do if t.Parent then touchObj(t) end end end
      local crate = getCrate(); if crate then
        if crate:IsA("BasePart") then touchBoth(crate, tp)
        elseif crate:IsA("Model") then for _, p in ipairs(crate:GetDescendants()) do if p:IsA("BasePart") then touchBoth(p, tp) end end end
        if crate:IsA("Tool") then pcall(function() crate:Activate() end) end
      end
      local near = getNearbyPrompts(14)
      local qual = {}
      for pi = 1, math.min(#near, 4) do
        if not isBlockedPrompt(near[pi].prompt) then qual[#qual+1] = near[pi].prompt end
      end
      if #qual == 0 then
        if didHold then
          if not hasCrate() then delivered = true; break end
        end
      elseif not didHold then
        didHold = true
        for pi = 1, math.min(#qual, 2) do
          activatePrompt(qual[pi], true, 2.0)
          if not hasCrate() then delivered = true; break end
        end
      else
        for pi = 1, math.min(#qual, 2) do firePromptFast(qual[pi]) end
      end
      if delivered then break end
      task.wait(0.05)
      if not hasCrate() then delivered = true; break end
      pressE(0.1)
      task.wait(0.03)
    end
    if not ST.autoMission then ST.inProgress = false; return end
    if delivered or not hasCrate() then
      HardUnstuck()
      ST.isPickup = true
      ST.missionOn = false
      ST.target = nil
      ST.missionAliveAt = 0
      ST.cdExpire = tick() + 0.6
      ST.inProgress = false
      ST.progressStart = nil
      logMs("DELIVER", deliverT0, ("zHold=%s"):format(tostring(didHold)))
      addLog(("✅ تم التسليم (%.1fث) — استقرار..."):format(tick() - deliverT0))
      task.wait(0.45)
      HardUnstuck()
      h = hum(); if h then h.WalkSpeed = ST.customSpeedOn and ST.walkSpeed or 16 end
      return
    elseif ST.autoMission then
      ST.stats.failed = ST.stats.failed + 1
      logMs("DELIVER_FAIL", deliverT0, ("zPrompts=%d"):format(#getNearbyPrompts(14)))
    end
    h = hum(); if h then h.WalkSpeed = ST.customSpeedOn and ST.walkSpeed or 16 end
  end
  ST.inProgress = false
  ST.goalPos = nil
end

-- [الطيران]
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

-- [الاختفاء]
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

-- [ESP]
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

-- [Fullbright]
local function enableFullbright()
  lightSave.Brightness=Lighting.Brightness; lightSave.ClockTime=Lighting.ClockTime; lightSave.FogEnd=Lighting.FogEnd; lightSave.GlobalShadows=Lighting.GlobalShadows
  Lighting.Brightness=2; Lighting.ClockTime=14; Lighting.FogEnd=1e6; Lighting.GlobalShadows=false
  for _,e in ipairs(Lighting:GetDescendants()) do if e:IsA("Atmosphere") or e:IsA("BloomEffect") or e:IsA("BlurEffect") or e:IsA("ColorCorrectionEffect") then e.Enabled=false end end
end
local function disableFullbright()
  for prop,val in pairs(lightSave) do pcall(function() Lighting[prop]=val end) end
  for _,e in ipairs(Lighting:GetDescendants()) do if e:IsA("Atmosphere") or e:IsA("BloomEffect") or e:IsA("BlurEffect") or e:IsA("ColorCorrectionEffect") then e.Enabled=true end end
end

-- [الحماية]
local CUFF_WORDS = {"cuff","handcuff","arrest","restrain","zip","taze","stun","freeze","مصفاد","كلبش","تقييد","قيد","أغلال","اغلال","زنجير","تكتيف","ربط"}
local function isCuffName(s)
  s = tostring(s or ""):lower()
  for _, w in ipairs(CUFF_WORDS) do if s:find(w, 1, true) then return true end end
  return false
end
local function purgeCuffInst(inst)
  if not inst or not inst.Parent then return 0 end
  local c = char(); if not c or not inst:IsDescendantOf(c) then return 0 end
  if inst:IsA("Tool") and isCuffName(inst.Name) then
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
    if h.WalkSpeed < 10 and not ST.handlingDrop then h.WalkSpeed = ST.customSpeedOn and ST.walkSpeed or 16 end
  end
  restoreHumanoid(h)
  for _, p in ipairs(c:GetDescendants()) do
    if p:IsA("BasePart") and p.Anchored then pcall(function() p.Anchored = false end) end
    if p:IsA("ProximityPrompt") then local at = (p.ActionText or "") .. " " .. (p.ObjectText or ""); if at:find("كلبشة") or at:find("Arrest") or at:lower():find("cuff") then p.Enabled = false end end
  end
end

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

-- [Anti-Jail]
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
  if ST.busyDrop or ST.busyCyber or ST.flyOn or ST.inProgress or ST.clickTpOn or ST.spectating then
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
    addLog("️ السجن متكرر — توقفنا 15 ثانية")
  end
  task.wait(0.25)
end

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

-- [أدوات إضافية]
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
  addLog((" تم إرسال أمر فتح لـ %d بوابة"):format(count))
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
  if ST.customSpeedOn and not ST.handlingDrop and not ST.flyOn then h.WalkSpeed = ST.walkSpeed end
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
  if ST.busyDrop and ST.busyDropSince > 0 and (tick() - ST.busyDropSince) > 60 then ST.busyDrop = false; ST.handlingDrop = false; ST.dropRequested = false end
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

-- ============================================================
-- [GUI الكامل - 6 تبويبات]
-- ============================================================
local function buildGui()
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
  mkFlyBtn("↑", 80, -200, "W"); mkFlyBtn("↓", 80, -120, "S"); mkFlyBtn("←", 20, -160, "A"); mkFlyBtn("→", 140, -160, "D"); mkFlyBtn("⬆", 300, -200, "Up"); mkFlyBtn("", 300, -120, "Down")
  local floatBtn = Instance.new("TextButton", mobGui); floatBtn.Size = UDim2.new(0, 54, 0, 54); floatBtn.Position = UDim2.new(0, 14, 0.45, 0)
  floatBtn.BackgroundColor3 = Color3.fromRGB(14, 24, 38); floatBtn.BackgroundTransparency = 0.15
  floatBtn.Text = "v7.1"; floatBtn.TextSize = 12; floatBtn.TextColor3 = Color3.fromRGB(120, 235, 215)
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
    local c = P.cyan:Lerp(P.accent, 0.5 + 0.5 * math.sin(tick() * 0.8))
    mStroke.Color = c:Lerp(P.stroke, 0.45); fStroke.Color = c
  end))
  local header = Instance.new("Frame", frame); header.Size = UDim2.new(1, 0, 0, 46)
  header.BackgroundColor3 = Color3.new(1, 1, 1); header.BackgroundTransparency = 0.2
  Instance.new("UICorner", header).CornerRadius = UDim.new(0, 16)
  grad(header, Color3.fromRGB(22, 31, 50), Color3.fromRGB(13, 18, 30), 0)
  local title = Instance.new("TextLabel", header); title.Size = UDim2.new(1, -230, 0, 22); title.Position = UDim2.new(0, 16, 0, 7)
  title.BackgroundTransparency = 1; title.Text = "AUTOFARM  v7.1"; title.TextColor3 = P.text
  title.Font = Enum.Font.GothamBold; title.TextSize = 14; title.TextXAlignment = Enum.TextXAlignment.Left
  local subtitle = Instance.new("TextLabel", header); subtitle.Size = UDim2.new(1, -230, 0, 14); subtitle.Position = UDim2.new(0, 16, 0, 26)
  subtitle.BackgroundTransparency = 1; subtitle.Text = "LOCAS  •  Data-Driven • Hard-Unstuck • Double-Confirm"; subtitle.TextColor3 = P.muted
  subtitle.Font = Enum.Font.Gotham; subtitle.TextSize = 9; subtitle.TextXAlignment = Enum.TextXAlignment.Left
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
  scroll = Instance.new("ScrollingFrame", t1); scroll.Size = UDim2.new(1, 0, 0, 112); scroll.Position = UDim2.new(0, 0, 0, 58)
  scroll.BackgroundColor3 = Color3.fromRGB(7, 10, 17); scroll.BackgroundTransparency = 0.15
  scroll.BorderSizePixel = 0; scroll.ScrollBarThickness = 3; scroll.ScrollBarImageTransparency = 0.5
  Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 10)
  local lgStroke = Instance.new("UIStroke", scroll); lgStroke.Color = P.stroke; lgStroke.Thickness = 1; lgStroke.Transparency = 0.45
  logLbl = Instance.new("TextLabel", scroll); logLbl.Size = UDim2.new(1, -10, 0, 1); logLbl.Position = UDim2.new(0, 6, 0, 6)
  logLbl.AutomaticSize = Enum.AutomaticSize.Y; logLbl.BackgroundTransparency = 1; logLbl.Text = ""; logLbl.TextColor3 = Color3.fromRGB(186, 205, 228); logLbl.Font = Enum.Font.Code; logLbl.TextSize = 12
  logLbl.TextXAlignment = Enum.TextXAlignment.Left; logLbl.TextYAlignment = Enum.TextYAlignment.Top; logLbl.TextWrapped = true
  local c1b = mkCard(t1, 166, 176)
  mkToggle(c1b, "المهام", 8, 6, 266, 28, true, function(v)
    ST.autoMission = v
    if not v then
      ST.inProgress = false; ST.progressStart = nil
      setStatus("خامل", Color3.fromRGB(120,255,200))
      addLog("️ المهام: إيقاف فوري")
    else addLog("▶️ المهام: تشغيل") end
  end)
  mkToggle(c1b, "الدروبات", 286, 6, 266, 28, true, function(v)
    ST.autoDrop = v
    if not v then
      ST.busyDrop = false; ST.handlingDrop = false; ST.busyStart = nil; ST.lastDropObj = nil
      ST.dropRequested = false; ST.dropQueued = nil; ST.pendingQuiz = nil
      dropCacheClear()
      addLog("⏹️ الدروبات: إيقاف فوري")
    else addLog("▶️ الدروبات: تشغيل") end
  end)
  mkToggle(c1b, "كهف السيبراني (تلقائي)", 8, 38, 266, 28, true, function(v)
    ST.autoCyber = v
    if not v then
      ST.busyCyber = false; ST.busyCyberSince = 0
      ST.cyberPending = false; ST.cyberSignalAt = 0
      addLog("⏹️ الكهف: إيقاف فوري")
    else addLog("▶️ الكهف: تشغيل (ينتظر إشارة فتح الباب فقط)") end
  end)
  mkToggle(c1b, "الانتقال التلقائي عند التعليق", 286, 38, 266, 28, true, function(v)
    ST.emergencyTpOn = v
    if not v then addLog("⏹️ الانتقال التلقائي: إيقاف")
    else addLog("▶️ الانتقال التلقائي: تشغيل (فوري بعد 1.5 ثانية)") end
  end)
  mkToggle(c1b, "جوائز وقت اللعب", 8, 70, 266, 28, true, function(v) ST.autoPlaytime = v end)
  mkAction(c1b, "🎁 استلام جوائز", 286, 70, 266, 28, Color3.fromRGB(30, 92, 74), claimRewardsManually)
  mkToggle(c1b, "دروب: انتقال فوري (بدون مشي)", 8, 102, 266, 28, true, function(v)
    CFG.DROP_TP = v
    addLog(v and "▶️ الدروب: انتقال فوري فوق الدروب مباشرة" or "⏹️ الدروب: مشي + احتياط انتقال")
  end)
  mkAction(c1b, "🌐 دخول الكهف (يدوي)", 286, 102, 266, 28, Color3.fromRGB(37, 70, 130), function()
    task.spawn(function()
      local ok, err = pcall(lootCyberCave, true)
      if not ok then addLog(("❌ الكهف اليدوي: %s"):format(tostring(err))) end
    end)
  end)
  mkAction(c1b, "📦 تجربة الدروب الآن", 8, 134, 266, 28, Color3.fromRGB(96, 62, 132), function()
    task.spawn(forceDropNow)
  end)
  mkAction(c1b, "⏹ إيقاف السكربت", 286, 134, 266, 28, Color3.fromRGB(132, 40, 52), shutdown)
  local credit = mkLabel(t1, " youtube.com/@LocasBushee", 0, 344, 560, 26, 11)
  credit.TextColor3 = Color3.fromRGB(255, 205, 220)
  credit.TextXAlignment = Enum.TextXAlignment.Center
  credit.BackgroundTransparency = 0.15
  credit.BackgroundColor3 = Color3.fromRGB(70, 26, 44)
  credit.Size = UDim2.new(1, 0, 0, 22)
  Instance.new("UICorner", credit).CornerRadius = UDim.new(0, 9)
  local crStroke = Instance.new("UIStroke", credit); crStroke.Color = P.rose; crStroke.Thickness = 1; crStroke.Transparency = 0.65
  local creditBtn = Instance.new("TextButton", credit); creditBtn.Size = UDim2.new(1, 0, 1, 0); creditBtn.BackgroundTransparency = 1; creditBtn.Text = ""
  creditBtn.MouseButton1Click:Connect(function()
    local url = "https://www.youtube.com/@LocasBushee"
    pcall(function() setclipboard(url) end)
    pcall(function() if typeof(openbrowser) == "function" then openbrowser(url) end end)
    addLog(" قناة يوتيوب: " .. url)
  end)
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
    if x and y and z then HardUnstuck(Vector3.new(x, y, z)); addLog(("انتقال: %.0f,%.0f,%.0f"):format(x, y, z))
    else addLog("إحداثيات خاطئة") end
  end)
  local c2g = mkCard(t2, 40, 342, P.gold)
  mkLabel(c2g, "الانتقال التلقائي عند التعليق (فوري بعد 1.5 ثانية)", 10, 8, 350, 24, 11)
  mkToggle(c2g, "انتقال", 420, 6, 120, 28, true, function(v)
    ST.emergencyTpOn = v
    addLog(v and "🚑 الانتقال التلقائي: ON" or "الانتقال التلقائي: OFF")
  end)
  local t3 = tabs[3]
  local c3a = mkCard(t3, 44, 0)
  mkLabel(c3a, "كشف اللاعبين (ESP)", 10, 10, 360, 24, 12)
  mkToggle(c3a, "ESP لاعبين", 390, 8, 160, 28, false, function(v)
    ST.espPlayers = v
    if v then task.spawn(updatePlayerESP); addLog("ESP لاعبين: ON")
    else for _, h in pairs(espHL) do pcall(function() h:Destroy() end) end; espHL = {}; for _, b in pairs(espTags) do pcall(function() b:Destroy() end) end; espTags = {}; addLog("ESP لاعبين: OFF") end
  end)
  local c3b = mkCard(t3, 44, 52)
  mkLabel(c3b, "كشف الدروبات", 10, 10, 360, 24, 12)
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
  local targetNameLbl = mkLabel(inspectCard, "اختر لاعباَ...", 10, 4, 290, 22, 12); targetNameLbl.TextColor3 = P.cyan
  local rankTextLbl = mkLabel(inspectCard, "الرتبة: --", 10, 28, 290, 20, 11); rankTextLbl.TextColor3 = Color3.fromRGB(206, 219, 238)
  local rankCompBadge = Instance.new("TextLabel", inspectCard); rankCompBadge.Size = UDim2.new(1, -20, 0, 24); rankCompBadge.Position = UDim2.new(0, 10, 0, 52)
  rankCompBadge.BackgroundColor3 = P.row; rankCompBadge.Text = "⚖️ مقارنة الرتبة: --"; rankCompBadge.TextColor3 = P.muted
  rankCompBadge.Font = Enum.Font.GothamBold; rankCompBadge.TextSize = 11; Instance.new("UICorner", rankCompBadge).CornerRadius = UDim.new(0, 7)
  local distLbl = mkLabel(inspectCard, "المسافة: -- متر", 10, 80, 290, 18, 10); distLbl.TextColor3 = P.muted
  local actY = 104
  mkAction(inspectCard, "🚀 انتقال إليه", 8, actY, 135, 28, Color3.fromRGB(30, 85, 145), function()
    local p = ST.radarSelectedPlr; local tc = p and p.Character; local th = tc and tc:FindFirstChild("HumanoidRootPart")
    if th and char() then HardUnstuck(th.Position + Vector3.new(0, 0, 3)); addLog(("🚀 انتقال إلى: %s"):format(p.DisplayName))
    else addLog("اللاعب غير متواجد") end
  end)
  mkAction(inspectCard, "👮‍♂️ كلبشة", 150, actY, 135, 28, Color3.fromRGB(140, 70, 25), function() cuffPlayer(ST.radarSelectedPlr) end)
  mkAction(inspectCard, "👁️ مراقبة", 8, actY + 34, 135, 28, Color3.fromRGB(70, 40, 130), function() toggleSpectate(ST.radarSelectedPlr) end)
  mkAction(inspectCard, " تتبع", 150, actY + 34, 135, 28, Color3.fromRGB(30, 110, 80), function()
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
  local t5 = tabs[5]
  local c5_def = mkCard(t5, 78, 0)
  mkLabel(c5_def, "🛡️ أنظمة الحماية", 10, 6, 320, 20, 12)
  mkToggle(c5_def, "مضاد الكلبشة", 10, 36, 170, 30, true, function(v) ST.antiCuff = v; addLog(v and "🛡️ مضاد الكلبشة ON" or "إيقاف") end)
  mkToggle(c5_def, "درع تلقائي", 190, 36, 170, 30, true, function(v) ST.autoArmorDefense = v; addLog(v and "🛡️ درع تلقائي ON" or "إيقاف") end)
  mkAction(c5_def, "🛡️ أخذ درع الآن", 370, 36, 175, 30, Color3.fromRGB(30, 100, 140), takeArmor)
  local c5a = mkCard(t5, 78, 86)
  mkLabel(c5a, "🔫 أزرار الماب", 10, 6, 320, 20, 12)
  mkAction(c5a, "🔫 سحب أسلحة", 10, 36, 170, 30, Color3.fromRGB(130, 80, 25), grabWeapons)
  mkAction(c5a, " فتح البوابات", 190, 36, 170, 30, Color3.fromRGB(25, 110, 65), openAllGates)
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
  mkAction(c5g, " ريسباون", 420, 5, 120, 26, Color3.fromRGB(130, 35, 35), function() ST.forceReset = true; task.delay(8, function() ST.forceReset = false end); local h = hum(); if h then h.Health = 0; addLog("Reset") end end)
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
    addLog(v and "🕵️ إخفاء الاسم: ON" or "إخفاء الاسم: OFF")
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
    addLog((" سجن: %s | فرار آمن: %s"):format(ST.antiJail and "ON" or "OFF", ST.lastSafePos and "جاهز" or "--"))
  end)
  mkAction(c5i, "🧹 تنظيف وإصلاح فوري", 280, 76, 265, 30, Color3.fromRGB(30, 120, 100), function()
    pcall(runAntiCuff); pcall(restoreHumanoid, hum()); pcall(healNow, "فحص يدوي"); HardUnstuck()
    addLog("✅ تم تنظيف القيود وإصلاح الشخصية")
  end)
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
  mkToggle(c6b, "Aimbot (تصويب)", 10, 30, 180, 30, false, function(v) ST.aimbotOn = v; if v then aimbotLoop(); addLog(" Aimbot ON") end end)
  mkToggle(c6b, "Kill Aura (قتل قريب)", 200, 30, 180, 30, false, function(v) ST.killAuraOn = v; if v then killAuraLoop(); addLog("⚔️ Kill Aura ON") end end)
  mkAction(c6b, "☠️ سجن الكل", 390, 30, 155, 30, Color3.fromRGB(160, 30, 30), function()
    for _, p in ipairs(Players:GetPlayers()) do if p ~= pl and REM.AutoJail then pcall(function() REM.AutoJail:FireServer(p) end) end end
    addLog("️ سجن الكل")
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
    addLog(" تفجير الكل")
  end)
  mkAction(c6c, "👮‍♂️ Spam كلبشة", 340, 30, 205, 30, Color3.fromRGB(140, 70, 25), function()
    task.spawn(function()
      for i=1,10 do
        for _, p in ipairs(Players:GetPlayers()) do if p ~= pl and REM.EquipCuff then pcall(function() REM.EquipCuff:FireServer(p) end) end end
        task.wait(0.1)
      end
    end)
    addLog("👮‍️ Spam كلبشة")
  end)
  local c6d = mkCard(t6, 80, 264)
  mkLabel(c6d, "🎁 إضافي: سحب اللاعبين والمراقبة", 10, 6, 320, 20, 12)
  mkAction(c6d, " سحب الكل فوري", 10, 30, 180, 30, Color3.fromRGB(50, 100, 180), function()
    for _, p in ipairs(Players:GetPlayers()) do
      if p ~= pl and p.Character then local th = p.Character:FindFirstChild("HumanoidRootPart"); if th and hrp() then pcall(function() p.Character:PivotTo(CFrame.new(hrp().Position + Vector3.new(0, 0, -5))) end) end end
    end
    addLog(" سحب كامل")
  end)
  mkAction(c6d, "👁️ مراقبة الكاميرا", 200, 30, 180, 30, Color3.fromRGB(70, 40, 130), function()
    local p = ST.radarSelectedPlr
    if p then toggleSpectate(p) else addLog("اختر لاعباَ من الرادار") end
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
  local c6e = mkCard(t6, 116, 352, P.rose)
  mkLabel(c6e, "️ هجوم متقدم", 10, 6, 250, 20, 12)
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
  local help = Instance.new("Frame", frame); help.Size = UDim2.new(0, 420, 0, 330); help.Position = UDim2.new(0.5, -210, 0.5, -165)
  help.BackgroundColor3 = P.bg; help.BackgroundTransparency = 0.03; help.Visible = false; help.ZIndex = 60; help.Active = true
  Instance.new("UICorner", help).CornerRadius = UDim.new(0, 14)
  local hs = Instance.new("UIStroke", help); hs.Color = P.accent; hs.Thickness = 1.5; hs.Transparency = 0.2
  local ht = Instance.new("TextLabel", help); ht.Size = UDim2.new(1, -20, 0, 30); ht.Position = UDim2.new(0, 10, 0, 8)
  ht.BackgroundTransparency = 1; ht.Text = "🧭 دليل سريع"; ht.TextColor3 = P.cyan; ht.Font = Enum.Font.GothamBold; ht.TextSize = 15; ht.TextXAlignment = Enum.TextXAlignment.Left
  local hb = Instance.new("TextLabel", help); hb.Size = UDim2.new(1, -24, 0, 220); hb.Position = UDim2.new(0, 12, 0, 42)
  hb.BackgroundTransparency = 1; hb.TextColor3 = P.text; hb.Font = Enum.Font.Code; hb.TextSize = 11; hb.TextXAlignment = Enum.TextXAlignment.Left; hb.TextYAlignment = Enum.TextYAlignment.Top; hb.TextWrapped = true
  hb.Text = "Home : إظهار / إخفاء الواجهة\nEnd : إيقاف السكربت\nCtrl + 1..6 : تبديل التبويبات\n🏠 فارم : المهام + الدروبات + الكهف\n حركة : سرعة، جمب، طيران، Noclip\n👁 كشف : ESP + FOV + اختفاء\n🗺 خريطة : رادار + فحص الرتبة\n🧰 أدوات : حماية + أدوات الماب\n⚔ هجوم : Aimbot، Aura، Auto Kill\nالكهف: ينتظر إشارة الأمن ثم يفتح بالبرومبت، يلمّ الجوائز، يشفط الرافعة، ويصلح الكلبشة عند الموت بدون مطاطية\nالدروب: ينتقل فوقه مباشرة (بلا مشي) وينزل عليه ويضغط E ويحل الكويز\nيدوي: «دخول الكهف» و«تجربة الدروب الآن» في تبويب الفارم"
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

local missionCycleRunning = false
task.spawn(function() while not _G.StopAutoFarm do
  task.wait(0.12)
  if not pl.Character or not alive() then task.wait(0.5); continue end
  if ST.busyCyber or ST.handlingDrop or ST.busyDrop then continue end
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

addLog("AUTOFARM v7.1 جاهز 👑")
addLog("✅ الدروب: انتقال فوري فوقه + ضغط برومبته (لا مشي، لا انتظار)")
addLog("✅ الدروب: منفّذ واحد — اختفت «مقاطعة» المتكررة وإعادة المهمة كل ثانية")
addLog("✅ الكويز: يقرأ أي لايبل فيه معادلة ويكتب ويجوّل تأكيد ويرمي الريموت")
addLog("✅ كشف الصندوق: اسم موجب + تعلّم ذاتي")
addLog("✅ الكهف: لمّ الجوائز + الرافعة + ريستارت ضد المطاطية")
addLog("📋 تشخيص: zDROP zQUIZ zCRATE zTARGET zTIME zCYBER zCAVE zMISSION")
addLog("جرّب: زر «📦 تجربة الدروب الآن» يطلّع zDROP فورًا")
addLog("Home = إخفاء/إظهار | End = إيقاف")
updateStats()
print("[v7.1] Ready — teleport drops, real E-press, equation-agnostic quiz, UI-verified missions, safe cave entry")
