if myHero.charName ~= "Ezreal" then return end

-- Require
require "AoE_Skillshot_Position"

if VIP_USER then
	require "Prodiction"
	require "Collision"
	prodiction = ProdictManager.GetInstance()
end

-- Variables
local target
local enemyMinions
local rKillable = false
local version = 1.4

-- Spell information
local skillQ = {spellName = "Mystic Shot", range = 1200, speed = 2.0, delay = 250, width = 80}
local skillW = {spellName = "Essence Flux", range = 1050, speed = 1.6, delay = 250}
local skillR = {spellName = "Trueshot Barrage", range = 2000, speed = 2.0, delay = 1000, width = 160}

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
if VIP_USER then
	qCollision = Collision(skillQ.range, skillQ.speed, skillQ.delay, skillQ.width)
	rCollision = Collision(skillR.range, skillR.speed, skillR.delay, skillR.width)
end

function OnLoad()
	PrintChat("AesEzreal loaded! Version: "..version)
	menu()
	targetSelector = TargetSelector(TARGET_LESS_CAST_PRIORITY, skillR.range, DAMAGE_PHYSICAL, false)
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
	
	if menu.scriptCombo then combo() end
	if menu.scriptHarass then harass() end
	if menu.scriptFarm then farm() end
	if menu.finisherOptions.finishQ or menu.finisherOptions.finishW or menu.finisherOptions.finishR then finisher() end
end

function OnDraw()
	if menu.drawOptions.drawQ then DrawCircle(myHero.x, myHero.y, myHero.z, skillQ.range, 0xFF0000) end
	if menu.drawOptions.drawW then DrawCircle(myHero.x, myHero.y, myHero.z, skillW.range, 0xFF0000) end
	if menu.drawOptions.drawR then DrawCircle(myHero.x, myHero.y, myHero.z, skillR.range, 0xFF0000) end
	if menu.drawOptions.finisherR then
		if target ~= nil then
			local rDamage = getDmg("R", target, myHero)
			local rLoweredDamage = (70 / 100) * rDamage

			if VIP_USER and GetDistance(target) < skillR.range then
				if rCollision:GetMinionCollision(myHero, target) then
					rDamage = rDamage - rLoweredDamage
				end
			elseif GetDistance(target) < skillR.range then
				if GetMinionCollision(myHero, target, skillR.width) then
					rDamage = rDamage - rLoweredDamage
				end
			end
			if GetDistance(target) <= skillR.range and rDamage > target.health and not target.dead and target.visible and myHero:CanUseSpell(_R) == READY then
				rKillable = true
				PrintFloatText(target, 0, "Press R to do tons of damage")
				DrawCircle(target.x, target.y, target.z, 150, 0xFF0000)
				DrawCircle(target.x, target.y, target.z, 200, 0xFF0000)
				DrawCircle(target.x, target.y, target.z, 250, 0xFF0000)
			end
		end
	end
end

function combo()
	if target ~= nil then
		if menu.comboOptions.comboQ and GetDistance(target) < skillQ.range and qPosition ~= nil and myHero:CanUseSpell(_Q) == READY then
			if VIP_USER then
				if not qCollision:GetMinionCollision(myHero, qPosition) then
					CastSpell(_Q, qPosition.x, qPosition.z)
				end
			else
				if not GetMinionCollision(myHero, target, skillQ.width) then
					CastSpell(_Q, qPosition.x, qPosition.z)
				end
			end
		end
		
		if menu.comboOptions.comboW and GetDistance(target) < skillW.range and wPosition ~= nil and myHero:CanUseSpell(_W) == READY then
			CastSpell(_W, wPosition.x, wPosition.z)
		end
		
		if menu.comboOptions.comboR and GetDistance(target) < skillR.range and aoeRPosition ~= nil and myHero:CanUseSpell(_R) == READY then
			local aoeRPosition = GetAoESpellPosition(skillR.width, target, skillR.delay)
			CastSpell(_R, aoeRPosition.x, rPosition.z)
		end
	end
end

function harass()
	if target ~= nil then
		if menu.harassOptions.harassQ and GetDistance(target) < skillQ.range and qPosition ~= nil and myHero:CanUseSpell(_Q) == READY and checkManaHarass() then
			if VIP_USER then
				if not qCollision:GetMinionCollision(myHero, qPosition) then
					CastSpell(_Q, qPosition.x, qPosition.z)
				end
			else
				if not GetMinionCollision(myHero, target, skillQ.width) then
					CastSpell(_Q, qPosition.x, qPosition.z)
				end			
			end
		end
		
		if menu.harassOptions.harassW and GetDistance(target) < skillW.range and wPosition ~= nil and myHero:CanUseSpell(_W) == READY then
			if checkManaHarass() then
				CastSpell(_W, wPosition.x, wPosition.z)
			end
		end
	end
end

function farm()
	if menu.scriptFarm and checkManaFarm() then
		for i, minion in pairs(enemyMinions.objects) do
			local adDamage = getDmg("AD", minion, myHero)
			local qDamage = getDmg("Q", minion, myHero) + adDamage

			if not minion.dead and GetDistance(minion) <= skillQ.range and qDamage > minion.health and myHero:CanUseSpell(_Q) == READY then
				if VIP_USER then
					if not qCollision:GetMinionCollision(myHero, minion) then
						CastSpell(_Q, minion.x, minion.z)
					end
				else
					if not GetMinionCollision(myHero, minion, skillQ.width) then
						CastSpell(_Q, minion.x, minion.z)
					end
				end
			end
		end
	end
end

function finisher()
	if target ~= nil then
		local adDamage = getDmg("AD", target, myHero)
		local qDamage = getDmg("Q", target, myHero) + adDamage
		local wDamage = getDmg("W", target, myHero)
		local rDamage = getDmg("R", target, myHero)

		if menu.finisherOptions.finishQ then
			if qDamage >= target.health and GetDistance(target) < skillQ.range and not target.dead and target.visible and qPosition ~= nil then
				if VIP_USER then
					if not qCollision:GetMinionCollision(myHero, qPosition) then
						CastSpell(_Q, qPosition.x, qPosition.z)
					end
				else
					if not GetMinionCollision(myHero, target, skillQ.width) then
						CastSpell(_Q, qPosition.x, qPosition.z)
					end			
				end
			end
		end
		
		if menu.finisherOptions.finishW then
			local wDamage = getDmg("W", target, myHero) + myHero.ap
			if wDamage >= target.health and GetDistance(target) <= skillW.range and not target.dead and target.visible and wPosition ~= nil and myHero:CanUseSpell(_W) == READY then
				CastSpell(_W, wPosition.x, wPosition.z)
			end
		end
		
		if menu.finisherOptions.finishR and rKillable == true and rPosition ~= nil and myHero:CanUseSpell(_R) == READY then
			CastSpell(_R, rPosition.x, rPosition.z)
		end
	end
end

function checkManaHarass()
	if myHero.mana >= myHero.maxMana * (menu.managementOptions.manaProcentHarass / 100) then
		return true
	else
		return false
	end
end

function checkManaFarm()
	if myHero.mana >= myHero.maxMana * (menu.managementOptions.manaProcentFarm / 100) then
		return true
	else
		return false
	end
end
	
function menu()
	menu = scriptConfig("AesEzreal", "aesezreal")
	-- Combo submenu
	menu:addSubMenu("Combo options", "comboOptions")
	menu.comboOptions:addParam("comboQ", "Use "..skillQ.spellName, SCRIPT_PARAM_ONOFF, false)
	menu.comboOptions:addParam("comboW", "Use "..skillW.spellName, SCRIPT_PARAM_ONOFF, false)
	menu.comboOptions:addParam("comboR", "Use "..skillR.spellName, SCRIPT_PARAM_ONOFF, false)
	-- Harass submenu
	menu:addSubMenu("Harass options", "harassOptions")
	menu.harassOptions:addParam("harassQ", "Use "..skillQ.spellName, SCRIPT_PARAM_ONOFF, false)
	menu.harassOptions:addParam("harassW", "Use "..skillW.spellName, SCRIPT_PARAM_ONOFF, false)
	-- Farming submenu
	menu:addSubMenu("Farming options", "farmingOptions")
	menu.farmingOptions:addParam("farmQ", "Use "..skillQ.spellName, SCRIPT_PARAM_ONOFF, false)
	-- Finisher submenu
	menu:addSubMenu("Finisher options", "finisherOptions")
	menu.finisherOptions:addParam("finishQ", "Use "..skillQ.spellName, SCRIPT_PARAM_ONOFF, false)
	menu.finisherOptions:addParam("finishW", "Use "..skillW.spellName, SCRIPT_PARAM_ONOFF, false)
	menu.finisherOptions:addParam("finishR", "Use "..skillR.spellName, SCRIPT_PARAM_ONKEYDOWN, false, 82)
	-- Management submenu
	menu:addSubMenu("Management options", "managementOptions")
	menu.managementOptions:addParam("manaProcentHarass", "Minimum mana to harass", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
	menu.managementOptions:addParam("manaProcentFarm", "Minimum mana to farm", SCRIPT_PARAM_SLICE, 30, 0, 100, 0)
	-- Draw submenu
	menu:addSubMenu("Draw options", "drawOptions")
	menu.drawOptions:addParam("drawQ", "Draw "..skillQ.spellName.. " range", SCRIPT_PARAM_ONOFF, false)
	menu.drawOptions:addParam("drawW", "Draw "..skillW.spellName.. " range", SCRIPT_PARAM_ONOFF, false)
	menu.drawOptions:addParam("drawR", "Draw "..skillR.spellName.. " range", SCRIPT_PARAM_ONOFF, false)
	menu.drawOptions:addParam("finisherR", "Print killable target with "..skillR.spellName, SCRIPT_PARAM_ONOFF, false)
	-- Script combo and harass bottoms
	menu:addParam("scriptCombo", "Use combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	menu:addParam("scriptHarass", "Use harass", SCRIPT_PARAM_ONKEYDOWN, false, 65)
	menu:addParam("scriptFarm", "Use farm", SCRIPT_PARAM_ONKEYDOWN, false, 88)
end
