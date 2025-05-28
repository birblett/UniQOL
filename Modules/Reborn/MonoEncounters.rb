if UniLib.current_config("force_mono_encounters")

  MONO_SWITCHES = {
    1182 => :NORMAL,
    1183 => :FIRE,
    1184 => :WATER,
    1185 => :GRASS,
    1186 => :ELECTRIC,
    1187 => :ICE,
    1188 => :POISON,
    1189 => :FIGHTING,
    1190 => :GROUND,
    1191 => :FLYING,
    1192 => :BUG,
    1193 => :PSYCHIC,
    1194 => :ROCK,
    1195 => :GHOST,
    1196 => :DRAGON,
    1197 => :DARK,
    1198 => :STEEL,
    1199 => :FAIRY,
  }

  FORCE_MONOTYPE_ENCOUNTER = UniStringOption.new("Mono Encounters", "Forces encounters to match current monotype.", %w[Off New Always])

  UniLib.insert_in_method_before(:PokemonEncounters, :pbEncounteredPokemon, "forcedEncounter = pbForceEncounterUncapturedPkmn(encounters, chances)",
    "type = nil
      MONO_SWITCHES.each { |id, t| break type = t if $game_switches[id] } if FORCE_MONOTYPE_ENCOUNTER > 0
      if type
        newenc, newchances = get_mono_pokemon(encounters, chances, type)
        encounters, chances = newenc, newchances unless newenc.empty?
      end")

  class PokemonEncounters

    def get_mono_pokemon(encounters, chances, type)
      newenc, newchances = [], []
      for i in 0...encounters.length
        species, form = encounters[i][0], pbISActuallyDifferentForm(encounters[i][0])
        stack = [species]
        while (species = stack.pop)
          t1, t2 = $cache.pkmn[species, form].Type1, $cache.pkmn[species, form].Type2
          if t1 == type || t2 == type
            newenc.push(encounters[i])
            newchances.push(chances[i])
            break
          end
          $cache.pkmn[species, form].evolutions.each { |h| stack.push(h[:species]) } if $cache.pkmn[species, form].evolutions
        end
      end
      if FORCE_MONOTYPE_ENCOUNTER == 1
        encounters, chances = newenc, newchances if newenc.length > 0
        newenc, newchances = [], []
        (0...encounters.length).each { |i|
          next if !(ch = chances[i]) or chances[i] <= 0
          next unless (enc = encounters[i])
          if $Trainer.pokedex.dexList[enc[0]][:owned?]
            next if $Trainer.pokedex.dexList[enc[0]][:formsOwned].nil? || $Trainer.pokedex.dexList[enc[0]][:formsOwned].values.none?
            next if $cache.pkmn[enc[0]].forms.length <= 1
            encform = !$cache.pkmn[enc[0]].formInit.empty? ? eval($cache.pkmn[enc[0]].formInit).call : 0
            next if isCosmeticForm(enc[0], encform)
            $Trainer.pokedex.refreshDex unless $Trainer.pokedex.dexList[enc[0]][:formsOwned]
            next if $Trainer.pokedex.dexList[enc[0]][:formsOwned][encform]
          end
          newenc.push(enc)
          newchances.push(ch)
        }
      end
      [newenc, newchances]
    end

  end

end