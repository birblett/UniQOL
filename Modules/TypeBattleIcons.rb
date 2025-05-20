if UniLib.current_config("type_battle_icons")

  TYPE_ICONS = UniStringOption.new("Type Icons", "Type display in-battle.", %w[Off On], nil, 1)
  TYPE_ICON_X = UniNumberOption.new("Type Icon X", "Horizontal offset of type battle icons.", 0, 200, 1, 12)
  TYPE_ICON_Y = UniNumberOption.new("Type Icon Y", "Vertical offset of type battle icons.", 0, 80, 1, 10)

  TYPE_ICON_BITMAPS.each { |_, bmp| bmp.dispose } if defined? TYPE_ICON_BITMAPS
  TYPE_ICON_BITMAPS = [:NORMAL, :BUG, :DARK, :DRAGON, :ELECTRIC, :FAIRY, :FIGHTING, :FIRE, :FLYING, :GHOST, :GRASS, :GROUND, :ICE, :POISON, :PSYCHIC, :ROCK, :STEEL, :WATER, :SHADOW, :QMARKS].to_h { |type| [type, AnimatedBitmap.new(UniQOL.asset("Types/#{type.to_s}.png"))] }

  def draw_types(bitmap, textpos)
    textpos.each { |i|
      srcbitmap = TYPE_ICON_BITMAPS[i[0]]
      width = i[5] >= 0 ? i[5] : srcbitmap.width
      height = i[6] >= 0 ? i[6] : srcbitmap.height
      srcrect = Rect.new(i[3], i[4], width, height)
      bitmap.blt(i[1], i[2], srcbitmap.bitmap, srcrect)
    }
  end

  target = Reborn ? "pbShowStatsBoosts if loopstop == false" : "aShowStatBoosts if $DEV"
  UniLib.insert_in_method(:PokemonDataBox, :refresh, target,
    "@double = @battler.battle.doublebattle unless defined? @double
    offset_x, offset_y = TYPE_ICON_X - 36, TYPE_ICON_Y + (@double || Reborn ? -10 : 0)
    offset_y = offset_y + 3 if @battler.index & 1 == 1 and Rejuv
    offset_x, offset_y = offset_x - 4, offset_y + 40 if @battler.issossmon
    draw_types(self.bitmap, (@battler.effects[:Illusion].nil? ? [@battler.type1, @battler.type2] : [@battler.effects[:Illusion].type1, @battler.effects[:Illusion].type2]).reduce([]) { |types, type| type.nil? ? types : types << [type, (Reborn ? @spritebaseX : sbX) + (offset_x += 32), offset_y, 0, 0, -1, -1]}) if TYPE_ICONS == 1")

end