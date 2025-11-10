// “I may have broken my legs having to jump off a rooftop while running away from it,
// but at least I didn't get my shit blown up!”
//  - KM_CM (me), 09.11.2025
//
// NOTE: Logic is so complex because calling ENT:BlowUp() in the thread -
// - as in, in ENT:RunBehaviour, aka the coroutine, and anything called by it -
// causes it to be recalled because of self damage, which is weird -
// even safeguards don't work. ENT:OnKilled() is the cause.
// Why safeguards like `if self.bDetonated then return end` don't work?
// No idea, but it is weird!

AddCSLuaFile()
DEFINE_BASECLASS "BaseActor"

scripted_ents.Register( ENT, "MentalHordeBeHeadedKamikaze" )

ENT.CATEGORIZE = {
	MentalHorde = true,
	BeHeadedKamikaze = true,
	Kamikaze = true
}

sound.Add {
	name = "MentalHorde_BeHeadedKamikaze_ScreamLoop",
	channel = CHAN_STATIC,
	level = 110,
	sound = "MentalHorde/BeHeadedKamikaze/ScreamLoop.wav"
}

sound.Add {
	name = "MentalHorde_BeHeadedKamikaze_Explode",
	channel = CHAN_STATIC,
	level = 150,
	sound = "MentalHorde/BeHeadedKamikaze/Explode.wav"
}

list.Set( "NPC", "MentalHordeBeHeadedKamikaze", {
	Name = "#MentalHordeBeHeadedKamikaze",
	Class = "MentalHordeBeHeadedKamikaze",
	Category = "#MentalHorde"
} )

if !SERVER then return end

ENT.HAS_MELEE_ATTACK = true

ENT.flIdleStandTimeMin = 0
ENT.flIdleStandTimeMax = 0

ENT.flTopSpeed = 460
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
		self:PromoteSequence( "attack", GetVelocity( self ):Length() / self:GetSequenceGroundSpeed( self:LookupSequence "attack" ) * .5 )
	end
	self:HandleJumpingAlongPath( pPath, tFilter )
end

function ENT:Stand() end

local EXPLOSION_RADIUS = 192

Actor_RegisterSchedule( "MentalHordeBeHeadedKamikazeTick", function( self, sched )
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
	local f = EXPLOSION_RADIUS * .5
	f = f * f
	v = v + self:GetUp() * 50
	if v:DistToSqr( enemy:NearestPoint( v ) ) <= f then
		if enemy.__ACTOR_BULLSEYE__ && trueenemy:GetPos():DistToSqr( enemy:GetPos() ) > f then
			enemy:Remove()
		else
			self.bBlowUp = true
		end
	end
end )

function ENT:SelectSchedule( MyTable )
	if IsValid( MyTable.Enemy ) then
		MyTable.SetNPCState( self, NPC_STATE_COMBAT )
		MyTable.SetSchedule( self, "MentalHordeBeHeadedKamikazeTick", MyTable )
	else
		MyTable.SetNPCState( self, NPC_STATE_ALERT )
		MyTable.SetSchedule( self, "Idle", MyTable )
	end
end

local CEntity_EmitSound = FindMetaTable( "Entity" ).EmitSound

if !CLASS_MENTAL_HORDE then Add_NPC_Class "CLASS_MENTAL_HORDE" end
ENT.iDefaultClass = CLASS_MENTAL_HORDE

function ENT:Initialize()
	self:SetModel "models/ss3_kamikaze.mdl"
	// Use 200 for unrealistic but fun health and 256 for a bit harder...
	// This one is way more hard but it is pretty much realistic for Sirians with LCUs
	self:SetHealth( 384 )
	self:SetMaxHealth( 384 )
	self:SetBloodColor( -1 )
	local pScreamLoop = CreateSound( self, "MentalHorde_BeHeadedKamikaze_ScreamLoop" )
	pScreamLoop:PlayEx( 0, 100 )
	self.pScreamLoop = pScreamLoop
	BaseClass.Initialize( self )
end

local ai_disabled = GetConVar "ai_disabled"

function ENT:Think( ... )
	if self.bBlowUp then self:BlowUp() return end
	local vHullMins, vHullMaxs = self.vHullMins, self.vHullMaxs
	local vHullMinsCurrent, vHullMaxsCurrent = self:GetCollisionBounds()
	if vHullMaxsCurrent != vHullMins || vHullMaxsCurrent != vHullMaxs then
		self:SetCollisionBounds( self.vHullMins, self.vHullMaxs )
		if !IsValid( self:GetParent() ) && self:PhysicsInitShadow( false, false ) then
			local p = self:GetPhysicsObject()
			if IsValid( p ) then p:SetMass( 85 ) end
		end
	end
	local v = BaseClass.Think( self, ... )
	if ai_disabled:GetBool() then
		local pScreamLoop = self.pScreamLoop
		if pScreamLoop then pScreamLoop:ChangeVolume( 0, FrameTime() ) end
		return v
	end
	local f = GetVelocity( self ):Length()
	if f <= 12 then
		local pScreamLoop = self.pScreamLoop
		if pScreamLoop then pScreamLoop:ChangeVolume( 0, FrameTime() ) end
	else
		local pScreamLoop = self.pScreamLoop
		if pScreamLoop then pScreamLoop:ChangeVolume( math.Clamp( f / self.flTopSpeed, 0, 1 ), FrameTime() ) end
	end
	return v
end

function ENT:Behaviour( MyTable )
	local flLastHealth = MyTable.flLastHealth
	if flLastHealth then
		if flLastHealth > self:GetMaxHealth() * .5 && self:Health() <= self:GetMaxHealth() * .5 then
			MyTable.AnimationSystemHalt( self, MyTable )
			MyTable.PlaySequenceAndWait( self, self:LookupSequence( math.random( 1, 3 ) == 1 && "wound" || ( "wound" .. tostring( math.random( 2, 3 ) ) ) ), 1 )
		end
	end
	MyTable.flLastHealth = self:Health()
	BaseClass.Behaviour( self, MyTable )
end

function ENT:OnRemove()
	local pScreamLoop = self.pScreamLoop
	if pScreamLoop then pScreamLoop:Stop() end
	BaseClass.OnRemove( self )
end

function ENT:BlowUp()
	// if self.bDetonated then return end
	local v = self:GetPos() + self:GetUp() * 50
	ParticleEffect( "SS3BFE_Explosion_Kamikaze", v, Angle() )
	CEntity_EmitSound( self, "SS3_Splat" )
	CEntity_EmitSound( self, "MentalHorde_BeHeadedKamikaze_Explode" )
	// self.bDetonated = true
	local aAngles = self:GetAngles()
	local pGib = ents.Create "prop_physics"
	pGib:SetModel "models/ss3_kamikaze_gibs/debris1.mdl"
	pGib:SetPos( self:GetBonePosition( 13 ) )
	pGib:SetAngles( aAngles + Angle( 0, 270, 0 ) )
	pGib:Spawn()
	local pGib = ents.Create "prop_physics"
	pGib:SetModel "models/ss3_kamikaze_gibs/hand.mdl"
	pGib:SetPos( self:GetBonePosition( 11 ) )
	pGib:SetAngles( aAngles + Angle( 270, 270, 0 ) )
	pGib:Spawn()
	local pGib = ents.Create "prop_physics"
	pGib:SetModel "models/ss3_kamikaze_gibs/hand2.mdl"
	pGib:SetPos( self:GetBonePosition( 15 ) )
	pGib:SetAngles( aAngles + Angle( 0, 270, 0 ) )
	pGib:Spawn()
	local pGib = ents.Create "prop_physics"
	pGib:SetModel "models/ss3_kamikaze_gibs/leg1.mdl"
	pGib:SetPos( self:GetBonePosition( 2 ) )
	pGib:SetAngles( aAngles + Angle( 20, 270, 60 ) )
	pGib:Spawn()
	local pGib = ents.Create "prop_physics"
	pGib:SetModel "models/ss3_kamikaze_gibs/leg2.mdl"
	pGib:SetPos( self:GetBonePosition( 9 ) )
	pGib:SetAngles( aAngles + Angle( -30, 270, -30 ) )
	pGib:Spawn()
	local pBloodSpray = EffectData()
	pBloodSpray:SetOrigin( self:GetPos() + self:OBBCenter() )
	pBloodSpray:SetScale( 8 )
	pBloodSpray:SetFlags( 3 )
	pBloodSpray:SetColor( 0 )
	util.Effect( "bloodspray", pBloodSpray )
	util.Effect( "bloodspray", pBloodSpray )
	util.BlastDamage( self, self, v, EXPLOSION_RADIUS, 1024 )
	self:Remove()
end

function ENT:OnKilled( dmg )
	if BaseClass.OnKilled( self, dmg ) || self.bBlowUp then return end
	self:BlowUp()
end
