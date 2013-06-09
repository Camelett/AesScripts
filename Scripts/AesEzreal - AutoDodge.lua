--[[
Script: AesEzreal
Author: Bestplox
Version: 1.1
--]]

require "MapPosition"

if myHero.charName ~= "Ezreal" then return end

-- Prediction
if VIP_USER then
	require "Collision"
	Coll = Collision(1100, 2000, 0.251, 125)
	QPredic = TargetPredictionVIP(QRange, QSpeed, 0.251)
	WPredic = TargetPredictionVIP(WRange, 1600, 0.25)
	RPredic = TargetPredictionVIP(RRange, 1700, 0.265)
else
	QPredic = TargetPrediction(1100, 2.0, 251)
	WPredic = TargetPrediction(1000, 1.6, 250)
	RPredic = TargetPrediction(2000, 1.7, 265)
end
-- Collision
local Coll = Collision(1100, 2000, 0.251, 125)

-- Constants
local QRange = 1100
local WRange = 1000
local RRange = 2000

local QSpeed = 2000

-- Variables
local ignite = nil
local IREADY = false

-- Avoid
ticke = GetTickCount()
bDodged = false
local mapPosition = MapPosition()
local spellList =
{
	{charName = "Taric",            spellName = "Dazzle",                                   missileName = "Dazzle_mis.troy",                                radius = 0,     delay = nil,    spellType = "StunSnare"         }, -- Stun
	{charName = "Sion",             spellName = "CrypticGaze",                              missileName = "CrypticGaze_mis.troy",                   radius = 0,     delay = nil,    spellType = "StunSnare"         },
	{charName = "Leona",            spellName = "LeonaSolarFlare",                  missileName = nil,                                                              radius = 350,   delay = 0,              spellType = "StunSnare"         },
	{charName = "Pantheon",         spellName = "Pantheon_LeapBash",                missileName = nil,                                                              radius = 0,     delay = 125,    spellType = "StunSnare"         },
	{charName = "Renekton",         spellName = "RenektonPreExecute",               missileName = nil,                                                              radius = 0,             delay = 0,              spellType = "StunSnare"         },
	{charName = "Darius",           spellName = "DariusAxeGrabCone",                missileName = nil,                                                              radius = 550,   delay = 0,              spellType = "StunSnare"         },
	{charName = "Annie",            spellName = "InfernalGuardian",                 missileName = nil,                                                              radius = 250,   delay = 0,              spellType = "StunSnare"         },
	{charName = "Amumu",            spellName = "CurseoftheSadMummy",               missileName = nil,                                                              radius = 550,   delay = 0,              spellType = "StunSnare"         },
	{charName = "Diana",            spellName = "DianaVortex",                              missileName = nil,                                                              radius = 250,   delay = 0,              spellType = "StunSnare"         },
	{charName = "Riven",            spellName = "RivenMartyr",                              missileName = nil,                                                              radius = 125,   delay = 0,              spellType = "StunSnare"         },
	{charName = "Orianna",          spellName = "OrianaDetonateCommand",    missileName = nil,                                                              radius = 325,   delay = 0,              spellType = "StunSnare"         },
	{charName = "TwistedFate",      spellName = "PickaCard_yellow_mis.troy",missileName = nil,                                                              radius = 0,     delay = 0,              spellType = "StunSnare"         },
	{charName = "Irelia",           spellName = "IreliaEquilibriumStrike",  missileName = nil,                                                              radius = 0,     delay = 200,    spellType = "StunSnare"         },
	{charName = "Maokai",           spellName = "MaokaiUnstableGrowth",     missileName = nil,                                                              radius = 0,     delay = 0,              spellType = "StunSnare"         },
	{charName = "Ryze",             spellName = "RunePrison",                               missileName = nil,                                                              radius = 0,     delay = 0,              spellType = "StunSnare"         }, -- Knockback
	{charName = "Tristana",         spellName = "BusterShot",                               missileName = "BusterShot_mis.troy",                    radius = 0,     delay = nil,    spellType = "Knockback"         },
	{charName = "Gragas",           spellName = "GragasExplosiveCask",              missileName = nil,                                                              radius = 200,   delay = 0,              spellType = "Knockback"         },
	{charName = "Alistar",          spellName = "Headbutt",                                 missileName = nil,                                                              radius = 0,     delay = 200,    spellType = "Knockback"         },
	{charName = "LeeSin",           spellName = "BlindMonkRKick",                   missileName = nil,                                                              radius = 188,   delay = 200,    spellType = "Knockback"         },
	{charName = "Janna",            spellName = "ReapTheWhirlwind",                 missileName = nil,                                                              radius = 363,   delay = 0,              spellType = "Knockback"         },
	{charName = "Poppy",            spellName = "PoppyHeroicCharge",                missileName = nil,                                                              radius = 0,     delay = 200,    spellType = "Knockback"         },
	{charName = "Vayne",            spellName = "VayneCondemn",                     missileName = nil,                                                              radius = 0,     delay = 200,    spellType = "Knockback"         },
	{charName = "Skarner",          spellName = "SkarnerImpale",                    missileName = nil,                                                              radius = 0,     delay = 0,              spellType = "Suppress"          }, -- Suppress
	{charName = "Malzahar",         spellName = "AlZaharNetherGrasp",               missileName = nil,                                                              radius = 0,     delay = 0,              spellType = "Suppress"          },
	{charName = "Warwick",          spellName = "InfiniteDuress",                   missileName = nil,                                                              radius = 0,     delay = 0,              spellType = "Suppress"          },
	{charName = "Urgot",            spellName = "UrgotSwap2",                               missileName = nil,                                                              radius = 0,     delay = 0,              spellType = "Suppress"          },
	{charName = "Malphite",         spellName = "UFSlash",                                  missileName = nil,                                                              radius = 163,   delay = 200,    spellType = "Knockup"           }, -- Knockup
	{charName = "Alistar",          spellName = "Pulverize",                                missileName = nil,                                                              radius = 183,   delay = 0,              spellType = "Knockup"           },
	{charName = "Vi",                       spellName = "ViR",                                              missileName = nil,                                                              radius = 0,     delay = 200,    spellType = "Knockup"           },
	{charName = "FiddleSticks", spellName = "Terrify",                                      missileName = nil,                                                              radius = 0,     delay = 0,              spellType = "Fear"                      }, -- Fear
	{charName = "Nunu",             spellName = "IceBlast",                                 missileName = "yeti_iceBlast_mis.troy",                 radius = 0,     delay = nil,    spellType = "Slow"                      }, -- Slow
	{charName = "Malphite",         spellName = "SeismicShard",                     missileName = "SeismicShard_mis.troy",                  radius = 0,     delay = nil,    spellType = "Slow"                      },
	{charName = "JarvanIV",         spellName = "JarvanIVGoldenAegis",              missileName = nil,                                                              radius = 300,   delay = 0,              spellType = "Slow"                      },
	{charName = "XinZhao",          spellName = "XenZhaoSweep",                     missileName = nil,                                                              radius = 0,     delay = 150,    spellType = "Slow"                      },
	{charName = "Rengar",           spellName = "RengarE",                                  missileName = "missing_instant.troy",                   radius = 0,     delay = nil,    spellType = "Slow"                      },
	{charName = "Shaco",            spellName = "TwoShivPoison",                    missileName = "JesterDagger.troy",                              radius = 0,             delay = nil,    spellType = "Slow"                      },
	{charName = "LeBlanc",          spellName = "LeblancChaosOrb",                  missileName = "leBlanc_ChaosOrb_mis.troy",              radius = 0,     delay = nil,    spellType = "Silence"           }, -- Silence
	{charName = "Kassadin",         spellName = "NullLance",                                missileName = "Null_Lance_mis.troy",                    radius = 0,     delay = nil,    spellType = "Silence"           },
	{charName = "FiddleSticks", spellName = "FiddlesticksDarkWind",         missileName = "DarkWind_mis.troy",                              radius = 0,     delay = nil,    spellType = "Silence"           },
	{charName = "Talon",            spellName = "TalonCutthroat",                   missileName = nil,                                                              radius = 0,     delay = 0,              spellType = "Silence"           },
	{charName = "Rammus",           spellName = "PuncturingTaunt",                  missileName = nil,                                                              radius = 0,     delay = 0,              spellType = "Taunt"             }, -- Taunt
	{charName = "Shen",             spellName = "ShenShadowDash",                   missileName = nil,                                                              radius = 100,   delay = 0,              spellType = "Taunt"             },
	{charName = "Galio",            spellName = "GalioIdolOfDurand",                missileName = nil,                                                              radius = 600,   delay = 0,              spellType = "Taunt"             },
	{charName = "Teemo",            spellName = "BlindingDart",                     missileName = "BlindShot_mis.troy",                     radius = 0,     delay = nil,    spellType = "Blind"             },  -- Blind
	{charName = "Veigar",           spellName = "VeigarPrimordialBurst",    missileName = "permission_mana_flare_mis.troy", radius = 0,     delay = nil,    spellType = "MassiveDamage"     }, -- Massive Damage
	{charName = nil,                        spellName = "DeathfireGrasp",                   missileName = "missile",                                                radius = 0,     delay = nil,    spellType = "MassiveDamage"     },
	{charName = "Lux",                      spellName = "LuxMaliceCannon",                  missileName = nil,                                                              radius = 0,     delay = 250,    spellType = "MassiveDamage"     },
	{charName = "Vladimir",         spellName = "VladimirHemoplague",               missileName = nil,                                                              radius = 175,   delay = 0,              spellType = "MassiveDamage"     },
	{charName = "XinZhao",          spellName = "XenZhaoParry",                     missileName = nil,                                                              radius = 187.5, delay = 0,              spellType = "MassiveDamage"     },
	{charName = "Graves",           spellName = "GravesChargeShot",                 missileName = nil,                                                              radius = 0,     delay = 200,    spellType = "MassiveDamage"     },
	{charName = "Garen",            spellName = "GarenJustice",                     missileName = nil,                                                              radius = 0,     delay = 250,    spellType = "MassiveDamage"     },
	{charName = "Evelynn",          spellName = "EvelynnR",                                 missileName = nil,                                                              radius = 250,   delay = 0,              spellType = "MassiveDamage"     },
	{charName = "Darius",           spellName = "DariusExecute",                    missileName = nil,                                                              radius = 0,     delay = 300,    spellType = "MassiveDamage"     },
	{charName = "Zed",                      spellName = "ZedUlt",                                   missileName = "Zed_R_Dash.troy",                                radius = 0,     delay = nil,    spellType = "MassiveDamage"     }
}
-- Global variables
local targetedDistanceBuffer = 75*75
local useSpell
-- Spell variables
local spellCastTick = 0
local minDelay = 0
local maxDelay = 2000
-- Particle variables
local particleFound
local spellParticle = {valid = false}
local maxParticleDistance = 250*250

function OnLoad()
	PrintChat(">> AesEzreal Loaded!")
	Config = scriptConfig("AesEzreal", "config")
	Config:addParam("combo", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	Config:addParam("harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, 65)
	Config:addParam("ultimate", "Ultimate", SCRIPT_PARAM_ONKEYDOWN, false, 82)
	Config:addParam("ultimatecombo", "Use ultimate in combo", SCRIPT_PARAM_ONOFF, false)
	Config:addParam("ignite", "Use ignite if killable", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("w", "Use W in combo", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("draw", "Draw circles", SCRIPT_PARAM_ONOFF, true)
	Config:permaShow("combo")
	Config:permaShow("harass")

	DodgeMenu()
	CleanTable()
	if myHero.charName == "Ezreal" then
		useSpell = _E
	end

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
	actualDelay = GetTickCount() - spellCastTick
	shouldCast = (actualDelay >= minDelay and actualDelay <= maxDelay) or (spellParticle and spellParticle.valid and GetDistanceSqr(spellParticle) <= maxParticleDistance)


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

	if shouldCast and CanCast(useSpell) then
		Dodge()
	end

	if not CanCast(useSpell) then
		bDodged = false
	end

	if GetTickCount()-ticke > 50 then
		ticke = GetTickCount()
		if CanCast(useSpell) then
			for j = 1, heroManager.iCount, 1 do
				local enemyhero = heroManager:getHero(j)
				if ValidTarget(enemyhero, 175) and GetDistance(enemyhero) < 175 then
					Dodge()
					return
				end
			end
		end
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
		RDmg = (getDmg("R", ts.target, myHero) - 100)
		if myHero:CanUseSpell(_R) == READY and rPred ~= nil and Config.ultimate and GetDistance(rPred) <= 2000 and ts.target.health < RDmg then
			if VIP_USER  then
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

function findClosestEnemy(testPoint)
	local closestEnemy = nil
	local currentEnemy = nil
	for i=1, heroManager.iCount do
		currentEnemy = heroManager:GetHero(i)
		if currentEnemy.team ~= myHero.team and ValidTarget(currentEnemy) then
			if closestEnemy == nil then
				closestEnemy = currentEnemy
			elseif GetDistance(testPoint, currentEnemy) < GetDistance(testPoint, closestEnemy) then
				closestEnemy = currentEnemy
			end
		end
	end
	return closestEnemy
end

function Dodge()
	if bDodged then return end

	actualDelay = maxDelay + 1
	spellParticle = nil

	local closest = findClosestEnemy(myHero)
	if ValidTarget(closest) then
		-- scan for E safe place
		local maxL = 0
		local evadePoint
		local N = 36
		for i = 1, N do
			local testPoint = { x = myHero.x + 475*math.cos(2*i*math.pi / N), y = myHero.y, z = myHero.z + 475*math.sin(2*i*math.pi / N) }
			local closestEnemyToPoint = findClosestEnemy(testPoint)
			if GetDistance(testPoint, closestEnemyToPoint) > maxL and mapPosition:intersectsWall( Point(testPoint.x, testPoint.z) ) == false then
				maxL = GetDistance(testPoint, closestEnemyToPoint)
				evadePoint = testPoint
			end
		end
		CastSpell(_E, evadePoint.x, evadePoint.z)
		bDodged = true
	end
end

function OnProcessSpell(caster, spell)
	if ASAConfig.enabled then
		if caster.team ~= player.team and string.find(spell.name, "Basic") == nil then
			avoidSpell, spellRadius, spellDelay, particleName = GetSpellInfo(spell)
			if avoidSpell then
				if AffectsMe(spell, spellRadius) then
					if particleName then
						particleFound = particleName
					else
						spellCastTick = GetTickCount()
						minDelay = spellDelay
					end
				end
			end
		end
	end
end

function CanCast(Spell)
	return (player:CanUseSpell(Spell) == READY)
end

function IsOnEnemyTeam(charName)
	local onEnemyTeam = false
	local hero
	local i = 1
	while i <= heroManager.iCount and not onEnemyTeam do
		hero = heroManager:GetHero(i)
		if hero.team ~= player.team and hero.charName == charName then onEnemyTeam = true end
		i = i + 1
	end
	return onEnemyTeam
end

function CleanTable()
	local i = 1
	while i <= #spellList do
		if not IsOnEnemyTeam(spellList[i].charName) then table.remove(spellList, i)
		else i = i + 1
		end
	end
end

function CheckType(spellType)
	local type_enabled = false
	if spellType == "StunSnare" then
		type_enabled = ASAConfig.StunSnare
	elseif spellType == "Knockback" then
		type_enabled = ASAConfig.Knockback
	elseif spellType == "Knockup" then
		type_enabled = ASAConfig.Knockup
	elseif spellType == "Fear" then
		type_enabled = ASAConfig.Fear
	elseif spellType == "Slow" then
		type_enabled = ASAConfig.Slow
	elseif spellType == "Silence" then
		type_enabled = ASAConfig.Silence
	elseif spellType == "Taunt" then
		type_enabled = ASAConfig.Taunt
	elseif spellType == "Blind" then
		type_enabled = ASAConfig.Blind
	elseif spellType == "MassiveDamage" then
		type_enabled = ASAConfig.MassiveDamage
	end
	return type_enabled
end

function GetSpellInfo(spell)
	local detected = false
	local avoidSpell = false
	local radius
	local spellDelay
	local particleName
	local i = 1
	while i <= #spellList and not detected do
		if spellList[i].spellName == spell.name then
			detected = true
			radius = spellList[i].radius
			spellDelay = spellList[i].delay
			particleName = spellList[i].missileName
			avoidSpell = CheckType(spellList[i].spellType)
		end
		i = i + 1
	end
	return avoidSpell, radius, spellDelay, particleName
end

function AffectsMe(spell, spellRadius)
	local willAffectMe
	if spellRadius == 0 then
		willAffectMe = GetDistanceSqr(spell.endPos) <= targetedDistanceBuffer
	else
		willAffectMe = GetDistanceSqr(spell.endPos) <= spellRadius*spellRadius
	end
	return willAffectMe
end

function OnCreateObj(particle)
	if particle.team ~= player.team and particle.name == particleFound then
		spellParticle = particle
		particleFound = nil
	end
end

function DodgeMenu()
	ASAConfig = scriptConfig("Auto Spell Avoider", "ASA")
	ASAConfig:addParam("enabled", "Enabled", SCRIPT_PARAM_ONOFF, true)
	ASAConfig:addParam("StunSnare", "Avoid Stun/Snare", SCRIPT_PARAM_ONOFF, true)
	ASAConfig:addParam("Knockback", "Avoid Knockback", SCRIPT_PARAM_ONOFF, true)
	ASAConfig:addParam("Knockup", "Avoid Knockup", SCRIPT_PARAM_ONOFF, true)
	ASAConfig:addParam("Fear", "Avoid Fear", SCRIPT_PARAM_ONOFF, true)
	ASAConfig:addParam("Slow", "Avoid Slow", SCRIPT_PARAM_ONOFF, true)
	ASAConfig:addParam("Silence", "Avoid Silence", SCRIPT_PARAM_ONOFF, true)
	ASAConfig:addParam("Taunt", "Avoid Taunt", SCRIPT_PARAM_ONOFF, true)
	ASAConfig:addParam("Blind", "Avoid Blind", SCRIPT_PARAM_ONOFF, true)
	ASAConfig:addParam("MassiveDamage", "Avoid Mass Damage", SCRIPT_PARAM_ONOFF, true)
end

function OnDraw()
	if ts.target ~= nil then
		RDmg = getDmg("R", ts.target, myHero)
	end
	if Config.draw then
		if myHero:CanUseSpell(_Q) then
			DrawCircle(myHero.x, myHero.y, myHero.z, 1100, 0xFF0000)
		end
		if ts.target ~= nil and myHero:CanUseSpell(_R) and ts.target.team ~= myHero.team and not ts.target.dead and ts.target.visible and GetDistance(ts.target) <= RRange and GetDistance(ts.target) > 500 and ts.target.health < RDmg then
			DrawCircle(ts.target.x, ts.target.y, ts.target.z,100, 0xFF0000)
			DrawCircle(ts.target.x, ts.target.y, ts.target.z,150, 0xFF0000)
			DrawCircle(ts.target.x, ts.target.y, ts.target.z,200, 0xFF0000)
			DrawCircle(ts.target.x, ts.target.y, ts.target.z,300, 0xFF0000)
			DrawText("Press R to Snipe!!",50,520,100,0xFFFF0000)
			PrintFloatText(ts.target,0,"Ulti!!!")
		end
	end
end