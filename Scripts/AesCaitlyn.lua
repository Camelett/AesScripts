if myHero.charName ~= "Caitlyn" then return end

-- Require
if VIP_USER then
	require "Collision"
	require "Prodiction"
	prodiction = ProdictManager.GetInstance()
end

-- Variables
local target
local version = 1.2
local rKillable = false

-- Skills information
local skillQ = {spellName = "Piltover Peacemaker", range = 1300, speed = 2.2, delay = 640}
local skillW = {spellName = "Yordle Snap Trap", range = 800, speed = 1.5, delay = 500}
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

	if target ~= nil then
		qPosition = predictionQ:GetPrediction(target)
		wPosition = predictionW:GetPrediction(target)
		ePosition = predictionE:GetPrediction(target)
	end

	if menu.combo then combo() end
	if menu.harass then harass() end
	if menu.finisherSubMenu.finishQ or menu.finisherSubMenu.finishE or menu.finisherSubMenu.finishR then finisher() end
end

function OnDraw()
	if menu.drawSubMenu.drawQ then DrawCircle(myHero.x, myHero.y, myHero.z, skillQ.range, 0xFFFFFF) end
	if menu.drawSubMenu.drawW then DrawCircle(myHero.x, myHero.y, myHero.z, skillW.range, 0xFFFFFF) end
	if menu.drawSubMenu.drawE then DrawCircle(myHero.x, myHero.y, myHero.z, skillE.range, 0xFFFFFF) end
	if menu.drawSubMenu.drawR then DrawCircle(myHero.x, myHero.y, myHero.z, skillR.range, 0xFFFFFF) end
	if menu.drawSubMenu.finisherR then
		if target ~= nil then
			local rDamage = getDmg("R", target, myHero)
			if GetDistance(target) <= skillR.range and rDamage > target.health and not target.dead and target.visible then
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
		if menu.comboSubMenu.comboQ and qPosition ~= nil and skillQ.range >= GetDistance(target) then
			CastSpell(_Q, qPosition.x, qPosition.z)
		end
		if menu.comboSubMenu.comboW and wPosition ~= nil and skillW.range >= GetDistance(target) then
			CastSpell(_W, wPosition.x, wPosition.z)
		end
		if menu.comboSubMenu.comboE and ePosition ~= nil and skillE.range >= GetDistance(target) then
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
end

function harass()
	if target ~= nil then
		if menu.harassSubMenu.harassQ and qPosition ~= nil and skillQ.range >= GetDistance(target) and checkManaHarass() then
			CastSpell(_Q, qPosition.x, qPosition.z)
		end

		if menu.harassSubMenu.harassE and ePosition ~= nil and skillE.range >= GetDistance(target) and checkManaHarass() then
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

function finisher()
	if target ~= nil then

		local adDamage = getDmg("AD", target, myHero)
		local qDamage = getDmg("Q", target, myHero) + adDamage
		local eDamage = getDmg("E", target, myHero) + myHero.ap
		local rDamage = getDmg("R", target, myHero)

		if menu.finisherSubMenu.finishQ and qPosition ~= nil and skillQ.range >= GetDistance(target) and qDamage >= target.health and not target.dead and target.visible then
			CastSpell(_Q, qPosition.x, qPosition.z)
		end

		if menu.finisherSubMenu.finishE and ePosition ~= nil and skillE.range >= GetDistance(target) and eDamage >= target.health and not target.dead and target.visible then
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

		if rKillable == true and menu.finisherSubMenu.finishR then
			CastSpell(_R, target)
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

function getRRange()
	if player:GetSpellData(_R).level == 1 or player:GetSpellData(_R).level == 0 then
		return 2000
	elseif player:GetSpellData(_R).level == 2 then
		return 2500 
	elseif player:GetSpellData(_R).level == 3 then
		return 3000
	end
end

function OnWndMsg()

end

function menu()
	menu = scriptConfig("AesCaitlyn", "aescaitlyn")
	-- Combo submenu
	menu:addSubMenu("Combo options", "comboSubMenu")
	menu.comboSubMenu:addParam("comboQ", "Use "..skillQ.spellName, SCRIPT_PARAM_ONOFF, false)
	menu.comboSubMenu:addParam("comboW", "Use "..skillW.spellName, SCRIPT_PARAM_ONOFF, false)
	menu.comboSubMenu:addParam("comboE", "Use "..skillE.spellName, SCRIPT_PARAM_ONOFF, false)
	-- Harass submenu
	menu:addSubMenu("Harass options", "harassSubMenu")
	menu.harassSubMenu:addParam("harassQ", "Use "..skillQ.spellName, SCRIPT_PARAM_ONOFF, false)
	menu.harassSubMenu:addParam("harassE", "Use "..skillE.spellName, SCRIPT_PARAM_ONOFF, false)
	-- Finisher submenu
	menu:addSubMenu("Finisher options", "finisherSubMenu")
	menu.finisherSubMenu:addParam("finishQ", "Use "..skillQ.spellName, SCRIPT_PARAM_ONOFF, false)
	menu.finisherSubMenu:addParam("finishE", "Use "..skillE.spellName, SCRIPT_PARAM_ONOFF, false)
	menu.finisherSubMenu:addParam("finishR", "Use "..skillR.spellName, SCRIPT_PARAM_ONKEYDOWN, false, 82)
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
end
