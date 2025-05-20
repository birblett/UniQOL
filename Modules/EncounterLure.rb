if UniLib.current_config("encounter_lure")

  ENCOUNTER_LURE = UniStringOption.new("Encounter Lure", "Always-active magnetic or mirror lure.", %w[Off Magnetic Mirror])

  UniLib.insert_in_method_before(:PokemonEncounters, :pbShouldFilterKnownPkmnFromEncounter?, "return false", "return true if ENCOUNTER_LURE == 1")
  UniLib.insert_in_method_before(:PokemonEncounters, :pbShouldFilterOtherPkmnFromEncounter?, "return false", "return true if ENCOUNTER_LURE == 2")

end