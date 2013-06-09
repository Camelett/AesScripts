--[[
Script: AesEzreal
Author: Bestplox
Version: 1.0
--]]
if myHero.charName ~= "Ezreal" then return end

-- Constants
local QRange = 1100
local WRange = 1050
local RRange = 2000

local QSpeed = 2000
local WSpeed = 1600
local RSpeed = 1700

-- Variables
local ignite = nil
local IREADY = false

-- Prediction
if VIP_USER then
	require "Collision"
	Coll = Collision(QRange, QSpeed, 0.25, 125)
	QPredic = TargetPredictionVIP(QRange, QSpeed, 0.25)
	WPredic = TargetPredictionVIP(WRange, WSpeed, 0.25)
	RPredic = TargetPredictionVIP(RRange, RSpeed, 1.0)
else
	QPredic = TargetPrediction(QRange, 2.0, 251)
	WPredic = TargetPrediction(WRange, 1.6, 250)
	RPredic = TargetPrediction(RRange, 1.7, 1000)
end

function OnLoad()
	PrintChat(">> AesEzreal Loaded!")
	Config = scriptConfig("AesEzreal", "config")
	Config:addParam("combo", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	Config:addParam("harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, 65)
	Config:addParam("ultimate", "Ultimate if killable", SCRIPT_PARAM_ONKEYDOWN, false, 82)
	Config:addParam("ultimatecombo", "Use ultimate in combo", SCRIPT_PARAM_ONOFF, false)
	Config:addParam("ignite", "Use ignite if killable", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("w", "Use W in combo", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("draw", "Draw circles", SCRIPT_PARAM_ONOFF, true)
	Config:permaShow("combo")
	Config:permaShow("harass")

	ts = TargetSelector(TARGET_PRIORITY, QRange, DAMAGE_PHYSICAL)
	ts.name = "Ezreal"
	Config:addTS(ts)
	enemyMinions = minionManager(MINION_ENEMY, QRange, player)

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

	if ts.target ~= nil then
		qPred = QPredic:GetPrediction(ts.target)
		wPred = WPredic:GetPrediction(ts.target)
		rPred = RPredic:GetPrediction(ts.target)
	end

	if Config.combo then
		Combo()
	end

	if Config.ultimate then
		Ultimate()
	end

	if Config.harass then
		Harass()
	end

	if Config.ignite then
		Ignite()
	end
end

function Combo()
	if ts.target ~= nil then
		if rPred ~= nil and Config.ultimatecombo then
			if myHero:CanUseSpell(_R) == READY and GetDistance(rPred) <= RRange then
				if VIP_USER and RPredic:GetHitChance(ts.target) > 0.6 then
					CastSpell(_R, rPred.x, rPred.z)
				elseif not VIP_USER then
					CastSpell(_R, rPred.x, rPred.z)
				end
			end
		end

		if qPred ~= nil then
			if myHero:CanUseSpell(_Q) == READY and GetDistance(qPred) <= QRange then
				if VIP_USER and QPredic:GetHitChance(ts.target) > 0.6 and not Coll:GetMinionCollision(myHero, qPred) then
					CastSpell(_Q, qPred.x, qPred.z)
				elseif not VIP_USER and not GetMinionCollision(myHero, ts.target, 125, enemyMinions.objects) then
					CastSpell(_Q, qPred.x, qPred.z)
				end
			end
		end

		if wPred ~= nil and Config.w then
			if myHero:CanUseSpell(_W) == READY and GetDistance(wPred) <= WRange then
				if VIP_USER and WPredic:GetHitChance(ts.target) > 0.6 then
					CastSpell(_W, wPred.x, wPred.z)
				elseif not VIP_USER then
					CastSpell(_W, wPred.x, wPred.z)
				end
			end
		end
	end
end

function Harass()
	if ts.target ~= nil and qPred ~= nil then
		if myHero:CanUseSpell(_Q) == READY and GetDistance(qPred) <= QRange then
			if VIP_USER and QPredic:GetHitChance(ts.target) > 0.6 and not Coll:GetMinionCollision(myHero, qPred) then
				CastSpell(_Q, qPred.x, qPred.z)
			elseif not VIP_USER and not GetMinionCollision(myHero, ts.target, 125, enemyMinions.objects) then
				CastSpell(_Q, qPred.x, qPred.z)
			end
		end
	end
end

function Ultimate()
	if ts.target ~= nil then
		RDmg = getDmg("R", ts.target, myHero)
		if myHero:CanUseSpell(_R) == READY and rPred ~= nil and Config.ultimate and GetDistance(rPred) <= 2000 and GetDistance(ts.target) > 200 and ts.target.health < RDmg then
			if VIP_USER then
				CastSpell(_R, rPred.x, rPred.z)
			elseif not VIP_USER then
				CastSpell(_R, rPred.x, rPred.z)
			end
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
	if ts.target ~= nil then
		RDmg = getDmg("R", ts.target, myHero)
	end
	if ts.target ~= nil and myHero:CanUseSpell(_R) and ts.target.team ~= myHero.team and not ts.target.dead and ts.target.visible and
	GetDistance(ts.target) <= RRange and GetDistance(ts.target) > 200 and ts.target.health < RDmg then
		DrawCircle(ts.target.x, ts.target.y, ts.target.z,100, 0xFF0000)
		DrawCircle(ts.target.x, ts.target.y, ts.target.z,150, 0xFF0000)
		DrawCircle(ts.target.x, ts.target.y, ts.target.z,200, 0xFF0000)
		DrawCircle(ts.target.x, ts.target.y, ts.target.z,300, 0xFF0000)
		DrawText("Press R to Snipe!!",50,520,100,0xFFFF0000)
		PrintFloatText(ts.target,0,"Ulti!!!")
	end
	if Config.draw then
		if myHero:CanUseSpell(_Q) then
			DrawCircle(myHero.x, myHero.y, myHero.z, 1100, 0xFF0000)
		end
	end
end