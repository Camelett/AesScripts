-- AesSivir 0.3 by Puze aka Bestplox. Use this script with Sida's auto carry and AutoBarrier

if myHero.charName ~= "Sivir" then return end

-- PREDICTION
local QPredic = TargetPrediction(1200, 300, 200)

-- MISC
local ignite = nil
local IREADY = false

function OnLoad()
	PrintChat(" >> Sivir combo loaded!")
	Config = scriptConfig("Sivir combo", "Configcombo")
	Config:addParam("combo", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	Config:addParam("harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, 65)
	Config:addParam("ult", "Use ult in combo", SCRIPT_PARAM_ONOFF, false)
	Config:addParam("ignite", "Use ignite when killable", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("draw", "Draw circles", SCRIPT_PARAM_ONOFF, true)

	Config:permaShow("combo")
	ts = TargetSelector(TARGET_LOW_HP, 1200, DAMAGE_PHYSICAL)
	ts.name = "Sivir"
	Config:addTS(ts)
end

function OnTick()
	ts:update()

	if Config.combo then
		Combo()
	end

	if Config.harass then
		Harass()
	end

	if Config.ignite then
		Ignite()
	end
end

function OnDraw()
	if Config.draw then
		if myHero:CanUseSpell(_Q) == READY then
			DrawCircle(myHero.x, myHero.y, myHero.z, 1100, 0xFF0000)
		end
	end
end

function Combo()
	if ts.target ~= nil then

		--R
		if Config.ult and myHero:CanUseSpell(_R) == READY then
			CastSpell(_R)
		end

		-- Q
		QPredict = QPredic:GetPrediction(ts.target)
		if myHero:CanUseSpell(_Q) == READY and QPredict ~= nil and GetDistance(QPredict) <= 1200 then
			CastSpell(_Q, QPredict.x, QPredict.z)
		end

		-- W
		if myHero:CanUseSpell(_W) == READY then
			CastSpell(_W)
		end
	end
end

function Ignite()
	-- Ignite
	if Config.ignite then
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
end

function Harass()
	QPredict = QPredic:GetPrediction(ts.target)
	if myHero:CanUseSpell(_Q) == READY and QPredict ~= nil and GetDistance(QPredict) <= 1200 then
		CastSpell(_Q, QPredict.x, QPredict.z)
	end
end