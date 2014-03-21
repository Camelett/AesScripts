if myHero.charName ~= "Jinx" then return end

if VIP_USER then
	require "VPrediction"
else
	require "AoE_Skillshot_Position"
end

local version = 1.0
local target = nil
local prediction = nil

local skills = {
	skillQ = {name = "Switcheroo!", range = 525.5},
	skillW = {name = "Zap!", range = 1500, speed = 3300, delay = .625, width = 60},
	skillE = {name = "Flame chompers!", range = 900, speed = 1750, delay = .375, radius = 315},
	skillR = {name = "Super mega death rocket!", range = 2000, speed = 1200, delay = .250, width = 120, radius = 210}
}

function OnLoad()
	menu()
	
	if not VIP_USER then
		wPrediction = TargetPrediction(skills.skillW.range, skills.skillW.speed / 1000, skills.skillW.delay * 1000, skills.skillW.width)
		ePrediction = TargetPrediction(skills.skillE.range, skills.skillE.speed / 1000, skills.skillE.delay * 1000, skills.skillE.radius)
		rPrediction = TargetPrediction(skills.skillR.range, skills.skillR.speed / 1000, skills.skillR.delay * 1000, skills.skillR.width)
	end
	
	targetSelector = TargetSelector(TARGET_LESS_CAST_PRIORITY, skills.skillR.range, DAMAGE_PHYSICAL, false)
	if VIP_USER then prediction = VPrediction() end
	targetSelector.name = "AesJinx"
	config:addTS(targetSelector)
	print("AesJinx "..version.." loaded!")
end

function OnTick()
	targetSelector:update()
	target = targetSelector.target
	
	if config.basicSubMenu.combo then combo() end
	if config.basicSubMenu.harass then harass() end
	if config.aggressiveSubMenu.finisherSubMenu.finisherW or finisherR then finisher() end
	if config.otherSubMenu.chomperSubMenu.stunE then castStunE() end
end

function OnDraw()
	if config.otherSubMenu.drawSubMenu.drawW then DrawCircle3D(myHero.x, myHero.y, myHero.z, skills.skillW.range, 1, RGB(255, 255, 255)) end
	if config.otherSubMenu.drawSubMenu.drawE then DrawCircle3D(myHero.x, myHero.y, myHero.z, skills.skillE.range, 1, RGB(255, 255, 255)) end
	if config.otherSubMenu.drawSubMenu.drawR then DrawCircle3D(myHero.x, myHero.y, myHero.z, skills.skillR.range, 1, RGB(255, 255, 255)) end
end

function combo()
	if ValidTarget(target, skills.skillR.range, true) then
		if config.aggressiveSubMenu.comboSubMenu.comboQ and config.otherSubMenu.manaSubMenu.manaRocket <= (myHero.mana / myHero.maxMana * 100) then
			switcheroo(target)
		end
		
		if config.aggressiveSubMenu.comboSubMenu.comboW then
			castW(target)
		end
		
		if config.aggressiveSubMenu.comboSubMenu.comboE then
			castE(target)
		end
		
		if config.aggressiveSubMenu.comboSubMenu.comboR then
			castR(target)
		end
		
		if config.aggressiveSubMenu.comboSubMenu.aoeR then
			aoeR(target)
		end
	end
end

function harass()
	if ValidTarget(target, skills.skillW.range, true) and config.otherSubMenu.manaSubMenu.manaHarass <= (myHero.mana / myHero.maxMana * 100) then
		if config.aggressiveSubMenu.harassSubMenu.harassQ then
			switcheroo(target)
		end
		
		if config.aggressiveSubMenu.harassSubMenu.harassW then
			castW(target)
		end
	end
end

function finisher()
	for i = 1, heroManager.iCount do
		local enemy = heroManager:getHero(i)
		
		if ValidTarget(enemy, skills.skillR.range, true) then
			if config.aggressiveSubMenu.finisherSubMenu.finisherW then
				local wDamage = getDmg("W", enemy, myHero)
				
				if wDamage > enemy.health then
					castW(enemy)
				end
			end
		
			if config.aggressiveSubMenu.finisherSubMenu.finisherR then
				local rDamage = getDmg("R", enemy, myHero)
				
				if rDamage > enemy.health then
					castR(enemy)
				end
			end
		end
	end
end

function castW(Target)
	if VIP_USER then
		local wPosition, wChance = prediction:GetLineCastPosition(Target, skills.skillW.delay, skills.skillW.width, skills.skillW.range, skills.skillW.speed, myHero, true)
		
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

function castE(Target)
	if VIP_USER then
		local ePosition, eChance = prediction:GetCircularCastPosition(Target, skills.skillE.delay, skills.skillE.radius, skills.skillE.range, skills.skillE.speed, myHero, false)
		
		if ePosition ~= nil and GetDistance(ePosition) < skills.skillE.range and myHero:CanUseSpell(_E) == READY and eChance >= 2 then
			CastSpell(_E, ePosition.x, ePosition.z)
		end
	else
		local ePosition = ePrediction:GetPrediction(Target)
		
		if ePosition ~= nil and GetDistance(ePosition) < skills.skillE.range and myHero:CanUseSpell(_E) == READY then
			CastSpell(_E, ePosition.x, ePosition.z)
		end
	end
end

function castStunE(Target)
	if ValidTarget(Target, skills.skillE.range, true) then
		if VIP_USER then
			local ePosition, eChance = prediction:GetCircularCastPosition(Target, skills.skillE.delay, skills.skillE.radius, skills.skillE.range, skills.skillE.speed, myHero, false)
			
			if ePosition ~= nil and GetDistance(ePosition) < skills.skillE.range and myHero:CanUseSpell(_E) == READY and eChance >= 3 then
				CastSpell(_E, ePosition.x, ePosition.z)
			end
		else
			local ePosition = ePrediction:GetPrediction(Target)
			
			if ePosition ~= nil and GetDistance(ePosition) < skills.skillE.range and myHero:CanUseSpell(_E) == READY and not Target.canMove then
				CastSpell(_E, ePosition.x, ePosition.z)
			end
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

function aoeR(Target)
	if VIP_USER then
		local aoeRPosition, aoeRChance, aoeTargets = prediction:GetLineAOECastPosition(Target, skills.skillR.delay, skills.skillR.radius, skills.skillR.range, skills.skillR.speed, myHero)
		
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

function switcheroo(Target)
	if myHero:CanUseSpell(_Q) == READY and GetDistance(Target) < skills.skillQ.range and isRocket() then
		CastSpell(_Q)
	elseif myHero:CanUseSpell(_Q) == READY and GetDistance(Target) > skills.skillQ.range and isRocket() and GetDistance(Target) < getRocketRange() then
		CastSpell(_Q)
	elseif myHero:CanUseSpell(_Q) == READY and GetDistance(Target) > skills.skillQ.range and not isRocket() then
		CastSpell(_Q)
	end
end

function getRocketRange()
	local ranges = {75, 100, 125, 150, 175}
	
	if myHero:GetSpellData(_Q).level > 0 and isRocket() then
		return myHero.range + ranges[myHero:GetSpellData(_Q).level]
	end
end

function isRocket()
	return myHero.range > 525.5
end

function menu()
	config = scriptConfig("AesJinx: Main menu", "aesjinx")
	
	config:addSubMenu("Basic settings", "basicSubMenu")
	config.basicSubMenu:addParam("combo", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, GetKey(" "))
	config.basicSubMenu:addParam("harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, GetKey("A"))
	config.basicSubMenu:addParam("scriptVersion", "AesJinx version:", SCRIPT_PARAM_INFO, version)
	
	config:addSubMenu("Aggressive settings", "aggressiveSubMenu")
	config.aggressiveSubMenu:addSubMenu("Combo settings", "comboSubMenu")
	config.aggressiveSubMenu.comboSubMenu:addParam("comboQ", "Use "..skills.skillQ.name, SCRIPT_PARAM_ONOFF, false)
	config.aggressiveSubMenu.comboSubMenu:addParam("comboW", "Use "..skills.skillW.name, SCRIPT_PARAM_ONOFF, false)
	config.aggressiveSubMenu.comboSubMenu:addParam("comboE", "Use "..skills.skillE.name, SCRIPT_PARAM_ONOFF, false)
	config.aggressiveSubMenu.comboSubMenu:addParam("comboR", "Use "..skills.skillR.name, SCRIPT_PARAM_ONOFF, false)
	config.aggressiveSubMenu.comboSubMenu:addParam("aoeR", "AOE "..skills.skillR.name, SCRIPT_PARAM_ONKEYDOWN, false, GetKey("Z"))
	config.aggressiveSubMenu:addSubMenu("Harass settings", "harassSubMenu")
	config.aggressiveSubMenu.harassSubMenu:addParam("harassQ", "Use "..skills.skillQ.name, SCRIPT_PARAM_ONOFF, false)
	config.aggressiveSubMenu.harassSubMenu:addParam("harassW", "Use "..skills.skillW.name, SCRIPT_PARAM_ONOFF, false)
	config.aggressiveSubMenu:addSubMenu("Finsiher settings", "finisherSubMenu")
	config.aggressiveSubMenu.finisherSubMenu:addParam("finisherW", "Use "..skills.skillW.name, SCRIPT_PARAM_ONOFF, false)
	config.aggressiveSubMenu.finisherSubMenu:addParam("finisherR", "Use "..skills.skillR.name, SCRIPT_PARAM_ONOFF, false)
	
	config:addSubMenu("Other settings", "otherSubMenu")
	config.otherSubMenu:addSubMenu("Drawing settings", "drawSubMenu")
	config.otherSubMenu.drawSubMenu:addParam("drawW", "Draw "..skills.skillW.name, SCRIPT_PARAM_ONOFF, false)
	config.otherSubMenu.drawSubMenu:addParam("drawE", "Draw "..skills.skillE.name, SCRIPT_PARAM_ONOFF, false)
	config.otherSubMenu.drawSubMenu:addParam("drawR", "Draw "..skills.skillR.name, SCRIPT_PARAM_ONOFF, false)
	config.otherSubMenu:addSubMenu("Mana settings", "manaSubMenu")
	config.otherSubMenu.manaSubMenu:addParam("manaHarass", "Mana to harass", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
	config.otherSubMenu.manaSubMenu:addParam("manaRocket", "Mana for "..skills.skillQ.name, SCRIPT_PARAM_SLICE, 30, 0, 100, 0)
	config.otherSubMenu:addSubMenu("Chompers settings", "chomperSubMenu")
	config.otherSubMenu.chomperSubMenu:addParam("stunE", "Use "..skills.skillE.name.." on stunned", SCRIPT_PARAM_ONOFF, false)
end
