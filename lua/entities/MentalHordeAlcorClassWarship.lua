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

Actor_RegisterSchedule( "MentalHordeAlcorClassWarshipTick", function( self, sched )
	local enemy = self.Enemy
	if !IsValid( enemy ) then return true end
end )

function ENT:SelectSchedule( MyTable )
	if IsValid( MyTable.Enemy ) then
		MyTable.SetNPCState( self, NPC_STATE_COMBAT )
		MyTable.SetSchedule( self, "MentalHordeAlcorClassWarshipTick", MyTable )
	else
		// MyTable.SetNPCState( self, NPC_STATE_ALERT )
		// MyTable.SetSchedule( self, "Idle", MyTable )
	end
end

ENT.vHullMins = Vector( -9725.2724609375, -8991.888671875, -851.29510498047 )
ENT.vHullMaxs = Vector( 4312.1313476563, 8830.90234375, 6716.767578125 )

function ENT:Initialize()
	self:SetModel "models/ss3_spaceship_alcor.mdl"
	self:SetHealth( 4194304 )
	self:SetMaxHealth( 4194304 )
	self:SetBloodColor( -1 )
	self:SetModelScale( 6.3 )
	self:SetCollisionBounds( self.vHullMins / self:GetModelScale(), self.vHullMaxs / self:GetModelScale() )
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
