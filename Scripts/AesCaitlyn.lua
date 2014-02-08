if myHero.charName ~= "Caitlyn" then return end

-- Require
if VIP_USER then
	require "Collision"
	require "Prodiction"
end

-- Variables
local target = nil
local version = 1.5

-- Skills information
local skillQ = {spellName = "Piltover Peacemaker", range = 1300, speed = 2.2, delay = 625, width = 90}
local skillW = {spellName = "Yordle Snap Trap", range = 800, speed = 1.45, delay = 250}
local skillE = {spellName = "90 Caliber Net", range = 950, speed = 2.0, delay = 150, width = 80}
local skillR = {spellName = "Ace in the Hole", range = 2000}

function OnLoad()
	if VIP_USER then
		prodiction = ProdictManager.GetInstance()
		predictionQ = prodiction:AddProdictionObject(_Q, skillQ.range, skillQ.speed * 1000, skillQ.delay / 1000, skillQ.width)
		predictionW = prodiction:AddProdictionObject(_W, skillW.range, skillW.speed * 1000, skillW.delay / 1000)
		predictionE = prodiction:AddProdictionObject(_E, skillE.range, skillE.speed * 1000, skillE.delay / 1000, skillE.width)
		eCollision = Collision(skillE.range, skillE.speed, skillE.delay / 1000, skillE.width)
	else
		predictionQ = TargetPrediction(skillQ.range, skillQ.speed, skillQ.delay)
		predictionW = TargetPrediction(skillW.range, skillW.speed, skillW.delay)
		predictionE = TargetPrediction(skillE.range, skillE.speed, skillE.delay, skillE.width)
	end

	skillR.range = getRRange()
	menu()
	targetSelector = TargetSelector(TARGET_LESS_CAST_PRIORITY, skillR.range, DAMAGE_PHYSICAL, false)
	print("AesCaitlyn version: ".. version .. " loaded!")
end

function OnTick()
	targetSelector:update()
	skillR.range = getRRange()

	target = targetSelector.target

	if config.basicSubMenu.combo then combo() end
	if config.basicSubMenu.harass then harass() end
	if config.basicSubMenu.reverseE then reversedE() end
	if config.defensiveSubMenu.trappingSubMenu.autoW then trap() end
	if config.aggressiveSubMenu.finisherSubMenu.finishQ or config.aggressiveSubMenu.finisherSubMenu.finishE or config.aggressiveSubMenu.finisherSubMenu.finishR then finisher() end
end

function OnDraw()
	if config.otherSubMenu.drawSubMenu.drawQ then DrawCircle(myHero.x, myHero.y, myHero.z, skillQ.range, 0xFFFFFF) end
	if config.otherSubMenu.drawSubMenu.drawW then DrawCircle(myHero.x, myHero.y, myHero.z, skillW.range, 0xFFFFFF) end
	if config.otherSubMenu.drawSubMenu.drawE then DrawCircle(myHero.x, myHero.y, myHero.z, skillE.range, 0xFFFFFF) end
	if config.otherSubMenu.drawSubMenu.drawR then DrawCircle(myHero.x, myHero.y, myHero.z, skillR.range, 0xFFFFFF) end
	for i, enemy in pairs(GetEnemyHeroes()) do	
		local rDamage = getDmg("R", enemy, myHero)
		local rRatio = rDamage - enemy.health

			if GetDistance(enemy) < skillR.range and rDamage > enemy.health and rRatio >= 50 and not enemy.dead and enemy.visible and myHero:CanUseSpell(_R) == READY then
				PrintFloatText(enemy, 0, "Press R to SNIPE!!")
				DrawCircle(enemy.x, enemy.y, enemy.z, 150, 0xFF0000)
				DrawCircle(enemy.x, enemy.y, enemy.z, 200, 0xFF0000)
				DrawCircle(enemy.x, enemy.y, enemy.z, 250, 0xFF0000)
				if config.aggressiveSubMenu.finisherSubMenu.finishR then
					CastSpell(_R, enemy)
				end
			end
	end
end

function combo()
	if target ~= nil then
		if config.aggressiveSubMenu.comboSubMenu.comboQ then
			local qPosition = predictionQ:GetPrediction(target)

			if qPosition ~= nil and myHero:CanUseSpell(_Q) == READY and config.aggressiveSubMenu.comboSubMenu.comboRangeQ > GetDistance(qPosition) then
				CastSpell(_Q, qPosition.x, qPosition.z)
			end
		end

		if config.aggressiveSubMenu.comboSubMenu.comboE then
			local ePosition = predictionE:GetPrediction(target)

			if ePosition ~= nil and myHero:CanUseSpell(_E) == READY and config.aggressiveSubMenu.comboSubMenu.comboRangeE > GetDistance(ePosition) then
				if VIP_USER then
					if not GetMinionCollision(myHero, target, skillE.width) then
						CastSpell(_E, ePosition.x, ePosition.z)
					end
				else
					if not GetMinionCollision(myHero, target, skillE.width) then 
						CastSpell(_E, ePosition.x, ePosition.z)
					end
				end
			end
		end

		if config.aggressiveSubMenu.comboSubMenu.comboW then
			local wPosition = predictionW:GetPrediction(target)

			if wPosition ~= nil and myHero:CanUseSpell(_W) == READY and config.aggressiveSubMenu.comboSubMenu.comboRangeW > GetDistance(wPosition) then
				CastSpell(_W, wPosition.x, wPosition.z)
			end
		end
	end
end

function harass()
	if target ~= nil then
		if config.aggressiveSubMenu.harassSubMenu.harassQ then
			local qPosition = predictionQ:GetPrediction(target)

			if qPosition ~= nil and myHero:CanUseSpell(_Q) == READY and config.aggressiveSubMenu.harassSubMenu.harassRangeQ > GetDistance(qPosition) and checkManaHarass() then
				CastSpell(_Q, qPosition.x, qPosition.z)
			end
		end

		if config.aggressiveSubMenu.harassSubMenu.harassE then
			local ePosition = predictionE:GetPrediction(target)

			if ePosition ~= nil and myHero:CanUseSpell(_E) == READY and config.aggressiveSubMenu.harassSubMenu.harassRangeE > GetDistance(ePosition) and checkManaHarass() then
				if VIP_USER then
					if not eCollision:GetMinionCollision(myHero, qPosition) then
						CastSpell(_E, ePosition.x, ePosition.z)
					end
				else
					if not GetMinionCollision(myHero, target, skillE.width) then
						CastSpell(_E, ePosition.x, ePosition.z)
					end
				end
			end
		end
	end
end

function finisher()
	if config.aggressiveSubMenu.finisherSubMenu.finishQ then
		for i, enemy in pairs(GetEnemyHeroes()) do
			local qPosition = predictionQ:GetPrediction(enemy)
			local qDamage = getDmg("Q", enemy, myHero)

			if qPosition ~= nil and skillQ.range > GetDistance(qPosition) and qDamage > enemy.health and not enemy.dead and enemy.visible then
				CastSpell(_Q, qPosition.x, qPosition.z)
			end
		end
	end

	if config.aggressiveSubMenu.finisherSubMenu.finishE then
		for i, enemy in pairs(GetEnemyHeroes()) do
			local ePosition = predictionE:GetPrediction(enemy)
			local eDamage = getDmg("E", enemy, myHero)

			if ePosition ~= nil and myHero:CanUseSpell(_E) == READY and skillE.range > GetDistance(ePosition) and eDamage > enemy.health and not enemy.dead and enemy.visible then
				if VIP_USER then
					if not eCollision:GetMinionCollision(myHero, qPosition) then
						CastSpell(_E, ePosition.x, ePosition.z)
					end
				else
					if not GetMinionCollision(myHero, enemy, skillE.width) then
						CastSpell(_E, ePosition.x, ePosition.z)
					end
				end
			end
		end
	end
end

function trap()
	if config.defensiveSubMenu.trappingSubMenu.autoW then
		for i, enemy in pairs(GetEnemyHeroes()) do
			if GetDistance(enemy) < skillW.range and myHero:CanUseSpell(_W) == READY and not enemy.canMove then
				CastSpell(_W, enemy.x, enemy.z)
			end
		end
	end
end

function reversedE()
	if myHero:CanUseSpell(_E) == READY then
		-- credits to jbman for calculations
		local MPos = Vector(mousePos.x, mousePos.y, mousePos.z)
		local HeroPos = Vector(myHero.x, myHero.y, myHero.z)
		local DashPos = HeroPos + ( HeroPos - MPos )*(500/GetDistance(mousePos))

		CastSpell(_E, DashPos.x, DashPos.y, DashPos.z)
	end
end

function checkManaHarass()
	if myHero.mana >= myHero.maxMana * (config.otherSubMenu.managementOptions.manaProcentHarass / 100) then
		return true
	else
		return false
	end
end

function getRRange()
	if player:GetSpellData(_R).level == 1 or player:GetSpellData(_R).level == 0 then
		return 2000
	elseif player:GetSpellData(_R).level == 2 then
		return 2500 
	elseif player:GetSpellData(_R).level == 3 then
		return 3000
	end
end

function menu()
	config = scriptConfig("AesCaitlyn: Main menu", "aescaitlyn")
	-- Basic submenu
	config:addSubMenu("AesCaitlyn: Basic settings", "basicSubMenu")
	config.basicSubMenu:addParam("combo", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	config.basicSubMenu:addParam("harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, 65)
	config.basicSubMenu:addParam("reverseE", "Use reversed "..skillE.spellName, SCRIPT_PARAM_ONKEYDOWN, false, 69)
	config.basicSubMenu:addParam("version", "Version:", SCRIPT_PARAM_INFO, version)

	-- Aggressive submenu
	config:addSubMenu("AesCaitlyn: Aggressive settings", "aggressiveSubMenu")

	config.aggressiveSubMenu:addSubMenu("Combo settings", "comboSubMenu")
	config.aggressiveSubMenu.comboSubMenu:addParam("comboQ", "Use "..skillQ.spellName, SCRIPT_PARAM_ONOFF, false)
	config.aggressiveSubMenu.comboSubMenu:addParam("comboW", "Use "..skillW.spellName, SCRIPT_PARAM_ONOFF, false)
	config.aggressiveSubMenu.comboSubMenu:addParam("comboE", "Use "..skillE.spellName, SCRIPT_PARAM_ONOFF, false)
	config.aggressiveSubMenu.comboSubMenu:addParam("comboRangeQ", "Set "..skillQ.spellName.." range", SCRIPT_PARAM_SLICE, 1300, 0, skillQ.range, 0)
	config.aggressiveSubMenu.comboSubMenu:addParam("comboRangeW", "Set "..skillW.spellName.." range", SCRIPT_PARAM_SLICE, 800, 0, skillW.range, 0)
	config.aggressiveSubMenu.comboSubMenu:addParam("comboRangeE", "Set "..skillE.spellName.." range", SCRIPT_PARAM_SLICE, 1000, 0, skillE.range, 0)

	config.aggressiveSubMenu:addSubMenu("Harass settings", "harassSubMenu")
	config.aggressiveSubMenu.harassSubMenu:addParam("harassQ", "Use "..skillQ.spellName, SCRIPT_PARAM_ONOFF, false)
	config.aggressiveSubMenu.harassSubMenu:addParam("harassE", "Use "..skillE.spellName, SCRIPT_PARAM_ONOFF, false)
	config.aggressiveSubMenu.harassSubMenu:addParam("harassRangeQ", "Set "..skillQ.spellName.." range", SCRIPT_PARAM_SLICE, 1300, 0, skillQ.range, 0)
	config.aggressiveSubMenu.harassSubMenu:addParam("harassRangeE", "Set "..skillE.spellName.." range", SCRIPT_PARAM_SLICE, 1000, 0, skillE.range, 0)

	config.aggressiveSubMenu:addSubMenu("Finisher settings", "finisherSubMenu")
	config.aggressiveSubMenu.finisherSubMenu:addParam("finishQ", "Use "..skillQ.spellName, SCRIPT_PARAM_ONOFF, false)
	config.aggressiveSubMenu.finisherSubMenu:addParam("finishE", "Use "..skillE.spellName, SCRIPT_PARAM_ONOFF, false)
	config.aggressiveSubMenu.finisherSubMenu:addParam("finishR", "Use "..skillR.spellName, SCRIPT_PARAM_ONKEYDOWN, false, 82)

	-- Defensive submenu
	config:addSubMenu("AesCaitlyn: Defensive settings", "defensiveSubMenu")

	config.defensiveSubMenu:addSubMenu("Trapping settings", "trappingSubMenu")
	config.defensiveSubMenu.trappingSubMenu:addParam("autoW", "Place "..skillW.spellName.." under stunned target", SCRIPT_PARAM_ONOFF, false)

	-- Other submenu
	config:addSubMenu("AesCaitlyn: Other settings", "otherSubMenu")

	config.otherSubMenu:addSubMenu("Management settingss", "managementOptions")
	config.otherSubMenu.managementOptions:addParam("manaProcentHarass", "Minimum mana to harass", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)

	config.otherSubMenu:addSubMenu("Drawing settings", "drawSubMenu")
	config.otherSubMenu.drawSubMenu:addParam("drawQ", "Draw "..skillQ.spellName.." range", SCRIPT_PARAM_ONOFF, false)
	config.otherSubMenu.drawSubMenu:addParam("drawW", "Draw "..skillW.spellName.." range", SCRIPT_PARAM_ONOFF, false)
	config.otherSubMenu.drawSubMenu:addParam("drawE", "Draw "..skillE.spellName.." range", SCRIPT_PARAM_ONOFF, false)
	config.otherSubMenu.drawSubMenu:addParam("drawR", "Draw "..skillR.spellName.." range", SCRIPT_PARAM_ONOFF, false)
end
