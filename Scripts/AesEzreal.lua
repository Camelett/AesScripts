local version = "1.04"

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
local skillQ = {spellName = "Mystic Shot", range = 1200, speed = 2000, delay = .250, width = 60}
local skillW = {spellName = "Essence Flux", range = 1050, speed = 1600, delay = .250, width = 80}
local skillR = {spellName = "Trueshot Barrage", range = 2000, speed = 2000, delay = 1.0, width = 160}

function OnLoad()
	if VIP_USER then
		prediction = VPrediction()
	else
		qPrediction = TargetPrediction(skillQ.range, skillQ.speed / 1000, skillQ.delay * 1000, skillQ.width)
		wPrediction = TargetPrediction(skillW.range, skillW.speed / 1000, skillW.delay * 1000, skillW.width)
		rPrediction = TargetPrediction(skillR.range, skillR.speed / 1000, skillR.delay * 1000, skillR.width)
	end

	menu()
	targetSelector = TargetSelector(TARGET_LESS_CAST_PRIORITY, skillR.range, DAMAGE_PHYSICAL, false)
	targetSelector.name = "AesEzreal"
	enemyMinions = minionManager(MINION_ENEMY, skillQ.range, myHero)
	menu:addTS(targetSelector)
end
	
function OnTick()
	targetSelector:update()
	enemyMinions:update()
	
	target = targetSelector.target

	if menu.basicSubMenu.scriptCombo then combo() end
	if menu.basicSubMenu.scriptHarass then harass() end
	if menu.basicSubMenu.aoeR then aoeR() end
	if menu.basicSubMenu.scriptFarm then farm() end
	if menu.aggressiveSubMenu.finisherSettings.finishQ or menu.aggressiveSubMenu.finisherSettings.finishW then finisher() end
end

function OnDraw()
	if menu.otherSubMenu.drawSettings.drawQ then DrawCircle3D(myHero.x, myHero.y, myHero.z, skillQ.range, 1, RGB(255, 255, 255)) end
	if menu.otherSubMenu.drawSettings.drawW then DrawCircle3D(myHero.x, myHero.y, myHero.z, skillW.range, 1, RGB(255, 255, 255)) end
	if menu.otherSubMenu.drawSettings.drawR then DrawCircle3D(myHero.x, myHero.y, myHero.z, skillR.range, 1, RGB(255, 255, 255)) end
	
	if ValidTarget(target, skillR.range, true) and myHero:CanUseSpell(_R) == READY then
		for i, enemy in pairs(GetEnemyHeroes()) do
			local correction = myHero:GetSpellData(_R).level * 20
			local rDamage = getDmg("R", enemy, myHero) - correction

			if ValidTarget(enemy, skillR.range, true) and rDamage > enemy.health then
				DrawText3D("Press R to kill!", enemy.x, enemy.y, enemy.z, 15, RGB(255, 0, 0), 0)
				DrawCircle3D(enemy.x, enemy.y, enemy.z, 150, 1, RGB(100, 0, 0))
				DrawCircle3D(enemy.x, enemy.y, enemy.z, 200, 1, RGB(100, 0, 0))
				DrawCircle3D(enemy.x, enemy.y, enemy.z, 250, 1, RGB(100, 0, 0))
				
				if menu.aggressiveSubMenu.finisherSettings.finishR then
					castR(enemy)
				end
			end
		end
	end
end

function combo()
	if ValidTarget(target, skillQ.range, true) then
		if menu.aggressiveSubMenu.comboSettings.comboQ then
			castQ(target)
		end

		if menu.aggressiveSubMenu.comboSettings.comboW then
			castW(target)
		end
	end
end

function harass()
	if ValidTarget(target, skillQ.range, true) and checkManaHarass() then
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

			if ValidTarget(minion, skillQ.range) and qDamage > minion.health and myHero:CanUseSpell(_Q) == READY and not GetMinionCollision(myHero, minion, skillQ.width) then
				CastSpell(_Q, minion.x, minion.z)
			end
		end
	end
end

function finisher()
	if ValidTarget(target, skillR.range, true) then
		for i, enemy in pairs(GetEnemyHeroes()) do
			if menu.aggressiveSubMenu.finisherSettings.finishQ and ValidTarget(enemy, skillQ.range, true) then
				local qDamage = getDmg("Q", enemy, myHero)
				
				if qDamage > enemy.health then
					castQ(enemy)
				end
			end
			
			if menu.aggressiveSubMenu.finisherSettings.finishW and ValidTarget(enemy, skillW.range, true) then
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
		local qPosition, qChance = prediction:GetLineCastPosition(Target, skillQ.delay, skillQ.width, skillQ.range, skillQ.speed, myHero, true)
		
		if qPosition ~= nil and GetDistance(qPosition) < skillQ.range and myHero:CanUseSpell(_Q) == READY and qChance >= 2 then
			CastSpell(_Q, qPosition.x, qPosition.z)
		end
	else
		local qPosition = qPrediction:GetPrediction(Target)
		
		if qPosition ~= nil and GetDistance(qPosition) < skillQ.range and myHero:CanUseSpell(_Q) == READY and not GetMinionCollision(myHero, qPosition, skillQ.width) then
			CastSpell(_Q, qPosition.x, qPosition.z)
		end
	end
end

function castW(Target)
	if VIP_USER then
		local wPosition, wChance = prediction:GetLineCastPosition(Target, skillW.delay, skillW.width, skillW.range, skillW.speed, myHero, false)
		
		if wPosition ~= nil and GetDistance(wPosition) < skillW.range and myHero:CanUseSpell(_W) == READY and wChance >= 2 then
			CastSpell(_W, wPosition.x, wPosition.z)
		end
	else
		local wPosition = wPrediction:GetPrediction(Target)
		
		if wPosition ~= nil and GetDistance(wPosition) < skillW.range and myHero:CanUseSpell(_W) == READY then
			CastSpell(_W, wPosition.x, wPosition.z)
		end
	end
end

function castR(Target)
	if VIP_USER then
		local rPosition, rChance = prediction:GetLineCastPosition(Target, skillR.delay, skillR.width, skillR.range, skillR.speed, myHero, false)
		
		if rPosition ~= nil and GetDistance(rPosition) < skillR.range and myHero:CanUseSpell(_R) == READY and rChance >= 2 then
			CastSpell(_R, rPosition.x, rPosition.z)
		end
	else
		local rPosition = rPrediction:GetPrediction(Target)
		
		if rPosition ~= nil and GetDistance(rPosition) < skillR.range and myHero:CanUseSpell(_R) == READY then
			CastSpell(_R, rPosition.x, rPosition.z)
		end
	end
end

function castAoeR(Target)
	if VIP_USER then
		local aoeRPosition, aoeRChance, aoeTargets = prediction:GetLineAOECastPosition(Target, skillR.delay, skillR.width, skillR.range, skillR.speed, myHero)
		
		if aoeRPosition ~= nil and GetDistance(aoeRPosition) < skillR.range and myHero:CanUseSpell(_R) == READY and aoeRChance >= 2 and aoeTargets >= 2 then
			CastSpell(_R, aoeRPosition.x, aoeRPosition.z)
		end
	else
		local aoeRPosition = GetAoESpellPosition(skillR.radius, Target, skillR.delay)
		
		if aoeRPosition ~= nil and GetDistance(aoeRPosition) < skillR.range and myHero:CanUseSpell(_R) == READY then
			CastSpell(_R, aoeRPosition.x, aoeRPosition.z)
		end
	end
end

function aoeR()
	if ValidTarget(target, skillR.range, true) and myHero:CanUseSpell(_R) == READY then
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
	menu.aggressiveSubMenu.comboSettings:addParam("comboQ", "Use "..skillQ.spellName, SCRIPT_PARAM_ONOFF, false)
	menu.aggressiveSubMenu.comboSettings:addParam("comboW", "Use "..skillW.spellName, SCRIPT_PARAM_ONOFF, false)
	menu.aggressiveSubMenu.comboSettings:addParam("comboR", "Use "..skillR.spellName, SCRIPT_PARAM_ONOFF, false)
	-- Harass submenu
	menu.aggressiveSubMenu:addSubMenu("Harass settings", "harassSettings")
	menu.aggressiveSubMenu.harassSettings:addParam("harassQ", "Use "..skillQ.spellName, SCRIPT_PARAM_ONOFF, false)
	menu.aggressiveSubMenu.harassSettings:addParam("harassW", "Use "..skillW.spellName, SCRIPT_PARAM_ONOFF, false)
	-- Finisher submenu
	menu.aggressiveSubMenu:addSubMenu("Finisher settings", "finisherSettings")
	menu.aggressiveSubMenu.finisherSettings:addParam("finishQ", "Use "..skillQ.spellName, SCRIPT_PARAM_ONOFF, false)
	menu.aggressiveSubMenu.finisherSettings:addParam("finishW", "Use "..skillW.spellName, SCRIPT_PARAM_ONOFF, false)
	menu.aggressiveSubMenu.finisherSettings:addParam("finishR", "Use "..skillR.spellName, SCRIPT_PARAM_ONKEYDOWN, false, GetKey("R"))
	-- Farming submenu
	menu.aggressiveSubMenu:addSubMenu("Farming settings", "farmingSettings")
	menu.aggressiveSubMenu.farmingSettings:addParam("farmQ", "Use "..skillQ.spellName, SCRIPT_PARAM_ONOFF, false)
	
	menu:addSubMenu("AesEzreal: Other settings", "otherSubMenu")
	-- Management submenu
	menu.otherSubMenu:addSubMenu("Management settings", "managementSettings")
	menu.otherSubMenu.managementSettings:addParam("manaProcentHarass", "Minimum mana to harass", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
	menu.otherSubMenu.managementSettings:addParam("manaProcentFarm", "Minimum mana to farm", SCRIPT_PARAM_SLICE, 30, 0, 100, 0)
	-- Draw submenu
	menu.otherSubMenu:addSubMenu("Draw settings", "drawSettings")
	menu.otherSubMenu.drawSettings:addParam("drawQ", "Draw "..skillQ.spellName, SCRIPT_PARAM_ONOFF, false)
	menu.otherSubMenu.drawSettings:addParam("drawW", "Draw "..skillW.spellName, SCRIPT_PARAM_ONOFF, false)
	menu.otherSubMenu.drawSettings:addParam("drawR", "Draw "..skillR.spellName, SCRIPT_PARAM_ONOFF, false)
end
