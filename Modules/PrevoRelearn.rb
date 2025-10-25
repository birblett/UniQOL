if UniLib.current_config("prevo_relearn")

  PREVO_RELEARN_OPTION = UniStringOption.new("PreEvo Relearn", "Learn moves from pre-evolutions.", %w[Off On])

  if Reborn
    UniLib.insert_in_function(:pbEachNaturalMove, :TAIL,
      "if PREVO_RELEARN_OPTION == 1
        prevo = pbGetPreviousForm(pokemon.species, pokemon.form)
        until prevo.nil?
          pkmn = $cache.pkmn[prevo[0], prevo[1]]
          pkmn.Moveset.each { |mv| yield mv[1], mv[0] } if pkmn.Moveset
          break if prevo == (tmp = pbGetPreviousForm(prevo[0], prevo[1]))
          prevo = tmp
        end
      end")
  else
    UniLib.insert_in_function(:pbEachNaturalMove, :TAIL,
      "if PREVO_RELEARN_OPTION == 1
        prevo, cache = pbGetPreviousForm(pokemon.species,pokemon.form), $cache.pkmn
        until prevo[0].nil? or prevo[1].nil? or %w[Mega Primal].include?(name = cache[prevo[0]].forms[prevo[1]])
          ((prevo[1] == 0 || (cache[prevo[0]].formData.dig(name,:Moveset).nil? && (prevo[1] = 0) == 0)) ?
             cache[prevo[0]].Moveset : cache[prevo[0]].formData.dig(name,:Moveset)).each { |mv| yield mv[1], mv[0] }
          break if prevo == (tmp = pbGetPreviousForm(prevo[0],prevo[1]))
          prevo = tmp
        end
      end")
  end

end unless UniLib.file_present?("Learn_PreEvo_Moves")