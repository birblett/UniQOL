if UniLib.current_config("snappy_menus")

  SNAPPY_MENUS = UniStringOption.new("Snappy Menus", "Disables menu transitions.", %w[Off On])

  UniLib.replace_in_function(:pbFadeOutIn, "Graphics.update", "Graphics.update unless SNAPPY_MENUS == 1")
  UniLib.replace_in_function(:pbFadeOutIn, "Graphics.update", "Graphics.update unless SNAPPY_MENUS == 1", 1)
  UniLib.replace_in_function(:pbFadeOutIn, "Input.update", "Input.update unless SNAPPY_MENUS == 1")
  UniLib.replace_in_function(:pbFadeOutIn, "Input.update", "Input.update unless SNAPPY_MENUS == 1", 1)
  UniLib.replace_in_function(:pbSetSpritesToColor, "Graphics.update", "Graphics.update unless SNAPPY_MENUS == 1")
  UniLib.replace_in_function(:pbSetSpritesToColor, "Input.update", "Input.update unless SNAPPY_MENUS == 1")

  UniLib.insert_in_function_before(:pbFadeOutIn, "pbPushFade",
    "if SNAPPY_MENUS == 1
      Graphics.update
      Input.update
    end")

  UniLib.insert_in_function_before(:pbFadeOutIn, "viewport.dispose",
    "if SNAPPY_MENUS == 1
      Graphics.update
      Input.update
    end")

  if Rejuv

    UniLib.insert_in_method(:QuestList_Scene, :fadeContent, :HEAD,
      "if SNAPPY_MENUS == 1
        Graphics.update
        @sprites[\"itemlist\"].contents_opacity -= 255
        @sprites[\"overlay1\"].opacity -= 255; @sprites[\"overlay_control\"].opacity -= 255
        @sprites[\"page_icon1\"].opacity -= 255; @sprites[\"pageIcon\"].opacity -= 255
        return
      end")

    UniLib.insert_in_method(:QuestList_Scene, :showContent, :HEAD,
      "if SNAPPY_MENUS == 1
        Graphics.update
        @sprites[\"itemlist\"].contents_opacity += 255
        @sprites[\"overlay1\"].opacity += 255; @sprites[\"overlay_control\"].opacity += 255
        @sprites[\"page_icon1\"].opacity += 255; @sprites[\"pageIcon\"].opacity += 255
        return
      end")

    UniLib.insert_in_method_before(:QuestList_Scene, :pbQuest, "Graphics.update",
      "if SNAPPY_MENUS == 1
        @sprites[\"overlay2\"].opacity += 255; @sprites[\"overlay3\"].opacity += 255; @sprites[\"page_icon2\"].opacity += 255
        Graphics.update
        break
      end")

    UniLib.insert_in_method_before(:QuestList_Scene, :pbQuest, "Graphics.update",
      "if SNAPPY_MENUS == 1
        @sprites[\"overlay2\"].opacity -= 255; @sprites[\"overlay3\"].opacity -= 255; @sprites[\"page_icon2\"].opacity -= 255
        Graphics.update
        break
      end", 2)

  end

  S_TRANS = Graphics.singleton_method(:transition) unless defined? S_TRANS
  Graphics.define_singleton_method(:transition) { |i=0, s=""| S_TRANS.(SNAPPY_MENUS == 1 ? 0 : i, s) }

end unless UniLib.file_present?("SWM - SnappyMenus")