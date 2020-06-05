ability_chaos_bolt = class({})

--------------------------------------------------------------------------------

function ability_chaos_bolt:OnSpellStart()
	-- get references
	local target = self:GetCursorTarget()
	local bolt_lua_speed = self:GetSpecialValueFor("chaos_bolt_speed")
	local projectile = "particles/units/heroes/hero_chaos_knight/chaos_knight_chaos_bolt.vpcf"

	-- Create Tracking Projectile
	local info = {
		Source = self:GetCaster(),
		Target = target,
		Ability = self,
		iMoveSpeed = bolt_lua_speed,
		EffectName = projectile,
		bDodgeable = true,
	}
	ProjectileManager:CreateTrackingProjectile( info )

	EmitSoundOn("Hero_ChaosKnight.ChaosBolt.Cast", self:GetCaster())
end

function ability_chaos_bolt:OnProjectileHit( hTarget, vLocation )

	if not hTarget or hTarget:IsInvulnerable() then
		return
	end

	if hTarget:TriggerSpellAbsorb( self ) then
		return
	end

	local damage_min = self:GetSpecialValueFor("damage_min")
	local damage_max = self:GetSpecialValueFor("damage_max")
	local stun_min = self:GetSpecialValueFor("stun_min")
	local stun_max = self:GetSpecialValueFor("stun_max")

	local rand = RandomFloat(0,1)
	local damage_act = self:Expand(rand,damage_min,damage_max)
	local stun_act = self:Expand(1-rand,stun_min,stun_max)

	ApplyDamage( {
		victim = hTarget,
		attacker = self:GetCaster(),
		damage = damage_act,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self
	})
	hTarget:AddNewModifier(self:GetCaster(),self,"modifier_stunned",{ duration = stun_act })

	self:PlayEffect2( hTarget, stun_act, damage_act )
end

function ability_chaos_bolt:Expand( value, min, max )
	return (max-min)*value + min
end

function ability_chaos_bolt:PlayEffect2( target, stun, damage )

	local digit = 4
	if damage < 100 then digit = 3 end
	local digit1 = damage%10
	local digit2 = math.floor((damage%100)/10)
	local digit3 = math.floor((damage%1000)/100)
	local number = digit3*100 + digit2*10 + digit1

	local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_chaos_knight/chaos_knight_bolt_msg.vpcf", PATTACH_OVERHEAD_FOLLOW, target )
	ParticleManager:SetParticleControl( nFXIndex, 0, target:GetOrigin() )
	ParticleManager:SetParticleControl( nFXIndex, 1, Vector( 0, number, 3 ) )
	ParticleManager:SetParticleControl( nFXIndex, 2, Vector( 2, digit, 0 ) )
	ParticleManager:SetParticleControl( nFXIndex, 3, Vector( 0,	stun, 4 ) )
	ParticleManager:SetParticleControl( nFXIndex, 4, Vector( 2,	2, 0 ) )
	ParticleManager:ReleaseParticleIndex( nFXIndex )

	EmitSoundOn( "Hero_ChaosKnight.ChaosBolt.Impact", target )
end