if UniLib.current_config("hidden_power_changer")

  HIDDEN_POWER_CHANGER = UniStringOption.new("HP Type Changer", "Allows changing hidden power type in the PC or party.", %w[Off PC Party Both])

  HP_TYPES = [:BUG, :DARK, :DRAGON, :ELECTRIC, :FAIRY, :FIGHTING, :FIRE, :FLYING, :GHOST, :GRASS, :GROUND, :ICE, :POISON, :PSYCHIC, :ROCK, :STEEL, :WATER, -1]

  def hp_type_change(mon)
    pbHiddenPower(mon) unless mon.hptype
    typechoices = [_INTL("Bug"),_INTL("Dark"),_INTL("Dragon"),_INTL("Electric"),_INTL("Fairy"),_INTL("Fighting"),_INTL("Fire"),_INTL("Flying"),_INTL("Ghost"),_INTL("Grass"),_INTL("Ground"),_INTL("Ice"),_INTL("Poison"),_INTL("Psychic"),_INTL("Rock"),_INTL("Steel"),_INTL("Water"),_INTL("Cancel")]
    choosetype = Kernel.pbMessage(_INTL("Which type should its move become? (currently {1})", typechoices[HP_TYPES.find_index(mon.hptype)]), typechoices,18)
    if (choosetype >= 0) && (choosetype < 17) and HP_TYPES[choosetype].class == Symbol
      mon.hptype = HP_TYPES[choosetype]
      Kernel.pbMessage(_INTL("{1}'s hidden power type was changed to {2}!", mon.name, typechoices[choosetype]))
    end
  end

  UniLib.add_party_command("hidden_power", "HP Type", proc { |pkmn| hp_type_change(pkmn) }, proc { |pkmn| !pkmn.isEgg? and HIDDEN_POWER_CHANGER >= 2 })
  UniLib.add_box_command("hidden_power", "HP Type", proc { |pkmn| hp_type_change(pkmn) }, proc { |pkmn, _| !pkmn.isEgg? and HIDDEN_POWER_CHANGER & 1 == 1 })

end