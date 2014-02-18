if myHero.charName ~= "Ashe" then return end

if VIP_USER then
	require "Prodiction"
	require "Collision"
end
require "AoE_Skillshot_Position"

local target = nil
local version = 0.1
local qActive = false

local SkillQ = {name = "Frost Shot"}
local SkillW = {name = "Volley", range = 1100, speed = .902, delay = 250, width = 175}
local SkillE = {name = "Hawkshot", range = 0, speed = 1.4, delay = 250}
local SkillR = {name = "Enchanted Crystal Arrow", range = 2000, speed = 1.6, delay = 250, width = 130, radius = 250}

function OnLoad()
	if VIP_USER then
		prodiction = ProdictManager.GetInstance()
		wCollision = Collision(SkillW.range, SkillW.speed, SkillW.delay / 1000, SkillW.width)
		predictionW = prodiction:AddProdictionObject(_W, SkillW.range, SkillW.speed * 1000, SkillW.delay / 1000)
		predictionE = prodiction:AddProdictionObject(_E, SkillE.range, SkillE.speed * 1000, SkillE.delay / 1000)
		predictionR = prodiction:AddProdictionObject(_R, SkillR.range, SkillR.speed * 1000, SkillR.delay / 1000, SkillR.width)
	else
		predictionW = TargetPrediction(SkillW.range, SkillW.speed, SkillW.delay)
		predictionE = TargetPrediction(SkillE.range, SkillE.speed, SkillE.delay)
		predictionR = TargetPrediction(SkillR.range, SkillR.speed, SkillR.delay)
	end
	
	Menu()
	ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, SkillR.range, DAMAGE_PHYSICAL, false)
	ts.name = "Ashe"
	Config:addTS(ts)
	
	print("AesAshe version: "..version.." loaded!")
end

function OnTick()
	ts:update()
	target = ts.target
	getERange()

	if Config.basicSubMenu.combo then Combo() end
	if Config.basicSubMenu.aoeR then aoeR() end
	if Config.basicSubMenu.harass then Harass() end
	if Config.aggressiveSubMenu.finishSubMenu.finishW or Config.aggressiveSubMenu.finishSubMenu.finishR then Finisher() end
end

function OnDraw()
	if Config.otherSubMenu.drawSubMenu.drawW then DrawCircle(myHero.x, myHero.y, myHero.z, SkillW.range, 0xFFFFFF) end
	if Config.otherSubMenu.drawSubMenu.drawE then DrawCircle(myHero.x, myHero.y, myHero.z, SkillE.range, 0xFFFFFF) end
	if Config.otherSubMenu.drawSubMenu.drawR then DrawCircle(myHero.x, myHero.y, myHero.z, SkillR.range, 0xFFFFFF) end
end

function Combo()
	if target ~= nil then
		if Config.aggressiveSubMenu.comboSubMenu.comboQ and checkManaQ() then
			if qActive == false and GetDistance(target) < 700 and ValidTarget(target) then
				CastSpell(_Q)
			end
		end
		
		if Config.aggressiveSubMenu.comboSubMenu.comboW then
			local wPosition = predictionW:GetPrediction(target)
			
			if wPosition ~= nil and GetDistance(wPosition) < SkillW.range and ValidTarget(target) and myHero:CanUseSpell(_W) == READY then
				if VIP_USER then
					if not wCollision:GetMinionCollision(myHero, wPosition) then
						CastSpell(_W, wPosition.x, wPosition.z)
					end
				else
					if not GetMinionCollision(myHero, wPosition, SkillW.width) then
						CastSpell(_W, wPosition.x, wPosition.z)
					end
				end
			end
		end
		
		if Config.aggressiveSubMenu.comboSubMenu.comboR then
			local rPosition = predictionR:GetPrediction(target)
			
			if rPosition ~= nil and GetDistance(rPosition) < SkillR.range and ValidTarget(target) and myHero:CanUseSpell(_R) then
				CastSpell(_R, rPosition.x, rPosition.z)
			end
		end
	end
	if target == nil and qActive == true then
		CastSpell(_Q)
	end
end

function Harass()
	if target ~= nil then
		if Config.aggressiveSubMenu.harassSubMenu.harassW and checkManaHarass() then
			local wPosition = predictionW:GetPrediction(target)
			
			if wPosition ~= nil and GetDistance(wPosition) < SkillW.range and ValidTarget(target) and myHero:CanUseSpell(_W) == READY then
				if VIP_USER then
					if not wCollision:GetMinionCollision(myHero, wPosition) then
						CastSpell(_W, wPosition.x, wPosition.z)
					end
				else
					if not GetMinionCollision(myHero, wPosition, SkillW.width) then
						CastSpell(_W, wPosition.x, wPosition.z)
					end
				end
			end
		end	
	end
end

function Finisher()
	if Config.aggressiveSubMenu.finishSubMenu.finishW then
		for i, enemy in pairs(GetEnemyHeroes()) do 
			local wPosition = predictionW:GetPrediction(enemy)
			local wDmg = getDmg("W", enemy, myHero)
			
			if wPosition ~= nil and GetDistance(wPosition) < SkillW.range and ValidTarget(enemy) and myHero:CanUseSpell(_W) == READY and wDmg > enemy.health then
				if VIP_USER then
					if not wCollision:GetMinionCollision(myHero, wPosition) then
						CastSpell(_W, wPosition.x, wPosition.z)
					end
				else
					if not GetMinionCollision(myHero, wPosition, SkillW.width) then
						CastSpell(_W, wPosition.x, wPosition.z)
					end
				end
			end
		end
	end
	
	if Config.aggressiveSubMenu.finishSubMenu.finishR then
		for i, enemy in pairs(GetEnemyHeroes()) do
			local rPosition = predictionR:GetPrediction(enemy)
			local rDmg = getDmg("R", enemy, myHero)
			
			if rPosition ~= nil and GetDistance(rPosition) < SkillR.range and ValidTarget(enemy) and myHero:CanUseSpell(_R) == READY and rDmg > enemy.health then
				CastSpell(_R, rPosition.x, rPosition.z)
			end
		end
	end
end

function aoeR()
	if target ~= nil then
		local rPosition = GetAoESpellPosition(SkillR.radius, target, SkillR.delay)
		
		if rPosition ~= nil and GetDistance(rPosition) < SkillR.range and ValidTarget(target) and myHero:CanUseSpell(_R) then
			CastSpell(_R, rPosition.x, rPosition.z)
		end
	end
end

function getERange()
	if myHero:GetSpellData(_E).level == 1 then
		SkillE.range = 2500
	elseif myHero:GetSpellData(_E).level == 2 then
		SkillE.range = 3250
	elseif myHero:GetSpellData(_E).level == 3 then
		SkillE.range = 4000
	elseif myHero:GetSpellData(_E).level == 4 then
		SkillE.range = 4750
	elseif myHero:GetSpellData(_E).level == 5 then
		SkillE.range = 5500
	else
		SkillE.range = 0
	end
end

function OnCreateObj(obj)
	if obj ~= nil and obj.name == "Ashe_Base_q_buf.troy" then
		qActive = true
	end
end

function OnDeleteObj(obj)
	if obj ~= nil and obj.name == "Ashe_Base_q_buf.troy" then
		qActive = false
	end
end

function checkManaQ()
	if myHero.mana >= myHero.maxMana * (Config.otherSubMenu.managementSubMenu.qMana / 100) then
		return true
	else
		return false
	end
end

function checkManaHarass()
	if myHero.mana >= myHero.maxMana * (Config.otherSubMenu.managementSubMenu.harassMana / 100) then
		return true
	else
		return false
	end
end

function Menu()
	Config = scriptConfig("AesAshe: Main menu", "aesAshe")
	
	Config:addSubMenu("AesAshe: Basic settings", "basicSubMenu")
	Config.basicSubMenu:addParam("combo", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, GetKey(" "))
	Config.basicSubMenu:addParam("harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, GetKey("A"))
	Config.basicSubMenu:addParam("aoeR", "Aoe "..SkillR.name, SCRIPT_PARAM_ONKEYDOWN, false, GetKey("R"))
	Config.basicSubMenu:addParam("version", "Version", SCRIPT_PARAM_INFO, version)
	
	Config:addSubMenu("AesAshe: Aggressive settings", "aggressiveSubMenu")
	Config.aggressiveSubMenu:addSubMenu("Combo settings", "comboSubMenu")
	Config.aggressiveSubMenu.comboSubMenu:addParam("comboQ", "Use "..SkillQ.name, SCRIPT_PARAM_ONOFF, false)
	Config.aggressiveSubMenu.comboSubMenu:addParam("comboW", "Use "..SkillW.name, SCRIPT_PARAM_ONOFF, false)
	Config.aggressiveSubMenu.comboSubMenu:addParam("comboR", "Use "..SkillR.name, SCRIPT_PARAM_ONOFF, false)
	
	Config.aggressiveSubMenu:addSubMenu("Harass settings", "harassSubMenu")
	Config.aggressiveSubMenu.harassSubMenu:addParam("harassW", "Use "..SkillW.name, SCRIPT_PARAM_ONOFF, false)
	
	Config.aggressiveSubMenu:addSubMenu("Finisher settings", "finishSubMenu")
	Config.aggressiveSubMenu.finishSubMenu:addParam("finishW", "Use "..SkillW.name, SCRIPT_PARAM_ONOFF, false)
	Config.aggressiveSubMenu.finishSubMenu:addParam("finishR", "Use "..SkillR.name, SCRIPT_PARAM_ONOFF, false)
	
	Config:addSubMenu("AesAshe: Other settings", "otherSubMenu")
	Config.otherSubMenu:addSubMenu("Management settings", "managementSubMenu")
	Config.otherSubMenu.managementSubMenu:addParam("qMana", "Minimum mana for "..SkillQ.name, SCRIPT_PARAM_SLICE, 30, 0, 100, 0)
	Config.otherSubMenu.managementSubMenu:addParam("harassMana", "Minimum mana to harass", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
	
	Config.otherSubMenu:addSubMenu("Drawing settings", "drawSubMenu")
	Config.otherSubMenu.drawSubMenu:addParam("drawW", "Draw "..SkillW.name, SCRIPT_PARAM_ONOFF, false)
	Config.otherSubMenu.drawSubMenu:addParam("drawE", "Draw "..SkillE.name, SCRIPT_PARAM_ONOFF, false)
	Config.otherSubMenu.drawSubMenu:addParam("drawR", "Draw "..SkillR.name, SCRIPT_PARAM_ONOFF, false)
end
