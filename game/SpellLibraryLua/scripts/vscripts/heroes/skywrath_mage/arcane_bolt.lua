ability_skywrath_mage_arcane_bolt = class({})

function ability_skywrath_mage_arcane_bolt:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	local projectile_particle = "particles/units/heroes/hero_skywrath_mage/skywrath_mage_arcane_bolt.vpcf"
	local projectile_speed = self:GetSpecialValueFor("bolt_speed")
	self.projectile_vision = self:GetSpecialValueFor("bolt_vision")
	self.vision_duration = self:GetSpecialValueFor("vision_duration")

	local base_damage = self:GetSpecialValueFor("bolt_damage")
	local int_multiplier = self:GetSpecialValueFor("int_multiplier")

	if caster:IsHero() then
		self.damage = base_damage * int_multiplier
	end

	ProjectileManager:CreateTrackingProjectile({
		Target = target,
		Source = caster,
		Ability = self,

		EffectName = projectile_particle,
		iMoveSpeed = projectile_speed,
		bDodgeable = false,

		bVisibleToEnemies = true,

		bProvidesVision = true,
		iVisionRadius = self.projectile_vision,
		iVisionTeamNumber = caster:GetTeamNumber()
	})
	
	caster:EmitSound("Hero_SkywrathMage.ArcaneBolt.Cast")
end

function ability_skywrath_mage_arcane_bolt:OnProjectileHit(hTarget, vLocation)
	if hTarget ~= nil and hTarget:TriggerSpellAbsorb(self) == false then
		ApplyDamage({
			victim = hTarget,
			attacker = self:GetCaster(),
			ability = self,
			damage = self.damage,
			damage_type = self:GetAbilityDamageType(),
		})

		AddFOWViewer(self:GetCaster():GetTeamNumber(), vLocation, self.projectile_vision, self.vision_duration, false)

		hTarget:EmitSound("Hero_SkywrathMage.ArcaneBolt.Impact")
		self:GetCaster():StopSound("Hero_SkywrathMage.ArcaneBolt.Cast")
	end
end