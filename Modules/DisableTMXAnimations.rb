if UniLib.current_config("tmx_animation_toggle")

  NO_TMX_ANIM = UniStringOption.new("Disable TMX Anim.", "Disables TMX animations.", %w[Off On])

  UniLib.insert_in_function(:pbHiddenMoveAnimation, :HEAD, "return false if NO_TMX_ANIM")

end unless UniLib.file_present?("SWM - NoTMXAnimations")