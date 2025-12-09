AddCSLuaFile()
DEFINE_BASECLASS "BaseActor"

scripted_ents.Register( ENT, "MentalHordeArachnoidHatchling" )

ENT.CATEGORIZE = {
	MentalHorde = true,
	Arachnoid = true,
	Hatchling = true
}

sound.Add {
	name = "MentalHorde_Arachnoid_Hatchling_Fire",
	channel = CHAN_WEAPON,
	level = 150,
	sound = "weapons/smg1/smg1_fire1.wav" // TODO: Better firing sound
}

list.Set( "NPC", "MentalHordeArachnoidHatchling", {
	Name = "#MentalHordeArachnoidHatchling",
	Class = "MentalHordeArachnoidHatchling",
	Category = "#MentalHorde"
} )

if !SERVER then return end

ENT.HAS_MELEE_ATTACK = true
ENT.HAS_RANGE_ATTACK = true

ENT.flIdleStandTimeMin = 0
ENT.flIdleStandTimeMax = 0

ENT.flTopSpeed = 178.57
ENT.flRunSpeed = ENT.flTopSpeed
ENT.flWalkSpeed = ENT.flTopSpeed

function ENT:MoveAlongPath( pPath, flSpeed, _, tFilter )
	self.loco:SetDesiredSpeed( flSpeed )
	local f = flSpeed * ACCELERATION_NORMAL
	self.loco:SetAcceleration( f )
	self.loco:SetDeceleration( f )
	self.loco:SetJumpHeight( 256 )
	local f = GetVelocity( self ):Length()
	if f <= 12 then self:PromoteSequence "idle" else
		self:PromoteSequence( "run", GetVelocity( self ):Length() / self:GetSequenceGroundSpeed( self:LookupSequence "run" ) )
	end
	self:HandleJumpingAlongPath( pPath, flSpeed, tFilter )
end

function ENT:Stand() end

function ENT:GetShootPos() return self:GetAttachment( 1 ).Pos end

Actor_RegisterSchedule( "MentalHordeArachnoidHatchlingCombat", function( self, sched )
	local enemy = self.Enemy
	if !IsValid( enemy ) then return true end
	local enemy, trueenemy = self:SetupEnemy( enemy )
	local pPath = sched.pPath
	if !pPath then pPath = Path "Follow" sched.pPath = pPath end
	self:ComputeFlankPath( pPath, enemy )
	self:MoveAlongPath( pPath, self.flTopSpeed )
	if self:Visible( enemy ) then
		self.bGun = true
		self.vDesAim = ( enemy:GetPos() + enemy:OBBCenter() - self:GetShootPos() ):GetNormalized()
	else
		self.bGun = nil
		local goal = pPath:GetCurrentGoal()
		local v = self:GetPos()
		if goal then self.vDesAim = ( goal.pos - v ):GetNormalized() end
	end
end )

if !CLASS_MENTAL_HORDE then Add_NPC_Class "CLASS_MENTAL_HORDE" end
ENT.iDefaultClass = CLASS_MENTAL_HORDE

ENT.bCombatForgetLastHostile = true

function ENT:Initialize()
	self:SetModel "models/ss3_arachnoid.mdl"
	self:SetHealth( 1120 )
	self:SetMaxHealth( 1120 )
	self:SetBloodColor( -1 )
	BaseClass.Initialize( self )
end

local ai_disabled = GetConVar "ai_disabled"

function ENT:Think( ... )
	local vHullMins, vHullMaxs = self.vHullMins, self.vHullMaxs
	local vHullMinsCurrent, vHullMaxsCurrent = self:GetCollisionBounds()
	if vHullMaxsCurrent != vHullMins || vHullMaxsCurrent != vHullMaxs then
		self:SetCollisionBounds( self.vHullMins, self.vHullMaxs )
		if !IsValid( self:GetParent() ) && self:PhysicsInitShadow( false, false ) then
			local p = self:GetPhysicsObject()
			if IsValid( p ) then p:SetMass( 85 ) end
		end
	end
	return v
end

ENT.flGunRate = 0
ENT.flLastShot = 0

function ENT:Behaviour( MyTable )
	local flLastHealth = MyTable.flLastHealth
	if flLastHealth then
		if flLastHealth > self:GetMaxHealth() * .5 && self:Health() <= self:GetMaxHealth() * .5 then
			MyTable.AnimationSystemHalt( self, MyTable )
			MyTable.flLastHealth = self:Health()
			MyTable.PlaySequenceAndWait( self, self:LookupSequence "wound", 1 )
			return
		end
	end
	MyTable.flLastHealth = self:Health()
	BaseClass.Behaviour( self, MyTable )
	if MyTable.Schedule && MyTable.Schedule.m_sName == "MentalHordeArachnoidHatchlingCombat" && MyTable.bGun then
		MyTable.flGunRate = math.Approach( MyTable.flGunRate, 32, 12 * FrameTime() )
		if CurTime() > MyTable.flLastShot then
			self:FireBullets {
				Src = self:GetShootPos(),
				Dir = self.vDesAim,
				Tracer = 1,
				Spread = Vector( .02, .02 ),
				Damage = 8 // I know this is ridiculous, but, HAVE YOU SEEN HOW FAST THESE THINGS SHOOT?!
			}
			local ed = EffectData()
			ed:SetEntity( self )
			ed:SetAttachment( 1 )
			ed:SetFlags( 1 )
			util.Effect( "MuzzleFlash", ed )
			self:EmitSound "MentalHorde_Arachnoid_Hatchling_Fire"
			MyTable.flLastShot = CurTime() + math.min( .4, 1 / MyTable.flGunRate )
		end
	else
		MyTable.flGunRate = math.Approach( MyTable.flGunRate, 0, 12 * FrameTime() )
		MyTable.flLastShot = -1
	end
end

function ENT:OnKilled( dmg )
	if BaseClass.OnKilled( self, dmg ) then return end
	self:Remove()
end

function ENT:SelectSchedule( MyTable )
	if IsValid( MyTable.Enemy ) then
		MyTable.SetNPCState( self, NPC_STATE_COMBAT )
		MyTable.SetSchedule( self, "MentalHordeArachnoidHatchlingCombat", MyTable )
	else
		MyTable.SetNPCState( self, NPC_STATE_ALERT )
		MyTable.SetSchedule( self, "Idle", MyTable )
	end
end
