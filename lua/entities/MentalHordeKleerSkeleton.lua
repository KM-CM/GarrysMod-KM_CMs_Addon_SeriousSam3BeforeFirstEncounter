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
	name = "MentalHorde_KleerSkeleton_Wound",
	channel = CHAN_AUTO,
	level = 100,
	sound = {
		"MentalHorde/KleerSkeleton/Wound/1.wav",
		"MentalHorde/KleerSkeleton/Wound/2.wav"
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

ENT.bCombatForgetLastHostile = true

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

ENT.flLeapSpeed = 1280

Actor_RegisterSchedule( "MentalHordeKleerSkeletonInLeap", function( self, sched )
	local enemy = self.Enemy
	if !IsValid( enemy ) then return true end
	if !sched.bActed then
		self:AddGestureSequence( self:LookupSequence "attack2" )
		sched.flEndTimeVelocity = CurTime() + 1
		sched.flEndTimeFull = CurTime() + 1.33
		self:EmitSound "MentalHorde_KleerSkeleton_Leap"
		sched.bActed = true
	end
	if CurTime() > sched.flEndTimeFull then return true end
	if CurTime() > sched.flEndTimeVelocity then return end
	self:AnimationSystemHalt()
	self.vDesAim = self:GetForward()
	self.loco:Approach( self:GetPos(), 1 )
	self.loco:SetVelocity( self:GetForward() * self.flLeapSpeed )
	local tHit = sched.tHit || {}
	local v = self:GetPos() + self:OBBCenter()
	local tr = util.TraceHull {
		start = v,
		endpos = v + self:GetForward() * 32,
		mask = MASK_SOLID,
		mins = Vector( -32, -32, -24 ),
		maxs = Vector( 32, 32, 32 ),
		filter = function( ent )
			if ent == self || tHit[ ent ] then return end
			tHit[ ent ] = true
			if IsValid( ent ) && self:Disposition( ent ) != D_LI then
				local dmg = DamageInfo()
				dmg:SetDamage( 768 )
				dmg:SetDamageType( DMG_SLASH )
				dmg:SetAttacker( self )
				dmg:SetInflictor( self )
				ent:TakeDamageInfo( dmg )
				local dmg = DamageInfo()
				dmg:SetDamage( 768 )
				dmg:SetDamageType( DMG_CLUB )
				dmg:SetAttacker( self )
				dmg:SetInflictor( self )
				ent:TakeDamageInfo( dmg )
			end
		end
	}
	sched.tHit = tHit
end )

Actor_RegisterSchedule( "MentalHordeKleerSkeletonCombatTick", function( self, sched )
	local enemy = self.Enemy
	if !IsValid( enemy ) then return true end
	self:SetNPCState( NPC_STATE_COMBAT )
	local enemy, trueenemy = self:SetupEnemy( enemy )
	local pPath = sched.pPath
	if !pPath then pPath = Path "Follow" sched.pPath = pPath end
	self:ComputeFlankPath( pPath, enemy )
	self:MoveAlongPath( pPath, self.flTopSpeed )
	local v = self:GetPos() + self:OBBCenter()
	local f = self.flLeapSpeed * .5 // TODO: This needs better calculations!!!
	if self:Visible( enemy ) && v:DistToSqr( enemy:NearestPoint( v ) ) <= f * f then
		local d = ( enemy:GetPos() + enemy:OBBCenter() - ( self:GetPos() + self:OBBCenter() ) ):GetNormalized()
		if self:GetForward():Dot( d ) > .99984769515 then self:SetSchedule "MentalHordeKleerSkeletonInLeap" return end
		self.vDesAim = d
	else
		local goal = pPath:GetCurrentGoal()
		local v = self:GetPos()
		if goal then self.vDesAim = ( goal.pos - v ):GetNormalized() end
	end
end )

function ENT:SelectSchedule( MyTable )
	if IsValid( MyTable.Enemy ) then
		MyTable.SetNPCState( self, NPC_STATE_COMBAT )
		MyTable.SetSchedule( self, "MentalHordeKleerSkeletonCombatTick", MyTable )
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
end

function ENT:Behaviour( MyTable )
	local flLastHealth = MyTable.flLastHealth
	if flLastHealth then
		if flLastHealth > self:GetMaxHealth() * .5 && self:Health() <= self:GetMaxHealth() * .5 then
			CEntity_EmitSound( self, "MentalHorde_KleerSkeleton_Wound" )
			MyTable.flLastHealth = self:Health()
			self:AddGestureSequence( self:LookupSequence "wound" )
			return
		end
	end
	MyTable.flLastHealth = self:Health()
	BaseClass.Behaviour( self, MyTable )
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
