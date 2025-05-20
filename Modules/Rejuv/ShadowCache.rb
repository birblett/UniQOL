if UniLib.current_config("shadow_cache")

  SHADOW_ICON_CACHE = {} unless defined? SHADOW_ICON_CACHE
  SHADOW_SPECIES_CACHE = {} unless defined? SHADOW_SPECIES_CACHE

  UniLib.insert_in_function(:pbPokemonIconBitmap, "species = $cache.pkmn[pokemon.species].dexnum",
    "return SHADOW_ICON_CACHE[pokemon] if (SHADOW_ICON_CACHE[pokemon] and pokemon.isShadow?)")

  UniLib.insert_in_function_before(:pbPokemonIconBitmap, "return bitmap",
    "SHADOW_ICON_CACHE[pokemon] = bitmap if pokemon.isShadow?")

  UniLib.insert_in_function(:pbLoadPokemonBitmapSpecies, :HEAD,
  "shadow_cache = pokemon.isShadow? && !back
  if shadow_cache
    key = [pokemon.species, pokemon.form, pokemon.isShiny?, pokemon.gender, pokemon.isEgg?]
    return SHADOW_SPECIES_CACHE[pokemon][1] if SHADOW_SPECIES_CACHE[pokemon] and SHADOW_SPECIES_CACHE[pokemon][0] == key
  end")

  UniLib.insert_in_function_before(:pbLoadPokemonBitmapSpecies, "return bitmap",
    "SHADOW_SPECIES_CACHE[pokemon] = [key, bitmap] if shadow_cache")

  UniLib.insert_in_function_before(:pbLoadPokemonBitmapSpecies, "return bitmap",
    "SHADOW_SPECIES_CACHE[pokemon] = [key, bitmap] if shadow_cache", 1)

end