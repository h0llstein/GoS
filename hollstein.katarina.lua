local ver = "1.0"
class "Katarina"

function AutoUpdate(data)
	if tonumber(data) > tonumber(ver) then
		PrintChat("New version found!" .. data)
		PrintChat("Downloading update, please wait ...")

DownloadFileAsync("https://github.com/h0llstein/GoS/blob/master/hollstein.katarina.lua",
SCRIPT_PATH .. "hollstein.katarina", function() PrintChat("Update Done ! Please 2x F6!") return end)
	else
		PrintChat("No updates available!")
	end
end

GetWebResultAsync("https://github.com/h0llstein/GoS/blob/master/hollstein.katarina.lua", AutoUpdate)

local champ = {"Katarina"}
if not table.contains(champ, myHero.CharName) then print ("" ..GetObjectName(myHero).. "is not supported!")return end

require("DamageLib")
require("OpenPredict")
	function function_name(Katarina)
		print("Hollstein.Katarina loaded, enjoy your game")
		self.Spells = {
				Q = {range = 625, delay = 0.25},
				W = {range = 0, delay = 0.25,},
				E = {range = 725, delay = 0.25,},
				R = {range = 550, delay = 0.25},
	}
self:Menu()
OnTick(function() self:Tick() end)
OnDraw(function() self:Draw() end)

end

function Katarina:Menu()
			self.Katarina = Menu("Katarina-Hollstein", "Katarina-Hollstein")

			self.Katarina:SubMenu("Combo", "Combo Settings")
			self.Katarina.Combo:Boolean("Q", "Use Q", true)
			self.Katarina.Combo:Boolean("W", "Use W", true)
			self.Katarina.Combo:Boolean("E", "use E", true)
			self.Katarina.Combo:Boolean("R", "use R", true)
			self.Katarina.Combo:Boolean("RK", "Only use R if killable", true)
			self.Katarina.Combo:Boolean("RC", "Don't cancel R", true)
			self.Katarina.Combo:Boolean("Kill", "Only Combo if killable", false)
			self.Katarina:SubMenu("Harass", "Harass Settings")
			self.Katarina.Harass:Boolean("Q", "Use Q", true)

			self.Katarina:SubMenu("LaneClear", "Lane Clear Settings")
			self.Katarina.LaneClear:Boolean("Q", "Use Q", true)
			self.Katarina.LaneClear:Boolean("W", "Use W", true)
			self.Katarina.LaneClear:Boolean("E", "Use E", true)

			self.Katarina:SubMenu("LastHit", "LastHit Settings")
			self.Katarina.LastHit:Boolean("Q", "Use Q", false)

			self.Katarina:SubMenu("Ks", "KillSteal Settings")
			self.Katarina.Ks:Boolean("Q", "Use Q", true)
			self.Katarina.Ks:Boolean("E", "Use E", true)
			self.Katarina.Ks:Boolean("Recall", "Don't Ks during Recall", true)
			self.Katarina.Ks:Boolean("Disabled", "Don't Ks", false)

			self.Katarina:SubMenu("Draw", "Drawing Settings")
			self.Katarina.Draw:Boolean("Q", "Draw Q", true)
			self.Katarina.Draw:Boolean("W", "Draw W", true)
			self.Katarina.Draw:Boolean("E", "Draw E", true)
			self.Katarina.Draw:Boolean("R", "Draw R", true)
			self.Katarina.Draw:Boolean("AA", "Draw AutoAttack", true)
	-- body
end

local inUlt = false
local dagger = {}
local daggerHitPos = {}
local resetAble = {}
local animationCancel = {}
local kataCounter = 0
local killablewithR = false

OnProcessSpell(function(unit,spell)
	if unit == myHero and spell.name == "KatarinaR" then
		inUlt = true
	end
end)

OnUpdateBuff(function(unit,buff)
	if unit == myHero and buff.Name == "katarinasound" then
		inUlt =true
	end
end)

onRemoveBuff(function(unit,buff)
	if unit == myHero and buff.Name == "katarinasound" then
		inUlt = false
	end
end)

onIssueOrder(function(orderProc)
	if (orderProc.flag == 2 or orderProc.flag == 3) and inUlt == true and ValidTarget(GetCurrentTarget(),550) and self.Katarina.Combo.RC:Value() then
		BlockOrder()
	end
end)

OnSpellCast(function(castProc)
	if inUlt == true and castProc.spellID == 1 and self.Katarina.Combo.RC:Value() then
		BlockCast()
	end
end)

OnCreateObj(function(o)
	if GetDistance(o) < 2500 then
		if o.name == "Katarina_Base_W_mis.troy" and GetDistance(o) < 100 then
			table.insert(dagger, o)
		end
		if o.name == "Katarina_Base_W_Indicator_Ally.troy" then
			table.insert(daggerHitPos, o)
			local delay = 0.2
			if GetDistance(o) < 50 then
				delay = 0
			end
			DelayAction(function()
				table.insert(resetAble, o)
			end,1.1 - delay)
		end
	end
end)

OnDeleteObj(function(o)
	if o.name == "Katarina_Base_W_mis.troy" then
		for i,v in pairs(dagger) do
			if GetNetworkID(v) == GetNetworkID(o) then
				table.remove(dagger,i)
			end
		end
	end
	if o.name == "Katarina_Base_W_Indicator_Ally.troy" then
		for i,v in pairs(resetAble) do
			if GetNetworkID(v) == GetNetworkID(o) then
				table.remove(resetAble,i)
			end
		end
		for i,v in pairs(daggerHitPos) do
			if GetNetworkID(v) == GetNetworkID(o) then
				table.remove(daggerHitPos,i)
			end
		end
	end
end)

function Katarina:Draw()
			if self.Katarina.Draw.Q:Value() then
				DrawCircle(myHero, 625, 0, 150, GoS.White)
			end
			if self.Katarina.Draw.E:Value() then
				DrawCircle(myHero, 725, 0, 150, GoS.White)
			end
			if self.Katarina.Draw.AA:Value() then
				DrawCircle(myHero, 125, 0, 150, GoS.White)
			end
			if self.Katarina.Draw:R:Value() then
				DrawCircle(myHero, 550, 0, 150, GoS.White)
			end
		end

KatarinaKillable(function(target)
	killable = "Not killable"
	if Ready(_E) and Ready(_Q) and Ready(_W) and self.Katarina.Combo.R:Value() and Ready(_R) and GetCurrentHP(target) < getdmg("E", target, myHero) + getdmg("Q", target, myHero) + getdmg("W", target, myHero) + getdmg("R", target, myHero) then
		killable = "Killable with R"
	end
	if Ready(_E) and Ready(_Q) and Ready(_W) and GetCurrentHP(target) < getdmg("E", target, myHero) + getdmg("Q", target, myHero) + getdmg("W", target, myHero) then
		killable = "Killable"
	end
	if Ready(_Q) and Ready (_W) and not Ready(_E) and GetCurrentHP(target) < getdmg("E", target, myHero) + getdmg("Q", target, myHero) + getdmg("W", target, myHero) then
		killable = "Killable if E ready"
	end
	if Ready(_Q) and Ready(_E) and not Ready(_W) and GetCurrentHP(target) < getdmg("E", target, myHero) + getdmg("Q", target, myHero) + getdmg("W", target, myHero) then
		killable = "Killable if W ready"
	end
	if Ready(_E) and Ready(_W) and not Ready(_Q) and GetCurrentHP(target) < getdmg("E", target, myHero) + getdmg("Q", target, myHero) + getdmg("W", target, myHero) then
		killable = "Killable if Q ready"
	end
	return killable
end)
	


function Katarina:Tick()	
	target = GetCurrentTarget()
	if Mode == "Combo" then
		if self.Katarina.Combo.Kill:Value() and KatarinaKillable(target) == "Killable" or KatarinaKillable(target) == "Killable with R" then
			if self.Katarina.Combo.E:Value() then
				if self.Katarina.Combo.Q:Value() then
					if self.Katarina.Combo.W:Value() then
						
					end
				end
			end
		end
	end