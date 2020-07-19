LinkLuaModifier("modifier_skywrath_mage_concussive_shot", "heroes/skywrath_mage/concussive_shot.lua", 0)

ability_skywrath_mage_concussive_shot = class({})

function ability_skywrath_mage_concussive_shot:OnSpellStart()
	local caster = self:GetCaster()
	local target = nil

	local search_radius = self:GetSpecialValueFor("launch_radius")

	local projectile_particle = "particles/units/heroes/hero_skywrath_mage/skywrath_mage_concussive_shot.vpcf"
	local projectile_speed = self:GetSpecialValueFor("speed")
	local projectile_vision = self:GetSpecialValueFor("shot_vision")

	local enemies = FindUnitsInRadius(
		caster:GetTeam(),
		caster:GetOrigin(),
		nil,
		search_radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS,
		FIND_CLOSEST,
		false
	)

	if #enemies == 0 then
		local particle = "particles/units/heroes/hero_skywrath_mage/skywrath_mage_concussive_shot_failure.vpcf"
		local fx = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
		ParticleManager:ReleaseParticleIndex(fx)
	else
		for _, enemy in pairs(enemies) do
			if enemy:IsHero() then
				target = enemy
				break
			end

			if not target then
				target = enemies[1]
			end
		end

		ProjectileManager:CreateTrackingProjectile({
			Target = target,
			Source = caster,
			Ability = self,

			EffectName = projectile_particle,
			iMoveSpeed = projectile_speed,
			bDodgeable = true,

			bVisibleToEnemies = true,

			bProvidesVision = true,
			iVisionRadius = projectile_vision,
			iVisionTeamNumber = caster:GetTeamNumber()
		})

		local cast_particle = "particles/units/heroes/hero_skywrath_mage/skywrath_mage_concussive_shot_cast.vpcf"
		local fx1 = ParticleManager:CreateParticle(cast_particle, PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControlEnt(fx1, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)
		ParticleManager:SetParticleControlEnt(fx1, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)

	end
	caster:EmitSound("Hero_SkywrathMage.ConcussiveShot.Cast")
end

function ability_skywrath_mage_concussive_shot:OnProjectileHit(hTarget, vLocation)
	if hTarget ~= nil then
		local caster = self:GetCaster()

		local radius = self:GetSpecialValueFor("slow_radius")
		local slow_duration = self:GetSpecialValueFor("slow_duration")
		local vision = self:GetSpecialValueFor("shot_vision")
		local vision_duration = self:GetSpecialValueFor("vision_duration")

		local enemies = FindUnitsInRadius(caster:GetTeam(), hTarget:GetOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false)

		for _, enemy in pairs(enemies) do
			local damage = self:GetSpecialValueFor("damage")
			local creep_mult = self:GetSpecialValueFor("creep_damage_pct")
			if enemy:IsCreep() then
				damage = damage * (creep_mult / 100)
			end

			ApplyDamage({
				victim = enemy,
				attacker = caster,
				Ability = self,
				damage = damage,
				damage_type = self:GetAbilityDamageType()
			})

			enemy:AddNewModifier(caster, self, "modifier_skywrath_mage_concussive_shot", {duration = slow_duration})
		end

		AddFOWViewer(caster:GetTeam(), vLocation, vision, vision_duration, false)

		hTarget:EmitSound("Hero_SkywrathMage.ConcussiveShot.Target")
	end
end

modifier_skywrath_mage_concussive_shot = class({
	IsHidden = function() return false end,
	IsPurgable = function() return true end,
	IsBuff = function() return false end,
	IsDebuff = function() return true end,
	IsStunDebuff = function() return false end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
	} end,
	GetEffectName = function() return "particles/units/heroes/hero_skywrath_mage/skywrath_mage_concussive_shot_slow_debuff.vpcf" end,
	GetEffectAttachType = function() return PATTACH_ABSORIGIN_FOLLOW end
})

function modifier_skywrath_mage_concussive_shot:OnCreated()
	self.slow = -self:GetAbility():GetSpecialValueFor("movement_speed_pct")
end

function modifier_skywrath_mage_concussive_shot:OnRefresh()
	self:OnCreated()
end

function modifier_skywrath_mage_concussive_shot:GetModifierMoveSpeedBonus_Percentage()
	return self.slow
end