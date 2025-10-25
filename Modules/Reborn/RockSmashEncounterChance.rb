if UniLib.current_config("rock_smash_encounter_chance")

  ROCK_SMASH_ENCOUNTER_CHANCE = UniNumberOption.new("Rock Smash Enc.", "Percent chance of encountering a Pokemon when using Rock Smash.", 0, 100, 5, 25)

  UniLib.replace_in_function(:pbRockSmashRandomEncounter, "if rand(100) < 25", "if ROCK_SMASH_ENCOUNTER_CHANCE > rand(100)")

end