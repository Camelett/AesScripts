if myHero.charName ~= "Ezreal" then return end

-- Require
if VIP_USER then
	require "Prodiction"
	require "Collision"
end

-- Variables
local target
local enemyMinions
local version = 1.2
local prodiction = ProdictManager.GetInstance()

-- Spell information
local skillQ = {spellName = "Mystic Shot", range = 1150, speed = 2.0, delay = 251, width = 80}
local skillW = {spellName = "Essence Flux", range = 1000, speed = 1.6, delay = 250}
local skillR = {spellName = "Trueshot Barrage", range = 2000, speed = 2.0, delay = 1000}

-- Prediction
if VIP_USER then
	predictionQ = prodiction:AddProdictionObject(_Q, skillQ.range, skillQ.speed * 1000, skillQ.delay / 1000, skillQ.width)
	predictionW = prodiction:AddProdictionObject(_W, skillW.range, skillW.speed * 1000, skillW.delay / 1000)
	predictionR = prodiction:AddProdictionObject(_R, skillR.range, skillR.speed * 1000, skillR.delay / 1000)
else
	predictionQ = TargetPrediction(skillQ.range, skillQ.speed, skillQ.delay, skillQ.width)
	predictionW = TargetPrediction(skillW.range, skillW.speed, skillW.delay)
	predictionR = TargetPrediction(skillR.range, skillR.speed, skillR.delay)
end

-- Spell collision
local qCollision = Collision(skillQ.range, skillQ.speed, skillQ.delay, skillQ.width)

function OnLoad()
	PrintChat("AesEzreal loaded! Version: "..version)
	Menu()
	targetSelector = TargetSelector(TARGET_LESS_CAST_PRIORITY, skillR.range, DAMAGE_PHYSICAL, true)
	enemyMinions = minionManager(MINION_ENEMY, skillR.range, myHero)
end
	
function OnTick()
	targetSelector:update()
	enemyMinions:update()
	
	if targetSelector.target ~= nil then
		target = targetSelector.target
	end
	
	if target ~= nil then
		qPosition = predictionQ:GetPrediction(target)
		wPosition = predictionW:GetPrediction(target)
		rPosition = predictionR:GetPrediction(target)
	end
	
	if Menu.scriptCombo then Combo() end
	if Menu.scriptHarass then Harass() end
	if Menu.finisherOptions.finishQ or Menu.finisherOptions.finishW or Menu.finisherOptions.finishR then Finisher() end
end

function OnDraw()
	if Menu.drawOptions.drawQ then DrawCircle(myHero.x, myHero.y, myHero.z, skillQ.range, 0xFF0000) end
	if Menu.drawOptions.drawW then DrawCircle(myHero.x, myHero.y, myHero.z, skillW.range, 0xFF0000) end
	if Menu.drawOptions.drawR then DrawCircle(myHero.x, myHero.y, myHero.z, skillR.range, 0xFF0000) end
end

function Combo()
	if target ~= nil then
		if Menu.comboOptions.comboQ and GetDistance(target) <= skillQ.range and qPosition ~= nil then
			if VIP_USER then
				if not qCollision:GetMinionCollision(myHero, qPosition) then
					CastSpell(_Q, qPosition.x, qPosition.z)
				end
			else
				if not GetMinionCollision(myHero, target, skillQ.width, enemyMinions) then
					CastSpell(_Q, qPosition.x, qPosition.z)
				end
			end
		end
		
		if Menu.comboOptions.comboW and GetDistance(target) <= skillW.range and wPosition ~= nil then
			CastSpell(_W, wPosition.x, wPosition.z)
		end
		
		if Menu.comboOptions.comboR and GetDistance(target) <= skillR.range and rPosition ~= nil then
			CastSpell(_R, rPosition.x, rPosition.z)
		end
	end
end

function Harass()
	if target ~= nil then
		if Menu.harassOptions.harassQ and GetDistance(target) <= skillQ.range and qPosition ~= nil then
			if VIP_USER then
				if not qCollision:GetMinionCollision(myHero, qPosition) and checkMana() then
					CastSpell(_Q, qPosition.x, qPosition.z)
				end
			else
				if not GetMinionCollision(myHero, target, skillQ.width, enemyMinions) and checkMana() then
					CastSpell(_Q, qPosition.x, qPosition.z)
				end			
			end
		end
		
		if Menu.harassOptions.harassW and GetDistance(target) <= skillW.range and wPosition ~= nil then
			if checkMana() then
				CastSpell(_W, wPosition.x, wPosition.z)
			end
		end
	end
end

function Finisher()
	if target ~= nil then
		if Menu.finisherOptions.finishQ then
			qDamage = getDmg("Q", target, myHero)
			if qDamage >= target.health and GetDistance(target) <= skillQ.range and qPosition ~= nil then
				CastSpell(_Q, qPosition.x, qPosition.z)
			end
		end
		
		if Menu.finisherOptions.finishW then
			wDamage = getDmg("W", target, myHero)
			if wDamage >= target.health and GetDistance(target) <= skillW.range and wPosition ~= nil then
				CastSpell(_W, wPosition.x, wPosition.z)
			end
		end
		
		if Menu.finisherOptions.finishR then
			rDamage = getDmg("R", target, myHero)
			if rDamage > target.health and GetDistance(target) <= skillR.range and rPosition ~= nil then
				CastSpell(_R, rPosition.x, rPosition.z)
			end
		end
	end
end

function checkMana()
	if myHero.mana >= myHero.maxMana * (Menu.managementOptions.manaProcent / 100) then
		return true
	else
		return false
	end
end
	
function Menu()
	Menu = scriptConfig("AesEzreal", "aesezreal")
	-- Combo submenu
	Menu:addSubMenu("Combo options", "comboOptions")
	Menu.comboOptions:addParam("comboQ", "Use "..skillQ.spellName, SCRIPT_PARAM_ONOFF, false)
	Menu.comboOptions:addParam("comboW", "Use "..skillW.spellName, SCRIPT_PARAM_ONOFF, false)
	Menu.comboOptions:addParam("comboR", "Use "..skillR.spellName, SCRIPT_PARAM_ONOFF, false)
	-- Harass submenu
	Menu:addSubMenu("Harass options", "harassOptions")
	Menu.harassOptions:addParam("harassQ", "Use "..skillQ.spellName, SCRIPT_PARAM_ONOFF, false)
	Menu.harassOptions:addParam("harassW", "Use "..skillW.spellName, SCRIPT_PARAM_ONOFF, false)
	-- Finisher submenu
	Menu:addSubMenu("Finisher options", "finisherOptions")
	Menu.finisherOptions:addParam("finishQ", "Use "..skillQ.spellName, SCRIPT_PARAM_ONOFF, false)
	Menu.finisherOptions:addParam("finishW", "Use "..skillW.spellName, SCRIPT_PARAM_ONOFF, false)
	Menu.finisherOptions:addParam("finishR", "Use "..skillR.spellName, SCRIPT_PARAM_ONOFF, false)
	-- Management submenu
	Menu:addSubMenu("Management options", "managementOptions")
	Menu.managementOptions:addParam("manaProcent", "Minimum mana to harass", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
	-- Draw submenu
	Menu:addSubMenu("Draw options", "drawOptions")
	Menu.drawOptions:addParam("drawQ", "Draw "..skillQ.spellName.. " range", SCRIPT_PARAM_ONOFF, false)
	Menu.drawOptions:addParam("drawW", "Draw "..skillW.spellName.. " range", SCRIPT_PARAM_ONOFF, false)
	Menu.drawOptions:addParam("drawR", "Draw "..skillR.spellName.. " range", SCRIPT_PARAM_ONOFF, false)
	-- Script combo and harass buttoms
	Menu:addParam("scriptCombo", "Use combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	Menu:addParam("scriptHarass", "Use harass", SCRIPT_PARAM_ONKEYDOWN, false, 65)
end
