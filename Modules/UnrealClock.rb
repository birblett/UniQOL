if UniLib.current_config("unreal_clock")

  UniLib.include "Options"

  UNREAL_CLOCK_BG = UniNumberOption.new("Unreal Clock BG", "One of 4 different backgrounds for Unreal Clock", 1, 4)

  UNI_DOW = %w[Mon Tue Wed Thu Fri Sat Sun]

  UNREAL_CLOCK_ASSETS = [UniQOL.asset("clockcontrolgui"), UniQOL.asset("cherry"), UniQOL.asset("antstroubled"), UniQOL.asset("texencringe")]

  UniLib.insert_in_method(:Scene_Pokegear, :setup, "@buttons[@cmdScent=@buttons.length] = \"Spice Scent\"",
    "unless $Settings.unrealTimeDiverge == 0
      @cmdUnrealClock = -1
      @buttons[@cmdUnrealClock = @buttons.length] = \"Unreal Clock\"
    end") if Rejuv

  target = Reborn ? :TAIL : "if ($game_switches[:NotPlayerCharacter] == false ||  $game_switches[:InterceptorsWish] == true)"
  UniLib.insert_in_method_before(:Scene_Pokegear, :checkChoice, target,
    "if @cmdUnrealClock>=0 && @sprites[\"command_window\"].index==@cmdUnrealClock
      pbPlayDecisionSE()
      $scene = Scene_UnrealClock.new
    end")

  # modified from Scene_EncounterRate
  class Scene_UnrealClock

    def initialize(menu_index = 0)
      @menu_index = menu_index
    end

    def main(trans = true)
      @sprites={}
      @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
      @viewport.z=99999
      @sprites["background"] = IconSprite.new(0,0)
      @sprites["background"].setBitmap(UNREAL_CLOCK_ASSETS[UNREAL_CLOCK_BG.value])
      @sprites["background"].z = 255
      Graphics.transition

      time = $game_screen.gameTimeCurrent
      day_offset, hours, minutes = 0, time.hour, time.min
      cmd = Window_InputTime.new(time.strftime("%a"), hours, minutes)
      offset_y = [18, 32, -32, 32][UNREAL_CLOCK_BG.value]
      cmd.x, cmd.y, cmd.z, cmd.visible = Graphics.width / 2 - 80, Graphics.height / 2 - offset_y, 99999, true
      loop do
        [Graphics, Input].each(&:update)
        pbUpdateSceneMap
        cmd.update
        yield if block_given?
        if Input.trigger?(Input::C)
          day_offset, hours, minutes = cmd.day_offset, cmd.hours, cmd.minutes
          break
        elsif Input.trigger?(Input::B)
          pbPlayCancelSE()
          pbWait(2)
          break
        end
      end
      if Reborn
        $game_screen.gameTimeCurrent = Time.new(time.year,time.month, time.day, hours, minutes, time.sec) + day_offset * 86400
        $game_screen.updateClock($game_screen.gameTimeCurrent, false)
      else
        $game_screen.gameTimeCurrent = Time.unrealTime_oldTimeNew(time.year,time.month, time.day, hours, minutes, time.sec) + day_offset * 86400
      end
      cmd.dispose
      Input.update
      if trans
        $scene = Scene_Pokegear.new
        Graphics.freeze
      end
      pbDisposeSpriteHash(@sprites)
      @viewport.dispose
    end
  end

  class Window_InputTime < SpriteWindow_Base

    attr_accessor :day_offset
    attr_accessor :hours
    attr_accessor :minutes

    def initialize(day_name, hours, minutes)
      super(0, 0, 32, 32)
      @day = UNI_DOW.find_index(day_name)
      @day_offset = 0
      @hours = hours
      @minutes = minutes
      @frame = 0
      @colors = getDefaultTextColors(self.windowskin)
      @index = 7
      self.width, self.height, self.active = 126 + self.borderX, 32 + self.borderY, true
      refresh
    end

    def refresh(blink=0)
      self.contents = pbDoEnsureBitmap(self.contents, self.width - self.borderX,self.height - self.borderY)
      pbSetSystemFont(self.contents)
      self.contents.clear
      s=sprintf("%s%0*d%s%0*d",UNI_DOW[@day % 7], 2, @hours, blink == 0 ? ":" : " ", 2, @minutes)
      render_time(0, 0, s[0, 3], 0)
      (3..4).each { |i| render_time((i - 0.5) * 14, 0, s[i, 1], i) }
      render_time(62, 0, s[5, 1], 5)
      (6..7).each { |i| render_time((i - 0.5) * 14, 0, s[i, 1], i) }
    end

    def update
      super
      refresh((@frame / 60).floor) if @frame % 60 == 0
      if self.active
        if Input.repeat?(Input::UP) or Input.repeat?(Input::DOWN)
          diff = Input.repeat?(Input::UP) ? 1 : -1
          case @index
          when 0 then @day += diff; @day_offset += diff; @day = 6 if @day < 0; @day = 0 if @day > 6
          when 3 then @hours = ((@hours / 10 + diff).floor % 3) * 10 + @hours % 10; @hours = 11.5 - 11.5 * diff if @hours > 23
          when 4 then @hours = (@hours + diff) % 24
          when 6 then @minutes = (@minutes + 10  * diff) % 60
          when 7 then @minutes = (@minutes + diff) % 60
          else nil
          end
          refresh(@frame / 60)
        elsif Input.repeat?(Input::RIGHT)
          pbPlayCursorSE()
          @index = (@index + 1) % 8
          @index = 3 if @index == 1
          @index = 6 if @index == 5
          refresh(@frame / 60)
        elsif Input.repeat?(Input::LEFT)
          pbPlayCursorSE()
          @index = (@index - 1) % 8
          @index = 0 if @index == 2
          @index = 4 if @index == 5
          refresh(@frame / 60)
        end
      end
      @frame = (@frame + 1) % 120
    end

    def render_time(x, y, text, i)
      textwidth = self.contents.text_size(text).width
      self.contents.font.color = @colors[1]
      pbDrawShadow(self.contents, x + (24 - textwidth / 2), y, textwidth + 4, 32, text)
      self.contents.font.color = @colors[0]
      self.contents.draw_text(x + (24 - textwidth / 2), y, textwidth + 4, 32, text)
      if @index == i && @active
        colors=getDefaultTextColors(self.windowskin)
        self.contents.fill_rect(x + (24 - textwidth / 2), y + 30, textwidth, 2, colors[0])
      end
    end
  end

end