--[[
Script: AesCaityn
Version: 0.6 Beta
Author: Bestplox
]]--

-- RANGE
local ERange = 1000
-- PREDICTION
local QPredic = TargetPrediction(1300, 2.2, 610) -- Range , Speed, Delay
local WPredic = TargetPrediction(800)
local EPredic = TargetPrediction(1000, 0, 8)
-- Misc
local ignite = nil
local IREADY = false

function OnLoad()
	PrintChat(" >> Caitlyn combo loaded!")
	Config = scriptConfig("Caitlyn Combo", "ConfigCombo")
	Config:addParam("combo", "Use Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32) -- SpaceBar
	Config:addParam("ult", "Show killable enemy with R", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("autoult", "Auto Ult", SCRIPT_PARAM_ONKEYDOWN, false, 82) -- R
	Config:addParam("trap", "Trap under enemy", SCRIPT_PARAM_ONKEYDOWN, false, 87) -- x
	Config:addParam("autoignite", "Use ignite", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("net", "Use net in combo", SCRIPT_PARAM_ONOFF, false)
	Config:addParam("draw", "Draw Circles", SCRIPT_PARAM_ONOFF, true)
	ts = TargetSelector(TARGET_LOW_HP, 1400, DAMAGE_PHYSICAL)
	ts.name = "Caitlyn"
	Config:addTS(ts)

	enemyMinions = minionManager(MINION_ENEMY, 1200, player)

	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then
		ignite = SUMMONER_1
	elseif
	myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then
		ignite = SUMMONER_2
	end
end

function OnTick()
	ts:update()
	enemyMinions:update()

	if Config.combo then
		Combo()
	end

	if Config.trap then
		Trap()
	end

	if Config.autoignite then
		Ignite()
	end
end

function Combo()
	if ts.target ~= nil then
		-- Q
		QPredict = QPredic:GetPrediction(ts.target)
		if myHero:CanUseSpell(_Q) == READY and QPredict ~= nil and GetDistance(QPredict) <= 1300 then
			CastSpell(_Q, QPredict.x, QPredict.z)
		end

		-- E
		EPredict = EPredic:GetPrediction(ts.target)
		if myHero:CanUseSpell(_E) == READY and EPredict ~= nil and Config.net and GetDistance(EPredict) <= 1000 then
			if not minionCollision(EPredict, 60, ERange) then
				CastSpell(_E, EPredict.x, EPredict.z)
			end
		end
	end
end

function Trap()
	if ts.target ~= nil then
		WPredict = WPredic:GetPrediction(ts.target)
		if myHero:CanUseSpell(_W) == READY and WPredict ~= nil then
			CastSpell(_W, WPredict.x, WPredict.z)
		end
	end
end

function Ignite()
	IREADY = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)
	if IREADY then
		local ignitedmg = 0
		for j = 1, heroManager.iCount, 1 do
			local enemyhero = heroManager:getHero(j)
			if ValidTarget(enemyhero,600) then
				ignitedmg = 50 + 20 * myHero.level
				if enemyhero.health <= ignitedmg then
					CastSpell(ignite, enemyhero)
				end
			end
		end
	end
end

function OnDraw()
	if Config.draw then
		if myHero:CanUseSpell(_Q) == READY then
			DrawCircle(myHero.x, myHero.y, myHero.z, 1300, 0xFF0000)
		end
		if myHero:CanUseSpell(_E) == READY then
			DrawCircle(myHero.x, myHero.y, myHero.z, 1000, 0xFF0000)
		end
		DrawCircle(myHero.x, myHero.y, myHero.z, 850, 0xFF0000)
	end

	if Config.ult then
		local rDmg = 0
		if myHero:CanUseSpell(_R) == READY then
			for i = 1, heroManager.iCount, 1 do
				local target = heroManager:getHero(i)
				if ValidTarget(target) then
					rDmg = (getDmg("R", target, myHero)-80)
					if target ~= nil and target.team ~= myHero.team and not target.dead and target.visible
					and GetDistance(target) <= 3000 and GetDistance(target) > 500 and target.health < rDmg then
						DrawCircle(target.x, target.y, target.z,100, 0xFF0000)
						DrawCircle(target.x, target.y, target.z,150, 0xFF0000)
						DrawCircle(target.x, target.y, target.z,200, 0xFF0000)
						DrawCircle(target.x, target.y, target.z,300, 0xFF0000)
						DrawText("Press R to Snipe!!",50,520,100,0xFFFF0000)
						PrintFloatText(target,0,"Ulti!!!")
						if Config.autoult then
							CastSpell(_R, target)
						end
					end
				end
			end
		end
	end
end

function minionCollision(predic, width, range)
	for _, minionObjectE in pairs(enemyMinions.objects) do
		if predic ~= nil and player:GetDistance(minionObjectE) < range then
			ex = player.x
			ez = player.z
			tx = predic.x
			tz = predic.z
			dx = ex - tx
			dz = ez - tz
			if dx ~= 0 then
				m = dz/dx
				c = ez - m*ex
			end
			mx = minionObjectE.x
			mz = minionObjectE.z
			distanc = (math.abs(mz - m*mx - c))/(math.sqrt(m*m+1))
			if distanc < width and math.sqrt((tx - ex)*(tx - ex) + (tz - ez)*(tz - ez)) > math.sqrt((tx - mx)*(tx - mx) + (tz - mz)*(tz - mz)) then
				return true
			end
		end
	end
	return false
end