if UniLib.current_config("free_nature_change")

  UniLib.include "Map"

  NATURE_CHANGE_FREE = UniStringOption.new("Free Nature Change", "Pokemon psychologist without costing a heart scale", %w[Off On])

  MapEvent.add_map_event(326) { |m|
    m.events[3].pages[0].list[28].parameters[1] = "$PokemonBag.pbQuantity(:HEARTSCALE)>0 || NATURE_CHANGE_FREE == 1"
    m.events[3].pages[0].list[45].parameters[1] = "$PokemonBag.pbDeleteItem(:HEARTSCALE) unless NATURE_CHANGE_FREE == 1"

    m.events[3].pages[1].list[24].parameters[1] = "$PokemonBag.pbQuantity(:HEARTSCALE)>1 || NATURE_CHANGE_FREE == 1"
    m.events[3].pages[1].list[150].parameters[1] = "$PokemonBag.pbDeleteItem(:HEARTSCALE) unless NATURE_CHANGE_FREE == 1"
    m.events[3].pages[1].list[151].parameters[1] = "$PokemonBag.pbDeleteItem(:HEARTSCALE) unless NATURE_CHANGE_FREE == 1"

    m.events[3].pages[2].list[25].parameters[1] = "$PokemonBag.pbQuantity(:HEARTSCALE)>1 || NATURE_CHANGE_FREE == 1"
    m.events[3].pages[2].list[51].parameters[1] = "$PokemonBag.pbDeleteItem(:HEARTSCALE,2) unless NATURE_CHANGE_FREE == 1"
  }

end