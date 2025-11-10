AddCSLuaFile()
DEFINE_BASECLASS "BaseActor"

scripted_ents.Register( ENT, "MentalHordeKleerSkeleton" )

ENT.CATEGORIZE = {
	MentalHorde = true,
	KleerSkeleton = true,
	Skeleton = true
}

sound.Add {
	name = "MentalHorde_KleerSkeleton_Death",
	channel = CHAN_AUTO,
	level = 150,
	sound = {
		"MentalHorde/KleerSkeleton/Die/1.wav",
		"MentalHorde/KleerSkeleton/Die/2.wav",
		"MentalHorde/KleerSkeleton/Die/3.wav"
	}
}

sound.Add {
	name = "MentalHorde_KleerSkeleton_Leap",
	channel = CHAN_AUTO,
	level = 100,
	sound = "MentalHorde/KleerSkeleton/Leap.wav"
}

list.Set( "NPC", "MentalHordeKleerSkeleton", {
	Name = "#MentalHordeKleerSkeleton",
	Class = "MentalHordeKleerSkeleton",
	Category = "#MentalHorde"
} )

if !SERVER then return end

ENT.HAS_MELEE_ATTACK = true

function ENT:Stand() end

ENT.flIdleStandTimeMin = 0
ENT.flIdleStandTimeMax = 0

ENT.flTopSpeed = 400
ENT.flProwlSpeed = ENT.flTopSpeed
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
	self:HandleJumpingAlongPath( pPath, tFilter )
end

local CEntity_EmitSound = FindMetaTable( "Entity" ).EmitSound

if !CLASS_MENTAL_HORDE then Add_NPC_Class "CLASS_MENTAL_HORDE" end
ENT.iDefaultClass = CLASS_MENTAL_HORDE

Actor_RegisterSchedule( "MentalHordeKleerSkeletonTick", function( self, sched )
	local enemy = self.Enemy
	if !IsValid( enemy ) then return true end
	self:SetNPCState( NPC_STATE_COMBAT )
	local enemy, trueenemy = self:SetupEnemy( enemy )
	local pPath = sched.pPath
	if !pPath then pPath = Path "Follow" sched.pPath = pPath end
	self:ComputeFlankPath( pPath, enemy )
	self:MoveAlongPath( pPath, self.flTopSpeed )
	local goal = pPath:GetCurrentGoal()
	local v = self:GetPos()
	if goal then self.vDesAim = ( goal.pos - v ):GetNormalized() end
end )

function ENT:SelectSchedule( MyTable )
	if IsValid( MyTable.Enemy ) then
		MyTable.SetNPCState( self, NPC_STATE_COMBAT )
		MyTable.SetSchedule( self, "MentalHordeKleerSkeletonTick", MyTable )
	else
		MyTable.SetNPCState( self, NPC_STATE_ALERT )
		MyTable.SetSchedule( self, "Idle", MyTable )
	end
end

function ENT:Initialize()
	self:SetModel "models/ss3_kleer.mdl"
	self:SetHealth( 1000 )
	self:SetMaxHealth( 1000 )
	self:SetBloodColor( -1 )
	BaseClass.Initialize( self )
end

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
	return BaseClass.Think( self, ... )
end

function ENT:OnKilled( dmg )
	if BaseClass.OnKilled( self, dmg ) then return end
	CEntity_EmitSound( self, "MentalHorde_KleerSkeleton_Death" )
	local pPhys = self:GetPhysicsObject()
	local vVelocity, flDamageForce, vDamagePosition, vAngularVelocity = GetVelocity( self ), dmg:GetDamageForce():Length(), dmg:GetDamagePosition(), IsValid( pPhys ) && pPhys:GetAngleVelocity() || Vector()
	for iBone = 0, self:GetBoneCount() - 1 do
		local sModel = "models/ss3_kleer_gibs/" .. self:GetBoneName( iBone ) .. ".mdl"
		if !util.IsValidModel( sModel ) then continue end
		local vPos, aAng = self:GetBonePosition( iBone )
		local pBone = ents.Create "prop_physics"
		pBone:SetModel( sModel )
		pBone:SetAngles( aAng )
		pBone:SetPos( vPos )
		pBone:Spawn()
		local pPhys = pBone:GetPhysicsObject()
		if IsValid( pPhys ) then
			pPhys:SetVelocity( ( vVelocity + ( pBone:GetPos() + pBone:OBBCenter() - vDamagePosition ):GetNormalized() * flDamageForce ) * math.Rand( 1.5, 2 ) )
			pPhys:SetAngleVelocity( vAngularVelocity )
		end
	end
	self:Remove()
end
