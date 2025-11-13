// TODO: Make a good timed laughing animation

AddCSLuaFile()
DEFINE_BASECLASS "BaseActor"

scripted_ents.Register( ENT, "MentalHordeScrapJackRocketeer" )

ENT.CATEGORIZE = {
	MentalHorde = true,
	ScrapJackRocketeer = true
}

sound.Add {
	name = "MentalHorde_ScrapJackRocketeer_Fire",
	channel = CHAN_AUTO,
	level = 150,
	sound = {
		"MentalHorde/ScrapJackRocketeer/Fire/1.wav",
		"MentalHorde/ScrapJackRocketeer/Fire/2.wav"
	}
}

sound.Add {
	name = "MentalHorde_ScrapJackRocketeer_Laugh",
	channel = CHAN_STATIC,
	level = 110,
	sound = "MentalHorde/ScrapJackRocketeer/Laugh.wav"
}

list.Set( "NPC", "MentalHordeScrapJackRocketeer", {
	Name = "#MentalHordeScrapJackRocketeer",
	Class = "MentalHordeScrapJackRocketeer",
	Category = "#MentalHorde"
} )

if !SERVER then return end

ENT.HAS_MELEE_ATTACK = true
ENT.HAS_RANGE_ATTACK = true

ENT.flIdleStandTimeMin = 0
ENT.flIdleStandTimeMax = 0

ENT.flTopSpeed = 65
ENT.flProwlSpeed = ENT.flTopSpeed
ENT.flWalkSpeed = ENT.flTopSpeed

function ENT:GetShootPos() return self:GetPos() + self:OBBCenter() end

function ENT:MoveAlongPath( pPath, flSpeed, _, tFilter )
	self.loco:SetDesiredSpeed( flSpeed )
	local f = flSpeed * ACCELERATION_NORMAL
	self.loco:SetAcceleration( f )
	self.loco:SetDeceleration( f )
	self.loco:SetJumpHeight( 128 )
	local f = GetVelocity( self ):Length()
	if f <= 12 then self:PromoteSequence "idle" else
		self:PromoteSequence( "walk", GetVelocity( self ):Length() / self:GetSequenceGroundSpeed( self:LookupSequence "walk" ) )
	end
	self:HandleJumpingAlongPath( pPath, flSpeed, tFilter )
end

function ENT:Stand() end

ENT.flTurnRate = 22.5

local CEntity_EmitSound = FindMetaTable( "Entity" ).EmitSound
local ParticleEffectAttach = ParticleEffectAttach
local PATTACH_POINT_FOLLOW = PATTACH_POINT_FOLLOW

function ENT:ShootLeft()
	CEntity_EmitSound( self, "MentalHorde_ScrapJackRocketeer_Fire" )
	local at = self:LookupAttachment "Left_Cannon"
	ParticleEffectAttach( "SS3_EnemyRL_Shot", PATTACH_POINT_FOLLOW, self, at )
	local pProjectile = self:CreateProjectile "MentalHordeRocketLarge"
	if !IsValid( pProjectile ) then return end
	pProjectile:SetPos( self:GetAttachment( at ).Pos )
	pProjectile:SetAngles( self:GetAimVector():Angle() )
	pProjectile:Spawn()
end
function ENT:ShootRight()
	CEntity_EmitSound( self, "MentalHorde_ScrapJackRocketeer_Fire" )
	local at = self:LookupAttachment "Right_Cannon"
	ParticleEffectAttach( "SS3_EnemyRL_Shot", PATTACH_POINT_FOLLOW, self, at )
	local pProjectile = self:CreateProjectile "MentalHordeRocketLarge"
	if !IsValid( pProjectile ) then return end
	pProjectile:SetPos( self:GetAttachment( at ).Pos )
	pProjectile:SetAngles( self:GetAimVector():Angle() )
	pProjectile:Spawn()
end

Actor_RegisterSchedule( "MentalHordeScrapJackRocketeerCombat", function( self, sched )
	local enemy = self.Enemy
	if !IsValid( enemy ) then return true end
	local enemy, trueenemy = self:SetupEnemy( enemy )
	local pPath = sched.pPath
	if !pPath then pPath = Path "Follow" sched.pPath = pPath end
	self:ComputeFlankPath( pPath, enemy )
	self:MoveAlongPath( pPath, self.flTopSpeed )
	if sched.bBeganAttack then
		if !self:Visible( enemy ) then sched.bBeganAttack = nil return end
		local d = ( enemy:GetPos() + enemy:OBBCenter() - ( self:GetPos() + self:OBBCenter() ) ):GetNormalized()
		self.vDesAim = d
		if self:GetForward():Dot( d ) > math.cos( math.rad( self.flTurnRate ) ) then
			self:SetSchedule( math.Rand( 0, math.Remap( self:Health(), self:GetMaxHealth() * .33, self:GetMaxHealth(), 1.5, 12 ) ) <= 1 && "MentalHordeScrapJackRocketeerShootRage" ||
			( math.Rand( 0, math.Remap( self:Health(), self:GetMaxHealth() * .66, self:GetMaxHealth(), 12, 2 ) ) <= 1 && "MentalHordeScrapJackRocketeerShootWeak" ||
			( math.random( 2 ) == 1 && "MentalHordeScrapJackRocketeerShootPairs" || "MentalHordeScrapJackRocketeerShootAuto" ) ) )
		end
		return
	elseif self:Visible( enemy ) && math.Rand( 0, math.Remap( self:Health(), self:GetMaxHealth() * .33, self:GetMaxHealth(), 1, 10000 ) * FrameTime() ) <= 1 then sched.bBeganAttack = true return end
	local goal = pPath:GetCurrentGoal()
	local v = self:GetPos()
	if goal then self.vDesAim = ( goal.pos - v ):GetNormalized() end
end )

if !CLASS_MENTAL_HORDE then Add_NPC_Class "CLASS_MENTAL_HORDE" end
ENT.iDefaultClass = CLASS_MENTAL_HORDE

ENT.vHullMins = Vector( -50, -50, 0 )
ENT.vHullMaxs = Vector( 50, 50, 128 )

ENT.bCombatForgetLastHostile = true

function ENT:Initialize()
	self:SetModel "models/ss3_scrapjack.mdl"
	self:SetHealth( 16384 )
	self:SetMaxHealth( 16384 )
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

function ENT:Behaviour( MyTable )
	local flLastHealth = MyTable.flLastHealth
	if flLastHealth then
		if flLastHealth > self:GetMaxHealth() * .5 && self:Health() <= self:GetMaxHealth() * .5 then
			MyTable.AnimationSystemHalt( self, MyTable )
			MyTable.flLastHealth = self:Health()
			MyTable.PlaySequenceAndWait( self, self:LookupSequence( math.random( 1, 3 ) == 1 && "wound" || ( "wound" .. tostring( math.random( 2, 3 ) ) ) ), 1 )
			return
		end
	end
	MyTable.flLastHealth = self:Health()
	BaseClass.Behaviour( self, MyTable )
end

function ENT:OnKilled( dmg )
	if BaseClass.OnKilled( self, dmg ) then return end
	local aAngles = self:GetAngles()
	local pGib = ents.Create "prop_physics"
	pGib:SetModel "models/ss3_scrapjack_gibs/legs.mdl"
	pGib:SetPos( self:GetPos() + self:GetUp() * 32 )
	pGib:SetAngles( aAngles + Angle( 0, 180, 0 ) )
	pGib:Spawn()
	local pGib = ents.Create "prop_physics"
	pGib:SetModel "models/ss3_scrapjack_gibs/arm.mdl"
	pGib:SetPos( self:GetBonePosition( 20 ) + self:GetRight() * -30 - self:GetUp() * 50 )
	pGib:SetAngles( aAngles + Angle( 0, 180, -40 ) )
	pGib:Spawn()
	local pGib = ents.Create "prop_physics"
	pGib:SetModel "models/ss3_scrapjack_gibs/arm.mdl"
	pGib:SetPos( self:GetBonePosition( 16 ) + self:GetRight() * 30 - self:GetUp() * 50 )
	pGib:SetAngles( aAngles + Angle( -30, 0, -40 ) )
	pGib:Spawn()
	local pGib = ents.Create "prop_physics"
	pGib:SetModel "models/ss3_scrapjack_gibs/head.mdl"
	pGib:SetPos( self:GetBonePosition( 24 ) + self:GetUp() * 96 )
	pGib:SetAngles( aAngles + Angle( 0, 180, 0 ) )
	pGib:Spawn()
	local pGib = ents.Create "prop_physics"
	pGib:SetModel "models/ss3_scrapjack_gibs/skin1.mdl"
	pGib:SetPos( self:GetBonePosition( 11 ) + self:GetRight() * 10 + self:GetUp() * 12 )
	pGib:SetAngles( aAngles + Angle( 0, 180, 0 ) )
	pGib:Spawn()
	local pGib = ents.Create "prop_physics"
	pGib:SetModel "models/ss3_scrapjack_gibs/skin2.mdl"
	pGib:SetPos( self:GetBonePosition( 11 ) + self:GetRight() * 10 + self:GetForward() * 20 + self:GetUp() * 12 )
	pGib:SetAngles( aAngles + Angle( 0, 180, 0 ) )
	pGib:Spawn()
	self:Remove()
end

function ENT:SelectSchedule( MyTable )
	if IsValid( MyTable.Enemy ) then
		MyTable.SetNPCState( self, NPC_STATE_COMBAT )
		MyTable.SetSchedule( self, "MentalHordeScrapJackRocketeerCombat", MyTable )
	else
		MyTable.SetNPCState( self, NPC_STATE_ALERT )
		MyTable.SetSchedule( self, "Idle", MyTable )
	end
end

Actor_RegisterSchedule( "MentalHordeScrapJackRocketeerShootWeak", function( self, sched )
	local enemy = self.Enemy
	if !IsValid( enemy ) then if sched.flEndTime && CurTime() > sched.flEndTime then return true else return end end
	local enemy, trueenemy = self:SetupEnemy( enemy )
	self:SelectAim( enemy, self:GetShootPos(), 1020, 96, 24 )
	if !sched.flEndTime then
		local s = self:LookupSequence "fire22"
		self:AddGestureSequence( s )
		sched.flEndTime = CurTime() + self:SequenceDuration( s )
		timer.Simple( .66, function()
			if !IsValid( self ) || !self.Schedule || self.Schedule.m_sName != "MentalHordeScrapJackRocketeerShootWeak" then return end
			if !IsValid( self.Enemy ) then return end
			self:ShootLeft()
		end )
		timer.Simple( 2.2, function()
			if !IsValid( self ) || !self.Schedule || self.Schedule.m_sName != "MentalHordeScrapJackRocketeerShootWeak" then return end
			if !IsValid( self.Enemy ) then return end
			self:ShootRight()
		end )
	end
	if CurTime() > sched.flEndTime then return true end
end )

Actor_RegisterSchedule( "MentalHordeScrapJackRocketeerShootAuto", function( self, sched )
	local enemy = self.Enemy
	if !IsValid( enemy ) then if sched.flEndTime && CurTime() > sched.flEndTime then return true else return end end
	local enemy, trueenemy = self:SetupEnemy( enemy )
	self:SelectAim( enemy, self:GetShootPos(), 1020, 96, 24 )
	if !sched.flEndTime then
		local s = self:LookupSequence "fire33"
		self:AddGestureSequence( s )
		sched.flEndTime = CurTime() + self:SequenceDuration( s )
		timer.Simple( 1.33, function()
			if !IsValid( self ) || !self.Schedule || self.Schedule.m_sName != "MentalHordeScrapJackRocketeerShootAuto" then return end
			if !IsValid( self.Enemy ) then return end
			self:ShootRight()
		end )
		timer.Simple( 1.66, function()
			if !IsValid( self ) || !self.Schedule || self.Schedule.m_sName != "MentalHordeScrapJackRocketeerShootAuto" then return end
			if !IsValid( self.Enemy ) then return end
			self:ShootLeft()
		end )
		timer.Simple( 2, function()
			if !IsValid( self ) || !self.Schedule || self.Schedule.m_sName != "MentalHordeScrapJackRocketeerShootAuto" then return end
			if !IsValid( self.Enemy ) then return end
			self:ShootRight()
		end )
		timer.Simple( 2.33, function()
			if !IsValid( self ) || !self.Schedule || self.Schedule.m_sName != "MentalHordeScrapJackRocketeerShootAuto" then return end
			if !IsValid( self.Enemy ) then return end
			self:ShootLeft()
		end )
		timer.Simple( 2.66, function()
			if !IsValid( self ) || !self.Schedule || self.Schedule.m_sName != "MentalHordeScrapJackRocketeerShootAuto" then return end
			if !IsValid( self.Enemy ) then return end
			self:ShootRight()
		end )
		timer.Simple( 3, function()
			if !IsValid( self ) || !self.Schedule || self.Schedule.m_sName != "MentalHordeScrapJackRocketeerShootAuto" then return end
			if !IsValid( self.Enemy ) then return end
			self:ShootLeft()
		end )
	end
	if CurTime() > sched.flEndTime then return true end
end )

Actor_RegisterSchedule( "MentalHordeScrapJackRocketeerShootPairs", function( self, sched )
	local enemy = self.Enemy
	if !IsValid( enemy ) then if sched.flEndTime && CurTime() > sched.flEndTime then return true else return end end
	local enemy, trueenemy = self:SetupEnemy( enemy )
	self:SelectAim( enemy, self:GetShootPos(), 1020, 96, 24 )
	if !sched.flEndTime then
		local s = self:LookupSequence "fire23"
		self:AddGestureSequence( s )
		sched.flEndTime = CurTime() + self:SequenceDuration( s )
		timer.Simple( 1.33, function()
			if !IsValid( self ) || !self.Schedule || self.Schedule.m_sName != "MentalHordeScrapJackRocketeerShootPairs" then return end
			if !IsValid( self.Enemy ) then return end
			self:ShootLeft()
			self:ShootRight()
		end )
		timer.Simple( 2, function()
			if !IsValid( self ) || !self.Schedule || self.Schedule.m_sName != "MentalHordeScrapJackRocketeerShootPairs" then return end
			if !IsValid( self.Enemy ) then return end
			self:ShootLeft()
			self:ShootRight()
		end )
		timer.Simple( 2.66, function()
			if !IsValid( self ) || !self.Schedule || self.Schedule.m_sName != "MentalHordeScrapJackRocketeerShootPairs" then return end
			if !IsValid( self.Enemy ) then return end
			self:ShootLeft()
			self:ShootRight()
		end )
	end
	if CurTime() > sched.flEndTime then return true end
end )

Actor_RegisterSchedule( "MentalHordeScrapJackRocketeerShootRage", function( self, sched )
	local enemy = self.Enemy
	if !IsValid( enemy ) then if sched.flEndTime && CurTime() > sched.flEndTime then return true else return end end
	local enemy, trueenemy = self:SetupEnemy( enemy )
	self:SelectAim( enemy, self:GetShootPos(), 1020, 96, 24 )
	local s = self:LookupSequence "fire rage"
	if !sched.flEndTime then
		self:AddGestureSequence( s )
		sched.flEndTime = CurTime() + self:SequenceDuration( s )
		timer.Simple( 1.33, function()
			if !IsValid( self ) || !self.Schedule || self.Schedule.m_sName != "MentalHordeScrapJackRocketeerShootRage" then return end
			if !IsValid( self.Enemy ) then return end
			self:ShootRight()
		end )
		timer.Simple( 1.66, function()
			if !IsValid( self ) || !self.Schedule || self.Schedule.m_sName != "MentalHordeScrapJackRocketeerShootRage" then return end
			if !IsValid( self.Enemy ) then return end
			self:ShootLeft()
		end )
		timer.Simple( 2, function()
			if !IsValid( self ) || !self.Schedule || self.Schedule.m_sName != "MentalHordeScrapJackRocketeerShootRage" then return end
			if !IsValid( self.Enemy ) then return end
			self:ShootRight()
		end )
		timer.Simple( 2.33, function()
			if !IsValid( self ) || !self.Schedule || self.Schedule.m_sName != "MentalHordeScrapJackRocketeerShootRage" then return end
			if !IsValid( self.Enemy ) then return end
			self:ShootLeft()
		end )
		timer.Simple( 2.66, function()
			if !IsValid( self ) || !self.Schedule || self.Schedule.m_sName != "MentalHordeScrapJackRocketeerShootRage" then return end
			if !IsValid( self.Enemy ) then return end
			self:ShootRight()
		end )
		timer.Simple( 3, function()
			if !IsValid( self ) || !self.Schedule || self.Schedule.m_sName != "MentalHordeScrapJackRocketeerShootRage" then return end
			if !IsValid( self.Enemy ) then return end
			self:ShootLeft()
		end )
		timer.Simple( 3.33, function()
			if !IsValid( self ) || !self.Schedule || self.Schedule.m_sName != "MentalHordeScrapJackRocketeerShootRage" then return end
			if !IsValid( self.Enemy ) then return end
			self:ShootRight()
		end )
		timer.Simple( 3.66, function()
			if !IsValid( self ) || !self.Schedule || self.Schedule.m_sName != "MentalHordeScrapJackRocketeerShootRage" then return end
			if !IsValid( self.Enemy ) then return end
			self:ShootLeft()
		end )
		timer.Simple( 4, function()
			if !IsValid( self ) || !self.Schedule || self.Schedule.m_sName != "MentalHordeScrapJackRocketeerShootRage" then return end
			if !IsValid( self.Enemy ) then return end
			self:ShootRight()
		end )
		timer.Simple( 4.33, function()
			if !IsValid( self ) || !self.Schedule || self.Schedule.m_sName != "MentalHordeScrapJackRocketeerShootRage" then return end
			if !IsValid( self.Enemy ) then return end
			self:ShootLeft()
		end )
		timer.Simple( 4.66, function()
			if !IsValid( self ) || !self.Schedule || self.Schedule.m_sName != "MentalHordeScrapJackRocketeerShootRage" then return end
			if !IsValid( self.Enemy ) then return end
			self:ShootRight()
		end )
		timer.Simple( 5, function()
			if !IsValid( self ) || !self.Schedule || self.Schedule.m_sName != "MentalHordeScrapJackRocketeerShootRage" then return end
			if !IsValid( self.Enemy ) then return end
			self:ShootLeft()
		end )
		timer.Simple( 5.33, function()
			if !IsValid( self ) || !self.Schedule || self.Schedule.m_sName != "MentalHordeScrapJackRocketeerShootRage" then return end
			if !IsValid( self.Enemy ) then return end
			self:ShootRight()
		end )
		timer.Simple( 5.66, function()
			if !IsValid( self ) || !self.Schedule || self.Schedule.m_sName != "MentalHordeScrapJackRocketeerShootRage" then return end
			if !IsValid( self.Enemy ) then return end
			self:ShootLeft()
		end )
		timer.Simple( 6, function()
			if !IsValid( self ) || !self.Schedule || self.Schedule.m_sName != "MentalHordeScrapJackRocketeerShootRage" then return end
			if !IsValid( self.Enemy ) then return end
			self:ShootRight()
		end )
		timer.Simple( 6.33, function()
			if !IsValid( self ) || !self.Schedule || self.Schedule.m_sName != "MentalHordeScrapJackRocketeerShootRage" then return end
			if !IsValid( self.Enemy ) then return end
			self:ShootLeft()
		end )
	end
	if CurTime() > sched.flEndTime then return true end
end )
