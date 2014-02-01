if myHero.charName ~= "Jinx" then return end

--Requires
if VIP_USER then
	require "Prodiction"
	require "Collision"
end
require "AoE_Skillshot_Position"

--Variables
local target = nil
local version = 0.1
if VIP_USER then prodiction = ProdictManager.GetInstance() end

--Skill table
local skillsTable = {
	skillQ = {name = "Switcheroo!"},
	skillW = {name = "Zap!", range = 1500, speed = 3.35 , delay = 600, width = 100},
	skillE = {name = "Flame Chompers!", range = 900, speed = .885, delay = 500},
	skillR = {name = "Super Mega Death Rocket!", range = math.huge, speed = 2.0, delay = 600, radius = 200}
}

--Prediction
if VIP_USER then
	predictionW = prodiction:AddProdictionObject(_W, skillsTable.skillW.range, skillsTable.skillW.speed * 1000, skillsTable.skillW.delay / 1000)
	predictionE = prodiction:AddProdictionObject(_E, skillsTable.skillE.range, skillsTable.skillE.speed * 1000, skillsTable.skillE.delay / 1000, skillsTable.skillW.width)
	predictionR = prodiction:AddProdictionObject(_R, skillsTable.skillR.range, skillsTable.skillR.speed * 1000, skillsTable.skillR.delay / 1000)
else
	predictionW = TargetPrediction(skillsTable.skillW.range, skillsTable.skillW.speed, skillsTable.skillW.delay, skillsTable.skillW.width)
	predictionE = TargetPrediction(skillsTable.skillE.range, skillsTable.skillE.speed, skillsTable.skillE.delay)
	predictionR = TargetPrediction(skillsTable.skillR.range, skillsTable.skillR.speed, skillsTable.skillR.delay)
end

--Collision
if VIP_USER then
	wCollision = Collision(skillsTable.skillW.range, skillsTable.skillW.speed, skillsTable.skillW.delay, skillsTable.skillW.width)
end

function OnLoad()
	targetSelector = TargetSelector(TARGET_LESS_CAST_PRIORITY, skillsTable.skillR.range, DAMAGE_PHYSICAL, false)

	menu()
	print("AesJinx version: "..version.." loaded!")
end

function OnTick()
	targetSelector:update()

	if targetSelector.target ~= nil then
		target = targetSelector.target
	end

	if config.basicSubMenu.combo then combo() end
	if config.basicSubMenu.harass then harass() end
	if config.aggressiveSubMenu.finisherSubMenu.finishW or config.aggressiveSubMenu.finisherSubMenu.finishR then finisher() end
	if config.defensiveSubMenu.chompersSubMenu.stunChompers then chompers() end
end

function OnDraw()
	if config.drawSubMenu.drawW then DrawCircle(myHero.x, myHero.y, myHero.z, skillsTable.skillW.range, ARGB(255, 255, 0, 0)) end
	if config.drawSubMenu.drawE then DrawCircle(myHero.x, myHero.y, myHero.z, skillsTable.skillE.range, ARGB(255, 255, 0, 0)) end
	if config.drawSubMenu.drawR then DrawCircle(myHero.x, myHero.y, myHero.z, skillsTable.skillR.range, ARGB(255, 255, 0, 0)) end
end

function combo()
	if target ~= nil then
		if config.aggressiveSubMenu.comboSubMenu.comboW then
			local wPosition = predictionW:GetPrediction(target)
			
			if wPosition ~= nil and myHero:CanUseSpell(_W) and GetDistance(target) < skillsTable.skillW.range then
				if VIP_USER then
					if not wCollision:GetMinionCollision(myHero, wPosition) then
						CastSpell(_W, wPosition.x, wPosition.z)
					end
				else
					if not GetMinionCollision(myHero, target, skillsTable.skillW.width) then
						CastSpell(_W, wPosition.x, wPosition.z)
					end
				end
			end
		end

		if config.aggressiveSubMenu.comboSubMenu.comboE then
			local ePosition = predictionE:GetPrediction(target)

			if ePosition ~= nil and myHero:CanUseSpell(_E) and GetDistance(target) < skillsTable.skillE.range then
				CastSpell(_E, ePosition.x, ePosition.z)
			end
		end

		if config.aggressiveSubMenu.comboSubMenu.comboR then
			local aoeRPosition = GetAoESpellPosition(skillsTable.skillR.radius, target, skillsTable.skillR.delay)

			if aoeRPosition ~= nil and myHero:CanUseSpell(_R) and GetDistance(target) < skillsTable.skillR.range then
				CastSpell(_R, aoeRPosition.x, aoeRPosition.z)
			end
		end
	end
end

function harass()
	if target ~= nil then
		if config.aggressiveSubMenu.harassSubMenu.harassW then
			local wPosition = predictionW:GetPrediction(target)
			
			if wPosition ~= nil and myHero:CanUseSpell(_W) and GetDistance(target) < skillsTable.skillW.range and checkManaHarass() then
				if VIP_USER then
					if not wCollision:GetMinionCollision(myHero, wPosition) then
						CastSpell(_W, wPosition.x, wPosition.z)
					end
				else
					if not GetMinionCollision(myHero, target, skillsTable.skillW.width) then
						CastSpell(_W, wPosition.x, wPosition.z)
					end
				end
			end
		end
	end
end

function finisher()
	if config.aggressiveSubMenu.finisherSubMenu.finishW then
		for i, enemy in pairs(GetEnemyHeroes()) do
			local wPosition = predictionW:GetPrediction(enemy)
			local wDamage = getDmg("W", enemy, myHero)

			if wPosition ~= nil and myHero:CanUseSpell(_W) and GetDistance(enemy) < skillsTable.skillW.range and wDamage > enemy.health then
				if VIP_USER then
					if not wCollision:GetMinionCollision(myHero, wPosition) then
						CastSpell(_W, wPosition.x, wPosition.z)
					end
				else
					if not GetMinionCollision(myHero, enemy, skillsTable.skillW.width) then
						CastSpell(_W, wPosition.x, wPosition.z)
					end
				end
			end
		end
	end

	if config.aggressiveSubMenu.finisherSubMenu.finishR then
		for i, enemy in pairs(GetEnemyHeroes()) do
			local rPosition = predictionR:GetPrediction(enemy)
			local rDamage = getDmg("R", enemy, myHero)

			if rPosition ~= nil and myHero:CanUseSpell(_R) and GetDistance(enemy) < skillsTable.skillR.range and rDamage > enemy.health then
				CastSpell(_R, rPosition.x, rPosition.z)
			end
		end
	end
end

function chompers()
	if config.defensiveSubMenu.chompersSubMenu.stunChompers then
		for i, enemy in pairs(GetEnemyHeroes()) do
			local ePosition = predictionE:GetPrediction(enemy)
			
			if ePosition ~= nil and myHero:CanUseSpell(_E) == READY and GetDistance(enemy) < skillsTable.skillE.range and not enemy.canMove then
				CastSpell(_E, enemy.x, enemy.z)
			end
		end
	end
end

function checkManaHarass()
	if myHero.mana >= myHero.maxMana * (config.managementSubMenu.manaHarass / 100) then
		return true
	else
		return false
	end
end

function menu()
	config = scriptConfig("AesJinx", "aesjinx")
	-- Basic submenu
	config:addSubMenu("AesJinx: Basic settings", "basicSubMenu")
	config.basicSubMenu:addParam("combo", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	config.basicSubMenu:addParam("harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, 65)
	config.basicSubMenu:addParam("version", "Version:", SCRIPT_PARAM_INFO, version)
	-- Aggressive submenu
	config:addSubMenu("AesJinx: Aggressive settings", "aggressiveSubMenu")
	config.aggressiveSubMenu:addSubMenu("Combo settings", "comboSubMenu")
	config.aggressiveSubMenu.comboSubMenu:addParam("comboW", "Use "..skillsTable.skillW.name, SCRIPT_PARAM_ONOFF, false)
	config.aggressiveSubMenu.comboSubMenu:addParam("comboE", "Use "..skillsTable.skillE.name, SCRIPT_PARAM_ONOFF, false)
	config.aggressiveSubMenu.comboSubMenu:addParam("comboR", "Use "..skillsTable.skillR.name, SCRIPT_PARAM_ONOFF, false)

	config.aggressiveSubMenu:addSubMenu("Harass settings", "harassSubMenu")
	config.aggressiveSubMenu.harassSubMenu:addParam("harassW" ,"Use "..skillsTable.skillW.name, SCRIPT_PARAM_ONOFF, false)

	config.aggressiveSubMenu:addSubMenu("Finisher settings", "finisherSubMenu")
	config.aggressiveSubMenu.finisherSubMenu:addParam("finishW", "Use "..skillsTable.skillW.name, SCRIPT_PARAM_ONOFF, false)
	config.aggressiveSubMenu.finisherSubMenu:addParam("finishR", "Use "..skillsTable.skillR.name, SCRIPT_PARAM_ONOFF, false)

	-- Defensive submenu
	config:addSubMenu("AesJinx: Defensive settings", "defensiveSubMenu")
	config.defensiveSubMenu:addSubMenu("Chompers settings", "chompersSubMenu")
	config.defensiveSubMenu.chompersSubMenu:addParam("stunChompers", "Use "..skillsTable.skillE.name.." under stunned target",SCRIPT_PARAM_ONOFF, false)

	-- Management submenu
	config:addSubMenu("AesJinx: Management settings", "managementSubMenu")
	config.managementSubMenu:addParam("manaHarass", "Minimum mana to harass", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
	-- Drawing submenu
	config:addSubMenu("AesJinx: Drawing settings", "drawSubMenu")
	config.drawSubMenu:addParam("drawW", "Draw "..skillsTable.skillW.name, SCRIPT_PARAM_ONOFF, false)
	config.drawSubMenu:addParam("drawE", "Draw "..skillsTable.skillE.name, SCRIPT_PARAM_ONOFF, false)
	config.drawSubMenu:addParam("drawR", "Draw "..skillsTable.skillR.name, SCRIPT_PARAM_ONOFF, false)
end
