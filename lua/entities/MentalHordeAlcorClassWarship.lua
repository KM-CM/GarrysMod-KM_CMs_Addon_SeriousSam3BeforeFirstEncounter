// Deployment hatch bones
// 1  -> SpawnSlot08
// 2  -> SpawnSlot04
// 3  -> SpawnSlot09
// 4  -> SpawnSlot05
// 5  -> SpawnSlot01
// 6  -> SpawnSlot07
// 7  -> SpawnSlot06
// 8  -> SpawnSlot02
// 9  -> SpawnSlot00
// 10 -> SpawnSlot03
// Which is which? No idea...

AddCSLuaFile()
DEFINE_BASECLASS "BaseActor"

scripted_ents.Register( ENT, "MentalHordeAlcorClassWarship" )

ENT.CATEGORIZE = {
	MentalHorde = true,
	AlcorClassWarship = true,
	Warship = true,
	Spaceship = true
}

list.Set( "NPC", "MentalHordeAlcorClassWarship", {
	Name = "#MentalHordeAlcorClassWarship",
	Class = "MentalHordeAlcorClassWarship",
	Category = "#MentalHorde",
	AdminOnly = true
} )

if !SERVER then return end

ENT.HAS_MELEE_ATTACK = true

ENT.GAME_bDontIgnite = true

ENT.bPhysics = true

if !CLASS_MENTAL_HORDE then Add_NPC_Class "CLASS_MENTAL_HORDE" end
ENT.iDefaultClass = CLASS_MENTAL_HORDE

ENT.bVisNot360 = false
ENT.flVisionPitch = 180
ENT.flVisionYaw = 180

ENT.flTopSpeed = 8192
ENT.flRunSpeed = 4096
ENT.flWalkSpeed = 1024
ENT.flAcceleration = 8192

ENT.flTurnRate = 2048
ENT.flTurnAcceleration = 512

ENT.flCapacity = 20000

ENT.tHatchesOpen = {} // Bone ID 1-10 -> true / nil
ENT.tNextHatchDeploy = {} // Bone ID 1-10 -> Time / nil
ENT.tHatchTargets = {} // Bone ID 1-10 -> { flVerticalOffset, flHorizontalOffset }

Actor_RegisterSchedule( "MentalHordeAlcorClassWarshipCombat", function( self, sched )
	local pEnemy = self.Enemy
	if !IsValid( pEnemy ) then return true end
	local pPhys = self:GetPhysicsObject()
	if !IsValid( pPhys ) then self:Remove() return true end
	local pEnemy, pTrueEnemy = self:SetupEnemy( pEnemy )
	if ( pEnemy:GetPos() + pEnemy:OBBCenter() - ( self:GetPos() + self:OBBCenter() ) ):GetNormalized():Dot( Vector( 0, 0, -1 ) ) > .70710678118 then
		if self.flCapacity > 0 then
			local iHatches
			local flRatio = self:Health() / self:GetMaxHealth()
			if flRatio <= .25 then iHatches = 10
			else iHatches = math.Round( Lerp( ( flRatio - .25 ) / .75, 10, 1 ) ) end
			local tHatchesOpen = self.tHatchesOpen
			local tNextHatchDeploy = self.tNextHatchDeploy
			if table.Count( tHatchesOpen ) != iHatches then
				table.Empty( tHatchesOpen )
				local iCurrent = 0
				while iCurrent < iHatches do
					local iHatch = math.random( 1, 10 )
					if !tHatchesOpen[ iHatch ] then
						tHatchesOpen[ iHatch ] = true
						iCurrent = iCurrent + 1
						if CurTime() > ( tNextHatchDeploy[ iHatch ] || 0 ) then
							tNextHatchDeploy[ iHatch ] = CurTime() + math.Rand( 0, 30 )
						end
					end
				end
			end
			local tHatchTargets = self.tHatchTargets
			local tSpawn = { "MentalHordeBeHeadedKamikaze", "MentalHordeBeHeadedRocketeer" }
			local iSpawnLength = #tSpawn
			for i in RandomPairs( tHatchesOpen ) do
				if !tHatchesOpen[ i ] then continue end
				-------------------------------------------------
				// Draw a developer only epic "beam" for now
				local vBone = self:GetBonePosition( i )
				local tOffset = tHatchTargets[ i ]
				if !tOffset then tOffset = { math.Rand( -1, 1 ), math.Rand( -1, 1 ) } tHatchTargets[ i ] = tOffset end
				local dTarget = -self:GetUp() + self:GetForward() * tOffset[ 1 ] + self:GetRight() * tOffset[ 2 ]
				dTarget:Normalize()
				local tr = util.TraceLine {
					start = vBone,
					endpos = vBone + dTarget * 999999,
					mask = MASK_SOLID,
					filter = self
				}
				local flDistanceHalf = tr.StartPos:Distance( tr.HitPos ) * .5
				local flSize = 192
				debugoverlay.BoxAngles(
					LerpVector( .5, tr.StartPos, tr.HitPos ),
					Vector( -flDistanceHalf, -flSize, -flSize ),
					Vector( flDistanceHalf, flSize, flSize ),
					( tr.HitPos - tr.StartPos ):Angle(),
					FrameTime() * 4, Color( 255, 64, 0, 64 )
				)
				-------------------------------------------------
				if CurTime() <= ( tNextHatchDeploy[ i ] || 0 ) then continue end
				//	if !tHatchesOpen[ i ] || CurTime() <= ( tNextHatchDeploy[ i ] || 0 ) then continue end
				//	local vBone = self:GetBonePosition( i )
				//	local tOffset = tHatchTargets[ i ]
				//	if !tOffset then tOffset = { math.Rand( -1, 1 ), math.Rand( -1, 1 ) } tHatchTargets[ i ] = tOffset end
				//	local dTarget = -self:GetUp() + self:GetForward() * tOffset[ 1 ] + self:GetRight() * tOffset[ 2 ]
				//	dTarget:Normalize()
				//	local tr = util.TraceLine {
				//		start = vBone,
				//		endpos = vBone + dTarget * 999999,
				//		mask = MASK_SOLID,
				//		filter = self
				//	}
				tNextHatchDeploy[ i ] = CurTime() + 30
				local pEntity = self:CreateActor( tSpawn[ math.random( 1, iSpawnLength ) ] )
				if !IsValid( pEntity ) then continue end
				pEntity:SetPos( tr.HitPos )
				pEntity:SetAngles( Angle( 0, math.Rand( 0, 360 ), 0 ) )
				pEntity:Spawn()
				self.flCapacity = self.flCapacity - 1
			end
		else self.tHatchesOpen = {} end
	else self:SetSchedule "MentalHordeAlcorClassWarshipCombatFlyTo" end
end )

Actor_RegisterSchedule( "MentalHordeAlcorClassWarshipCombatFlyTo", function( self, sched )
	local pEnemy = self.Enemy
	if !IsValid( pEnemy ) then return true end
	local pPhys = self:GetPhysicsObject()
	if !IsValid( pPhys ) then self:Remove() return true end
	local pEnemy, pTrueEnemy = self:SetupEnemy( pEnemy )
	local vEnemy = pEnemy:GetPos() + pEnemy:OBBCenter()
	local dTarget = vEnemy - ( self:GetPos() + self:OBBCenter() )
	if dTarget:GetNormalized():Dot( Vector( 0, 0, -1 ) ) > .70710678118 then return true end
	local dActualTarget = -dTarget
	dActualTarget[ 3 ] = 0
	dActualTarget:Normalize()
	local pPhys = self:GetPhysicsObject()
	pPhys:AddAngleVelocity( CalculateAngularVelocity( dActualTarget, self:GetForward(), pPhys:GetAngleVelocity(), self.flTurnRate, self.flTurnAcceleration ) )
	local vTarget = Vector( vEnemy )
	vTarget[ 3 ] = vTarget[ 3 ] + self:BoundingRadius() * .5
	pPhys:AddVelocity( CalculateVelocity( vTarget, pPhys:GetPos(), pPhys:GetVelocity(), self.flTopSpeed, self.flAcceleration ) )
end )

function ENT:SelectSchedule( MyTable )
	if IsValid( MyTable.Enemy ) then
		MyTable.SetNPCState( self, NPC_STATE_COMBAT )
		MyTable.SetSchedule( self, "MentalHordeAlcorClassWarshipCombat", MyTable )
	else
		// MyTable.SetNPCState( self, NPC_STATE_ALERT )
		// MyTable.SetSchedule( self, "Idle", MyTable )
	end
end

// TODO: Find a realistic size! 6.3 is too huge, I've played Serious Sam 3,
// it's way smaller than this model x6.3 here... sticking with 4.725 for now!
ENT.vHullMins = Vector( -7293.954102, -6743.916504, -638.471313 )

ENT.vHullMaxs = Vector( 3234.098389, 6623.176270, 5037.575684 )

local table_insert = table.insert
local math_random = math.random

function ENT:Initialize()
	self:SetModel "models/ss3_spaceship_alcor.mdl"
	self:SetHealth( 4194304 )
	self:SetMaxHealth( 4194304 )
	self:SetBloodColor( -1 )
	self:SetModelScale( 4.725 )
	self:SetCollisionBounds( self.vHullMins / 4.725, self.vHullMaxs / 4.725 )
	self:PhysicsInit( SOLID_OBB )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	local pPhys = self:GetPhysicsObject()
	if IsValid( pPhys ) then pPhys:EnableGravity( false )
	else self:Remove() return end
	BaseClass.Initialize( self )
end

function ENT:OnKilled( dmg )
	if BaseClass.OnKilled( self, dmg ) then return end
	self:Remove()
end
