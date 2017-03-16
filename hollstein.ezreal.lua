local ver = "1.0"
class "Ezreal"

function AutoUpdate(data)
	if tonumber(data) > tonumber(ver) then
		PrintChat("New version found!" .. data)
		PrintChat("Downloading update, please wait ...")

		DownloadFileAsync("https://github.com/h0llstein/GoS/blob/master/hollstein.ezreal.lua",
		SCRIPT_PATH .. "hollstein.ezreal.lua", function() PrintChat("Update Done ! Please 2x F6!") return end)
	else
		PrintChat("No updates available!")
	end
end

GetWebResultAsync("https://github.com/h0llstein/GoS/blob/master/hollstein.ezreal.lua", AutoUpdate)

local champ = { "Ezreal" }
local insert = table.insert
if not table.contains(champ, myHero.charName) then print("" .. GetObjectName(myHero) .. "is not supported!") return end

require("DamageLib")
require("OpenPredict")

function Mode()
	if _G.IOW_Loaded and IOW:Mode() then
		return IOW:Mode()
	elseif _G.PW_Loaded and PW:Mode() then
		return PW:Mode()
	elseif _G.DAC_Loaded and DAC:Mode() then
		return DAC:Mode()
	elseif _G.AutoCarry_Loaded and DACR:Mode() then
		return DACR:Mode()
	end
end

function Ezreal:_init()
	print("Hollstein.Ezreal loaded, enjoy your game")
	self.Spells = {
		Q = { range = 1150, delay = 0.25, speed = 2000, width = 30 },
		W = { range = 1000, delay = 0.25, speed = 1550, width = 80 },
		E = { range = 475, delay = 0.25, speed = math.huge, width = 750 },
		R = { range = 2000, delay = 1, speed = 2000, width = 40 },
	}
	self:Menu()
	OnTick( function() self:Tick() end)
	OnDraw( function() self:Draw() end)
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)

end

function Ezreal:Menu()
	self.Ezreal = Menu("Ezreal-Hollstein", "Ezreal-Hollstein")

	self.Ezreal:SubMenu("Combo", "Combo Settings")
	self.Ezreal.Combo:Boolean("Q", "Use Q", true)
	self.Ezreal.Combo:Boolean("W", "Use W", true)
	self.Ezreal.Combo:Boolean("E", "use E", false)
	self.Ezreal.Combo:Boolean("R", "use R", false)

	self.Ezreal:SubMenu("Harass", "Harass Settings")
	self.Ezreal.Harass:Boolean("Q", "Use Q", true)
	self.Ezreal.Harass:Boolean("W", "Use W", true)
	self.Ezreal.Harass:Slider("Mana", "Min. Mana", 40, 0, 100, 1)

	self.Ezreal:SubMenu("LaneClear", "Lane Clear Settings")
	self.Ezreal.LaneClear:Boolean("Q", "Use Q", true)
	self.Ezreal.LaneClear:Boolean("R", "Use R", true)
	self.Ezreal.LaneClear:Slider("Mana", "Min. Mana", 40, 0, 100, 1)
	self.Ezreal.Farm:Slider("Minionstohit", "Min. Minions to hit with R", 3, 0, 20, 1)
	self.Ezreal.Farm:Slider("RRange", "R Range Maximum, 25k = global", 25000, 0, 25000, 1)

	self.Ezreal:SubMenu("LastHit", "LastHit Settings")
	self.Ezreal.LastHit:Boolean("Q", "Use Q", true)
	self.Ezreal.LastHit:Slider("Mana", "Min. Mana", 40, 0, 100, 1)

	self.Ezreal:SubMenu("Ks", "KillSteal Settings")
	self.Ezreal.Ks:Boolean("Q", "Use Q", true)
	self.Ezreal.Ks:Boolean("W", "Use W", true)
	self.Ezreal.Ks:Boolean("R", "Use R", true)
	self.Ezreal.Ks:Boolean("E", "Use E", true)
	self.Ezreal.Ks:Boolean("Recall", "Don't Ks during Recall", true)
	self.Ezreal.Ks:Boolean("Disabled", "Don't Ks", false)

	self.Ezreal:SubMenu("Draw", "Drawing Settings")
	self.Ezreal.Draw:Boolean("Q", "Draw Q", true)
	self.Ezreal.Draw:Boolean("W", "Draw W", true)
	self.Ezreal.Draw:Boolean("E", "Draw E", true)
	self.Ezreal.Draw:Boolean("EM", "Draw E around Mouse", true)
	self.Ezreal.Draw:Boolean("AA", "Draw AutoAttack", true)
	-- body
end
require '2DGeometry'
function GetBestLinearAOECastPosition(aoe_radius, range, listOfEntities)
	-- If only one Minion in List we dont need to calc a Pos so escape from the function
	if #listOfEntities <= 1 then return false end
	-- Max will hold the Maximum Minions we can hit
	local Max, Minion = 0, nil
	-- This table holds all Hitable Minions for one selected Minion
	local _ = { }

	for i = 1, #listOfEntities do
		local firstEntity = listOfEntities[i]
		_[firstEntity.id] = { }
		local Count = 0
		-- check Collision for First
		for j = 1, #listOfEntities do
			local secondEntity = listOfEntities[j]

			if firstEntity.id ~= secondEntity.id then
				local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(myHero, firstEntity, secondEntity)
				local Distance =(aoe_radius + secondEntity.boundingRadius) * 0.5
				-- try with and without this * .5

				if secondEntity:DistanceTo(pointSegment) < Distance then
					Count = Count + 1
					insert(_[firstEntity.id], secondEntity)
				end
			end
		end

		if Count >= Max then
			Max = Count + 1
			Minion = firstEntity
		end
	end

	insert(_[Minion.id], Minion)
	local Data = { x = Minion.x, y = Minion.y, z = Minion.z, count = Max, list = _[Minion.id] }

	return Data
end


function Ezreal:Tick()
	target = GetCurrentTarget()
	if Mode() == "Combo" then
		if self.Ezreal.Combo.Q:Value() and Ready(_Q) and ValidTarget(target, 1150) then
			local QPred = GetPrediction(target, self.Spells.Q)
			if QPred.hitChance > 0.3 and not QPred:mCollision(1) then
				CastSkillShot(_Q, QPred.castPos)
			end
		end
		if self.Ezreal.Combo.W:Value() and Ready(_W) and ValidTarget(target, 1000) then
			local WPred = GetPrediction(target, self.Spells.W)
			if WPred.hitChance > 0.3 then
				CastSkillShot(_W, WPred.castPos)

			end
		end
		if self.Ezreal.Combo.E:Value() and ready(_E) then
			local CurPos = GetCursourPos()
			CastSkillShot(_E, CurPos)

		end
	end
	if self.Ezreal.Combo.R:Value() and Ready(_R) and ValidTarget(target, 3000) then
		if GetCurrentHP(target) < getdmg("R", enemy, myHero) then
			local RPred = GetLinearAOEPrediction(target, self.Spells.R)
			if RPred.hitChance > 0.8 then
				CastSkillShot(_R, RPred.PredPos)
			end
		end
	end
	if Mode() == "Harass" then
		if (myHero.mana / myHero.maxMana >= self.Ezreal.Harass.Mana:Value() / 100) then
			if self.Ezreal.Harass.Q:Value() and Ready(_Q) and ValidTarget(target, 1150) then
				local QPred = GetPrediction(enemy, self.SpellsQ)
				if QPred.hitChance > 0.3 and not QPred:mCollsion(1) then
					CastSkillshot(_Q, QPred.castPos)
				end
			end
			if self.Ezreal.Harass.W:Value() and Ready(_W) and ValidTarget(target, 1000) then
				local WPred = GetLinearAOEPrediction(target, self.Spells.W)
				if WPred.hitChance > 0.3 then
					CastSkillshot(_W, WPred.castPos)
				end
			end
		end
	end
	if Mode() == "LaneClear" then
		if (myHero.mana / myHero.maxMana >= self.Ezreal.LaneClear.Mana:Value() / 100) then
			if self.Ezreal.LaneClear.Q:Value() and Ready(_Q) and ValidTarget(minion, 1150) then
				local QPred = GetPrediction(minion, self.Spells.Q)
				if QPred.hitchance > 0.3 and not QPred:hCollision(1) then
					for _, minion in pairs(minionManager.objects) do
						CastSkillshot(_Q, QPred.castPos)
					end
				end
			end
		end
		if (myHero.mana >= 100) then
			if self.Ezreal.LaneClear.R:Value() and Ready(_R) then
				local RPred = GetBestLinearAOEPrediction(40, self.Ezreal.LaneClear.RRange:Value(), GetEnemyMinions())
				if RPred ~= false and RPred.count >= self.Ezreal.LaneClear.Minionstohit:Value() then
					CastSkillshot(_R, RPred)
				end
			end
		end
	end
	if Mode() == "LastHit" then
		if (myHero.mana / myHero.maxMana >= self.Ezreal.LastHit.Mana:Value() / 100) then
			for _, minion in pairs(minionManager.objects) do
				if self.Ezreal.LastHit.Q:Value() and Ready(_Q) and ValidTarget(minion, 1150) then
					if GetCurrentHP(minion) < getdmg("Q", minion, myHero) then
						local QPred = GetPrediction(minion, self.Spells.Q)
						if QPred.hitChance > 0.3 and not QPred:hCollision(1) and not QPred:mCollision(1) then
							CastSkillshot(_Q, QPred.castPos)
						end
					end
				end
			end
		end

	end
	for _, enemy in pairs(GetEnemyHeroes()) do
		if self.Ezreal.Ks.Disabled:Value() or(IsRecalling(myHero) and self.Ezreal.Ks.REcall:Value()) then return end
		if self.Ezreal.Ks.Q:Value() and Ready(_Q) and ValidTarget(enemy, 1150) then
			if GetCurrentHP(enemy) < getdmg("Q", enemy, myHero) then
				local QPred = GetPrediction(enemy, self.Spells.Q)
				if QPred.hitChance > 0.3 and not QPred:mCollision(1) and not QPred:hCollision(1) then
					CastSkillShot(_Q, QPred.castPos)
				end
			end
		end
		if self.Ezreal.Ks.W:Value() and Ready(_W) and ValidTarget(enemy, 1000) then
			if GetCurrentHP(enemy) < getdmg("W", enemy, myHero) then
				local WPred = GetLinearAOEPrediction(enemy, self.Spells.W)
				if WPred.hitChance > 0.3 then
					CastSkillShot(_W, WPred.castPos)
				end
			end
		end
		if self.Ezreal.Ks.E:Value() and Ready(_E) and ValidTarget(enemy, 1225) then
			if GetCurrentHP(enemy) < getdmg("E", enemy, myHero) then
				local EPred = GetPrediction(enemy, self.Spells.E)
				if EPred.hitChance > 0.3 then
					CastSkillshot(_W, WPred.castPos)
				end
			end
		end
		if self.Ezreal.Ks.R:Value() and Ready(_R) and ValidTarget(enemy, 3000) then
			if GetCurrentHP(enemy) < getdmg("R", enemy, myHero) then
				local RPred = GetLinearAOEPrediction(enemy, self.Spells.R)
				if RPred.HitChance > 0.8 then
					CastSkillshot(_R, RPred.PredPos)
				end
			end
		end
	end
end
function Ezreal:Draw()
	if self.Ezreal.Draw.Q:Value() then
		DrawCircle(myHero, 1150, 0, 150, GoS.White)
	end
	if self.Ezreal.Draw.W:Value() then
		DrawCircle(myHero, 1000, 0, 150, GoS.White)
	end
	if self.Ezreal.Draw.E:Value() then
		DrawCircle(myHero, 475, 0, 150, GoS.White)
	end
	if self.Ezreal.Draw.EM:Value() then
		DrawCircle(GetCursourPos(), 475, 0, 150, GoS.White)
	end
	if self.Ezreal.Draw.AA:Value() then
		DrawCircle(myHero, 550, 0, 150, GoS.White)
	end
end