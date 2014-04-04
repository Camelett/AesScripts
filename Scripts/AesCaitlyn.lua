local version = "1.02"

if myHero.charName ~= "Caitlyn" then return end

-- Credits for honda7 and Skeem for updater
local autoupdateenabled = true
local UPDATE_SCRIPT_NAME = "AesCaitlyn"
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/Tikutis/AesScripts/master/Scripts/AesCaitlyn.lua?chunk="..math.random(1, 1000)
local UPDATE_FILE_PATH = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH

local ServerData
if autoupdateenabled then
	GetAsyncWebResult(UPDATE_HOST, UPDATE_PATH, function(d) ServerData = d end)
	function update()
		if ServerData ~= nil then
			local ServerVersion
			local send, tmp, sstart = nil, string.find(ServerData, "local version = \"")
			if sstart then
				send, tmp = string.find(ServerData, "\"", sstart+1)
			end
			if send then
				ServerVersion = tonumber(string.sub(ServerData, sstart+1, send-1))
			end

			if ServerVersion ~= nil and tonumber(ServerVersion) ~= nil and tonumber(ServerVersion) > tonumber(version) then
				DownloadFile(UPDATE_URL.."?nocache"..myHero.charName..os.clock(), UPDATE_FILE_PATH, function () print("<font color=\"#FF0000\"><b>"..UPDATE_SCRIPT_NAME..":</b> successfully updated. ("..version.." => "..ServerVersion..")</font>") end)     
			elseif ServerVersion then
				print("<font color=\"#FF0000\"><b>"..UPDATE_SCRIPT_NAME..":</b> You have got the latest version: <u><b>"..ServerVersion.."</b></u></font>")
			end		
			ServerData = nil
		end
	end
	AddTickCallback(update)
end


if VIP_USER then
	require "VPrediction"
end

local target = nil
local prediction = nil

local skills = {
	skillQ = {name = "Piltover peacemaker", range = 1300, speed = 2200, delay = 0.625, width = 90},
	skillW = {name = "Yordle snap trap", range = 800, speed = 1450, delay = 0.250, width = 100},
	skillE = {name = "90 caliber net", range = 1000, speed = 2000, delay = 0.250, width = 80},
	skillR = {name = "Ace in the hole"}
}

function OnLoad()
	if not VIP_USER then
		qPrediction = TargetPrediction(skills.skillQ.range, skills.skillQ.speed / 1000, skills.skillQ.delay * 1000, skills.skillQ.width)
		wPrediction = TargetPrediction(skills.skillW.range, skills.skillW.speed / 1000, skills.skillW.delay * 1000, skills.skillW.width)
		ePrediction = TargetPrediction(skills.skillE.range, skills.skillE.speed / 1000, skills.skillE.delay * 1000, skills.skillE.width)
	end

	targetSelector = TargetSelector(TARGET_LESS_CAST_PRIORITY, skills.skillQ.range, DAMAGE_PHYSICAL, false)
	if VIP_USER then prediction = VPrediction() end
	targetSelector.name = "AesCaitlyn"
	
	menu()
	config:addTS(targetSelector)
end

function OnTick()
	targetSelector:update()
	target = targetSelector.target
	
	if config.basicSubMenu.combo then combo() end
	if config.basicSubMenu.harass then harass() end
	if config.aggressiveSubMenu.finisherSubMenu.finisherQ or finisherE then finisher() end
	if config.defensiveSubMenu.autoW and ValidTarget(target, skills.skillW.range, true) then castStunnedW() end
	reversedE()
end

function OnDraw()
	if config.otherSubMenu.drawSubMenu.drawQ then DrawCircle3D(myHero.x, myHero.y, myHero.z, skills.skillQ.range, 1, RGB(255, 255, 255)) end
	if config.otherSubMenu.drawSubMenu.drawW then DrawCircle3D(myHero.x, myHero.y, myHero.z, skills.skillW.range, 1, RGB(255, 255, 255)) end
	if config.otherSubMenu.drawSubMenu.drawE then DrawCircle3D(myHero.x, myHero.y, myHero.z, skills.skillE.range, 1, RGB(255, 255, 255)) end
	if config.otherSubMenu.drawSubMenu.drawR then DrawCircle3D(myHero.x, myHero.y, myHero.z, getRRange(), 1, RGB(255, 255, 255)) end
	if ValidTarget(target, getRRange(), true) and myHero:CanUseSpell(_R) == READY then
		for i = 1, heroManager.iCount do
			local enemy = heroManager:getHero(i)
			
			if myHero:CanUseSpell(_R) == READY then
				local correction = myHero:GetSpellData(_R).level * 20
				local rDamage = getDmg("R", enemy, myHero) - correction

				if rDamage > enemy.health and ValidTarget(enemy, getRRange(), true) then
					DrawText3D("Press R to kill!", enemy.x, enemy.y, enemy.z, 15, RGB(255, 0, 0), 0)
					DrawCircle3D(enemy.x, enemy.y, enemy.z, 100, 1, RGB(255, 0, 0))
					DrawCircle3D(enemy.x, enemy.y, enemy.z, 150, 1, RGB(255, 0, 0))
					DrawCircle3D(enemy.x, enemy.y, enemy.z, 200, 1, RGB(255, 0, 0))
					if config.aggressiveSubMenu.finisherSubMenu.finisherR and rDamage > enemy.health then
						CastSpell(_R, enemy)
					end
				end
			end
		end
	end
end

function combo()
	if ValidTarget(target, skills.skillQ.range) then
		if config.aggressiveSubMenu.comboSubMenu.comboQ then
			castQ(target)
		end
		
		if config.aggressiveSubMenu.comboSubMenu.comboW then
			castW(target)
		end
		
		if config.aggressiveSubMenu.comboSubMenu.comboE then
			castE(target)
		end
	end
end

function harass()
	if ValidTarget(target, skills.skillQ.range) and checkManaHarass() then
		if config.aggressiveSubMenu.harassSubMenu.harassE then
			castE(target)
		end
	
		if config.aggressiveSubMenu.harassSubMenu.harassQ then
			castQ(target)
		end
	end
end

function finisher()
	for i = 1, heroManager.iCount do
		local enemy = heroManager:getHero(i)
		
		if ValidTarget(enemy, getRRange(), true) then
			if config.aggressiveSubMenu.finisherSubMenu.finisherQ then
				local qDamage = getDmg("Q", enemy, myHero)
				
				if qDamage > enemy.health and ValidTarget(enemy, skills.skillQ.range, true) then
					castQ(enemy)
				end
			end
			
			if config.aggressiveSubMenu.finisherSubMenu.finisherE and ValidTarget(enemy, skills.skillE.range, true) then
				local eDamage = getDmg("E", enemy, myHero)
				
				if eDamage > enemy.health then
					castE(enemy)
				end
			end
		end
	end
end

function castQ(Target)
	if VIP_USER then
		local qPosition, qChance = prediction:GetLineCastPosition(Target, skills.skillQ.delay, skills.skillQ.width, skills.skillQ.range, skills.skillQ.speed, myHero, false)
		
		if qPosition ~= nil and GetDistance(qPosition) < skills.skillQ.range and myHero:CanUseSpell(_Q) == READY and qChance >= 2 then
			CastSpell(_Q, qPosition.x, qPosition.z)
		end
	else
		local qPosition = qPrediction:GetPrediction(Target)
		
		if qPosition ~= nil and GetDistance(qPosition) < skills.skillQ.range and myHero:CanUseSpell(_Q) == READY then
			CastSpell(_Q, qPosition.x, qPosition.z)
		end
	end
end

function castW(Target)
	if VIP_USER then
		local wPosition, wChance = prediction:GetCircularCastPosition(Target, skills.skillW.delay, skills.skillW.delay, skills.skillW.range, skills.skillW.speed, myHero, false)
		
		if wPosition ~= nil and GetDistance(wPosition) < skills.skillW.range and myHero:CanUseSpell(_W) == READY and wChance >= 3 then
			CastSpell(_W, wPosition.x, wPosition.z)
		end
	else
		local wPosition = wPrediction:GetPrediction(Target)
		
		if wPosition ~= nil and GetDistance(wPosition) < skills.skillW.range and myHero:CanUseSpell(_W) == READY then
			CastSpell(_W, wPosition.x, wPosition.z)
		end
	end
end

function castStunnedW()
	for i, enemy in pairs(GetEnemyHeroes()) do
		if VIP_USER then
			local wPosition, wChance = prediction:GetCircularCastPosition(enemy, skills.skillW.delay, skills.skillW.delay, skills.skillW.range, skills.skillW.speed, myHero, false)
			
			if wPosition ~= nil and GetDistance(wPosition) < skills.skillW.range and myHero:CanUseSpell(_W) == READY and wChance >= 4 then
				CastSpell(_W, wPosition.x, wPosition.z)
			end
		else		
			if GetDistance(enemy) < skills.skillW.range and myHero:CanUseSpell(_W) == READY and not enemy.canMove then
				CastSpell(_W, enemy.x, enemy.z)
			end
		end
	end
end

function castE(Target)
	if VIP_USER then
		local ePosition, eChance = prediction:GetLineCastPosition(target, skills.skillE.delay, skills.skillE.width, skills.skillE.range, skills.skillE.speed, myHero, true)
		
		if ePosition ~= nil and GetDistance(ePosition) < skills.skillE.range and myHero:CanUseSpell(_E) == READY and eChance >= 2 then
			CastSpell(_E, ePosition.x, ePosition.z)
		end
	else
		local ePosition = ePrediction:GetPrediction(target)
		
		if ePosition ~= nil and GetDistance(ePosition) < skills.skillE.range and myHero:CanUseSpell(_E) == READY and not GetMinionCollision(myHero, ePosition, skills.skillE.width) then
			CastSpell(_E, ePosition.x, ePosition.z)
		end
	end
end

function getRRange()
	return 1500 + (500 * myHero:GetSpellData(_R).level)
end

function OnProcessSpell(unit, spell)
    if not config.defensiveSubMenu.autoE then return end
		local jarvanAddition = unit.charName == "JarvanIV" and unit:CanUseSpell(_Q) ~= READY and _R or _Q -- Did not want to break the table below.
		local isAGapcloserUnit = {
	--        ['Ahri']        = {true, spell = _R, range = 450,   projSpeed = 2200},
			['Aatrox']      = {true, spell = _Q,                  range = 1000,  projSpeed = 1200, },
			['Akali']       = {true, spell = _R,                  range = 800,   projSpeed = 2200, }, -- Targeted ability
			['Alistar']     = {true, spell = _W,                  range = 650,   projSpeed = 2000, }, -- Targeted ability
			['Diana']       = {true, spell = _R,                  range = 825,   projSpeed = 2000, }, -- Targeted ability
			['Gragas']      = {true, spell = _E,                  range = 600,   projSpeed = 2000, },
			['Graves']      = {true, spell = _E,                  range = 425,   projSpeed = 2000, exeption = true },
			['Hecarim']     = {true, spell = _R,                  range = 1000,  projSpeed = 1200, },
			['Irelia']      = {true, spell = _Q,                  range = 650,   projSpeed = 2200, }, -- Targeted ability
			['JarvanIV']    = {true, spell = jarvanAddition,      range = 770,   projSpeed = 2000, }, -- Skillshot/Targeted ability
			['Jax']         = {true, spell = _Q,                  range = 700,   projSpeed = 2000, }, -- Targeted ability
			['Jayce']       = {true, spell = 'JayceToTheSkies',   range = 600,   projSpeed = 2000, }, -- Targeted ability
			['Khazix']      = {true, spell = _E,                  range = 900,   projSpeed = 2000, },
			['Leblanc']     = {true, spell = _W,                  range = 600,   projSpeed = 2000, },
			['LeeSin']      = {true, spell = 'blindmonkqtwo',     range = 1300,  projSpeed = 1800, },
			['Leona']       = {true, spell = _E,                  range = 900,   projSpeed = 2000, },
			['Malphite']    = {true, spell = _R,                  range = 1000,  projSpeed = 1500 + unit.ms},
			['Maokai']      = {true, spell = _Q,                  range = 600,   projSpeed = 1200, }, -- Targeted ability
			['MonkeyKing']  = {true, spell = _E,                  range = 650,   projSpeed = 2200, }, -- Targeted ability
			['Pantheon']    = {true, spell = _W,                  range = 600,   projSpeed = 2000, }, -- Targeted ability
			['Poppy']       = {true, spell = _E,                  range = 525,   projSpeed = 2000, }, -- Targeted ability
			--['Quinn']       = {true, spell = _E,                  range = 725,   projSpeed = 2000, }, -- Targeted ability
			['Renekton']    = {true, spell = _E,                  range = 450,   projSpeed = 2000, },
			['Sejuani']     = {true, spell = _Q,                  range = 650,   projSpeed = 2000, },
			['Shen']        = {true, spell = _E,                  range = 575,   projSpeed = 2000, },
			['Tristana']    = {true, spell = _W,                  range = 900,   projSpeed = 2000, },
			['Tryndamere']  = {true, spell = 'Slash',             range = 650,   projSpeed = 1450, },
			['XinZhao']     = {true, spell = _E,                  range = 650,   projSpeed = 2000, }, -- Targeted ability
		}
		
		if unit.type == 'obj_AI_Hero' and unit.team == TEAM_ENEMY and isAGapcloserUnit[unit.charName] and GetDistance(unit) < 2000 and spell ~= nil then
			if spell.name == (type(isAGapcloserUnit[unit.charName].spell) == 'number' and unit:GetSpellData(isAGapcloserUnit[unit.charName].spell).name or isAGapcloserUnit[unit.charName].spell) then
				if spell.target ~= nil and spell.target.name == myHero.name or isAGapcloserUnit[unit.charName].spell == 'blindmonkqtwo' then
					CastSpell(_E, unit.x, unit.z)
				else
					spellExpired = false
					informationTable = {
						spellSource = unit,
						spellCastedTick = GetTickCount(),
						spellStartPos = Point(spell.startPos.x, spell.startPos.z),
						spellEndPos = Point(spell.endPos.x, spell.endPos.z),
						spellRange = isAGapcloserUnit[unit.charName].range,
						spellSpeed = isAGapcloserUnit[unit.charName].projSpeed,
						spellIsAnExpetion = isAGapcloserUnit[unit.charName].exeption or false,
					}
				end
			end
		end
end

function reversedE()
	if config.defensiveSubMenu.reversedE and myHero:CanUseSpell(_E) == READY then
		-- credits to jbman for calculations
		local MPos = Vector(mousePos.x, mousePos.y, mousePos.z)
		local HeroPos = Vector(myHero.x, myHero.y, myHero.z)
		local DashPos = HeroPos + ( HeroPos - MPos )*(500/GetDistance(mousePos))

		CastSpell(_E, DashPos.x, DashPos.y, DashPos.z)
	end
end

function checkManaHarass()
	if myHero.mana >= myHero.maxMana * (config.otherSubMenu.manaSubMenu.harassMana / 100) then
		return true
	else
		return false
	end
end

function menu()
	config = scriptConfig("AesCaitlyn: Main menu", "aesConfig")
	
	config:addSubMenu("Basic settings", "basicSubMenu")
	config.basicSubMenu:addParam("combo", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, GetKey(" "))
	config.basicSubMenu:addParam("harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, GetKey("A"))
	config.basicSubMenu:addParam("versionInfo", "AesCaitlyn version:", SCRIPT_PARAM_INFO, version)
	
	config:addSubMenu("Aggressive settings", "aggressiveSubMenu")
	config.aggressiveSubMenu:addSubMenu("Combo settings", "comboSubMenu")
	config.aggressiveSubMenu.comboSubMenu:addParam("comboQ", "Use "..skills.skillQ.name, SCRIPT_PARAM_ONOFF, false)
	config.aggressiveSubMenu.comboSubMenu:addParam("comboW", "Use "..skills.skillW.name, SCRIPT_PARAM_ONOFF, false)
	config.aggressiveSubMenu.comboSubMenu:addParam("comboE", "Use "..skills.skillE.name, SCRIPT_PARAM_ONOFF, false)
	config.aggressiveSubMenu:addSubMenu("Harass settings", "harassSubMenu")
	config.aggressiveSubMenu.harassSubMenu:addParam("harassQ", "Use "..skills.skillQ.name, SCRIPT_PARAM_ONOFF, false)
	config.aggressiveSubMenu.harassSubMenu:addParam("harassE", "Use "..skills.skillE.name, SCRIPT_PARAM_ONOFF, false)
	config.aggressiveSubMenu:addSubMenu("Finisher settings", "finisherSubMenu")
	config.aggressiveSubMenu.finisherSubMenu:addParam("finisherQ", "Use "..skills.skillQ.name, SCRIPT_PARAM_ONOFF, false)
	config.aggressiveSubMenu.finisherSubMenu:addParam("finisherE", "Use "..skills.skillE.name, SCRIPT_PARAM_ONOFF, false)
	config.aggressiveSubMenu.finisherSubMenu:addParam("finisherR", "Use "..skills.skillR.name, SCRIPT_PARAM_ONKEYDOWN, false, GetKey("R"))
	
	config:addSubMenu("Defensive settings", "defensiveSubMenu")
	config.defensiveSubMenu:addParam("autoE", "Use "..skills.skillE.name.." from gapclosers", SCRIPT_PARAM_ONOFF, false)
	config.defensiveSubMenu:addParam("reversedE", "Use "..skills.skillE.name.." reversed", SCRIPT_PARAM_ONKEYDOWN, false, GetKey("E"))
	config.defensiveSubMenu:addParam("autoW", "Use "..skills.skillW.name.." under stunned enemy", SCRIPT_PARAM_ONOFF, false)
	
	config:addSubMenu("Other settings", "otherSubMenu")
	config.otherSubMenu:addSubMenu("Drawing settings", "drawSubMenu")
	config.otherSubMenu.drawSubMenu:addParam("drawQ", "Draw "..skills.skillQ.name.." range", SCRIPT_PARAM_ONOFF, false)
	config.otherSubMenu.drawSubMenu:addParam("drawW", "Draw "..skills.skillW.name.." range", SCRIPT_PARAM_ONOFF, false)
	config.otherSubMenu.drawSubMenu:addParam("drawE", "Draw "..skills.skillE.name.." range", SCRIPT_PARAM_ONOFF, false)
	config.otherSubMenu.drawSubMenu:addParam("drawR", "Draw "..skills.skillR.name.." range", SCRIPT_PARAM_ONOFF, false)
	config.otherSubMenu:addSubMenu("Mana settings", "manaSubMenu")
	config.otherSubMenu.manaSubMenu:addParam("harassMana", "Minimum mana to harass", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
end
