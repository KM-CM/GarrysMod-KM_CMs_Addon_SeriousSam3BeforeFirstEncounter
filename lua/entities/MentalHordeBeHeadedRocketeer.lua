AddCSLuaFile()
DEFINE_BASECLASS "BaseActor"

scripted_ents.Register( ENT, "MentalHordeBeHeadedRocketeer" )

ENT.CATEGORIZE = {
	MentalHorde = true,
	BeHeaded = true,
	Rocketeer = true
}

sound.Add {
	name = "MentalHorde_BeHeadedRocketeer_Fire",
	channel = CHAN_STATIC,
	level = 110,
	sound = {
		"MentalHorde/BeHeadedRocketeer/Fire/1.wav",
		"MentalHorde/BeHeadedRocketeer/Fire/2.wav"
	}
}

list.Set( "NPC", "MentalHordeBeHeadedRocketeer", {
	Name = "#MentalHordeBeHeadedRocketeer",
	Class = "MentalHordeBeHeadedRocketeer",
	Category = "#MentalHorde"
} )

if !SERVER then return end

ENT.HAS_MELEE_ATTACK = true
ENT.HAS_RANGE_ATTACK = true

ENT.flIdleStandTimeMin = 0
ENT.flIdleStandTimeMax = 0

ENT.bCombatForgetLastHostile = true

ENT.flTopSpeed = 160
ENT.flProwlSpeed = ENT.flTopSpeed
ENT.flWalkSpeed = 75

function ENT:MoveAlongPath( pPath, flSpeed, _, tFilter )
	self.loco:SetDesiredSpeed( flSpeed )
	local f = flSpeed * ACCELERATION_NORMAL
	self.loco:SetAcceleration( f )
	self.loco:SetDeceleration( f )
	self.loco:SetJumpHeight( 256 )
	local f = GetVelocity( self ):Length()
	if f <= 12 then self:PromoteSequence "idle"
	elseif f <= ( self.flWalkSpeed * 1.1 ) then
		self:PromoteSequence( "walk", GetVelocity( self ):Length() / self:GetSequenceGroundSpeed( self:LookupSequence "walk" ) )
	else
		self:PromoteSequence( "run", GetVelocity( self ):Length() / self:GetSequenceGroundSpeed( self:LookupSequence "run" ) )
	end
	self:HandleJumpingAlongPath( pPath, flSpeed, tFilter )
end

function ENT:Stand() BaseClass.Stand( self ) end

function ENT:GetShootPos() return self:GetAttachment( 1 ).Pos end

local CEntity_EmitSound = FindMetaTable( "Entity" ).EmitSound

ENT.flShot = 0
ENT.flWalk = 0
Actor_RegisterSchedule( "MentalHordeBeHeadedRocketeerCombat", function( self, sched )
	local enemy = self.Enemy
	if !IsValid( enemy ) then return true end
	self:SetNPCState( NPC_STATE_COMBAT )
	local enemy, trueenemy = self:SetupEnemy( enemy )
	if CurTime() <= self.flShot then
		self.flWalk = CurTime() + math.Rand( 1, 4 )
		self:SelectAim( enemy, self:GetShootPos(), 2048, 96, 0 )
		self:AnimationSystemHalt()
		self.loco:SetDesiredSpeed( 0 )
		self.loco:Approach( self:GetPos(), 1 )
		return
	end
	local pPath = sched.pPath
	if !pPath then pPath = Path "Follow" sched.pPath = pPath end
	self:ComputeFlankPath( pPath, enemy )
	self:MoveAlongPath( pPath, self.flTopSpeed )
	if CurTime() > self.flWalk && self:Visible( enemy ) then
		self:SelectAim( enemy, self:GetShootPos(), 2048, 96, 24 )
		if self:GetAimVector():Dot( self.vDesAim ) < .999 then return end
		local pProjectile = self:CreateProjectile "MentalHordeRocketSmall"
		if !IsValid( pProjectile ) then return end
		pProjectile:SetPos( self:GetShootPos() )
		pProjectile:SetAngles( self:GetAimVector():Angle() )
		pProjectile:Spawn()
		CEntity_EmitSound( self, "MentalHorde_BeHeadedRocketeer_Fire" )
		self:AddGestureSequence( self:LookupSequence "shot" )
		self.flShot = CurTime() + 3.25
	else
		local goal = pPath:GetCurrentGoal()
		local v = self:GetPos()
		if goal then self.vDesAim = ( goal.pos - v ):GetNormalized() end
	end
end )

function ENT:SelectSchedule( MyTable )
	if IsValid( MyTable.Enemy ) then
		MyTable.SetNPCState( self, NPC_STATE_COMBAT )
		MyTable.SetSchedule( self, "MentalHordeBeHeadedRocketeerCombat", MyTable )
	else
		MyTable.SetNPCState( self, NPC_STATE_ALERT )
		MyTable.SetSchedule( self, "Idle", MyTable )
	end
end

if !CLASS_MENTAL_HORDE then Add_NPC_Class "CLASS_MENTAL_HORDE" end
ENT.iDefaultClass = CLASS_MENTAL_HORDE

function ENT:Initialize()
	self:SetModel "models/ss3_rocketman.mdl" // WHO IN GOD'S NAME NAMED THE MODEL THAT?! WHAT THE HELL?!
	// Use 200 for unrealistic but fun health and 256 for a bit harder...
	// This one is way more hard but it is pretty much realistic for Sirians with LCUs
	self:SetHealth( 384 )
	self:SetMaxHealth( 384 )
	self:SetBloodColor( -1 )
	BaseClass.Initialize( self )
end

function ENT:Think( ... )
	local vHullMins, vHullMaxs = self.vHullMins, self.vHullMaxs
	local vHullMinsCurrent, vHullMaxsCurrent = self:GetCollisionBounds()
	if vHullMaxsCurrent != vHullMins || vHullMaxsCurrent != vHullMaxs then
		self:SetCollisionBounds( vHullMins, vHullMaxs )
		if !IsValid( self:GetParent() ) && self:PhysicsInitShadow( false, false ) then
			local p = self:GetPhysicsObject()
			if IsValid( p ) then p:SetMass( 85 ) end
		end
	end
	return BaseClass.Think( self, ... )
end

local tWound = { "wound", "wound2", "wound3", "wound4", "wound5" }
local iWoundLength = 5
function ENT:Behaviour( MyTable )
	local flLastHealth = MyTable.flLastHealth
	if flLastHealth then
		if flLastHealth > self:GetMaxHealth() * .5 && self:Health() <= self:GetMaxHealth() * .5 then
			MyTable.AnimationSystemHalt( self, MyTable )
			MyTable.flLastHealth = self:Health()
			MyTable.PlaySequenceAndWait( self, self:LookupSequence( tWound[ math.random( 1, iWoundLength ) ] ), 1 )
			return
		end
	end
	MyTable.flLastHealth = self:Health()
	BaseClass.Behaviour( self, MyTable )
end

function ENT:OnKilled( dmg )
	if BaseClass.OnKilled( self, dmg ) || self.bBlowUp then return end
	self:Remove()
end
