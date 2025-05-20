if UniLib.current_config("move_relearn_utils")

  MOVE_RELEARN_COMMAND = UniStringOption.new("Move Relearner", "Allows relearning moves in the PC or party.", %w[Off PC Party Both])

  MOVE_RELEARN_FREE = UniStringOption.new("Free Relearning", "Party/PC relearn without costing a heart scale", %w[Off On])

  if Reborn

    UniLib.include "Map"

    MapEvent.add_map_event(355) { |m| m.events[35].pages[0].list[10].instance_variable_set(:@parameters, [12, "$PokemonBag.pbQuantity(:HEARTSCALE)>0 || MOVE_RELEARN_FREE == 1"]) }

  end

  MOVE_RELEARN_BEFORE_TUTOR = Reborn ? 1 : UniStringOption.new("Relearn Any Time", "Allows party relearning before unlocking the move relearner.", %w[Off On])

  def relearn_from_menu(pkmn)
    if MOVE_RELEARN_FREE == 1 or ($PokemonBag.pbHasItem?(:HEARTSCALE) and Kernel.pbConfirmMessage("This will consume a Heart Scale. Continue?"))
      pbFadeOutIn(99999) { $has_relearned = MoveRelearnerScreen.new(MoveRelearnerScene.new).pbStartScreen(pkmn); pbUpdateSceneMap }
      $updateFLHUD = true
      $PokemonBag.pbDeleteItem(:HEARTSCALE) if $has_relearned
    elsif !$PokemonBag.pbHasItem?(:HEARTSCALE)
      Kernel.pbMessage("You need a Heart Scale to relearn moves!")
    end
  end

  UniLib.add_party_command("move_relearner", "Relearn", proc { |pkmn| relearn_from_menu(pkmn) }, proc { |pkmn| ($game_switches[1444] || MOVE_RELEARN_BEFORE_TUTOR == 1) and MOVE_RELEARN_COMMAND >= 2 and (!pkmn.relearner.is_a?(Array) or !pkmn.relearner[0])})
  UniLib.add_box_command("move_relearner", "Relearn", proc { |pkmn| relearn_from_menu(pkmn) }, proc { ($game_switches[1444] || MOVE_RELEARN_BEFORE_TUTOR == 1) and MOVE_RELEARN_COMMAND & 1 == 1 and (!pkmn.relearner.is_a?(Array) or !pkmn.relearner[0])})

end