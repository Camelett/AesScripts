if myHero.charName ~= "Ezreal" then return end

-- Require
require "AoE_Skillshot_Position"

if VIP_USER then
	require "Prodiction"
	require "Collision"
end

-- Variables
local target
local enemyMinions
local version = 1.6
local lastAnimation = nil
local lastAttack = 0
local lastAttackCD = 0
local lastWindUpTime = 0

-- Spell information
local skillQ = {spellName = "Mystic Shot", range = 1200, speed = 2.0, delay = 250, width = 60}
local skillW = {spellName = "Essence Flux", range = 1050, speed = 1.6, delay = 250, width = 80}
local skillR = {spellName = "Trueshot Barrage", range = 2000, speed = 2.0, delay = 1000, width = 160}

function OnLoad()
	if VIP_USER then
		prodiction = ProdictManager.GetInstance()
		predictionQ = prodiction:AddProdictionObject(_Q, skillQ.range, skillQ.speed * 1000, skillQ.delay / 1000, skillQ.width)
		predictionW = prodiction:AddProdictionObject(_W, skillW.range, skillW.speed * 1000, skillW.delay / 1000, skillW.width)
		predictionR = prodiction:AddProdictionObject(_R, skillR.range, skillR.speed * 1000, skillR.delay / 1000, skillR.width)
		qCollision = Collision(skillQ.range, skillQ.speed, skillQ.delay / 1000, skillQ.width)
		rCollision = Collision(skillR.range, skillR.speed, skillR.delay / 1000, skillR.width)
	else
		predictionQ = TargetPrediction(skillQ.range, skillQ.speed, skillQ.delay, skillQ.width)
		predictionW = TargetPrediction(skillW.range, skillW.speed, skillW.delay)
		predictionR = TargetPrediction(skillR.range, skillR.speed, skillR.delay)
	end
	
	PrintChat("AesEzreal loaded! Version: "..version)
	menu()
	targetSelector = TargetSelector(TARGET_LESS_CAST_PRIORITY, skillR.range, DAMAGE_PHYSICAL, true)
	enemyMinions = minionManager(MINION_ENEMY, skillR.range, myHero)
	
	targetSelector.name = "AesEzreal"
	menu:addTS(targetSelector)
end
	
function OnTick()
	targetSelector:update()
	enemyMinions:update()
	
	target = targetSelector.target

	if menu.basicSubMenu.scriptCombo then combo() end
	if menu.basicSubMenu.scriptHarass then harass() end
	if menu.basicSubMenu.scriptFarm then farm() end
	if menu.aggressiveSubMenu.finisherSettings.finishQ or menu.aggressiveSubMenu.finisherSettings.finishW then finisher() end
end

function OnDraw()
	if menu.otherSubMenu.drawSettings.drawQ then DrawCircle(myHero.x, myHero.y, myHero.z, skillQ.range, RGB(255, 255, 255)) end
	if menu.otherSubMenu.drawSettings.drawW then DrawCircle(myHero.x, myHero.y, myHero.z, skillW.range, RGB(255, 255, 255)) end
	if menu.otherSubMenu.drawSettings.drawR then DrawCircle(myHero.x, myHero.y, myHero.z, skillR.range, RGB(255, 255, 255)) end
	for i, enemy in pairs(GetEnemyHeroes()) do
		local rPosition = predictionR:GetPrediction(enemy)
		local rDamage = getDmg("R", enemy, myHero, 2)

		if GetDistance(enemy) < skillR.range and ValidTarget(enemy) and rDamage > enemy.health and myHero:CanUseSpell(_R)  == READY then
			PrintFloatText(enemy, 0, "Press R to do tons of damage")
			DrawCircle(enemy.x, enemy.y, enemy.z, 150, RGB(100, 0, 0))
			DrawCircle(enemy.x, enemy.y, enemy.z, 200, RGB(100, 0, 0))
			DrawCircle(enemy.x, enemy.y, enemy.z, 250, RGB(100, 0, 0))
			
			if menu.aggressiveSubMenu.finisherSettings.finishR and rPosition ~= nil then
				CastSpell(_R, rPosition.x, rPosition.z)
			end
		end
	end
end

function combo()
	if target ~= nil and ValidTarget(target) then
		if menu.aggressiveSubMenu.comboSettings.comboQ then
			local qPosition = predictionQ:GetPrediction(target)

			if qPosition ~= nil and GetDistance(qPosition) < skillQ.range and myHero:CanUseSpell(_Q) == READY then
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

		if menu.aggressiveSubMenu.comboSettings.comboW then
			local wPosition = predictionW:GetPrediction(target)
			
			if wPosition ~= nil and GetDistance(wPosition) < skillW.range and myHero:CanUseSpell(_W) == READY then
				CastSpell(_W, wPosition.x, wPosition.z)
			end
		end
		
		if menu.aggressiveSubMenu.comboSettings.comboR then
			local aoeRPosition = GetAoESpellPosition(skillR.width, target, skillR.delay)
			
			if aoeRPosition ~= nil and GetDistance(aoeRPosition) < skillR.range and myHero:CanUseSpell(_R) == READY then
				CastSpell(_R, aoeRPosition.x, aoeRPosition.z)
			end
		end
		
		if menu.basicSubMenu.orbEnable then
			OrbWalking(target)
		end
	else 
		moveToCursor()
	end
end

function harass()
	if target ~= nil and ValidTarget(target) then
		if menu.aggressiveSubMenu.harassSettings.harassQ then
			local qPosition = predictionQ:GetPrediction(target)
			
			if qPosition ~= nil and GetDistance(qPosition) < skillQ.range and myHero:CanUseSpell(_Q) == READY and checkManaHarass() then
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
		
		if menu.aggressiveSubMenu.harassSettings.harassW then
			local wPosition = predictionW:GetPrediction(target)

			if wPosition ~= nil and GetDistance(wPosition) < skillW.range and myHero:CanUseSpell(_W) == READY and checkManaHarass() then
				CastSpell(_W, wPosition.x, wPosition.z)
			end
		end
		
		if menu.basicSubMenu.orbEnable then
			OrbWalking(target)
		end
	else 
		moveToCursor()
	end
end

function farm()
	if menu.basicSubMenu.scriptFarm and menu.aggressiveSubMenu.farmingSettings.farmQ and checkManaFarm() then
		for i, minion in pairs(enemyMinions.objects) do
			local adDamage = getDmg("AD", minion, myHero)
			local qDamage = getDmg("Q", minion, myHero) + adDamage + getExtraDamage(minion)
			
			if not minion.dead and GetDistance(minion) < skillQ.range and qDamage > minion.health and myHero:CanUseSpell(_Q) == READY then
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
	if menu.aggressiveSubMenu.finisherSettings.finishQ then
		for i, enemy in pairs(GetEnemyHeroes()) do
			local adDamage = getDmg("AD", enemy, myHero)
			local qDamage = getDmg("Q", enemy, myHero) + adDamage + getExtraDamage(enemy)
			local qPosition = predictionQ:GetPrediction(enemy)

			if qPosition ~= nil and GetDistance(qPosition) < skillQ.range and qDamage > enemy.health then
				if VIP_USER then
					if not qCollision:GetMinionCollision(myHero, qPosition) then
						CastSpell(_Q, qPosition.x, qPosition.z)
					end
				else
					if not GetMinionCollision(myHero, enemy, skillQ.width) then
						CastSpell(_Q, qPosition.x, qPosition.z)
					end			
				end
			end
		end
	end

	if menu.aggressiveSubMenu.finisherSettings.finishW then
		for i, enemy in pairs(GetEnemyHeroes()) do
			local wPosition = predictionW:GetPrediction(enemy)
			local wDamage = getDmg("W", enemy, myHero) + myHero.ap
				
			if wPosition ~= nil and GetDistance(wPosition) < skillW.range and myHero:CanUseSpell(_W) == READY and wDamage > enemy.health then
				CastSpell(_W, wPosition.x, wPosition.z)
			end
		end
	end
end


function checkManaHarass()
	if myHero.mana >= myHero.maxMana * (menu.otherSubMenu.managementSettings.manaProcentHarass / 100) then
		return true
	else
		return false
	end
end

function checkManaFarm()
	if myHero.mana >= myHero.maxMana * (menu.otherSubMenu.managementSettings.manaProcentFarm / 100) then
		return true
	else
		return false
	end
end

function getExtraDamage(Target)
	local extraDamage = 0
	
	if GetInventoryHaveItem(3078) then -- Trinity force
		extraDamage = getDmg("TRINITY", Target, myHero)
	end
	
	if GetInventoryHaveItem(3057) then -- Sheen
		extraDamage = getDmg("SHEEN", Target, myHero)
	end
	
	return extraDamage
end

function OrbWalking(Target)
	if TimeToAttack() and GetDistance(Target) <= myHero.range + GetDistance(myHero.minBBox) then
		myHero:Attack(Target)
    elseif heroCanMove() then
        moveToCursor()
    end
end

function TimeToAttack()
    return (GetTickCount() + GetLatency()/2 > lastAttack + lastAttackCD)
end

function heroCanMove()
	return (GetTickCount() + GetLatency()/2 > lastAttack + lastWindUpTime + 20)
end

function moveToCursor()
	if GetDistance(mousePos) then
		local moveToPos = myHero + (Vector(mousePos) - myHero):normalized()*300
		myHero:MoveTo(moveToPos.x, moveToPos.z)
    end        
end

function OnProcessSpell(object,spell)
	if object == myHero then
		if spell.name:lower():find("attack") then
			lastAttack = GetTickCount() - GetLatency()/2
			lastWindUpTime = spell.windUpTime*1000
			lastAttackCD = spell.animationTime*1000
        end
    end
end

function OnAnimation(unit,animationName)
    if unit.isMe and lastAnimation ~= animationName then lastAnimation = animationName end
end
	
function menu()
	menu = scriptConfig("AesEzreal: Main menu", "aesezreal")

	menu:addSubMenu("AesEzreal: Basic settings", "basicSubMenu")
	menu.basicSubMenu:addParam("scriptCombo", "Use combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	menu.basicSubMenu:addParam("scriptHarass", "Use harass", SCRIPT_PARAM_ONKEYDOWN, false, GetKey("A"))
	menu.basicSubMenu:addParam("scriptFarm", "Use farm", SCRIPT_PARAM_ONKEYDOWN, false, GetKey("X"))
	menu.basicSubMenu:addParam("orbEnable", "Enable orbwalking", SCRIPT_PARAM_ONOFF, false)
	menu.basicSubMenu:addParam("version", "Version:", SCRIPT_PARAM_INFO, version)

	menu:addSubMenu("AesEzreal: Aggressive settings", "aggressiveSubMenu")
	-- Combo submenu
	menu.aggressiveSubMenu:addSubMenu("Combo settings", "comboSettings")
	menu.aggressiveSubMenu.comboSettings:addParam("comboQ", "Use "..skillQ.spellName, SCRIPT_PARAM_ONOFF, false)
	menu.aggressiveSubMenu.comboSettings:addParam("comboW", "Use "..skillW.spellName, SCRIPT_PARAM_ONOFF, false)
	menu.aggressiveSubMenu.comboSettings:addParam("comboR", "Use "..skillR.spellName, SCRIPT_PARAM_ONOFF, false)
	-- Harass submenu
	menu.aggressiveSubMenu:addSubMenu("Harass settings", "harassSettings")
	menu.aggressiveSubMenu.harassSettings:addParam("harassQ", "Use "..skillQ.spellName, SCRIPT_PARAM_ONOFF, false)
	menu.aggressiveSubMenu.harassSettings:addParam("harassW", "Use "..skillW.spellName, SCRIPT_PARAM_ONOFF, false)
	-- Finisher submenu
	menu.aggressiveSubMenu:addSubMenu("Finisher settings", "finisherSettings")
	menu.aggressiveSubMenu.finisherSettings:addParam("finishQ", "Use "..skillQ.spellName, SCRIPT_PARAM_ONOFF, false)
	menu.aggressiveSubMenu.finisherSettings:addParam("finishW", "Use "..skillW.spellName, SCRIPT_PARAM_ONOFF, false)
	menu.aggressiveSubMenu.finisherSettings:addParam("finishR", "Use "..skillR.spellName, SCRIPT_PARAM_ONKEYDOWN, false, GetKey("R"))
	-- Farming submenu
	menu.aggressiveSubMenu:addSubMenu("Farming settings", "farmingSettings")
	menu.aggressiveSubMenu.farmingSettings:addParam("farmQ", "Use "..skillQ.spellName, SCRIPT_PARAM_ONOFF, false)
	
	menu:addSubMenu("AesEzreal: Other settings", "otherSubMenu")
	-- Management submenu
	menu.otherSubMenu:addSubMenu("Management settings", "managementSettings")
	menu.otherSubMenu.managementSettings:addParam("manaProcentHarass", "Minimum mana to harass", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
	menu.otherSubMenu.managementSettings:addParam("manaProcentFarm", "Minimum mana to farm", SCRIPT_PARAM_SLICE, 30, 0, 100, 0)
	-- Draw submenu
	menu.otherSubMenu:addSubMenu("Draw settings", "drawSettings")
	menu.otherSubMenu.drawSettings:addParam("drawQ", "Draw "..skillQ.spellName, SCRIPT_PARAM_ONOFF, false)
	menu.otherSubMenu.drawSettings:addParam("drawW", "Draw "..skillW.spellName, SCRIPT_PARAM_ONOFF, false)
	menu.otherSubMenu.drawSettings:addParam("drawR", "Draw "..skillR.spellName, SCRIPT_PARAM_ONOFF, false)
end
