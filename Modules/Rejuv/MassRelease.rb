if UniLib.current_config("mass_release")

  UniLib.insert_in_method(:PokemonStorageScene, :pbSelectBox, "if @aMultiSelectedMons.include?(ret)",
    "case Kernel.pbMessage(\"What do you want to do?\", [\"Deselect\", \"Mass Release\", \"Cancel\"], 3)
    when 0 then @screen.pbHold(ret, true)
    when 1
      if Kernel.pbMessage(_INTL(\"Are you sure you want to mass release {1} Pokémon?\", @aMultiSelectedMons.length), %w[Yes No], 2) == 0
        @aMultiSelectedMons.each { |pkmn| @storage.pbDelete(pkmn[0], pkmn[1]) }
        pbHardRefresh
        pbDisplay(_INTL(\"Released {1} Pokémon.\", @aMultiSelectedMons.length))
        @aMultiSelectedMons.clear
      end
    else return [-2,-1]
    end
    return [-2,-1]")

end