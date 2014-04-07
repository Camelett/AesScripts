local version = "1.06"

if myHero.charName ~= "Ezreal" then return end

-- Credits for honda7 and Skeem for updater
local autoupdateenabled = true
local UPDATE_SCRIPT_NAME = "AesEzreal"
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/Tikutis/AesScripts/master/Scripts/AesEzreal.lua?chunk="..math.random(1, 1000)
local UPDATE_FILE_PATH = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH

local ServerData
if autoupdateenabled then
  GetAsyncWebResult(UPDATE_HOST, UPDATE_PATH, function(d) ServerData = d end)
  function update()
    if ServerData ~= nil then
      local ServerVersion
      local send, tmp, sstart = nil, string.find(ServerData, "local version = \"")
      if sstart then
        send, tmp = string.find(ServerData, "\"", sstart+1)
      end
      if send then
        ServerVersion = tonumber(string.sub(ServerData, sstart+1, send-1))
      end

      if ServerVersion ~= nil and tonumber(ServerVersion) ~= nil and tonumber(ServerVersion) > tonumber(version) then
        DownloadFile(UPDATE_URL.."?nocache"..myHero.charName..os.clock(), UPDATE_FILE_PATH, function () print("<font color=\"#FF0000\"><b>"..UPDATE_SCRIPT_NAME..":</b> successfully updated. ("..version.." => "..ServerVersion..")</font>") end)
      elseif ServerVersion then
        print("<font color=\"#FF0000\"><b>"..UPDATE_SCRIPT_NAME..":</b> You have got the latest version: <u><b>"..ServerVersion.."</b></u></font>")
      end
      ServerData = nil
    end
  end
  AddTickCallback(update)
end

-- Require
if VIP_USER then
  require "VPrediction"
else
  require "AoE_Skillshot_Position"
end

-- Variables
local target = nil
local enemyMinions
local prediction = nil

-- Spell information
local skills = {
  skillQ = {spellName = "Mystic Shot", range = 1200, speed = 2000, delay = .250, width = 60},
  skillW = {spellName = "Essence Flux", range = 1050, speed = 1600, delay = .250, width = 80},
  skillR = {spellName = "Trueshot Barrage", range = 2000, speed = 2000, delay = 1.0, width = 160},
}

function OnLoad()
  if VIP_USER then
    prediction = VPrediction()
  else
    qPrediction = TargetPrediction(skills.skillQ.range, skills.skillQ.speed / 1000, skills.skillQ.delay * 1000, skills.skillQ.width)
    wPrediction = TargetPrediction(skills.skillW.range, skills.skillW.speed / 1000, skills.skillW.delay * 1000, skills.skillW.width)
    rPrediction = TargetPrediction(skills.skillR.range, skills.skillR.speed / 1000, skills.skillR.delay * 1000, skills.skillR.width)
  end

  targetSelector = TargetSelector(TARGET_LESS_CAST_PRIORITY, skills.skillR.range, DAMAGE_PHYSICAL, false)
  enemyMinions = minionManager(MINION_ENEMY, skills.skillQ.range, myHero)
  targetSelector.name = "AesEzreal"
  menu()
  menu:addTS(targetSelector)
end

function OnTick()
  target = GetCustomTarget()
  enemyMinions:update()

  if menu.basicSubMenu.scriptCombo then combo() end
  if menu.basicSubMenu.scriptHarass then harass() end
  if menu.basicSubMenu.aoeR then aoeR() end
  if menu.basicSubMenu.scriptFarm then farm() end
  if menu.aggressiveSubMenu.finisherSettings.finishQ or menu.aggressiveSubMenu.finisherSettings.finishW then finisher() end
end

function OnDraw()
  if menu.otherSubMenu.drawSettings.drawQ then DrawCircle3D(myHero.x, myHero.y, myHero.z, skills.skillQ.range, 1, RGB(255, 255, 255)) end
  if menu.otherSubMenu.drawSettings.drawW then DrawCircle3D(myHero.x, myHero.y, myHero.z, skills.skillW.range, 1, RGB(255, 255, 255)) end
  if menu.otherSubMenu.drawSettings.drawR then DrawCircle3D(myHero.x, myHero.y, myHero.z, skills.skillR.range, 1, RGB(255, 255, 255)) end

  if myHero:CanUseSpell(_R) == READY then
    for i, enemy in pairs(GetEnemyHeroes()) do
      local correction = myHero:GetSpellData(_R).level * 20
      local rDamage = getDmg("R", enemy, myHero) - correction

      if ValidTarget(enemy, skills.skillR.range, true) and rDamage > enemy.health then
        DrawText3D("Press R to kill!", enemy.x, enemy.y, enemy.z, 15, RGB(255, 0, 0), 0)
        DrawCircle3D(enemy.x, enemy.y, enemy.z, 150, 1, RGB(255, 0, 0))
        DrawCircle3D(enemy.x, enemy.y, enemy.z, 180, 1, RGB(255, 0, 0))
        DrawCircle3D(enemy.x, enemy.y, enemy.z, 210, 1, RGB(255, 0, 0))

        if menu.aggressiveSubMenu.finisherSettings.finishR then
          castR(enemy)
        end
      end
    end
  end
end

function combo()
  if ValidTarget(target, skills.skillQ.range, true) then
    if menu.aggressiveSubMenu.comboSettings.comboQ then
      castQ(target)
    end

    if menu.aggressiveSubMenu.comboSettings.comboW then
      castW(target)
    end
  end
end

function harass()
  if ValidTarget(target, skills.skillQ.range, true) and checkManaHarass() then
    if menu.aggressiveSubMenu.harassSettings.harassQ then
      castQ(target)
    end

    if menu.aggressiveSubMenu.harassSettings.harassW then
      castW(target)
    end
  end
end

function farm()
  if menu.aggressiveSubMenu.farmingSettings.farmQ and checkManaFarm() then
    for i, minion in pairs(enemyMinions.objects) do
      local adDamage = getDmg("AD", minion, myHero)
      local qDamage = getDmg("Q", minion, myHero) + adDamage + getExtraDamage(minion)

      if ValidTarget(minion, skills.skillQ.range) and qDamage > minion.health and myHero:CanUseSpell(_Q) == READY and not GetMinionCollision(myHero, minion, skills.skillQ.width) then
        CastSpell(_Q, minion.x, minion.z)
      end
    end
  end
end

function finisher()
  for i, enemy in pairs(GetEnemyHeroes()) do
    if ValidTarget(target, skills.skillQ.range, true) then
      if menu.aggressiveSubMenu.finisherSettings.finishQ then
        local qDamage = getDmg("Q", enemy, myHero)

        if qDamage > enemy.health then
          castQ(enemy)
        end
      end

      if menu.aggressiveSubMenu.finisherSettings.finishW then
        local wDamage = getDmg("W", enemy, myHero)

        if wDamage > enemy.health then
          castW(enemy)
        end
      end
    end
  end
end

function castQ(Target)
  if VIP_USER then
    local qPosition, qChance = prediction:GetLineCastPosition(Target, skills.skillQ.delay, skills.skillQ.width, skills.skillQ.range, skills.skillQ.speed, myHero, true)

    if qPosition ~= nil and GetDistance(qPosition) < skills.skillQ.range and myHero:CanUseSpell(_Q) == READY and qChance >= 2 then
      CastSpell(_Q, qPosition.x, qPosition.z)
    end
  else
    local qPosition = qPrediction:GetPrediction(Target)

    if qPosition ~= nil and GetDistance(qPosition) < skills.skillQ.range and myHero:CanUseSpell(_Q) == READY and not GetMinionCollision(myHero, qPosition, skills.skillQ.width) then
      CastSpell(_Q, qPosition.x, qPosition.z)
    end
  end
end

function castW(Target)
  if VIP_USER then
    local wPosition, wChance = prediction:GetLineCastPosition(Target, skills.skillW.delay, skills.skillW.width, skills.skillW.range, skills.skillW.speed, myHero, false)

    if wPosition ~= nil and GetDistance(wPosition) < skills.skillW.range and myHero:CanUseSpell(_W) == READY and wChance >= 2 then
      CastSpell(_W, wPosition.x, wPosition.z)
    end
  else
    local wPosition = wPrediction:GetPrediction(Target)

    if wPosition ~= nil and GetDistance(wPosition) < skills.skillW.range and myHero:CanUseSpell(_W) == READY then
      CastSpell(_W, wPosition.x, wPosition.z)
    end
  end
end

function castR(Target)
  if VIP_USER then
    local rPosition, rChance = prediction:GetLineCastPosition(Target, skills.skillR.delay, skills.skillR.width, skills.skillR.range, skills.skillR.speed, myHero, false)

    if rPosition ~= nil and GetDistance(rPosition) < skills.skillR.range and myHero:CanUseSpell(_R) == READY and rChance >= 2 then
      CastSpell(_R, rPosition.x, rPosition.z)
    end
  else
    local rPosition = rPrediction:GetPrediction(Target)

    if rPosition ~= nil and GetDistance(rPosition) < skills.skillR.range and myHero:CanUseSpell(_R) == READY then
      CastSpell(_R, rPosition.x, rPosition.z)
    end
  end
end

function castAoeR(Target)
  if VIP_USER then
    local aoeRPosition, aoeRChance, aoeTargets = prediction:GetLineAOECastPosition(Target, skills.skillR.delay, skills.skillR.width, skills.skillR.range, skills.skillR.speed, myHero)

    if aoeRPosition ~= nil and GetDistance(aoeRPosition) < skills.skillR.range and myHero:CanUseSpell(_R) == READY and aoeRChance >= 2 and aoeTargets >= 2 then
      CastSpell(_R, aoeRPosition.x, aoeRPosition.z)
    end
  else
    local aoeRPosition = GetAoESpellPosition(skills.skillR.radius, Target, skills.skillR.delay)

    if aoeRPosition ~= nil and GetDistance(aoeRPosition) < skills.skillR.range and myHero:CanUseSpell(_R) == READY then
      CastSpell(_R, aoeRPosition.x, aoeRPosition.z)
    end
  end
end

function aoeR()
  if ValidTarget(target, skills.skillR.range, true) and myHero:CanUseSpell(_R) == READY then
    castAoeR(target)
  end
end

function checkManaHarass()
  if myHero.mana >= myHero.maxMana * (menu.otherSubMenu.managementSettings.manaProcentHarass / 100) then
    return true
  else
    return false
  end
end

function checkManaFarm()
  if myHero.mana >= myHero.maxMana * (menu.otherSubMenu.managementSettings.manaProcentFarm / 100) then
    return true
  else
    return false
  end
end

--Credit Trees
function GetCustomTarget()
  targetSelector:update()
  if _G.MMA_Target and _G.MMA_Target.type == myHero.type then return _G.MMA_Target end
  if _G.AutoCarry and _G.AutoCarry.Crosshair and _G.AutoCarry.Attack_Crosshair and _G.AutoCarry.Attack_Crosshair.target and _G.AutoCarry.Attack_Crosshair.target.type == myHero.type then return _G.AutoCarry.Attack_Crosshair.target end
  return targetSelector.target
end

function getExtraDamage(Target)
  local extraDamage = 0

  if GetInventoryHaveItem(3078) then -- Trinity force
    extraDamage = getDmg("TRINITY", Target, myHero)
  end

  if GetInventoryHaveItem(3057) then -- Sheen
    extraDamage = getDmg("SHEEN", Target, myHero)
  end

  return extraDamage
end

function menu()
  menu = scriptConfig("AesEzreal: Main menu", "aesezreal")

  menu:addSubMenu("AesEzreal: Basic settings", "basicSubMenu")
  menu.basicSubMenu:addParam("scriptCombo", "Use combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
  menu.basicSubMenu:addParam("scriptHarass", "Use harass", SCRIPT_PARAM_ONKEYDOWN, false, GetKey("A"))
  menu.basicSubMenu:addParam("scriptFarm", "Use farm", SCRIPT_PARAM_ONKEYDOWN, false, GetKey("X"))
  menu.basicSubMenu:addParam("aoeR", "Use ultimate at best position", SCRIPT_PARAM_ONKEYDOWN, false, GetKey("Z"))
  menu.basicSubMenu:addParam("version", "Version:", SCRIPT_PARAM_INFO, version)

  menu:addSubMenu("AesEzreal: Aggressive settings", "aggressiveSubMenu")
  -- Combo submenu
  menu.aggressiveSubMenu:addSubMenu("Combo settings", "comboSettings")
  menu.aggressiveSubMenu.comboSettings:addParam("comboQ", "Use "..skills.skillQ.spellName, SCRIPT_PARAM_ONOFF, false)
  menu.aggressiveSubMenu.comboSettings:addParam("comboW", "Use "..skills.skillW.spellName, SCRIPT_PARAM_ONOFF, false)
  menu.aggressiveSubMenu.comboSettings:addParam("comboR", "Use "..skills.skillR.spellName, SCRIPT_PARAM_ONOFF, false)
  -- Harass submenu
  menu.aggressiveSubMenu:addSubMenu("Harass settings", "harassSettings")
  menu.aggressiveSubMenu.harassSettings:addParam("harassQ", "Use "..skills.skillQ.spellName, SCRIPT_PARAM_ONOFF, false)
  menu.aggressiveSubMenu.harassSettings:addParam("harassW", "Use "..skills.skillW.spellName, SCRIPT_PARAM_ONOFF, false)
  -- Finisher submenu
  menu.aggressiveSubMenu:addSubMenu("Finisher settings", "finisherSettings")
  menu.aggressiveSubMenu.finisherSettings:addParam("finishQ", "Use "..skills.skillQ.spellName, SCRIPT_PARAM_ONOFF, false)
  menu.aggressiveSubMenu.finisherSettings:addParam("finishW", "Use "..skills.skillW.spellName, SCRIPT_PARAM_ONOFF, false)
  menu.aggressiveSubMenu.finisherSettings:addParam("finishR", "Use "..skills.skillR.spellName, SCRIPT_PARAM_ONKEYDOWN, false, GetKey("R"))
  -- Farming submenu
  menu.aggressiveSubMenu:addSubMenu("Farming settings", "farmingSettings")
  menu.aggressiveSubMenu.farmingSettings:addParam("farmQ", "Use "..skills.skillQ.spellName, SCRIPT_PARAM_ONOFF, false)

  menu:addSubMenu("AesEzreal: Other settings", "otherSubMenu")
  -- Management submenu
  menu.otherSubMenu:addSubMenu("Management settings", "managementSettings")
  menu.otherSubMenu.managementSettings:addParam("manaProcentHarass", "Minimum mana to harass", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
  menu.otherSubMenu.managementSettings:addParam("manaProcentFarm", "Minimum mana to farm", SCRIPT_PARAM_SLICE, 30, 0, 100, 0)
  -- Draw submenu
  menu.otherSubMenu:addSubMenu("Draw settings", "drawSettings")
  menu.otherSubMenu.drawSettings:addParam("drawQ", "Draw "..skills.skillQ.spellName, SCRIPT_PARAM_ONOFF, false)
  menu.otherSubMenu.drawSettings:addParam("drawW", "Draw "..skills.skillW.spellName, SCRIPT_PARAM_ONOFF, false)
  menu.otherSubMenu.drawSettings:addParam("drawR", "Draw "..skills.skillR.spellName, SCRIPT_PARAM_ONOFF, false)
end
