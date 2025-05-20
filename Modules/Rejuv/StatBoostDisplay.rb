if UniLib.current_config("stat_boost_display")

  STAT_BOOST_DISPLAY = UniStringOption.new("Stat Boost Disp.", "Stat change display while in battle.", %w[Off Reborn Compact], nil, 1)
  STAT_DISPLAY_POSITION_ARRAY = [[-24, 6], [220, 10]]
  STAT_DISPLAY_POSITION_ARRAY_DOUBLE = [[-14, 2], [224, 2]]
  STAT_DISPLAY_TYPES = [PBStats::ACCURACY, PBStats::ATTACK, PBStats::SPATK, PBStats::SPEED, PBStats::DEFENSE, PBStats::SPDEF, PBStats::EVASION]
  STAT_DISPLAY_POSITION_MAP = [[14,0], [2,10], [26,10], [14,20], [2,30], [26,30], [14,40]]

  ALT_STAT_DISPLAY_POSITION_ARRAY = [[4, 10], [218, 13]]
  ALT_STAT_DISPLAY_POSITION_ARRAY_DOUBLE = [[10, -0.5], [226, 0]]

  DISPLAY_BITMAPS.each { |b| b.dispose } if defined? DISPLAY_BITMAPS
  DISPLAY_BITMAPS = [
    AnimatedBitmap.new(UniQOL.asset("StatIcons/main.png")),
    AnimatedBitmap.new(UniQOL.asset("StatIcons/stages.png")),
    AnimatedBitmap.new(UniQOL.asset("StatIcons/main_alt.png")),
    AnimatedBitmap.new(UniQOL.asset("StatIcons/words_alt.png")),
    AnimatedBitmap.new(UniQOL.asset("StatIcons/stages_alt.png"))
  ]

  def draw_stats(bitmap, textpos)
    for i in textpos
      srcbitmap = DISPLAY_BITMAPS[i[0]]
      width=i[5]>=0 ? i[5] : srcbitmap.width
      height=i[6]>=0 ? i[6] : srcbitmap.height
      srcrect=Rect.new(i[3], i[4], width,height)
      bitmap.blt(i[1], i[2], srcbitmap.bitmap, srcrect)
    end
  end

  TRACKED_BMPS = []

  UniLib.insert_in_method(:PokeBattle_Scene, :pbDisposeSprites, :HEAD,
    "TRACKED_BMPS.each { |bmp| bmp.dispose unless bmp.nil? }
    TRACKED_BMPS.clear")

  class PokemonDataBox < SpriteWrapper

    def init_stat_bitmap
      @stat_boost_bmp = SpriteWrapper.new(self.viewport)
      @stat_boost_bmp.bitmap = STAT_BOOST_DISPLAY == 1 ? BitmapWrapper.new(50, 64) :BitmapWrapper.new(24, 57)
      @stat_boost_bmp.z = 51
      prev = TRACKED_BMPS[@battler.index]
      unless prev.nil?
        prev.bitmap.clear
        prev.dispose
      end
      TRACKED_BMPS[@battler.index] = @stat_boost_bmp
    end

    def show_stat_stages
      return if !defined? @stat_boost_bmp or @stat_boost_bmp.disposed? or @battler.nil?
      @stat_boost_bmp.bitmap.clear
      return unless self.visible
      stats = []
      if STAT_BOOST_DISPLAY == 1
        @double = @battler.battle.doublebattle unless defined? @double
        x_offset, y_offset = @double ? STAT_DISPLAY_POSITION_ARRAY_DOUBLE[@battler.index & 1] : STAT_DISPLAY_POSITION_ARRAY[@battler.index & 1]
        x_offset += @battler.index & 1 == 1 ? 30 : -30 if @battler.crested
        x_offset, y_offset = x_offset - 30, y_offset if @battler.issossmon
        @stat_boost_bmp.x, @stat_boost_bmp.y = self.x + x_offset, self.y + y_offset
        stats.push([0, 0, 0, 0, 0, -1, -1])
        STAT_DISPLAY_TYPES.map { |type| @battler.stages[type]}.each_with_index { |stage, i| stats.push([1, STAT_DISPLAY_POSITION_MAP[i][0], STAT_DISPLAY_POSITION_MAP[i][1], stage > 0 ? 0 : 22, (stage.abs - 1) * 22, 22, 22]) unless stage == 0 }
      else
        @double = @battler.battle.doublebattle unless defined? @double
        x_offset, y_offset = @double ? ALT_STAT_DISPLAY_POSITION_ARRAY_DOUBLE[@battler.index & 1] : ALT_STAT_DISPLAY_POSITION_ARRAY[@battler.index & 1]
        x_offset += @battler.index & 1 == 1 ? 22 : -22 if @battler.crested
        x_offset, y_offset = x_offset - 30, y_offset + 6 if @battler.issossmon
        @stat_boost_bmp.x, @stat_boost_bmp.y = self.x + x_offset, self.y + y_offset
        stats.push([2, 0, 0, 0, 0, -1, -1])
        (1..7).map { |type| @battler.stages[type] }.each_with_index do |stage, i|
          if stage == 0
            stage_offset = 0
          else
            stage_offset = stage > 0 ? 12 : 24
          end
          stats.push([3, 2, i * 8 + 2, stage_offset, i * 8, 11, 5])
          stats.push([4, 15, i * 8 + 2, stage < 0 ? 8 : 0, stage.abs * 6, 7, 5])
        end
      end
      draw_stats(@stat_boost_bmp.bitmap, stats)
    end

  end

  UniLib.insert_in_method(:PokemonDataBox, :update, "self.x-=8",
    "if STAT_BOOST_DISPLAY > 0
      init_stat_bitmap if !defined? @stat_boost_bmp
      show_stat_stages
    end")

  UniLib.insert_in_method(:PokemonDataBox, :update, "self.x+=8",
    "if STAT_BOOST_DISPLAY > 0
      init_stat_bitmap if !defined? @stat_boost_bmp
      show_stat_stages
    end")

  UniLib.insert_in_method(:PokemonDataBox, :update, :TAIL,
    "show_stat_stages if STAT_BOOST_DISPLAY > 0")

  UniLib.insert_in_method(:PokemonDataBox, :refresh, "hpGaugeSize=PBScene::HPGAUGESIZE", "show_stat_stages if STAT_BOOST_DISPLAY > 0")
  class BossPokemonDataBox < SpriteWrapper

    def init_stat_bitmap
      @stat_boost_bmp = SpriteWrapper.new(self.viewport)
      @stat_boost_bmp.bitmap = STAT_BOOST_DISPLAY == 1 ? BitmapWrapper.new(50, 64) :BitmapWrapper.new(24, 57)
      @stat_boost_bmp.z = 100
      prev = TRACKED_BMPS[@battler.index]
      unless prev.nil?
        prev.bitmap.clear
        prev.dispose
      end
      TRACKED_BMPS[@battler.index] = @stat_boost_bmp
    end

    def show_stat_stages
      return if !defined? @stat_boost_bmp or @stat_boost_bmp.disposed? or @battler.nil?
      @stat_boost_bmp.bitmap.clear
      return unless self.visible
      stats = []
      if STAT_BOOST_DISPLAY == 1
        x_offset, y_offset = 290, 10
        @stat_boost_bmp.x, @stat_boost_bmp.y = self.x + x_offset, self.y + y_offset
        stats = [[0, 0, 0, 0, 0, -1, -1]]
        STAT_DISPLAY_TYPES.map { |type| @battler.stages[type]}.each_with_index { |stage, i| stats.push([1, STAT_DISPLAY_POSITION_MAP[i][0], STAT_DISPLAY_POSITION_MAP[i][1], stage > 0 ? 0 : 22, (stage.abs - 1) * 22, 22, 22]) unless stage == 0 }
      else
        x_offset, y_offset = 298, 28
        @stat_boost_bmp.x, @stat_boost_bmp.y = self.x + x_offset, self.y + y_offset
        stats.push([2, 0, 0, 0, 0, -1, -1])
        (1..7).map { |type| @battler.stages[type] }.each_with_index do |stage, i|
          if stage == 0
            stage_offset = 0
          else
            stage_offset = stage > 0 ? 12 : 24
          end
          stats.push([3, 2, i * 8 + 2, stage_offset, i * 8, 11, 5])
          stats.push([4, 15, i * 8 + 2, stage < 0 ? 8 : 0, stage.abs * 6, 7, 5])
        end
      end
      draw_stats(@stat_boost_bmp.bitmap, stats)
    end
  end

  UniLib.insert_in_method(:BossPokemonDataBox, :update, "self.x+=8",
    "if STAT_BOOST_DISPLAY > 0
      init_stat_bitmap if !defined? @stat_boost_bmp or @stat_boost_bmp.disposed?
      show_stat_stages
    end")

  UniLib.insert_in_method(:BossPokemonDataBox, :update, :TAIL, "show_stat_stages if STAT_BOOST_DISPLAY > 0")

  UniLib.insert_in_method(:BossPokemonDataBox, :refresh, :TAIL, "show_stat_stages if STAT_BOOST_DISPLAY > 0")

end