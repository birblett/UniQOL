if UniLib.current_config("debug_toggle")

  DEBUG_ENABLED = UniStringOption.new("Debug", "Debug mode toggle.", %w[Off On], proc { |value| $DEBUG = value == 1})

end
