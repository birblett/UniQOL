if UniLib.current_config("full_party_encounter_effect")

  UniLib.include "Multibility"

  FULL_PARTY_ENCOUNTER_EFFECT = UniStringOption.new("Full Party Enc.", "Abilities in the party all apply to encounters.", %w[Off On])

  class PokeBattle_Pokemon

    FULL_PARTY_ABILITY_METHOD = instance_method(:ability) unless defined? FULL_PARTY_ABILITY_METHOD
    def ability(multi = false)
      original = multi
      multi = caller[0].include?("pbGenerateEncounter") || caller[0].include?("pbGenerateWildPokemon") unless original
      if !original and FULL_PARTY_ENCOUNTER_EFFECT == 1 and multi
        added_abilities = []
        $Trainer.party.each_with_index { |pkmn, i| added_abilities += AbilityContainer.new(pkmn, pkmn.ability).abilities unless i == 0 }
        AbilityContainer.new(self, @ability, added_abilities)
      else
        FULL_PARTY_ABILITY_METHOD.bind(self).(multi)
      end
    end

  end

end