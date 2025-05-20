if UniLib.current_config("egg_relearn")

  RELEARN_EGG_MOVES = UniStringOption.new("Egg Relearn", "Egg moves in move relearner before Fly.", %w[Off On])

  target = Reborn ? "moves = tmoves + pokemon.getEggMoveList(true) + moves if Rejuv && $PokemonBag.pbHasItem?(:HM02)" : "moves= tmoves+pokemon.getEggMoveList(true)+moves if Rejuv && $PokemonBag.pbHasItem?(:HM02)"
  UniLib.replace_in_function(:pbGetRelearnableMoves, target,
    "eggs = RELEARN_EGG_MOVES == 1 or Rejuv && $PokemonBag.pbHasItem?(:HM02)
    moves = tmoves + pokemon.getEggMoveList(true) + moves if eggs", 0)

end unless UniLib.file_present?("Learn_Egg_moves")