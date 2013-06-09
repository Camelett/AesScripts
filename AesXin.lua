-- AesXin 1.0 by Bestplox

if myHero.charName ~= "XinZhao" then return end

-- ITEMS: Credits for Tux
local items =
{
    BRK = { id = 3153, range = 500, reqTarget = true, slot = nil },
    BWC = { id = 3144, range = 400, reqTarget = true, slot = nil },
    DFG = { id = 3128, range = 750, reqTarget = true, slot = nil },
    HGB = { id = 3146, range = 400, reqTarget = true, slot = nil },
    RSH = { id = 3074, range = 350, reqTarget = false, slot = nil },
    STD = { id = 3131, range = 350, reqTarget = false, slot = nil },
    TMT = { id = 3077, range = 350, reqTarget = false, slot = nil },
    YGB = { id = 3142, range = 350, reqTarget = false, slot = nil }
}

-- IGNITE
local ignite = nil
local IREADY = false

function OnLoad(...)
    PrintChat(" >> AesXin Loaded!")
    Config = scriptConfig("Xin Combo", "config")
    Config:addParam("combo", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32) -- SpaceBar
    Config:addParam("ult", "Use ultimate in combo", SCRIPT_PARAM_ONOFF, false)
    Config:addParam("chargeks", "Killsteal with charge", SCRIPT_PARAM_ONOFF, false)
    Config:addParam("autoignite", "Use ignite", SCRIPT_PARAM_ONOFF, true)
    Config:addParam("circles", "Draw Circles", SCRIPT_PARAM_ONOFF, false)
    Config:permaShow("combo")

    ts = TargetSelector(TARGET_LOW_HP, 600, DAMAGE_PHYSICAL, true)
    ts.name = "XinZhao"
    Config:addTS(ts)

    if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then
        ignite = SUMMONER_1
    elseif
    myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then
        ignite = SUMMONER_2
    end
end

function OnTick(...)
    ts:update()

    if Config.combo then
        Combo()
    end

    if Config.autoignite then
        Ignite()
    end

    if Config.chargeks then
        Killsteal()
    end
end

function Combo(...)
    if ts.target ~= nil then
        UseItems(ts.target)
        if myHero:CanUseSpell(_E) == READY and GetDistance(ts.target) <= 600 then
            CastSpell(_E, ts.target)
        end

        if myHero:CanUseSpell(_W) == READY then
            CastSpell(_W)
        end

        if myHero:CanUseSpell(_Q) == READY and GetDistance(ts.target) <= 600 then
            CastSpell(_Q)
        end

        if myHero:CanUseSpell(_R) == READY and Config.ult and GetDistance(ts.target) <= 200 then
            CastSpell(_R)
        end
    end
end

function Ignite(...)
    IREADY = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)
    if IREADY then
        local ignitedmg = 0
        for j = 1, heroManager.iCount, 1 do
            local enemyhero = heroManager:getHero(j)
            if ValidTarget(enemyhero, 600) then
                ignitedmg = 50 + 20 * myHero.level
                if enemyhero.health <= ignitedmg then
                    CastSpell(ignite, enemyhero)
                end
            end
        end
    end
end

function Killsteal(...)
    if ts.target ~= nil then
        RDmg = getDmg("E", ts.target, myHero)
        if myHero:CanUseSpell(_E) == READY and GetDistance(ts.target) <= 200 then
            CastSpell(_E)
        end
    end
end

function OnDraw(...)
    if Config.circles then
        if myHero:CanUseSpell(_E) == READY then
            DrawCircle(myHero.x, myHero.y, myHero.z, 600, 0xFFFFFF)
        end
        DrawCircle(myHero.x, myHero.y, myHero.z, 235, 0xFFFFFF)
    end
end

function UseItems(target)
    if target == nil then return end
    for _, item in pairs(items) do
        item.slot = GetInventorySlotItem(item.id)
        if item.slot ~= nil then
            if item.reqTarget and GetDistance(target) < item.range then
                CastSpell(item.slot, target)
            elseif not item.reqTarget then
                CastSpell(item.slot)
            end
        end
    end
end