--[[
Author: Puze
Script: AesNami
Version: 0.1
--]]
if myHero.charName ~= "Nami" then return end

--Prediction
if VIP_USER then
	QPredic = TargetPredictionVIP(QRange, math.huge, 0.4)
	RPredic = TargetPredictionVIP(RRange, 1200, 0.5)
else
	QPredic = TargetPrediction(850, 2.0, 500)
	RPredic = TargetPrediction(1000, 1.2, 500)
end

--Constants
local QRange = 850
local WRange = 725
local RRange = 1000


function OnLoad()
	PrintChat(">> AesNami loaded!")
	Config = scriptConfig("AesNami", "config")
	Config:addParam("combo", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	Config:addParam("harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("A"))
	Config:addParam("ult", "Use ultimate", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("S"))
	Config:permaShow("combo")
	Config:permaShow("harass")

	ts = TargetSelector(TARGET_PRIORITY, QRange, DAMAGE_PHYSICAL)
	ts.name = "Nami"
	Config:addTS(ts)
end

function OnTick()
	ts:update()

	if ts.target ~= nil then
		qPred = QPredic:GetPrediction(ts.target)
		rPred = RPredic:GetPrediction(ts.target)
	end

	if Config.combo then
		Combo()
	end

	if Config.harass then
		Harass()
	end

	if Config.ult then
		Ultimate()
	end
end

function Combo()
	if ts.target ~= nil then
		if qPred ~= nil then
			if myHero:CanUseSpell(_Q) == READY and GetDistance(qPred) <= QRange then
				if VIP_USER and QPredic:GetHitChance(ts.target) > 0.6 then
					CastSpell(_Q, qPred.x, qPred.z)
				elseif not VIP_USER then
					CastSpell(_Q, qPred.x, qPred.z)
				end
			end
		end

		if myHero:CanUseSpell(_W) == READY and GetDistance(ts.target) <= WRange then
			CastSpell(_W, ts.target)
		end
	end
end

function Harass()
	if ts.target ~= nil then
		if myHero:CanUseSpell(_W) == READY and GetDistance(ts.target) <= WRange then
			CastSpell(_W, ts.target)
		end
	end
end

function Ultimate()
	if ts.target ~= nil then
		if rPred ~= nil then
			if myHero:CanUseSpell(_R) == READY and GetDistance(rPred) <= RRange then
				if VIP_USER and RPredic:GetHitChance(ts.target) > 0.6 then
					CastSpell(_R, rPred.x, rPred.z)
				elseif not VIP_USER then
					CastSpell(_R, rPred.x, rPred.z)
				end
			end
		end
	end
end

function OnDraw()
	if myHero:CanUseSpell(_Q) then
		DrawCircle(myHero.x, myHero.y, myHero.z, 850, 0xFF0000)
	end
end