ability_elder_dragon_form = {}

LinkLuaModifier( "modifier_ability_elder_dragon_form", "heroes/dragon_knight/elder_dragon_form", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_elder_dragon_form_corrosive", "heroes/dragon_knight/elder_dragon_form", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_elder_dragon_form_frost", "heroes/dragon_knight/elder_dragon_form", LUA_MODIFIER_MOTION_NONE )

function ability_elder_dragon_form:OnSpellStart()
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor("duration")

	caster:AddNewModifier(
		caster,
		self,
		"modifier_ability_elder_dragon_form",
		{ duration = duration }
	)
end

modifier_ability_elder_dragon_form = {}

modifier_ability_elder_dragon_form.effect_data = {
	[1] = {
		["projectile"] = "particles/units/heroes/hero_dragon_knight/dragon_knight_elder_dragon_corrosive.vpcf",
		["attack_sound"] = "Hero_DragonKnight.ElderDragonShoot1.Attack",
		["transform"] = "particles/units/heroes/hero_dragon_knight/dragon_knight_transform_green.vpcf",
		["scale"] = 0,
	},
	[2] = {
		["projectile"] = "particles/units/heroes/hero_dragon_knight/dragon_knight_elder_dragon_fire.vpcf",
		["attack_sound"] = "Hero_DragonKnight.ElderDragonShoot2.Attack",
		["transform"] = "particles/units/heroes/hero_dragon_knight/dragon_knight_transform_red.vpcf",
		["scale"] = 10,
	},
	[3] = {
		["projectile"] = "particles/units/heroes/hero_dragon_knight/dragon_knight_elder_dragon_frost.vpcf",
		["attack_sound"] = "Hero_DragonKnight.ElderDragonShoot3.Attack",
		["transform"] = "particles/units/heroes/hero_dragon_knight/dragon_knight_transform_blue.vpcf",
		["scale"] = 20,
	},
	[4] = {
		["projectile"] = "particles/units/heroes/hero_dragon_knight/dragon_knight_elder_dragon_frost.vpcf",
		["attack_sound"] = "Hero_DragonKnight.ElderDragonShoot3.Attack",
		["transform"] = "particles/units/heroes/hero_dragon_knight/dragon_knight_transform_blue.vpcf",
		["scale"] = 50,
	}
}

function modifier_ability_elder_dragon_form:IsHidden()
	return false
end

function modifier_ability_elder_dragon_form:IsDebuff()
	return false
end

function modifier_ability_elder_dragon_form:IsPurgable()
	return false
end

function modifier_ability_elder_dragon_form:OnCreated( kv )
	self.parent = self:GetParent()

	self.level = self:GetAbility():GetLevel()
	if self.parent:HasScepter() then
		self.level = self.level + 1
	end
	self.bonus_ms = self:GetAbility():GetSpecialValueFor( "bonus_movement_speed" )
	self.bonus_damage = self:GetAbility():GetSpecialValueFor( "bonus_attack_damage" )
	self.bonus_range = self:GetAbility():GetSpecialValueFor( "bonus_attack_range" )
	self.magic_resist = 0

	self.corrosive_duration = self:GetAbility():GetSpecialValueFor( "corrosive_breath_duration" )
	
	self.splash_radius = self:GetAbility():GetSpecialValueFor( "splash_radius" )
	self.splash_pct = self:GetAbility():GetSpecialValueFor( "splash_damage_percent" )/100
	
	self.frost_radius = self:GetAbility():GetSpecialValueFor( "frost_aoe" )
	self.frost_duration = self:GetAbility():GetSpecialValueFor( "frost_duration" )

	if self.level==4 then
		self.bonus_range = self.bonus_range + 100
		self.splash_pct = self.splash_pct * 1.5
		self.magic_resist = 30
	end

	if not IsServer() then return end

	self.parent:SetAttackCapability( DOTA_UNIT_CAP_RANGED_ATTACK )

	self:StartIntervalThink( 0.03 )
	self.projectile = self.effect_data[self.level].projectile
	self.attack_sound = self.effect_data[self.level].attack_sound
	self.scale = self.effect_data[self.level].scale

	self:PlayEffects()

	EmitSoundOn( "Hero_DragonKnight.ElderDragonForm", self.parent )
end

function modifier_ability_elder_dragon_form:OnRefresh( kv )
	self:OnCreated( kv )
end

function modifier_ability_elder_dragon_form:OnDestroy()
	if not IsServer() then return end

	self.parent:SetAttackCapability( DOTA_UNIT_CAP_MELEE_ATTACK )

	self:PlayEffects()

	EmitSoundOn( "Hero_DragonKnight.ElderDragonForm.Revert", self.parent )
end

function modifier_ability_elder_dragon_form:OnIntervalThink()
	self.parent:SetSkin( self.level-1 )
end

function modifier_ability_elder_dragon_form:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_MODEL_CHANGE,
		MODIFIER_PROPERTY_MODEL_SCALE,
		MODIFIER_PROPERTY_TRANSLATE_ATTACK_SOUND,
		MODIFIER_PROPERTY_PROJECTILE_NAME,
		MODIFIER_PROPERTY_PROJECTILE_SPEED_BONUS,
		MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
	}
end

function modifier_ability_elder_dragon_form:GetModifierBaseAttack_BonusDamage()
	return self.bonus_damage
end

function modifier_ability_elder_dragon_form:GetModifierMoveSpeedBonus_Constant()
	return self.bonus_ms
end

function modifier_ability_elder_dragon_form:GetModifierAttackRangeBonus()
	return self.bonus_range
end

function modifier_ability_elder_dragon_form:GetModifierMagicalResistanceBonus()
	return self.magic_resist
end

function modifier_ability_elder_dragon_form:GetModifierModelChange()
	return "models/heroes/dragon_knight/dragon_knight_dragon.vmdl"
end

function modifier_ability_elder_dragon_form:GetModifierModelScale()
	return self.scale
end

function modifier_ability_elder_dragon_form:GetAttackSound()
	return self.attack_sound
end

function modifier_ability_elder_dragon_form:GetModifierProjectileName()
	return self.projectile
end

function modifier_ability_elder_dragon_form:GetModifierProjectileSpeedBonus()
	return 900
end

function modifier_ability_elder_dragon_form:GetModifierProcAttack_Feedback( params )
	if params.target:GetTeamNumber()==self.parent:GetTeamNumber() then return end

	if self.level==1 then
		self:Corrosive( params.target )
	elseif self.level==2 then
		self:Corrosive( params.target )
		self:Splash( params.target, params.damage )
	elseif self.level==3 then
		self:Corrosive( params.target )
		self:Splash( params.target, params.damage )
		self:Frost( params.target )
	else
		self:Corrosive( params.target )
		self:Splash( params.target, params.damage )
		self:Frost( params.target )
	end

	EmitSoundOn( "Hero_DragonKnight.ProjectileImpact", params.target )
end

function modifier_ability_elder_dragon_form:Corrosive( target )
	target:AddNewModifier(
		self.parent,
		self:GetAbility(),
		"modifier_ability_elder_dragon_form_corrosive",
		{ duration = self.corrosive_duration }
	)
end

function modifier_ability_elder_dragon_form:Splash( target, damage )
	local enemies = FindUnitsInRadius(
		self.parent:GetTeamNumber(),
		target:GetOrigin(),
		nil,
		self.splash_radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,	-- 
		0,
		false
	)

	for _,enemy in pairs(enemies) do
		if enemy~=target then
			local damageTable = {
				victim = enemy,
				attacker = self.parent,
				damage = damage * self.splash_pct,
				damage_type = DAMAGE_TYPE_PHYSICAL,
				ability = self:GetAbility(),
			}
			ApplyDamage(damageTable)

			self:Corrosive( enemy )
		end
	end
end

function modifier_ability_elder_dragon_form:Frost( target )
	local enemies = FindUnitsInRadius(
		self.parent:GetTeamNumber(),
		target:GetOrigin(),
		nil,
		self.frost_radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		0,
		false
	)

	for _,enemy in pairs(enemies) do
		enemy:AddNewModifier(
			self.parent,
			self:GetAbility(),
			"modifier_ability_elder_dragon_form_frost",
			{ duration = self.frost_duration }
		)
	end
end

function modifier_ability_elder_dragon_form:PlayEffects()
	local particle_cast = self.effect_data[self.level].transform

	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self.parent )
	ParticleManager:ReleaseParticleIndex( effect_cast )
end

modifier_ability_elder_dragon_form_corrosive = {}

function modifier_ability_elder_dragon_form_corrosive:IsHidden()
	return false
end

function modifier_ability_elder_dragon_form_corrosive:IsDebuff()
	return true
end

function modifier_ability_elder_dragon_form_corrosive:IsStunDebuff()
	return false
end

function modifier_ability_elder_dragon_form_corrosive:IsPurgable()
	return false
end

function modifier_ability_elder_dragon_form_corrosive:OnCreated( kv )
	local damage = self:GetAbility():GetSpecialValueFor( "corrosive_breath_damage" )

	local level = self:GetAbility():GetLevel()
	if self:GetCaster():HasScepter() then
		level = level + 1
	end
	if level==4 then
		damage = damage*1.5
	end

	self.damageTable = {
		victim = self:GetParent(),
		attacker = self:GetCaster(),
		damage = damage,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self:GetAbility(),
	}

	if not IsServer() then return end
	self:StartIntervalThink( 1 )
end

function modifier_ability_elder_dragon_form_corrosive:OnRefresh( kv )
	local damage = self:GetAbility():GetSpecialValueFor( "corrosive_breath_damage" )

	local level = self:GetAbility():GetLevel()
	if self:GetCaster():HasScepter() then
		level = level + 1
	end
	if level==4 then
		damage = damage*1.5
	end

	self.damageTable.damage = damage
end

function modifier_ability_elder_dragon_form_corrosive:OnIntervalThink()
	ApplyDamage(self.damageTable)
end

function modifier_ability_elder_dragon_form_corrosive:GetEffectName()
	return "particles/units/heroes/hero_dragon_knight/dragon_knight_corrosion_debuff.vpcf"
end

function modifier_ability_elder_dragon_form_corrosive:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

modifier_ability_elder_dragon_form_frost = {}

function modifier_ability_elder_dragon_form_frost:IsHidden()
	return false
end

function modifier_ability_elder_dragon_form_frost:IsDebuff()
	return true
end

function modifier_ability_elder_dragon_form_frost:IsStunDebuff()
	return false
end

function modifier_ability_elder_dragon_form_frost:IsPurgable()
	return false
end

function modifier_ability_elder_dragon_form_frost:OnCreated( kv )
	self.frost_as = self:GetAbility():GetSpecialValueFor( "frost_bonus_attack_speed" )
	self.frost_ms = self:GetAbility():GetSpecialValueFor( "frost_bonus_movement_speed" )

	local level = self:GetAbility():GetLevel()
	if self:GetCaster():HasScepter() then
		level = level + 1
	end
	if level==4 then
		self.frost_as = self.frost_as*1.5
		self.frost_ms = self.frost_ms*1.5
	end

end

function modifier_ability_elder_dragon_form_frost:OnRefresh( kv )
	self.frost_as = self:GetAbility():GetSpecialValueFor( "frost_bonus_attack_speed" )
	self.frost_ms = self:GetAbility():GetSpecialValueFor( "frost_bonus_movement_speed" )	
end

function modifier_ability_elder_dragon_form_frost:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	}
end

function modifier_ability_elder_dragon_form_frost:GetModifierMoveSpeedBonus_Percentage()
	return self.frost_ms
end
function modifier_ability_elder_dragon_form_frost:GetModifierAttackSpeedBonus_Constant()
	return self.frost_as
end

function modifier_ability_elder_dragon_form_frost:GetStatusEffectName()
	return "particles/status_fx/status_effect_frost.vpcf"
end