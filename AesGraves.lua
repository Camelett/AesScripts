--[[
	AesGraves Version: 1.0 By Bestplox
]]--

if myHero.charName ~= "Graves" then return end

--Prediction
local QPredic = TargetPrediction(950, 2.0 ,266)
local RPredic = TargetPrediction(1000, 2.1 ,219)

-- Misc
local ignite = nil
local IREADY = false
local version = 1.0


function OnLoad()
	PrintChat(" >> AesGraves Loaded!")
	Config = scriptConfig("Graves combo", "ComboConfig")
	Config:addParam("combo", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	Config:addParam("harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, 65)
	Config:addParam("ult", "Use ultimate", SCRIPT_PARAM_ONKEYDOWN, false, 83)
	Config:addParam("ultkill", "Ultimate when killable" ,SCRIPT_PARAM_ONOFF, true)
	Config:addParam("autoignite", "Use ignite", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("circles", "Draw circles", SCRIPT_PARAM_ONOFF, false)
	
	Config:permaShow("combo")
	Config:permaShow("harass")
	
	ts = TargetSelector(TARGET_LOW_HP, 1000, DAMAGE_PHYSICAL)
	ts.name = "Graves"
	Config:addTS(ts)
	
	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then 
		ignite = SUMMONER_1
    elseif 
    	myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then 
    	ignite = SUMMONER_2 
    end
end

function OnTick()
	ts:update()
	
	if Config.combo then
		Combo()
	end
	
	if Config.harass then
		Harass()
	end
	
	if Config.ult then
		Ultimate()
	end
	
	if Config.autoignite then
		Ignite()
	end
end

function Combo()
	if Config.combo and ts.target ~= nil then
		if myHero:CanUseSpell(_W) == READY and GetDistance(ts.target) <= 950 then
			CastSpell(_W, ts.target.x, ts.target.z)
		end
	
		QPredict = QPredic:GetPrediction(ts.target)
		if myHero:CanUseSpell(_Q) == READY and QPredict ~= nil and GetDistance(QPredict) <= 950 then
			CastSpell(_Q, QPredict.x, QPredict.z)
		end
		
		RDmg = (getDmg("R", ts.target, myHero) - 100)
		RPredict = RPredic:GetPrediction(ts.target)
		if myHero:CanUseSpell(_R) == READY and Config.ultkill and RDmg >= ts.target.health and RPredict ~= nil and GetDistance(ts.target) <= 1000 then
			CastSpell(_R, RPredict.x , RPredict.z)
		end
	end
end

function Harass()
	if Config.harass and ts.target ~= nil then
		QPredict = QPredic:GetPrediction(ts.target)
		if myHero:CanUseSpell(_Q) == READY and QPredict ~= nil and GetDistance(QPredict) <= 950 then
			CastSpell(_Q, QPredict.x, QPredict.z)
		end
	end
end

function Ultimate()
	if Config.ult and ts.target ~= nil then
		RPredict = RPredic:GetPrediction(ts.target)
		if myHero:CanUseSpell(_R) == READY and RPredict ~= nil and GetDistance(ts.target) <= 1000 then
			CastSpell(_R, RPredict.x , RPredict.z)
		end	
	end
end

function Ignite()
 	if Config.autoignite then
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

function OnDraw()
	if Config.circles then
		if myHero:CanUseSpell(_Q) == READY then
			DrawCircle(myHero.x, myHero.y, myHero.z, 950, 0xFF0000)
		end
	end
end