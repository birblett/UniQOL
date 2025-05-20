if UniLib.current_config("fishing_utils")

  AUTO_HOOK = UniStringOption.new("Auto Hook", "Fishing hook triggers automatically.", %w[Off On], proc { |value| FISHINGAUTOHOOK = value == 1 })

  INSTANT_HOOK = UniStringOption.new("Instant Hook", "Fishing hook triggers instantly.", %w[Off On])

  target = Reborn ? "time = 2 + rand(10)" : "time=2+rand(10)"
  UniLib.replace_in_function(:pbFishing, target, "time = INSTANT_HOOK == 0 ? 2 + rand(10) : 0")

  target = Reborn ? "if !pbWaitForInput(msgwindow, message + _INTL(\"\\r\\nOh!  A bite!\"), frames)" : "if !pbWaitForInput(msgwindow,message+_INTL(\"\\r\\nOh!  A bite!\"),frames)"
  UniLib.replace_in_function(:pbFishing, target,
    "unless INSTANT_HOOK == 1 ? pbWaitForInput(msgwindow, _INTL(\"Oh!  A bite!\"), frames) : pbWaitForInput(msgwindow, message + _INTL(\"\\r\\nOh!  A bite!\"), frames)")

end unless UniLib.file_present?("FISHINGAUTOHOOK")