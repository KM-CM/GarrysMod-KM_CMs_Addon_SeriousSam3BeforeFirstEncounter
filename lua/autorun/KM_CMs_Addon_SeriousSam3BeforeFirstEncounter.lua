game.AddParticles "particles/SS3Muzzles.pcf" 
game.AddParticles "particles/SS3EntityParticles.pcf"

sound.Add {
	name = "SS3_Splat",
	channel = CHAN_STATIC,
	level = 150,
	sound = {
		"SS3_Splat/1.wav",
		"SS3_Splat/2.wav",
		"SS3_Splat/3.wav"
	}
}

// The game automatically tries to precache particle systems as soon as they're used
// local PrecacheParticleSystem = PrecacheParticleSystem
// PrecacheParticleSystem "SS3_Kamikaze_Smoke"
// PrecacheParticleSystem "SS3_Kamikaze_Explosion"
// PrecacheParticleSystem "SS3_Kamikaze_ExpParts"
// PrecacheParticleSystem "SS3_Rocketeer_Grenade_Explosion"
// PrecacheParticleSystem "SS3_KHNUM_FIREBALL1"
// PrecacheParticleSystem "SS3_KHNUM_FIREBALL2"
// PrecacheParticleSystem "SS3_Rocketeer_Grenade_Flash"
// PrecacheParticleSystem "SS3_ROCKETMAN_TRACER"
// PrecacheParticleSystem "SS3_ROCKETTRAIL"
// PrecacheParticleSystem "SS3_SmallBiomech_Impact"
// PrecacheParticleSystem "SS3_SmallBiomech_Impact_Sparks"
// PrecacheParticleSystem "SS3_BiomechSmall_Muzzle"
// PrecacheParticleSystem "SS3_RocketExplosion"
// PrecacheParticleSystem "SS3_KhnumFireball_Trail"
// PrecacheParticleSystem "SS3_Reptiloid_Charge" 
// PrecacheParticleSystem "SS3_ReptProjExp"  
// PrecacheParticleSystem "SS3_ReptGreenProj_Trail"  
// PrecacheParticleSystem "SS3_BulletTracer" 
// PrecacheParticleSystem "SS3BFE_BloodSplat"
// PrecacheParticleSystem "SS3BFE_Gib"
// PrecacheParticleSystem "SS3BFE_Explosion_Kamikaze"
// PrecacheParticleSystem "SS3BFE_SpawnEf"
// PrecacheParticleSystem "SS3BFE_SpawnFlare"
// PrecacheParticleSystem "SS3_SpiderProj_drisnya"
// PrecacheParticleSystem "SS3_SpiderProj_Impact"
// PrecacheParticleSystem "SS3_SpiderBloodDrops"
// PrecacheParticleSystem "SS3_BiomechRocketFlare"  
// PrecacheParticleSystem "SS3_BiomechRocketTrail_Flames" 
// PrecacheParticleSystem "SS3_BiomechRocket_SmokeTrail" 
// PrecacheParticleSystem "SS3_BiomechanoidRocketTrail" 
// PrecacheParticleSystem "SS3_EnemyRL_Shot"
// PrecacheParticleSystem "SS3_Witch_FlameModelPlacement"  
// PrecacheParticleSystem "SS3BFE_BloodTrail_Large" 
// PrecacheParticleSystem "SS3BFE_BloodTrail_Middle" 
// PrecacheParticleSystem "SS3BFE_Shoot_AssaultRifle"
// PrecacheParticleSystem "SS3_werebullrun"
