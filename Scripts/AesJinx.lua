if myHero.charName ~= "Jinx" then return end

--Requires
if VIP_USER then
	require "VPrediction"
else
	require "AoE_Skillshot_Position"
end

--Variables
local target = nil
local prediction = nil
local version = 0.5
local rocket = false

--Skill table
local skillsTable = {
	skillQ = {name = "Switcheroo!", minigunRange = 525, fishRange = 525},
	skillW = {name = "Zap!", range = 1450, speed = 3300, delay = 0.5, width = 60},
	skillE = {name = "Flame chompers!", range = 900, speed = .885, delay = 0.25, width = 325},
	skillR = {name = "Super mega death rocket!", range = 2000, speed = 1200, delay = 0.5, width = 120, radius = 450}
}

function OnLoad()

	if not VIP_USER then
		wPrediction = TargetPrediction(skillsTable.skillW.range, skillsTable.skillW.speed, skillsTable.skillW.delay, skillsTable.skillW.width)
		ePrediction = TargetPrediction(skillsTable.skillE.range, skillsTable.skillE.speed, skillsTable.skillE.delay)
		rPrediction = TargetPrediction(skillsTable.skillR.range, skillsTable.skillR.speed, skillsTable.skillR.delay, skillsTable.skillR.width)
	end

	ts = TargetSelector(TARGET_LOW_HP_PRIORITY, skillsTable.skillR.range, DAMAGE_PHYSICAL, false)
	if VIP_USER then prediction = VPrediction() end
	ts.name = "AesJinx"
	
	menu()
	config:addTS(ts)
	
	print("AesJinx version: "..version.." loaded!")
end

function OnTick()
	ts:update()
	getQRange()
	getGun()

	target = ts.target
	
	if config.basicSubMenu.combo then combo() end
	if config.basicSubMenu.combo and config.aggressiveSubMenu.comboSubMenu.comboQ then rocketLauncher() end
	if config.miscSubMenu.autoQ or config.miscSubMenu.outofrangeQ then rocketLauncher() end
	if config.basicSubMenu.harass then harass() end
	if config.aggressiveSubMenu.finisherSubMenu.finishW or config.aggressiveSubMenu.finisherSubMenu.finishR then finisher() end
	if config.defensiveSubMenu.chompersSubMenu.stunChompers then chompers() end
end

function OnDraw()
	if config.drawSubMenu.drawW then DrawCircle3D(myHero.x, myHero.y, myHero.z, skillsTable.skillW.range, 1, RGB(255, 255, 255)) end
	if config.drawSubMenu.drawE then DrawCircle3D(myHero.x, myHero.y, myHero.z, skillsTable.skillE.range, 1, RGB(255, 255, 255)) end
	if config.drawSubMenu.drawR then DrawCircle3D(myHero.x, myHero.y, myHero.z, skillsTable.skillR.range, 1, RGB(255, 255, 255)) end
	if config.drawSubMenu.drawKillable and myHero:CanUseSpell(_R) == READY then
		for i, enemy in pairs(GetEnemyHeroes()) do
			local rDamage = getDmg("R", enemy, myHero)
			
			if ValidTarget(enemy, skillsTable.skillR.range, true) and rDamage > enemy.health then
				DrawText3D("Killable target with ultimate", enemy.x, enemy.y, enemy.z, 15, RGB(255, 0, 0), 0)
				DrawCircle3D(enemy.x, enemy.y, enemy.z, 150, 1, RGB(255, 0, 0))
				DrawCircle3D(enemy.x, enemy.y, enemy.z, 200, 1, RGB(255, 0, 0))
				DrawCircle3D(enemy.x, enemy.y, enemy.z, 250, 1, RGB(255, 0, 0))
			end
		end
	end
end

function combo()
	if ValidTarget(target, skillsTable.skillR.range, true) then
		if config.aggressiveSubMenu.comboSubMenu.comboW then
			castW(target)
		end

		if config.aggressiveSubMenu.comboSubMenu.comboE then
			castE(target)
		end

		if config.aggressiveSubMenu.comboSubMenu.comboR then
			castR(target)
		end
		
		-[[
		if config.aggressiveSubMenu.comboSubMenu.aoeR then
			aoeR(target)
		end
		]]-
	end
end

function harass()
	if target ~= nil and checkManaHarass() then
		if config.aggressiveSubMenu.harassSubMenu.harassW then
			castW(target)
		end
	end
end

function finisher()
	if config.aggressiveSubMenu.finisherSubMenu.finishW and myHero:CanUseSpell(_W) == READY then
		for i, enemy in pairs(GetEnemyHeroes()) do
			local wDamage = getDmg("W", enemy, myHero)

			if ValidTarget(enemy, skillsTable.skillR.range, true) and wDamage > enemy.health then
				castW(enemy)
			end
		end
	end

	if config.aggressiveSubMenu.finisherSubMenu.finishR and myHero:CanUseSpell(_R) == READY then
		for i, enemy in pairs(GetEnemyHeroes()) do
			local rDamage = getDmg("R", enemy, myHero)

			if ValidTarget(enemy, skillsTable.skillR.range, true) and rDamage > enemy.health then
				castR(enemy)
			end
		end
	end
end

function castW(Target)
	if VIP_USER then
		local wPosition, wChance = prediction:GetLineCastPosition(Target, skillsTable.skillW.delay, skillsTable.skillW.width, skillsTable.skillW.range, skillsTable.skillW.speed, myHero, true)
		
		if wPosition ~= nil and GetDistance(wPosition) < skillsTable.skillW.range and myHero:CanUseSpell(_W) == READY and wChance >= 2 then
			CastSpell(_W, wPosition.x, wPosition.z)
		end
	else
		local wPosition = wPrediction:GetPrediction(Target)
		
		if wPosition ~= nil and GetDistance(wPosition) < skillsTable.skillW.range and myHero:CanUseSpell(_W) == READY and not GetMinionCollision(myHero, wPosition, skillsTable.skillW.width) then
			CastSpell(_W, wPosition.x, wPosition.z)
		end
	end
end

function castE(Target)
	if VIP_USER then
		local ePosition, eChance = prediction:GetLineCastPosition(Target, skillsTable.skillE.delay, skillsTable.skillE.width, skillsTable.skillE.range, skillsTable.skillE.speed, myHero, true)
		
		if ePosition ~= nil and GetDistance(ePosition) < skillsTable.skillE.range and myHero:CanUseSpell(_E) == READY and eChance >= 3 then
			CastSpell(_E, ePosition.x, ePosition.z)
		end
	else
		local ePosition = ePrediction:GetPrediction(target)
		
		if ePosition ~= nil and GetDistance(ePosition) < skillsTable.skillE.range and myHero:CanUseSpell(_E) == READY then
			CastSpell(_E, ePosition.x, ePosition.z)
		end
	end
end

function castR(Target)
	if VIP_USER then
		local rPosition, rChance = prediction:GetLineCastPosition(Target, skillsTable.skillR.delay, skillsTable.skillR.width, skillsTable.skillR.range, skillsTable.skillR.speed, myHero, false)
		
		if rPosition ~= nil and GetDistance(rPosition) < skillsTable.skillR.range and myHero:CanUseSpell(_R) == READY and rChance >= 2 then
			CastSpell(_R, rPosition.x, rPosition.z)
		end
	else
		local rPosition = wPrediction:GetPrediction(Target)
		
		if rPosition ~= nil and GetDistance(rPosition) < skillsTable.skillR.range and myHero:CanUseSpell(_R) == READY then
			CastSpell(_R, rPosition.x, rPosition.z)
		end
	end
end

function aoeR(Target)
	if VIP_USER then
		local aoeRPosition, aoeRChance, aoeRTargets = VPrediction:GetLineAOECastPosition(Target, skillsTable.skillR.delay, skillsTable.skillR.radius, skillsTable.skillR.range, skillsTable.skillR.speed, myHero)
	
		if aoeRPosition ~= nil and GetDistance(aoeRPosition) < skillsTable.skillR.range and myHero:CanUseSpell(_R) == READY and aoeRChance >= 2 and aoeRTargets > 2 then
			CastSpell(_R, rPosition.x, rPosition.z)
		end
	else
		local aoeRPosition = GetAoESpellPosition(skillsTable.skillR.radius, target, skillsTable.skillR.delay)
		
		if aoeRPosition ~= nil and GetDistance(aoeRPosition) < skillsTable.skillR.range and myHero:CanUseSpell(_R) == READY then
			CastSpell(_R, rPosition.x, rPosition.z)
		end
	end
end

function chompers()
	if config.defensiveSubMenu.chompersSubMenu.stunChompers and myHero:CanUseSpell(_E) == READY then
		for i, enemy in pairs(GetEnemyHeroes()) do				
			if GetDistance(enemy) < skillsTable.skillE.range and not enemy.canMove then
				CastSpell(_E, enemy.x, enemy.z)
			end
		end
	end
end

function rocketLauncher()
	if ValidTarget(target) and checkManaRocket() then
		if myHero:CanUseSpell(_Q) and GetDistance(target) <= skillsTable.skillQ.minigunRange and rocket == true then
			CastSpell(_Q)
		elseif myHero:CanUseSpell(_Q) and GetDistance(target) >= skillsTable.skillQ.minigunRange and GetDistance(target) <= skillsTable.skillQ.fishRange and rocket == false then
			CastSpell(_Q)
		elseif myHero:CanUseSpell(_Q) and GetDistance(target) > skillsTable.skillQ.fishRange + 300 and rocket == true then
			CastSpell(_Q)
		end
	end

	if target == nil and rocket == true then
		CastSpell(_Q)
	end
	
	if checkManaRocket() == false and rocket == true then
		CastSpell(_Q)
	end
end

function checkManaHarass()
	if myHero.mana >= myHero.maxMana * (config.managementSubMenu.manaHarass / 100) then
		return true
	else
		return false
	end
end

function checkManaRocket()
	if myHero.mana >= myHero.maxMana * (config.managementSubMenu.manaRocket / 100) then
		return true
	else
		return false
	end 
end

function getGun()
	if myHero.range == 525.5 then
		rocket = false
	elseif myHero.range > 525.5 then
		rocket = true
	end
end

function getQRange()
	if myHero:GetSpellData(_Q).level == 1 then
		skillsTable.skillQ.fishRange = 525 + 75 + 65
	elseif myHero:GetSpellData(_Q).level == 2 then
		skillsTable.skillQ.fishRange = 525 + 100 + 65
	elseif myHero:GetSpellData(_Q).level == 3 then
		skillsTable.skillQ.fishRange = 525 + 125 + 65
	elseif myHero:GetSpellData(_Q).level == 4 then
		skillsTable.skillQ.fishRange = 525 + 150 + 65
	elseif myHero:GetSpellData(_Q).level == 5 then
		skillsTable.skillQ.fishRange = 525 + 175 + 65
	else
		skillsTable.skillQ.fishRange = 525 + 65
	end
end

function menu()
	config = scriptConfig("AesJinx: Main menu", "aesjinx")
	-- Basic submenu
	config:addSubMenu("AesJinx: Basic settings", "basicSubMenu")
	config.basicSubMenu:addParam("combo", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	config.basicSubMenu:addParam("harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, 65)
	config.basicSubMenu:addParam("version", "Version:", SCRIPT_PARAM_INFO, version)
	-- Aggressive submenu
	config:addSubMenu("AesJinx: Aggressive settings", "aggressiveSubMenu")
	config.aggressiveSubMenu:addSubMenu("Combo settings", "comboSubMenu")
	config.aggressiveSubMenu.comboSubMenu:addParam("comboQ", "Use "..skillsTable.skillQ.name, SCRIPT_PARAM_ONOFF, false)
	config.aggressiveSubMenu.comboSubMenu:addParam("comboW", "Use "..skillsTable.skillW.name, SCRIPT_PARAM_ONOFF, false)
	config.aggressiveSubMenu.comboSubMenu:addParam("comboE", "Use "..skillsTable.skillE.name, SCRIPT_PARAM_ONOFF, false)
	config.aggressiveSubMenu.comboSubMenu:addParam("comboR", "Use "..skillsTable.skillR.name, SCRIPT_PARAM_ONOFF, false)
	--config.aggressiveSubMenu.comboSubMenu:addParam("aoeR", "Use "..skillsTable.skillR.name.." as aoe", SCRIPT_PARAM_ONKEYDOWN, false, GetKey("Z"))

	config.aggressiveSubMenu:addSubMenu("Harass settings", "harassSubMenu")
	config.aggressiveSubMenu.harassSubMenu:addParam("harassW" ,"Use "..skillsTable.skillW.name, SCRIPT_PARAM_ONOFF, false)

	config.aggressiveSubMenu:addSubMenu("Finisher settings", "finisherSubMenu")
	config.aggressiveSubMenu.finisherSubMenu:addParam("finishW", "Use "..skillsTable.skillW.name, SCRIPT_PARAM_ONOFF, false)
	config.aggressiveSubMenu.finisherSubMenu:addParam("finishR", "Use "..skillsTable.skillR.name, SCRIPT_PARAM_ONOFF, false)

	-- Defensive submenu
	config:addSubMenu("AesJinx: Defensive settings", "defensiveSubMenu")
	config.defensiveSubMenu:addSubMenu("Chompers settings", "chompersSubMenu")
	config.defensiveSubMenu.chompersSubMenu:addParam("stunChompers", "Use "..skillsTable.skillE.name.." under stunned target",SCRIPT_PARAM_ONOFF, false)

	-- Misc submenu
	config:addSubMenu("AesJinx: Misc settings", "miscSubMenu")
	config.miscSubMenu:addParam("autoQ", "Automatically use "..skillsTable.skillQ.name, SCRIPT_PARAM_ONOFF, false)
	config.miscSubMenu:addParam("outofrangeQ", "Change to minigun, when there is no target", SCRIPT_PARAM_ONOFF, false)

	-- Management submenu
	config:addSubMenu("AesJinx: Management settings", "managementSubMenu")
	config.managementSubMenu:addParam("manaHarass", "Minimum mana to harass", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
	config.managementSubMenu:addParam("manaRocket", "Minimum mana to change gun", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
	-- Drawing submenu
	config:addSubMenu("AesJinx: Drawing settings", "drawSubMenu")
	config.drawSubMenu:addParam("drawW", "Draw "..skillsTable.skillW.name, SCRIPT_PARAM_ONOFF, false)
	config.drawSubMenu:addParam("drawE", "Draw "..skillsTable.skillE.name, SCRIPT_PARAM_ONOFF, false)
	config.drawSubMenu:addParam("drawR", "Draw "..skillsTable.skillR.name, SCRIPT_PARAM_ONOFF, false)
	config.drawSubMenu:addParam("drawKillable", "Draw killable target", SCRIPT_PARAM_ONOFF, false)
end
