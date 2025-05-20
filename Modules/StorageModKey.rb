if UniLib.current_config("storage_mod_key")

  STORAGE_MODIFIER = UniStringOption.new("Storage Mod Key", "Hold Pagedown or Run keybinds to withdraw/store without having to go through a menu.", %w[Off On], nil, 1)

  UniLib.insert_in_method_before(:PokemonStorageScreen, :pbStartScreen, "if @scene.quickswap",
    "if STORAGE_MODIFIER == 1 and (Input.press?(Input::D) or Input.press?(Input.press?(Input::D)))
      if selected[0]==-1
        pbStore(selected,@heldpkmn)
      else
        pbWithdraw(selected,@heldpkmn)
      end
      next
    end")

end