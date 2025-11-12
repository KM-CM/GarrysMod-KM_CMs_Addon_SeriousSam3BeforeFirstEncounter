AddCSLuaFile()
DEFINE_BASECLASS "BaseProjectile"

scripted_ents.Register( ENT, "MentalHordeRocketLarge" )

if !SERVER then return end

function ENT:Initialize()
	self:SetModel "models/ss3_bbiomechrocket.mdl"
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetHealth( 128 )
	self:SetMaxHealth( 128 )
	ParticleEffectAttach( "SS3_BiomechRocketFlare", PATTACH_ABSORIGIN_FOLLOW, self, 1 )
	ParticleEffectAttach( "SS3_BiomechRocket_SmokeTrail", PATTACH_ABSORIGIN_FOLLOW, self, 1 )
 	ParticleEffectAttach( "SS3_BiomechanoidRocketTrail", PATTACH_ABSORIGIN_FOLLOW, self, 1 )
	util.SpriteTrail( self, 0, Color( 255, 255, 255, 255 ), false, 20, 20, 1, .1125, "trails/ss3_smoke_trail.vmt" )
end

ENT.__PROJECTILE_EXPLOSION__ = true
ENT.EXPLOSION_flDamage = 2048
ENT.EXPLOSION_flRadius = 96

ENT.__PROJECTILE_ROCKET__ = true
ENT.ROCKET_flSpeed = 1020

function ENT:Think()
	local pPhys = self:GetPhysicsObject()
	if !IsValid( pPhys ) then return end
	pPhys:SetVelocity( self:GetForward() * self.ROCKET_flSpeed )
	self:NextThink( CurTime() )
	return true
end

function ENT:Detonate()
	if self.bDetonated then return end
	local v = self:GetPos() + self:OBBCenter()
	util.BlastDamage( self, IsValid( self:GetOwner() ) && self:GetOwner() || self, v, self.EXPLOSION_flRadius, self.EXPLOSION_flDamage )
	ParticleEffect( "SS3_RocketExplosion", self:GetPos(), self:GetAngles(), nil )
	// Not using the custom sound because it SUCKS!
	self:EmitSound( self:WaterLevel() < 3 && "BaseExplosionEffect.Water" || "BaseExplosionEffect.Sound" ) 
	self.bDetonated = true
	self:Remove()
end

function ENT:PhysicsCollide() self:Detonate() end

function ENT:OnTakeDamage( dDamage )
	if self.bDead then return 0 end
	self:SetHealth( self:Health() - dDamage:GetDamage() )
	if self:Health() <= 0 then self.bDead = true self:Detonate() return 0 end
end
