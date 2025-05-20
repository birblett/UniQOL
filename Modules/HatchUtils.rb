if UniLib.current_config("hatch_utils")

  DAYCARE_EGG_COUNT = UniNumberOption.new("Daycare Egg Count", "Number of eggs to generate when picking up from the daycare.", 1, 30, 1)

  target = Reborn ? "pokemon0 = $PokemonGlobal.daycare[0][0]" : "pokemon0=$PokemonGlobal.daycare[0][0]"
  UniLib.insert_in_function_before(:pbDayCareGenerateEgg, target,
    "egg_count = 0
    sent = 0
    boxes = []
    loop do
      egg_count += 1")

  UniLib.insert_in_function(:pbDayCareGenerateEgg, "addPkmnToPartyOrPC(egg)",
      "break if $Trainer.party.length >= 6 or DAYCARE_EGG_COUNT <= egg_count
    end
    if sent > 0
      if sent == 1
        Kernel.pbMessage(_INTL(\"Egg was sent to {1}.\", $PokemonStorage[boxes[0]].name))
      elsif boxes.length == 1
        Kernel.pbMessage(_INTL(\"Sent {1} eggs to {2}.\", sent, $PokemonStorage[boxes[0]].name))
      else
        Kernel.pbMessage(_INTL(\"Sent {1} eggs from {2} to {3}.\", sent, $PokemonStorage[boxes[0]].name, $PokemonStorage[boxes[-1]].name))
      end
    elsif sent == -1
      Kernel.pbMessage(\"No space left in the PC...\")
    end")

  EGG_DESTINATION_OPTION = UniStringOption.new("Daycare Egg Dest.", "Where eggs are sent when picking up from the daycare.", %w[Party Box])

  UniLib.replace_in_function(:pbDayCareGenerateEgg, "addPkmnToPartyOrPC(egg)",
    "if EGG_DESTINATION_OPTION == 0
      addPkmnToPartyOrPC(egg)
    else
      (box = $PokemonStorage.pbStoreCaught(egg)) >= 0 ? sent += 1 : (sent = -1; break)
      boxes.push(box) unless boxes.include?(box)
    end")

  NO_HATCH_SCENE = UniStringOption.new("Egg Hatch Anim.", "Egg hatch animation.", %w[Off On], nil, 1)

  target = Reborn ? "val = pbHatchAnimation(pokemon)" : "val=pbHatchAnimation(pokemon)"
  UniLib.replace_in_function(:pbHatch, target, "val = NO_HATCH_SCENE == 0 or pbHatchAnimation(pokemon)")

  target = Reborn ? "val = pbHatchAnimation(pokemon)" : "puts val"
  UniLib.insert_in_function(:pbHatch, target,
    "if NO_HATCH_SCENE == 0
      Kernel.pbMessage(_INTL(\"{1} hatched from the Egg!\", speciesname))
      if Kernel.pbConfirmMessage(_INTL(\"Would you like to nickname the newly hatched {1}?\", speciesname))
        nickname=pbEnterPokemonName(_INTL(\"{1}'s nickname?\", speciesname),0,12,\"\", pokemon)
        pokemon.name=nickname if nickname!=\"\"
      end unless defined? HATCH_NICKNAME and HATCH_NICKNAME == 0
    end")

  HATCH_NICKNAME = UniStringOption.new("Egg Name Prompt", "Prompt for nickname when an egg hatches.", %w[Off On], nil, 1)

  target = Reborn ? "if Kernel.pbConfirmMessage(_INTL(\"Would you like to nickname the newly hatched {1}?\", @pokemon.name))" :
             "if Kernel.pbConfirmMessage(_INTL(\"Would you like to nickname the newly hatched {1}?\",@pokemon.name))"
  UniLib.replace_in_method(:PokemonEggHatchScene, :pbMain, target, "if HATCH_NICKNAME == 1 and Kernel.pbConfirmMessage(_INTL(\"Would you like to nickname the newly hatched {1}?\",@pokemon.name))")

end