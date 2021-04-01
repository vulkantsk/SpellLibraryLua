ability_song_of_the_siren_cancel = {}

function ability_song_of_the_siren_cancel:OnSpellStart()
	self.modifier:End()
	self.modifier = nil
end