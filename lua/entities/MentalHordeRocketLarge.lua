AddCSLuaFile()
DEFINE_BASECLASS "BaseProjectile"

scripted_ents.Register( ENT, "MentalHordeRocketLarge" )

if !SERVER then return end

local SOLID_VPHYSICS = SOLID_VPHYSICS
local ParticleEffectAttach = ParticleEffectAttach
local PATTACH_ABSORIGIN_FOLLOW = PATTACH_ABSORIGIN_FOLLOW
local util_SpriteTrail = util.SpriteTrail

local CEntity = FindMetaTable "Entity"
local CEntity_SetModel = CEntity.SetModel
local CEntity_PhysicsInit = CEntity.PhysicsInit
local CEntity_SetHealth = CEntity.SetHealth
local CEntity_SetMaxHealth = CEntity.SetMaxHealth

function ENT:Initialize()
	CEntity_SetModel( self, "models/ss3_bbiomechrocket.mdl" )
	CEntity_PhysicsInit( self, SOLID_VPHYSICS )
	CEntity_SetHealth( self, 128 )
	CEntity_SetMaxHealth( self, 128 )
	ParticleEffectAttach( "SS3_BiomechRocketFlare", PATTACH_ABSORIGIN_FOLLOW, self, 1 )
	ParticleEffectAttach( "SS3_BiomechRocket_SmokeTrail", PATTACH_ABSORIGIN_FOLLOW, self, 1 )
 	ParticleEffectAttach( "SS3_BiomechanoidRocketTrail", PATTACH_ABSORIGIN_FOLLOW, self, 1 )
	util_SpriteTrail( self, 0, Color( 255, 255, 255, 255 ), false, 20, 20, 1, .1125, "trails/ss3_smoke_trail.vmt" )
end

ENT.__PROJECTILE_EXPLOSION__ = true
ENT.EXPLOSION_flDamage = 2048
ENT.EXPLOSION_flRadius = 96

ENT.__PROJECTILE_ROCKET__ = true
ENT.ROCKET_flSpeed = 2048

local CEntity_GetPhysicsObject = CEntity.GetPhysicsObject
local CEntity_GetForward = CEntity.GetForward
local CEntity_GetTable = CEntity.GetTable
local CEntity_NextThink = CEntity.NextThink
local CurTime = CurTime

function ENT:Think()
	local pPhys = CEntity_GetPhysicsObject( self )
	if !IsValid( pPhys ) then return end
	pPhys:SetVelocity( CEntity_GetForward( self ) * CEntity_GetTable( self ).ROCKET_flSpeed )
	CEntity_NextThink( self, CurTime() )
	return true
end

local util_BlastDamage = util.BlastDamage
local CEntity_GetOwner = CEntity.GetOwner
local IsValid = IsValid
local ParticleEffect = ParticleEffect

local CEntity_GetPos = CEntity.GetPos
local CEntity_OBBCenter = CEntity.OBBCenter
local CEntity_EmitSound = CEntity.EmitSound
local CEntity_GetAngles = CEntity.GetAngles
local CEntity_EmitSound = CEntity.EmitSound
local CEntity_WaterLevel = CEntity.WaterLevel
local CEntity_Remove = CEntity.Remove

function ENT:Detonate( MyTable )
	MyTable = MyTable || CEntity_GetTable( self )
	if MyTable.bDetonated then return end
	local vPos = CEntity_GetPos( self )
	local v = vPos + CEntity_OBBCenter( self )
	local pOwner = CEntity_GetOwner( self )
	util_BlastDamage( self, IsValid( pOwner ) && pOwner || self, v, MyTable.EXPLOSION_flRadius, MyTable.EXPLOSION_flDamage )
	ParticleEffect( "SS3_RocketExplosion", vPos, CEntity_GetAngles( self ), nil )
	// Not using the custom sound because it SUCKS!
	CEntity_EmitSound( self, CEntity_WaterLevel( self ) < 3 && "BaseExplosionEffect.Water" || "BaseExplosionEffect.Sound" ) 
	MyTable.bDetonated = true
	CEntity_Remove( self )
end

function ENT:PhysicsCollide()
	local MyTable = CEntity_GetTable( self )
	MyTable.Detonate( self, MyTable )
end

local CEntity_Health = CEntity.Health

function ENT:OnTakeDamage( dDamage )
	local MyTable = CEntity_GetTable( self )
	if MyTable.bDead then return 0 end
	local f = CEntity_Health( self ) - dDamage:GetDamage()
	CEntity_SetHealth( self, f )
	if f <= 0 then MyTable.bDead = true MyTable.Detonate( self, MyTable ) return 0 end
end

