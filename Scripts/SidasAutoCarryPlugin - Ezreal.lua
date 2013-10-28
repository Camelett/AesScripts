-- Variables --
local Target = nil
local Config = AutoCarry.PluginMenu

-- Skills information --
local QRange, WRange, RRange = 1150, 1050, 2000
local QSpeed, WSpeed, RSpeed = 2.0, 1.6, 2.0
local QDelay, WDelay, RDelay = 251, 250, 1000
local QWidth, WWidth, RWidth = 80, 80, 160

-- Skills Table --
local SkillQ = {spellKey = _Q, range = QRange, speed = QSpeed, delay = QDelay, width = QWidth, minions = true }
local SkillW = {spellKey = _W, range = WRange, speed = WSpeed, delay = WDelay, width = WWidth, minions = false }
local SkillR = {spellKey = _R, range = RRange, speed = RSpeed, delay = RDelay, width = RWidth, minions = false }


-- Plugin functions --
function PluginOnLoad()
	if AutoCarry.Skills and VIP_USER then IsSACReborn = true else IsSACReborn = false end
	
	if IsSACReborn then
		AutoCarry.Crosshair:SetSkillCrosshairRange(RRange)
		AutoCarry.Skills:DisableAll()
	else
		AutoCarry.SkillsCrosshair.range = RRange
	end

	Menu()
end

function PluginOnTick()
	Target = AutoCarry.GetAttackTarget()

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
	if AutoCarry.MainMenu.MixedMode and CheckManaHarass() then
		CastQ()
		CastW()
	end
end

function CastQ()
	if Target ~= nil and GetDistance(Target) < QRange then
		if Config.ComboOptions.ComboQ or Config.HarassOptions.HarassQ then
			AutoCarry.CastSkillshot(SkillQ, Target)
		end
	end
end

function CastW()
	if Target ~= nil and GetDistance(Target) < WRange then
		if Config.ComboOptions.ComboW or Config.HarassOptions.HarassW then
			AutoCarry.CastSkillshot(SkillW, Target)
		end
	end
end

function CastR()
	if Target ~= nil then
		RDmg = getDmg("R", Target, myHero)
		if GetDistance(Target) < RRange and RDmg > Target.health then
			if Config.ComboOptions.ComboR or Config.FinisherOptions.FinisherR then
				AutoCarry.CastSkillshot(SkillR, Target)
			end
		end
	end
end

function CheckManaHarass()
	if myHero.mana > myHero.maxMana * (Config.HarassOptions.HarassMana / 100) then
		return true
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
	Config.HarassOptions:addParam("HarassMana", "Lowest mana percent to harass", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
	Config:addSubMenu("Finisher Options","FinisherOptions")
	Config.FinisherOptions:addParam("FinisherR", "Use Trueshot Barrage", SCRIPT_PARAM_ONOFF, true)
	Config:addSubMenu("Drawing Options","DrawingOptions")
	Config.DrawingOptions:addParam("DrawQ", "Draw Mystic Shot", SCRIPT_PARAM_ONOFF, true)
	Config.DrawingOptions:addParam("DrawR", "Draw Trueshot Barrage", SCRIPT_PARAM_ONOFF, true)
end
