if myHero.charName ~= "Caitlyn" then return end

-- Require
if VIP_USER then
	require "Collision"
	require "Prodiction"
end

-- Variables
local target = nil
local version = 1.4
if VIP_USER then prodiction = ProdictManager.GetInstance() end

-- Skills information
local skillQ = {spellName = "Piltover Peacemaker", range = 1300, speed = 2.2, delay = 640}
local skillW = {spellName = "Yordle Snap Trap", range = 800, speed = 1.45, delay = 500}
local skillE = {spellName = "90 Caliber Net", range = 1000, speed = 2.0, delay = 10, width = 80}
local skillR = {spellName = "Ace in the Hole", range = 2000}

-- Prediction
if VIP_USER then
	predictionQ = prodiction:AddProdictionObject(_Q, skillQ.range, skillQ.speed * 1000, skillQ.delay / 1000)
	predictionW = prodiction:AddProdictionObject(_W, skillW.range, skillW.speed * 1000, skillW.delay / 1000)
	predictionE = prodiction:AddProdictionObject(_E, skillE.range, skillE.speed * 1000, skillE.delay / 1000, skillE.width)
else
	predictionQ = TargetPrediction(skillQ.range, skillQ.speed, skillQ.delay)
	predictionW = TargetPrediction(skillW.range, skillW.speed, skillW.delay)
	predictionE = TargetPrediction(skillE.range, skillE.speed, skillE.delay, skillE.width)
end

-- Collision
if VIP_USER then
 	eCollision = Collision(skillE.range, skillE.speed, skillE.delay, skillE.width)
end

function OnLoad()
	print("AesCaitlyn version: ".. version .. " loaded!")
	skillR.range = getRRange()
	menu()
	targetSelector = TargetSelector(TARGET_LESS_CAST_PRIORITY, skillR.range, DAMAGE_PHYSICAL, false)
end

function OnTick()
	targetSelector:update()
	skillR.range = getRRange()

	if targetSelector.target ~= nil then
		target = targetSelector.target
	end

	if menu.combo then combo() end
	if menu.harass then harass() end
	if menu.trappingSubMenu.autoW then trap() end
	if menu.miscSubMenu.reverseE then reversedE() end
	if menu.finisherSubMenu.finishQ or menu.finisherSubMenu.finishE or menu.finisherSubMenu.finishR then finisher() end
end

function OnDraw()
	if menu.drawSubMenu.drawQ then DrawCircle(myHero.x, myHero.y, myHero.z, skillQ.range, 0xFFFFFF) end
	if menu.drawSubMenu.drawW then DrawCircle(myHero.x, myHero.y, myHero.z, skillW.range, 0xFFFFFF) end
	if menu.drawSubMenu.drawE then DrawCircle(myHero.x, myHero.y, myHero.z, skillE.range, 0xFFFFFF) end
	if menu.drawSubMenu.drawR then DrawCircle(myHero.x, myHero.y, myHero.z, skillR.range, 0xFFFFFF) end
	if menu.drawSubMenu.finisherR then
		for i, enemy in pairs(GetEnemyHeroes()) do	
		local rDamage = getDmg("R", enemy, myHero)

			if GetDistance(enemy) <= skillR.range and rDamage > enemy.health and not enemy.dead and enemy.visible then
				PrintFloatText(enemy, 0, "Press R to do tons of damage")
				DrawCircle(enemy.x, enemy.y, enemy.z, 150, 0xFF0000)
				DrawCircle(enemy.x, enemy.y, enemy.z, 200, 0xFF0000)
				DrawCircle(enemy.x, enemy.y, enemy.z, 250, 0xFF0000)
			end
		end
	end
end

function combo()
	if target ~= nil then
		if menu.comboSubMenu.comboQ then
			local qPosition = predictionQ:GetPrediction(target)

			if qPosition ~= nil and myHero:CanUseSpell(_Q) and menu.comboSubMenu.comboRangeQ > GetDistance(target) then
				CastSpell(_Q, qPosition.x, qPosition.z)
			end
		end

		if menu.comboSubMenu.comboE then
			local ePosition = predictionE:GetPrediction(target)

			if ePosition ~= nil and myHero:CanUseSpell(_E) and menu.comboSubMenu.comboRangeE > GetDistance(target) then
				if VIP_USER then
					if not GetMinionCollision(myHero, target, skillE.width) then
						CastSpell(_E, ePosition.x, ePosition.z)
					end
				end
			else
				if not GetMinionCollision(myHero, target, skillE.width) then 
					CastSpell(_E, ePosition.x, ePosition.z)
				end
			end
		end

		if menu.comboSubMenu.comboW then
			local wPosition = predictionW:GetPrediction(target)

			if wPosition ~= nil and myHero:CanUseSpell(_W) and menu.comboSubMenu.comboRangeW > GetDistance(target) then
				CastSpell(_W, wPosition.x, wPosition.z)
			end
		end
	end
end

function harass()
	if target ~= nil then
		if menu.harassSubMenu.harassQ then
			local qPosition = predictionQ:GetPrediction(target)

			if qPosition ~= nil and myHero:CanUseSpell(_Q) and menu.harassSubMenu.harassRangeQ > GetDistance(target) and checkManaHarass() then
				CastSpell(_Q, qPosition.x, qPosition.z)
			end
		end

		if menu.harassSubMenu.harassE then
			local ePosition = predictionE:GetPrediction(target)

			if ePosition ~= nil and myHero:CanUseSpell(_E) and menu.harassSubMenu.harassRangeE > GetDistance(target) and checkManaHarass() then
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
	if menu.finisherSubMenu.finishQ then
		for i, enemy in pairs(GetEnemyHeroes()) do
			local qPosition = predictionQ:GetPrediction(enemy)
			local qDamage = getDmg("Q", enemy, myHero)

			if qPosition ~= nil and skillQ.range > GetDistance(enemy) and qDamage > enemy.health and not enemy.dead and enemy.visible then
				CastSpell(_Q, qPosition.x, qPosition.z)
			end
		end
	end

	if menu.finisherSubMenu.finishE then
		for i, enemy in pairs(GetEnemyHeroes()) do
			local eDamage = getDmg("E", enemy, myHero)

			if ePosition ~= nil and myHero:CanUseSpell(_E) and skillE.range > GetDistance(enemy) and eDamage > enemy.health and not enemy.dead and enemy.visible then
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

	if menu.finisherSubMenu.finishR then
		for i, enemy in pairs(GetEnemyHeroes()) do
			local rDamage = getDmg("R", enemy, myHero)

			if enemy~= nil and GetDistance(enemy) <= skillR.range and rDamage > enemy.health and not enemy.dead and enemy.visible then
				CastSpell(_R, enemy)
			end
		end
	end
end

function trap()
	if menu.trappingSubMenu.autoW then
		for i, enemy in pairs(GetEnemyHeroes()) do
			if GetDistance(enemy) < skillW.range and wPosition ~= nil and myHero:CanUseSpell(_W) == READY and not enemy.canMove then
				CastSpell(_W, enemy.x, enemy.z)
			end
		end
	end
end

function reversedE()
	if menu.miscSubMenu.reverseE and myHero:CanUseSpell(_E) == READY then
		-- credits to jbman for calculations
		local MPos = Vector(mousePos.x, mousePos.y, mousePos.z)
		local HeroPos = Vector(myHero.x, myHero.y, myHero.z)
		local DashPos = HeroPos + ( HeroPos - MPos )*(500/GetDistance(mousePos))

		CastSpell(_E, DashPos.x, DashPos.y, DashPos.z)
	end
end

function checkManaHarass()
	if myHero.mana >= myHero.maxMana * (menu.managementOptions.manaProcentHarass / 100) then
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
	menu = scriptConfig("AesCaitlyn", "aescaitlyn")
	-- Combo submenu
	menu:addSubMenu("Combo options", "comboSubMenu")
	menu.comboSubMenu:addParam("comboQ", "Use "..skillQ.spellName, SCRIPT_PARAM_ONOFF, false)
	menu.comboSubMenu:addParam("comboW", "Use "..skillW.spellName, SCRIPT_PARAM_ONOFF, false)
	menu.comboSubMenu:addParam("comboE", "Use "..skillE.spellName, SCRIPT_PARAM_ONOFF, false)
	menu.comboSubMenu:addParam("comboRangeQ", "Set "..skillQ.spellName.." range", SCRIPT_PARAM_SLICE, 1300, 0, skillQ.range, 0)
	menu.comboSubMenu:addParam("comboRangeW", "Set "..skillW.spellName.." range", SCRIPT_PARAM_SLICE, 800, 0, skillW.range, 0)
	menu.comboSubMenu:addParam("comboRangeE", "Set "..skillE.spellName.." range", SCRIPT_PARAM_SLICE, 1000, 0, skillE.range, 0)
	-- Harass submenu
	menu:addSubMenu("Harass options", "harassSubMenu")
	menu.harassSubMenu:addParam("harassQ", "Use "..skillQ.spellName, SCRIPT_PARAM_ONOFF, false)
	menu.harassSubMenu:addParam("harassE", "Use "..skillE.spellName, SCRIPT_PARAM_ONOFF, false)
	menu.harassSubMenu:addParam("harassRangeQ", "Set "..skillQ.spellName.." range", SCRIPT_PARAM_SLICE, 1300, 0, skillQ.range, 0)
	menu.harassSubMenu:addParam("harassRangeE", "Set "..skillE.spellName.." range", SCRIPT_PARAM_SLICE, 1000, 0, skillE.range, 0)
	-- Finisher submenu
	menu:addSubMenu("Finisher options", "finisherSubMenu")
	menu.finisherSubMenu:addParam("finishQ", "Use "..skillQ.spellName, SCRIPT_PARAM_ONOFF, false)
	menu.finisherSubMenu:addParam("finishE", "Use "..skillE.spellName, SCRIPT_PARAM_ONOFF, false)
	menu.finisherSubMenu:addParam("finishR", "Use "..skillR.spellName, SCRIPT_PARAM_ONKEYDOWN, false, 82)
	-- Traps submenu
	menu:addSubMenu("Trapping options", "trappingSubMenu")
	menu.trappingSubMenu:addParam("autoW", "Place "..skillW.spellName.." under stunned target", SCRIPT_PARAM_ONOFF, false)
	-- Misc submenu
	menu:addSubMenu("Misc options", "miscSubMenu")
	menu.miscSubMenu:addParam("reverseE", "Use reversed "..skillE.spellName, SCRIPT_PARAM_ONKEYDOWN, false, 69)
	-- Draw submenu
	menu:addSubMenu("Draw options", "drawSubMenu")
	menu.drawSubMenu:addParam("drawQ", "Draw "..skillQ.spellName.." range", SCRIPT_PARAM_ONOFF, false)
	menu.drawSubMenu:addParam("drawW", "Draw "..skillW.spellName.." range", SCRIPT_PARAM_ONOFF, false)
	menu.drawSubMenu:addParam("drawE", "Draw "..skillE.spellName.." range", SCRIPT_PARAM_ONOFF, false)
	menu.drawSubMenu:addParam("drawR", "Draw "..skillR.spellName.." range", SCRIPT_PARAM_ONOFF, false)
	menu.drawSubMenu:addParam("finisherR", "Draw text under killable target with "..skillR.spellName, SCRIPT_PARAM_ONOFF, false)
	-- Management submenu
	menu:addSubMenu("Management options", "managementOptions")
	menu.managementOptions:addParam("manaProcentHarass", "Minimum mana to harass", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
	-- Script bottoms
	menu:addParam("combo", "Use combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	menu:addParam("harass", "Use harass", SCRIPT_PARAM_ONKEYDOWN, false, 65)
	menu:addParam("version", "Version:", SCRIPT_PARAM_INFO, version)
end
