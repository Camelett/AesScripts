if myHero.charName ~= "Ezreal" then return end

-- Variables
local target = targetSelector.target

-- Spell information
local skillQ = {spellName = "Mystic Shot", range = 1150, speed = 2.0, delay = 251, width = 80}
local skillW = {spellName = "Essence Flux", range = 1000, speed = 1.6, delay = 250}
local skillR = {spellName = "Trueshot Barrage", range = 2000, speed = 2.0, delay = 1000}

-- Prediction
if VIP_USER then
	predictionQ = TargetPredictionVIP(skillQ.range, skillQ.speed * 1000, skillQ.delay / 1000, skillQ.width)
	predictionW = TargetPredictionVIP(skillW.range, skillW.speed * 1000, skillW.delay / 1000)
	predictionR = TargetPredictionVIP(skillR.range, skillR.speed * 1000, skillR.delay / 1000)
else
	predictionQ = TargetPrediction(skillQ.range, skillQ.speed, skillQ.delay, skillQ.width)
	predictionW = TargetPrediction(skillW.range, skillW.speed, skillW.delay)
	predictionR = TargetPrediction(skillR.range, skillR.speed, skillR.delay)
end

function OnLoad()
	Menu()
	targetSelector = TargetSelector(TARGET_LESS_CAST_PRIORITY, skillR.range, DAMAGE_PHYSICAL, true)
end
	
function OnTick()
	targetSelector:update()
	
	if target ~= nil then
		qPosition = predictionQ:GetPrediction(target)
		wPosition = predictionW:GetPrediction(target)
		rPosition = predictionR:GetPrediction(target)
	end
	
	if Menu.scriptCombo then Combo() end
	if Menu.scriptHarass then Harass() end
end

function OnDraw()
	if Menu.drawOptions.drawQ then DrawCircle(myHero.x, myHero.z, skillQ.range, 0xFF0000) end
	if Menu.drawOptions.drawW then DrawCircle(myHero.x, myHero.z, skillW.range, 0xFF0000) end
	if Menu.drawOptions.drawR then DrawCircle(myHero.x, myHero.z, skillR.range, 0xFF0000) end
end

function Combo()
	if target ~= nil then
		if Menu.comboOptions.comboQ and GetDistance(target) <= skillQ.range then
			if predictionQ:GetCollision(target) == false then
				CastSpell(_Q, qPosition.x, qPosition.z)
			end
		end
		
		if Menu.comboOptions.comboW and GetDistance(target) <= skillW.range then
			CastSpell(_W, wPosition.x, wPosition.z)
		end
		
		if Menu.comboOptions.comboR and GetDistance(target) <= SkillR.range then
			CastSpell(_R, rPosition.x, rPosition.z)
		end
	end
end

function Harass()
	if target ~= nil then
		if Menu.harassOptions.harassQ and GetDistance(target) <= skillQ.range then
			if predictionQ:GetCollision(target) == false and CheckMana() then
				CastSpell(_Q, qPosition.x, qPosition.z)
			end
		end
		
		if Menu.harassOptions.harassW and GetDistance(target) <= skillW.range then
			if CheckMana() then
				CastSpell(_W, predictionW.x, predictionW.z)
			end
		end
	end
end

function Finisher()
	if target ~= nil then
		if Menu.finisherOptions.finishQ and GetDistance(target) <= skillQ.range then
			qDamage = getDmg("Q", target, myHero)
			if qDamage >= target.health then
				CastSpell(_Q, predictionQ.x, prediction.z)
			end
		end
		
		if Menu.finisherOptions.finishW and GetDistance(target) <= skillW.range then
			wDamage = getDmg("W", target, myHero)
			if wDamage >= target.health then
				CastSpell(_W, predictionW.x, predictionW.z)
			end
		end
		
		if Menu.finisherOptions.finishR and GetDistance(target) <= skillR.range then
			rDamage = getDmg("R", target, myHero)
			if rDamage >= target.health then
				CastSpell(_R, predictionR.x, prediction.z)
			end
		end
	end
end

function CheckMana()
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
	Menu:addParam("manaProcent", "Minimum mana to harass", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
	-- Draw submenu
	Menu:addSubMenu("Draw options", "drawOptions")
	Menu.drawOptions:addParam("drawQ", "Draw "..skillQ.spellName.. " range", SCRIPT_PARAM_ONOFF, false)
	Menu.drawOptions:addParam("drawW", "Draw "..skillW.spellName.. " range", SCRIPT_PARAM_ONOFF, false)
	Menu.drawOptions:addParam("drawR", "Draw "..skillR.spellName.. " range", SCRIPT_PARAM_ONOFF, false)
	-- Script combo and harass buttoms
	Menu:addParam("scriptCombo", "Use combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	Menu:addParam("scriptHarass", "Use harass", SCRIPT_PARAM_ONKEYDOWN, false, 65)
end
