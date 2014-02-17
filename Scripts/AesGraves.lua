if myHero.charName ~= "Graves" then return end

if VIP_USER then require "Prodiction" end
require "AoE_Skillshot_Position"

local target = nil
local version = 0.2

local skillsTable = {
	skillQ = {name = "Buckshot", range = 900, speed = .902, delay = 250},
	skillW = {name = "Smoke Screen", range = 950, speed = 1.650, delay = 250},
	skillE = {name = "Quickdraw"},
	skillR = {name = "Collateral Damage", range = 1000, speed = 1.4, delay = 250, radius = 210}
}

function OnLoad()
	if VIP_USER then
		prodiction = ProdictManager.GetInstance()
		predictionQ = prodiction:AddProdictionObject(_Q, skillsTable.skillQ.range, skillsTable.skillQ.speed * 1000, skillsTable.skillQ.delay / 1000)
		predictionW = prodiction:AddProdictionObject(_W, skillsTable.skillW.range, skillsTable.skillW.speed * 1000, skillsTable.skillW.delay / 1000)
		predictionR = prodiction:AddProdictionObject(_R, skillsTable.skillR.range, skillsTable.skillR.speed * 1000, skillsTable.skillR.delay / 1000)
	else
		predictionQ = TargetPrediction(skillsTable.skillQ.range, skillsTable.skillQ.speed, skillsTable.skillQ.delay)
		predictionW = TargetPrediction(skillsTable.skillW.range, skillsTable.skillW.speed, skillsTable.skillW.delay)
		predictionR = TargetPrediction(skillsTable.skillR.range, skillsTable.skillR.speed, skillsTable.skillR.delay)
	end

	targetSelector = TargetSelector(TARGET_LOW_HP_PRIORITY, skillsTable.skillR.range, DAMAGE_PHYSICAL, false)
	menu()
	print("AesGraves version: "..version.." loaded!")
end

function OnTick()
	targetSelector:update()
	target = targetSelector.target
	
	if config.basicSubMenu.combo then combo() end
	if config.basicSubMenu.harass then harass() end
	if config.aggressiveSubMenu.finisherSubMenu.finisherQ or config.aggressiveSubMenu.finisherSubMenu.finisherW or config.aggressiveSubMenu.finisherSubMenu.finisherR then finisher() end
end

function OnDraw()
	if config.otherSubMenu.drawingSubMenu.drawQ then DrawCircle(myHero.x, myHero.y, myHero.z, skillsTable.skillQ.range, 0xFFFFFF) end
	if config.otherSubMenu.drawingSubMenu.drawW then DrawCircle(myHero.x, myHero.y, myHero.z, skillsTable.skillW.range, 0xFFFFFF) end
	if config.otherSubMenu.drawingSubMenu.drawR then DrawCircle(myHero.x, myHero.y, myHero.z, skillsTable.skillR.range, 0xFFFFFF) end
end

function combo()
	if target ~= nil then
		if config.aggressiveSubMenu.comboSubMenu.comboQ then
			local qPosition = predictionQ:GetPrediction(target)

			if qPosition ~= nil and myHero:CanUseSpell(_Q) == READY and GetDistance(qPosition) < skillsTable.skillQ.range then
				if _G.MMA_Loaded then
					if _G.MMA_NextAttackAvailability >= 0.5 and _G.MMA_NextAttackAvailability <= 0.8 then
						CastSpell(_Q, qPosition.x, qPosition.z)
					end
				else
					CastSpell(_Q, qPosition.x, qPosition.z)
				end
			end
		end

		if config.aggressiveSubMenu.comboSubMenu.comboW then
			local wPosition = predictionW:GetPrediction(target)

			if wPosition ~= nil and myHero:CanUseSpell(_W) == READY and GetDistance(wPosition) < skillsTable.skillW.range then
				CastSpell(_W, wPosition.x, wPosition.z)
			end
		end

		if config.aggressiveSubMenu.comboSubMenu.comboR then
			local aoeRPosition = GetAoESpellPosition(skillsTable.skillR.radius, target, skillsTable.skillR.delay)

			if aoeRPosition ~= nil and myHero:CanUseSpell(_R) == READY and GetDistance(aoeRPosition) < skillsTable.skillR.range then
				CastSpell(_R, aoeRPosition.x, aoeRPosition.z)
			end
		end
	end
end

function harass()
	if target ~= nil then
		if config.aggressiveSubMenu.harassSubMenu.harassQ then
			local qPosition = predictionQ:GetPrediction(target)

			if qPosition ~= nil and myHero:CanUseSpell(_Q) == READY and GetDistance(qPosition) < skillsTable.skillQ.range then
				CastSpell(_Q, qPosition.x, qPosition.z)
			end
		end

		if config.aggressiveSubMenu.harassSubMenu.harassW then
			local wPosition = predictionW:GetPrediction(target)

			if wPosition ~= nil and myHero:CanUseSpell(_W) == READY and GetDistance(wPosition) < skillsTable.skillW.range then
				CastSpell(_W, wPosition.x, wPosition.z)
			end
		end
	end
end

function finisher()
	if config.aggressiveSubMenu.finisherSubMenu.finisherQ then
		for i, enemy in pairs(GetEnemyHeroes()) do
			local qPosition = predictionQ:GetPrediction(enemy)
			local qDamage = getDmg("Q", enemy, myHero)

			if qPosition ~= nil and myHero:CanUseSpell(_Q) == READY and GetDistance(qPosition) < skillsTable.skillQ.range and qDamage > enemy.health then
				CastSpell(_Q, qPosition.x, qPosition.z)
			end
		end
	end

	if config.aggressiveSubMenu.finisherSubMenu.finisherW then
		for i, enemy in pairs(GetEnemyHeroes()) do
			local wPosition = predictionW:GetPrediction(enemy)
			local wDamage = getDmg("W", enemy, myHero)

			if wPosition ~= nil and myHero:CanUseSpell(_W) == READY and GetDistance(wPosition) < skillsTable.skillW.range and wDamage > enemy.health then
				CastSpell(_W, wPosition.x, wPosition.z)
			end
		end
	end

	if config.aggressiveSubMenu.finisherSubMenu.finisherR then
		for i, enemy in pairs(GetEnemyHeroes()) do
			local rPosition = predictionW:GetPrediction(enemy)
			local rDamage = getDmg("R", enemy, myHero)

			if rPosition ~= nil and myHero:CanUseSpell(_R) == READY and GetDistance(rPosition) < skillsTable.skillR.range and rDamage > enemy.health then
				CastSpell(_R, rPosition.x, rPosition.z)
			end
		end
	end
end

function menu()
	config = scriptConfig("AesGraves: Main menu", "aesGraves")
	-- Basic submenu start
	config:addSubMenu("AesGraves: Basic settings", "basicSubMenu")
	config.basicSubMenu:addParam("combo", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, string.byte(" "))
	config.basicSubMenu:addParam("harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("A"))
	config.basicSubMenu:addParam("version", "Version:", SCRIPT_PARAM_INFO, version)
	-- Basic sub menu end

	-- Aggressive submenu start
	config:addSubMenu("AesGraves: Aggressive settings", "aggressiveSubMenu")
	config.aggressiveSubMenu:addSubMenu("Combo settings", "comboSubMenu")
	config.aggressiveSubMenu.comboSubMenu:addParam("comboQ", "Use "..skillsTable.skillQ.name, SCRIPT_PARAM_ONOFF, false)
	config.aggressiveSubMenu.comboSubMenu:addParam("comboW", "Use "..skillsTable.skillW.name, SCRIPT_PARAM_ONOFF, false)
	config.aggressiveSubMenu.comboSubMenu:addParam("comboR", "Use "..skillsTable.skillR.name, SCRIPT_PARAM_ONOFF, false)

	config.aggressiveSubMenu:addSubMenu("Harass settings", "harassSubMenu")
	config.aggressiveSubMenu.harassSubMenu:addParam("harassQ", "Use "..skillsTable.skillQ.name, SCRIPT_PARAM_ONOFF, false)
	config.aggressiveSubMenu.harassSubMenu:addParam("harassW", "Use "..skillsTable.skillW.name, SCRIPT_PARAM_ONOFF, false)

	config.aggressiveSubMenu:addSubMenu("Finisher settings", "finisherSubMenu")
	config.aggressiveSubMenu.finisherSubMenu:addParam("finisherQ", "Use "..skillsTable.skillQ.name, SCRIPT_PARAM_ONOFF, false)
	config.aggressiveSubMenu.finisherSubMenu:addParam("finisherW", "Use "..skillsTable.skillW.name, SCRIPT_PARAM_ONOFF, false)
	config.aggressiveSubMenu.finisherSubMenu:addParam("finisherR", "Use "..skillsTable.skillR.name, SCRIPT_PARAM_ONOFF, false)
	-- Aggressive submenu end

	-- Defensive submenu start

	-- Defensive submenu end

	-- Other submenu start
	config:addSubMenu("AesGraves: Other settings", "otherSubMenu")
	config.otherSubMenu:addSubMenu("Drawing submenu", "drawingSubMenu")
	config.otherSubMenu.drawingSubMenu:addParam("drawQ", "Draw "..skillsTable.skillQ.name, SCRIPT_PARAM_ONOFF, false)
	config.otherSubMenu.drawingSubMenu:addParam("drawW", "Draw "..skillsTable.skillW.name, SCRIPT_PARAM_ONOFF, false)
	config.otherSubMenu.drawingSubMenu:addParam("drawR", "Draw "..skillsTable.skillR.name, SCRIPT_PARAM_ONOFF, false)

	config.otherSubMenu:addSubMenu("Management submenu", "managementSubMenu")
	config.otherSubMenu.managementSubMenu:addParam("manaHarass", "Minimum mana for harass", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
	-- Other submenu end
end
