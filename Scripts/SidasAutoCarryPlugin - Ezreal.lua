-- Variables --
local Target
local Config = AutoCarry.PluginMenu
local IsReborn = false

-- Skills information --
local QRange, WRange, RRange = 1100, 1050, 2000
local QSpeed, WSpeed, RSpeed = 2.0, 1.6, 2.0
local QDelay, WDelay, RDelay = 251, 250, 1000
local QWidth, WWidth, RWidth = 70, 90, 150

-- Skills Table --
if IsReborn then
	SkillQ = AutoCarry.Skills:NewSkill(false, _Q, QRange, "Mystic Shot", AutoCarry.SPELL_LINEAR_COL, 0, false, false, QSpeed, QDelay, QWidth, true)
	SkillW = AutoCarry.Skills:NewSkill(false, _W, WRange, "Essence Flux", AutoCarry.SPELL_LINEAR, 0, false, false, WSpeed, WDelay, WWidth, false)
	SkillR = AutoCarry.Skills:NewSkill(false, _R, RRange, "Trueshot Barrage", AutoCarry.SPELL_LINEAR, 0, false, false, RSpeed, RDelay, RWidth, false)
else
	SkillQ = {spellKey = _Q, range = QRange, speed = QSpeed, delay = QDelay, width = QWidth, minions = true }
	SkillW = {spellKey = _W, range = WRange, speed = WSpeed, delay = WDelay, width = WWidth, minions = false }
	SkillR = {spellKey = _R, range = RRange, speed = RSpeed, delay = RDelay, width = RWidth, minions = false }
end

-- Plugin functions --
function PluginOnLoad()
	if AutoCarry.Skils then 
		IsReborn = true 
	else 
		IsReborn = false 
	end

	if IsReborn then
		AutoCarry.Crosshair:SetSkillCrosshairRange(RRange)
		AutoCarry.Skills:DisableAll()
	else
		AutoCarry.SkillsCrosshair.range = RRange
	end

	Menu()
end

function PluginOnTick()
	Target = GetTarget()

	Combo()
	Harass()
end

function PluginOnDraw()
	if Config.DrawingOptions.DrawQ then
		DrawCircle(myHero.x, myHero.y, myHero.z, QRange, 0xFFFFFF)
	end

	if Config.DrawingOptions.DrawR then
		DrawCircle(myHero.x, myHero.y, myHero.z, RRange, 0xFFFFFF)
	end
end

-- Spells funtions --
function Combo()
	if AutoCarry.MainMenu.AutoCarry then
	CastQ()
	CastW()
	CastR()
	end
end

function Harass()
	if AutoCarry..MixedMode then
	CastQ()
	CastW()
	end
end

function CastQ()
	if Target ~= nil and GetDistance(Target) < QRange then
		if Config.ComboOptions.ComboQ or Config.HarassOptions.HarassQ then
			if IsReborn then	
				SkillQ:Cast(Target)
			else
				AutoCarry.CastSkillshot(SkillQ, Target)
			end
		end
	end
end

function CastW()
	if Target ~= nil and GetDistance(Target) < WRange then
		if Config.ComboOptions.ComboW or Config.HarassOptions.HarassW then
			if IsReborn then	
				SkillW:Cast(Target)
			else
				AutoCarry.CastSkillshot(SkillW, Target)
			end
		end
	end
end

function CastR()
	if Target ~= nil then
		RDmg = getDmg("R", Target, myHero)
		if GetDistance(Target) < RRange and RDmg > Target.health then
			if Config.ComboOptions.ComboR or Config.FinisherOptions.FinisherR then
				if IsReborn then	
					SkillR:Cast(Target)
				else
					AutoCarry.CastSkillshot(SkillR, Target)
				end
			end
		end
	end
end

-- Other functions
function Farm()

end

function GetTarget()
    if IsReborn then
        return AutoCarry.Crosshair:GetTarget()
    else
        return AutoCarry.GetAttackTarget()
    end
end

-- Menu --
function Menu()
	Config:addSubMenu("Combo Options", "ComboOptions")
	Config.ComboOptions:addParam("ComboQ", "Use Mystic Shot", SCRIPT_PARAM_ONOFF, true)
	Config.ComboOptions:addParam("ComboW", "Use Essence Flux", SCRIPT_PARAM_ONOFF, true)
	Config.ComboOptions:addParam("ComboR", "Use Trueshot Barrage", SCRIPT_PARAM_ONOFF, true)
	Config:addSubMenu("Harass Options", "HarassOptions")
	Config.HarassOptions:addParam("HarassQ", "Use Mystic Shot", SCRIPT_PARAM_ONOFF, true)
	Config.HarassOptions:addParam("HarassW", "Use Essence Flux", SCRIPT_PARAM_ONOFF, true)
	Config:addSubMenu("Finisher Options","FinisherOptions")
	Config.FinisherOptions:addParam("FinisherR", "Use Trueshot Barrage", SCRIPT_PARAM_ONOFF, true)
	Config:addSubMenu("Drawing Options","DrawingOptions")
	Config.DrawingOptions:addParam("DrawQ", "Draw Mystic Shot", SCRIPT_PARAM_ONOFF, true)
	Config.DrawingOptions:addParam("DrawR", "Draw Trueshot Barrage", SCRIPT_PARAM_ONOFF, true)
end

--UPDATEURL=
--HASH=56062607C8057C3C5CCDFE56837F99F9
