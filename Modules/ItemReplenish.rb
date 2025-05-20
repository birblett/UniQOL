if UniLib.current_config("item_replenish")

  ITEM_REPLACE_RESTORE = UniStringOption.new("Item Replenish", "Replace used items from the bag or restore them without consumption.", %w[Off Replace Restore])

  class PokeBattle_Pokemon

    def itemInitial=(other)
      @itemInitial = other unless other.nil? and (ITEM_REPLACE_RESTORE == 2 || ITEM_REPLACE_RESTORE == 1 && $PokemonBag.pbDeleteItem(self.item))
    end

  end

  UniLib.insert_in_method(:PokeBattle_Pokemon, :setItem, :HEAD, "@itemInitial = value")

end unless UniLib.file_present?("ItemReplaceRestore")