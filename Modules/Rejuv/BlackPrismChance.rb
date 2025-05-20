#=========================================================== BLACK PRISM CHANCE ===========================================================#

if UniLib.current_config("black_prism_chance")

  BLACK_PRISM_CHANCE = UniNumberOption.new("Black Prism Chance", "Black Prism chance, as a percentage", 1, 100, 1)

  Events.onWildPokemonCreate.instance_variable_get(:@callbacks)[6] = proc {|_, e|
    pokemon=e[0]
    check = rand(100)
    check = rand(20) if $game_variables[:LuckShinies] < 0
    if BLACK_PRISM_CHANCE > check
      pokemon.item = :BLKPRISM
      unless $cache.pkmn[pokemon.species].EggGroups.include?(:Undiscovered) || pokemon.species == :MANAPHY
        stat1, stat2, stat3 = [0, 1, 2, 3, 4, 5].sample(3)
        (0..5).each { |i| pokemon.iv[i] = 31 if [stat1, stat2, stat3].include?(i) }
      end
    end
  }

end
