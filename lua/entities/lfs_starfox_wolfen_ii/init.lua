--DO NOT EDIT OR REUPLOAD THIS FILE

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:SpawnFunction( ply, tr, ClassName )
	if not tr.Hit then return end

	local ent = ents.Create(ClassName)
	ent:SetPos(tr.HitPos + tr.HitNormal * 60)
	local ang = ply:EyeAngles()
	ent:SetAngles(Angle(0,ang.y +180,0))
	ent:Spawn()
	ent:Activate()

	return ent
end

function ENT:OnSetPilot(pilot)
	-- self:SetBodygroup(2,pilot == "Andrew" && 1 or pilot == "Leon" && 2 or pilot == "Pigma" && 3 or pilot == "Wolf" && 4 or 0)
end

function ENT:OnRemovePilot(pilot)
	-- self:SetBodygroup(2,0)
end

function ENT:RunOnSpawn()
	-- self:SetBodygroup(1,1)
	if self.PilotCode then
		self:SetNW2Entity("Enemy",NULL)
		self:SetNW2String("VO",nil)
	end
end

function ENT:OnRemove()
	if self.Charge then
		self.Charge:Stop()
	end
	if self.Alarm then self.Alarm:Stop() end
	SafeRemoveEntity(self.Trail1)
end

function ENT:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end

	self:SetNextPrimary(0.15)

	local bullet = {}
	bullet.Num 		= 1
	bullet.Src 		= self:GetAttachment(1).Pos
	bullet.Dir 		= self:LocalToWorldAngles(Angle(0,0,0)):Forward()
	bullet.Spread 	= Vector(0.01,0.01,0)
	bullet.Tracer	= 1
	bullet.TracerName = "lfs_laser_green"
	bullet.Force	= 100
	bullet.HullSize = 25
	bullet.Damage	= 75
	bullet.Attacker = self:GetDriver()
	bullet.AmmoType = "Pistol"
	bullet.Callback = function(att,tr,dmginfo)
		dmginfo:SetDamageType(DMG_AIRBOAT)
		sound.Play("cpthazama/starfox/64/vehicles/Lazerhit.wav", tr.HitPos, 90, 100, 1)
	end
	SF.PlaySound(3,bullet.Src,"cpthazama/starfox/64/vehicles/HyperLazer.wav",95,nil,nil,true)
	self:FireBullets(bullet)
	self:TakePrimaryAmmo()
end

function ENT:OnKeyThrottle( bPressed )

end

function ENT:ToggleLandingGear()
end

function ENT:RaiseLandingGear()
end

function ENT:HandleWeapons(Fire1, Fire2)
	local RPM = self:GetRPM()
	local MaxRPM = self:GetMaxRPM()

	local shouldAlarm = false
	for _,v in pairs(ents.FindInSphere(self:GetPos(), 8000)) do
		if v:GetClass() == "lunasflightschool_missile" then
			if v:GetPos():Distance(self:GetPos()) <= 2000 then
				v.Explode = true
			end
			shouldAlarm = true
		end
	end
	if shouldAlarm then
		self.Alarm = SF.PlaySound(1,IsValid(self:GetDriver()) && self:GetDriver() or self,"cpthazama/starfox/64/vehicles/LockonAlert.wav",60,nil,nil,true)
	else
		if self.Alarm then self.Alarm:Stop() end
	end

	if self.PilotCode && self:GetAI() then
		self:SetNW2Entity("Enemy",self:AIGetTarget())
		self:SetNW2Int("Team",self:GetAITEAM())
	end

	if RPM <= MaxRPM *0.05 then
		SafeRemoveEntity(self.Trail1)
	elseif self.CanUseTrail && !IsValid(self.Trail1) && RPM > MaxRPM *0.05 then
		local size = 800
		self.Trail1 = util.SpriteTrail(self, 2, Color(113,200,116), false, size, 0, 3, 1 /(10 +1) *0.5, "VJ_Base/sprites/vj_trial1.vmt")
	end
	local Driver = self:GetDriver()
	
	if IsValid(Driver) then
		if self:GetAmmoPrimary() > 0 then
			Fire1 = Driver:KeyReleased(IN_ATTACK)
			-- Fire1 = Driver:KeyDown(IN_ATTACK)
		end
	end
	
	if Fire1 then
		self:PrimaryAttack()
	end
end

function ENT:OnEngineStarted()
	self:EmitSound("cpthazama/starfox/vehicles/arwing_power_up.wav")
	if IsValid(self:GetDriver()) then
		self:GetDriver():EmitSound("cpthazama/starfox/vehicles/arwing_enter.wav")
	end

	self.CanUseTrail = true
end

function ENT:OnEngineStopped()
	self:EmitSound("cpthazama/starfox/vehicles/arwing_power_down.wav")

	self.CanUseTrail = false
	SafeRemoveEntity(self.Trail1)
end

function ENT:Destroy()
	self.Destroyed = true
	
	local PObj = self:GetPhysicsObject()
	if IsValid( PObj ) then
		PObj:SetDragCoefficient( -20 )
	end

	local ai = self:GetAI()
	if !ai then return end

	local attacker = self.FinalAttacker or Entity(0)
	local inflictor = self.FinalInflictor or Entity(0)
	if attacker:IsPlayer() then attacker:AddFrags(1) end
	gamemode.Call("OnNPCKilled",self,attacker,inflictor)
end