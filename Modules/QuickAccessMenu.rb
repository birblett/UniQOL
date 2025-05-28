if UniLib.current_config("quick_access_menu")

  QUICK_ACCESS_ENABLED = UniStringOption.new("Quick Access Menu", "Adds a convenience menu bound to the A key.", %w[Off On])
  QUICK_ACCESS_EXIT_AFTER = UniStringOption.new("Quick Access Exit", "Whether quick access menu should close after performing an action.", %w[None Auto], nil, 1)
  QUICK_ACCESS_OPTIONS = ["Heal Party", "Use PC", "Fly", "Add Item", "Add Pokémon", "Set Money", "Jukebox", "Spice Scent", "Move Tutor"]
  QUICK_ACCESS_OPTIONS.insert(QUICK_ACCESS_OPTIONS.index("Move Tutor"), "Unreal Clock") if UniLib.current_config("unreal_clock")

  def quick_access_menu
    $game_map.update
    QuickAccessMenu.new(QuickAccessMenuScene.new).menu
  end

  class PokemonTemp
    attr_accessor(:quick_access)
  end

  def create_number_param(range: nil, initial: nil, cancel: nil, max_digits: nil)
    params = ChooseNumberParams.new
    params.setRange(range[0], range[1]) if range
    params.setInitialValue(initial) if initial
    params.setCancelValue(cancel) if cancel
    params.setMaxDigits(max_digits) if max_digits
    params
  end

  class QuickAccessMenu

    def initialize(scene)
      @scene = scene
    end

    def option_select
      arr = $qol_quick_access.clone
      arr -= ["Fly"] if !(HIDDENMOVESCOUNTBADGES ? $Trainer.numbadges >= BADGEFORFLY : $Trainer.badges[BADGEFORFLY]) ||
                        (Rejuv and inPast? || $game_switches[:NotPlayerCharacter]) || $game_switches[:NoFlyZone] ||
                        $game_player.pbHasDependentEvents? || $game_switches[:Riding_Tauros] || !$cache.mapdata[$game_map.map_id].Outdoor
      (arr.select { |e| QUICK_ACCESS_OPTIONS.include? e }) + ["Add/Remove"]
    end

    def menu
      pbSEPlay("menu")
      $qol_quick_access = UniLib.restore_data("quick_access_settings", [])
      @scene.start(option_select)
      loop do
        if (command = @scene.show_commands) == -1
          pbSEPlay("menuclose")
          break
        end
        case command[1]
        when "Heal Party"
          $Trainer.party.each { |pkmn| pkmn.heal }
          Kernel.pbMessage("Your Pokémon were healed.")
          break if QUICK_ACCESS_EXIT_AFTER == 1
        when "Fly"
          region = $cache.mapdata[$game_map.map_id].MapPosition.is_a?(Hash) ? pbUnpackMapHash[0] : $cache.mapdata[$game_map.map_id].MapPosition[0]
          scene = PokemonRegionMapScene.new(region, false)
          screen = PokemonRegionMap.new(scene)
          @scene.hide_and_execute {
            ret = screen.pbStartFlyScreen
            if ret
              pbFlyAnimation
              pbSEPlay("PRSFX- Fly2")
              pbFadeOutIn(99999) {
                Kernel.pbCancelVehicles
                $game_temp.player_new_map_id, $game_temp.player_new_x, $game_temp.player_new_y = ret
                $game_temp.player_new_direction = 2
                $game_player.direction_fix = false
                pbToneChangeAll(Tone.new(-255, -255, -255), 0)
                $scene.transfer_player
                pbToneChangeAll(Tone.new(0, 0, 0), 8)
                $game_map.autoplay
                $game_map.refresh
                $game_variables[:Forced_Field_Effect] = 0
                $game_switches[:Rage_Powder_Vial] = false
                $game_switches[:Sleep_Powder_Vial] = false
              }
              pbFlyAnimation(true)
              pbEraseEscapePoint
            end
          }
          break if QUICK_ACCESS_EXIT_AFTER == 1
        when "Add Item"
          @scene.hide_and_execute {
            if (item = pbListScreen(_INTL("ADD ITEM"),ItemLister.new(0)))
              if (qty = Kernel.pbMessageChooseNumber("Choose the number of items.", create_number_param(range: [1, BAGMAXPERSLOT], initial: 1, cancel: 0))) == 1
                Kernel.pbReceiveItem(item)
              elsif qty > 1
                Kernel.pbMessage(_INTL("The item was added."))
                $PokemonBag.pbStoreItem(item, qty)
              end
            end
          }
          break if QUICK_ACCESS_EXIT_AFTER == 1
        when "Add Pokémon"
          @scene.hide_and_execute {
            if (species = pbChooseSpeciesOrdered(1))
              level = Kernel.pbMessageChooseNumber("Set the Pokémon's level.", create_number_param(range: [0, MAXIMUMLEVEL], initial: 5, cancel: 0))
              form = Kernel.pbMessageChooseNumber("Set the Pokémon's form.", create_number_param(range: [0, $cache.pkmn[species].forms.length], initial: 0))
              pbAddPokemon(species, level, true, form) if level > 0
            end
          }
          break if QUICK_ACCESS_EXIT_AFTER == 1
        when "Use PC"
          @scene.hide_and_execute { pbPokeCenterPC }
          break if QUICK_ACCESS_EXIT_AFTER == 1
        when "Set Money"
          @scene.hide_and_execute do
            $Trainer.money=Kernel.pbMessageChooseNumber("Set the player's money.", create_number_param(initial: $Trainer.money, max_digits: 6))
            Kernel.pbMessage(_INTL("You now have ${1}.",$Trainer.money))
          end
          break if QUICK_ACCESS_EXIT_AFTER == 1
        when "Jukebox"
          @scene.hide_and_execute { QuickAccessJukeboxScene.new.main }
          break if QUICK_ACCESS_EXIT_AFTER == 1
        when "Spice Scent"
          @scene.hide_and_execute { QuickAccessEncounterRateScene.new.main }
          break if QUICK_ACCESS_EXIT_AFTER == 1
        when "Unreal Clock"
          @scene.hide_and_execute {
            if $Settings.unrealTimeDiverge == 1
              Scene_UnrealClock.new.main(false)
            else
              Kernel.pbMessage("This requires Unreal Time to be active!")
            end
          }
          break if QUICK_ACCESS_EXIT_AFTER == 1
        when "Move Tutor"
          @scene.hide_and_execute { pbRelearnMoveTutorScreen }
          break if QUICK_ACCESS_EXIT_AFTER == 1
        when "Add/Remove"
          @scene.hide_and_execute { QuickAccessSelectorMenu.new(QuickAccessMenuScene.new).menu }
          @scene.commands = option_select
          @scene.refresh
        else break
        end
      end
      @scene.end
    end

  end

  class QuickAccessSelectorMenu < QuickAccessMenu

    def menu
      commands = QUICK_ACCESS_OPTIONS.map { |c| "#{$qol_quick_access.include?(c) ? "+" : "-"} #{c}" }
      @scene.start(commands)
      loop do
        break if (command = @scene.show_commands) == -1
        substr = command[1][2, command[1].length]
        if $qol_quick_access.include?(substr)
          @scene.set_cmd(command[0], "- " + substr)
          $qol_quick_access.delete(substr)
        else
          @scene.set_cmd(command[0], "+ " + substr)
          $qol_quick_access.push(substr).sort_by!(&QUICK_ACCESS_OPTIONS.method(:index))
        end
      end
      UniLib.save_data("quick_access_settings", $qol_quick_access)
      @scene.end
    end

  end

  class QuickAccessMenuScene

    attr_accessor(:commands)

    def start(commands)
      @commands = commands
      @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
      @viewport.z = 99999
      @sprites = {}
      @sprites["cmdwindow"] = Window_CommandPokemon.new(commands)
      @sprites["cmdwindow"].visible = false
      @sprites["cmdwindow"].viewport = @viewport
    end

    def refresh
      @sprites["cmdwindow"].dispose
      @sprites["cmdwindow"] = Window_CommandPokemon.new(@commands)
      @sprites["cmdwindow"].viewport = @viewport
      @index = [@commands.length - 1, @index].min
    end

    def end
      pbDisposeSpriteHash(@sprites)
      @viewport.dispose
    end

    def hide_and_execute
      @sprites["cmdwindow"].visible = false
      yield
      @sprites["cmdwindow"].visible = true
    end

    def set_cmd(idx, val)
      @sprites["cmdwindow"].commands[idx] = @commands[idx] = val
    end

    def commands=(other)
      @sprites["cmdwindow"].commands = @commands = other
    end

    def show_commands
      cmdwindow = @sprites["cmdwindow"]
      cmdwindow.commands = @commands
      delay = @index ? 10 : 0
      cmdwindow.index    = @index ? @index : 0
      cmdwindow.visible  = true
      loop do
        cmdwindow.index = 0 if (delay += 1) < 3
        pbUpdateSpriteHash(@sprites)
        pbUpdateSceneMap
        Graphics.update
        Input.update
        return -1 if Input.trigger?(Input::B)
        return [cmdwindow.index, cmdwindow.commands[@index = cmdwindow.index]] if Input.trigger?(Input::C) || Input.trigger?(14)
      end
    end

  end

  class QuickAccessJukeboxScene < Scene_Jukebox

    def main
      @sprites = {}
      @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
      @viewport.z = 99999
      @sprites["background"] = IconSprite.new(0,0)
      @sprites["background"].setBitmap("Graphics/Pictures/jukeboxbg")
      @sprites["background"].z = 255
      files= []
      @extras = []
      @extras_nested = []
      Dir.chdir("Audio/BGM/") { Dir.glob("{*.mp3,*.ogg,*.mid}") {|m| files.push(m) } }
      Dir.chdir(UniLib.path("")) { Dir.glob("{*.mp3,*.ogg,*.mid}") {|m| @extras.push(m) } }
      Dir.chdir(UniLib.path("Music")) { Dir.glob("{*.mp3,*.ogg,*.mid}") {|m| @extras_nested.push(m) } } rescue nil
      files.sort!
      @extras.sort!
      @extras_nested.sort!
      files += @extras + @extras_nested
      files.push("Stop Playing")
      @choices= files
      @sprites["header"] = Window_UnformattedTextPokemon.newWithSize(_INTL("Jukebox"), 2,-18,128,64,@viewport)
      @sprites["header"].baseColor = Color.new(248,248,248)
      @sprites["header"].shadowColor = Color.new(0,0,0)
      @sprites["header"].windowskin = nil
      @sprites["command_window"] = Window_CommandPokemon.new(@choices,324)
      @sprites["command_window"].windowskin = nil
      @sprites["command_window"].index = @menu_index
      @sprites["command_window"].setHW_XYZ(224,324,94,92,256)
      Graphics.transition
      loop do
        Graphics.update
        Input.update
        update
        break if @cancel
      end
      pbDisposeSpriteHash(@sprites)
      @viewport.dispose
    end

    def updateCustom
      if Input.trigger?(Input::B)
        pbPlayCancelSE()
        if @fromPokeGear
          $scene = Scene_Pokegear.new(:jukebox)
        else
          $scene = Scene_Map.new
        end
        return
      end
      if Input.trigger?(Input::C)
        $PokemonMap.whiteFluteUsed = false if $PokemonMap
        $PokemonMap.blackFluteUsed = false if $PokemonMap
        if !$Settings.volume
          $Settings.volume = 100.0
        end
        if @sprites["command_window"].index == @sprites["command_window"].commands.length - 1
          if Reborn && !@fromPokeGear
            $game_variables[808] = 0
            $game_map.map.bgm.name = "Nightclub- Main"
            pbBGMPlay($game_map.map.bgm)
          else
            $game_system.setDefaultBGM(nil, $Settings.volume)
            $game_system.bgm_stop
            $game_map.autoplay
          end
        else
          default = @sprites["command_window"].commands[@sprites["command_window"].index]
          default = "../../#{UniLib.path(default)}" if @extras.include? default
          default = "../../#{UniLib.path("Music/" + default)}" if @extras_nested.include? default
          if Reborn && !@fromPokeGear
            $game_variables[808] = default
            $game_system.setDefaultBGM(nil, $Settings.volume)
            $game_system.bgm_play(
              pbResolveAudioFile($game_variables[808], $Settings.volume)
            )
          else
            $game_system.setDefaultBGM(default, $Settings.volume)
          end
        end
        @sprites["command_window"].refresh
      end
    end

    def update
      pbUpdateSpriteHash(@sprites)
      if Input.trigger?(Input::B)
        pbPlayCancelSE()
        @cancel = true
        return
      end
      updateCustom
    end
  end


  class Scene_EncounterRate; end if Reborn

  class QuickAccessEncounterRateScene < Scene_EncounterRate

    def main
      $game_variables[:EncounterRateModifier]=1 if !defined?($game_variables[:EncounterRateModifier]) || $game_switches[:FirstUse]!=true
      @sprites={}
      @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
      @viewport.z=99999
      @sprites["background"] = IconSprite.new(0,0)
      @sprites["background"].setBitmap(UniQOL.asset("spicescentbg.png"))
      @sprites["background"].z=255
      Graphics.transition
      params=ChooseNumberParams.new
      params.setRange(0, 9999)
      params.setInitialValue([$game_variables[:EncounterRateModifier].to_f*100, 9999].min)
      params.setCancelValue($game_variables[:EncounterRateModifier].to_f*100)
      $game_variables[:EncounterRateModifier]=Kernel.pbMessageChooseNumberCentered(params).to_f/100
      $game_switches[:FirstUse]=true
      pbDisposeSpriteHash(@sprites)
      @viewport.dispose
    end

  end

  UniLib.insert_in_method_before(:Scene_Map, :update, "if Input.trigger?(Input::Y)",
    "if Input.trigger?(14) and UniLib.get_config(\"birb_uniqol\", \"quick_access_menu\") and QUICK_ACCESS_ENABLED == 1
      $PokemonTemp.quick_access = true
    end unless pbMapInterpreterRunning?")

  UniLib.replace_in_method(:Scene_Map, :update, "if $game_temp.battle_calling",
    "if $PokemonTemp.quick_access
      $PokemonTemp.quick_access = false
      quick_access_menu
    elsif $game_temp.battle_calling")

end