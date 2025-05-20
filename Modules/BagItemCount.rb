if UniLib.current_config("bag_item_count")

  MAX_BAG_COUNT = UniNumberOption.new("Bag Item Max", "Maximum number to be held in bag per item.", 99, 9999, 9, 999, proc { |value| BAGMAXPERSLOT = value })

end