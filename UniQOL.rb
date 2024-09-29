require "Data/Mods/UniLib/StandardAPI"

unilib_include "Options"

ENABLE_DEBUG_TOGGLE_OPTION = true
ENABLE_PRISM_CHANCE_OPTION = true
ENABLE_CONTRACT_MODE_OPTION = true
ENABLE_CONTRACT_PENALTY_OPTION = true
ENABLE_CONTRACT_INFO_OPTION = true
ENABLE_EGG_COUNT_OPTION = true
ENABLE_EGG_DESTINATION_OPTION = true
ENABLE_HATCH_ANIMATION_OPTION = true
ENABLE_HATCH_NICKNAME_OPTION = true
ENABLE_ENCOUNTER_LURE_OPTION = true
ENABLE_AUTO_HOOK_OPTION = true
ENABLE_INSTANT_HOOK_OPTION = true
ENABLE_MAX_BAG_ITEM_OPTION = true
ENABLE_TMX_ANIMATION_OPTION = true
ENABLE_ITEM_REPLENISH_OPTION = true
ENABLE_EGG_RELEARN_OPTION = true
ENABLE_PREEVO_RELEARN_OPTION = true
ENABLE_SNAPPY_MENUS_OPTION = true

ENABLE_MASS_RELEASE = true
ENABLE_UNREAL_CLOCK = true
ENABLE_HP_CHANGER = true

#======================================================================================================================#
#====================================================== OPTIONS =======================================================#
#======================================================================================================================#

#======================================================= DEBUG ========================================================#

if ENABLE_DEBUG_TOGGLE_OPTION

  DEBUG_ENABLED = UniStringOption.new("Debug", "Debug mode toggle.", %w[Off On], proc { |value|$DEBUG = value == 1})

end

#================================================= BLACK PRISM CHANCE =================================================#

if ENABLE_PRISM_CHANCE_OPTION

  BLACK_PRISM_CHANCE = UniNumberOption.new("Black Prism Chance", "Black Prism chance, as a percentage", 1, 100, 1)

  replace_in_function(Events.onWildPokemonCreate.instance_variable_get(:@callbacks)[6], "if check==0", "if BLACK_PRISM_CHANCE > check")

end

#=================================================== CONTRACT UTILS ===================================================#

if ENABLE_CONTRACT_MODE_OPTION

  CONTRACT_MODE = UniStringOption.new("Contract Mode", "Tech contract restrictions for the given move type.", %w[All TM UTM Tutor Egg])
  ALL_TM_MOVES = []

  def get_tm_moves
    $cache.items.each { |_, data| ALL_TM_MOVES.push(data.checkFlag?(:tm)) if data.checkFlag?(:tm) }
  end

  add_play_event(:get_tm_moves)

  Events.onWildPokemonCreate += proc do |_,e|
    pokemon=e[0]
    if CONTRACT_MODE > 0
      bonuslist = pokemon.formCheck(:compatiblemoves)
      bonuslist = $cache.pkmn[pokemon.species].compatiblemoves if bonuslist.nil?
      case CONTRACT_MODE
      when 1 then bonuslist = bonuslist & ALL_TM_MOVES - PBStuff::UNIVERSALTMS
      when 2 then bonuslist = bonuslist & ALL_TM_MOVES | PBStuff::UNIVERSALTMS
      when 3
        eggmoves = pokemon.formCheck(:EggMoves)
        eggmoves = $cache.pkmn[pokemon.species].EggMoves if eggmoves.nil?
        eggmoves = [] if eggmoves.nil?
        bonuslist = bonuslist - ALL_TM_MOVES - PBStuff::UNIVERSALTMS - eggmoves
      else
        eggmoves = pokemon.formCheck(:EggMoves)
        eggmoves = $cache.pkmn[pokemon.species].compatiblemoves if eggmoves.nil?
        eggmoves = [] if eggmoves.nil?
        bonuslist = eggmoves
      end
      move = bonuslist.sample
      move = nil if [:FISSURE,:ROCKCLIMB,:MAGMADRIFT].include?(move)
      pokemon.moves.reverse![0] = PBMove.new(move) unless move.nil?
      pokemon.moves.reverse!
    end unless [95, 98, 100, 120, 128, 129].include?($game_variables[:WildMods])
  end

end

#================================================== CONTRACT PENALTY ==================================================#

if ENABLE_CONTRACT_PENALTY_OPTION

  CONTRACT_PENALTY = UniStringOption.new("Contract Penalty", "Tech contract 50% catchrate penalty.", %w[Off On], nil, 1)

  replace_in_method(:PokeBattle_BattleCommon, :pbThrowPokeBall, "rareness /= 2 if $game_variables[:LuckMoves] != 0", "rareness /= 2 if $game_variables[:LuckMoves] != 0 unless CONTRACT_PENALTY == 0")

end

#=================================================== CONTRACT INFO ====================================================#

if ENABLE_CONTRACT_INFO_OPTION

  CONTRACT_INFO = UniStringOption.new("Contract Info", "Tech contract-related info in battle inspector.", %w[None Count Moves])

  insert_in_function_before(:pbShowBattleStats, "report.push(_INTL(\"Level: {1}\",pkmn.level))",  proc do |report, pkmn|
    if $game_variables[:LuckMoves] != 0 and !$game_switches[:Raid] and !@battle.opponent and pkmn != @battle.battlers[0] and pkmn != @battle.battlers[2]
      report.push(_INTL("Contract Encounters: {1}", $game_variables[:LuckMoves])) if CONTRACT_INFO >= 1
      report.push(_INTL("Contract Move: {1}", pkmn.moves[pkmn.moves.length - 1].name)) if CONTRACT_INFO == 2
    end unless [95, 98, 100, 120, 128, 129].include?($game_variables[:WildMods])
  end)

end

#================================================== DAYCARE EGG COUNT =================================================#

if ENABLE_EGG_COUNT_OPTION

  DAYCARE_EGG_COUNT = UniNumberOption.new("Daycare Egg Count", "Number of eggs to generate when picking up from the daycare.", 1, 30, 1)

  insert_in_function_before(:pbDayCareGenerateEgg, "pokemon0=$PokemonGlobal.daycare[0][0]", proc do
    egg_count = 0
    sent = 0
    boxes = []
    loop do
      egg_count += 1
  end end)

  insert_in_function(:pbDayCareGenerateEgg, "addPkmnToPartyOrPC(egg)", proc do |egg_count, sent, boxes| while true
      break if $Trainer.party.length >= 6 or DAYCARE_EGG_COUNT <= egg_count
    end
    if sent > 0
      if sent == 1
        Kernel.pbMessage(_INTL("Egg was sent to {1}.", $PokemonStorage[boxes[0]].name))
      elsif boxes.length == 1
        Kernel.pbMessage(_INTL("Sent {1} eggs to {2}.", sent, $PokemonStorage[boxes[0]].name))
      else
        Kernel.pbMessage(_INTL("Sent {1} eggs from {2} to {3}.", sent, $PokemonStorage[boxes[0]].name, $PokemonStorage[boxes[-1]].name))
      end
    elsif sent == -1
      Kernel.pbMessage("No space left in the PC")
    end
  end)

end

#=============================================== DAYCARE EGG DESTINATION ==============================================#

if ENABLE_EGG_DESTINATION_OPTION

  EGG_DESTINATION_OPTION = UniStringOption.new("Daycare Egg Dest.", "Where eggs are sent when picking up from the daycare.", %w[Party Box])

  replace_in_function(:pbDayCareGenerateEgg, "addPkmnToPartyOrPC(egg)", proc do |egg, boxes|
    if EGG_DESTINATION_OPTION == 0
      addPkmnToPartyOrPC(egg)
    else
      (box = $PokemonStorage.pbStoreCaught(egg)) >= 0 ? sent += 1 : (sent = -1; break)
      boxes.push(box) unless boxes.include?(box)
    end
  end)

end

#================================================= EGG HATCH ANIMATION ================================================#

if ENABLE_HATCH_ANIMATION_OPTION

  NO_HATCH_SCENE = UniStringOption.new("Egg Hatch Anim.", "Egg hatch animation.", %w[Off On], nil, 1)

  replace_in_function(:pbHatch, "val=pbHatchAnimation(pokemon)", "val = NO_HATCH_SCENE == 0 or pbHatchAnimation(pokemon)")

  insert_in_function(:pbHatch, "puts val", proc do |pokemon, speciesname|
    if NO_HATCH_SCENE == 0
      Kernel.pbMessage(_INTL("{1} hatched from the Egg!", speciesname))
      if Kernel.pbConfirmMessage(_INTL("Would you like to nickname the newly hatched {1}?", speciesname))
        nickname=pbEnterPokemonName(_INTL("{1}'s nickname?", speciesname),0,12,"", pokemon)
        pokemon.name=nickname if nickname!=""
      end unless defined? HATCH_NICKNAME and HATCH_NICKNAME == 0
    end
  end)

end

#============================================== EGG HATCH NICKNAME PROMPT =============================================#

if ENABLE_HATCH_NICKNAME_OPTION

  HATCH_NICKNAME = UniStringOption.new("Egg Name Prompt", "Prompt for nickname when an egg hatches.", %w[Off On], nil, 1)

  replace_in_method(:PokemonEggHatchScene, :pbMain, "if Kernel.pbConfirmMessage(_INTL(\"Would you like to nickname the newly hatched {1}?\",@pokemon.name))", "if HATCH_NICKNAME == 1 and Kernel.pbConfirmMessage(_INTL(\"Would you like to nickname the newly hatched {1}?\",@pokemon.name))")

end

#=================================================== ENCOUNTER LURE ===================================================#

if ENABLE_ENCOUNTER_LURE_OPTION

  ENCOUNTER_LURE = UniStringOption.new("Encounter Lure", "Always-active magnetic or mirror lure.", %w[Off Magnetic Mirror])

  insert_in_method_before(:PokemonEncounters, :pbShouldFilterKnownPkmnFromEncounter?, "return false", "return true if ENCOUNTER_LURE == 1")
  insert_in_method_before(:PokemonEncounters, :pbShouldFilterOtherPkmnFromEncounter?, "return false", "return true if ENCOUNTER_LURE == 2")

end

#================================================= FISHING AUTO HOOK ==================================================#

if ENABLE_AUTO_HOOK_OPTION

  AUTO_HOOK = UniStringOption.new("Auto Hook", "Fishing hook triggers automatically.", %w[Off On], proc { |value| FISHINGAUTOHOOK = value == 1 })

end unless mod_included?("FISHINGAUTOHOOK")

#================================================ FISHING INSTANT HOOK ================================================#

if ENABLE_INSTANT_HOOK_OPTION

  INSTANT_HOOK = UniStringOption.new("Instant Hook", "Fishing hook triggers instantly.", %w[Off On])

  replace_in_function(:pbFishing, "time=2+rand(10)", "time = INSTANT_HOOK == 0 ? 2 + rand(10) : 0")

  replace_in_function(:pbFishing, "if !pbWaitForInput(msgwindow,message+_INTL(\"\\r\\nOh!  A bite!\"),frames)", proc do |msgwindow, message, frames|
    unless INSTANT_HOOK == 1 ? pbWaitForInput(msgwindow, _INTL("Oh!  A bite!"), frames) : pbWaitForInput(msgwindow, message + _INTL("\r\nOh!  A bite!"), frames)
  end end)

end

#================================================= MAX BAG ITEM COUNT =================================================#

if ENABLE_MAX_BAG_ITEM_OPTION

  MAX_BAG_COUNT = UniNumberOption.new("Bag Item Max", "Maximum number to be held in bag per item.", 99, 9999, 9, 999, proc { |value| BAGMAXPERSLOT = value})

end

#=================================================== TMX ANIMATIONS ===================================================#
#====================================================== SWM PORT ======================================================#

if ENABLE_TMX_ANIMATION_OPTION

  NO_TMX_ANIM = UniStringOption.new("Disable TMX Anim.", "Disables TMX animations.", %w[Off On])

  insert_in_function(:pbHiddenMoveAnimation, :HEAD, "return false if NO_TMX_ANIM")

end unless mod_included?("SWM - NoTMXAnimations")

#================================================ ITEM REPLACE/RESTORE ================================================#
#====================================================== SWM PORT ======================================================#

if ENABLE_ITEM_REPLENISH_OPTION

  ITEM_REPLACE_RESTORE = UniStringOption.new("Item Replenish", "Replace used items from the bag or restore them without consumption.", %w[Off Replace Restore])

  replace_in_method(:PokeBattle_Battler, :pbDisposeItem, "self.pokemon.itemInitial=nil if self.pokemon.itemInitial==self.item", proc do
    self.pokemon.itemInitial=nil if self.pokemon.itemInitial==self.item and !(ITEM_REPLACE_RESTORE == 2 || ITEM_REPLACE_RESTORE == 1 && $PokemonBag.pbDeleteItem(self.item))
  end)

end unless mod_included?("ItemReplaceRestore")

#================================================== RELEARN EGG MOVES =================================================#
#====================================================== AMB PORT ======================================================#

if ENABLE_EGG_RELEARN_OPTION

  RELEARN_EGG_MOVES = UniStringOption.new("Egg Relearn", "Egg moves in move relearner before Fly.", %w[Off On])

  replace_in_function(:pbGetRelearnableMoves, "moves= tmoves+pokemon.getEggMoveList(true)+moves if Rejuv && $PokemonBag.pbHasItem?(:HM02)", proc do |moves, tmoves, pokemon|
    moves = tmoves + pokemon.getEggMoveList(true) + moves if RELEARN_EGG_MOVES == 1 or Rejuv && $PokemonBag.pbHasItem?(:HM02)
  end, 0)

end unless mod_included?("Learn_Egg_moves")

#================================================= RELEARN_PREEVO_MOVES ===============================================#
#====================================================== AMB PORT ======================================================#

if ENABLE_PREEVO_RELEARN_OPTION

  RELEARN_EGG_MOVES = UniStringOption.new("PreEvo Relearn", "Learn moves from pre-evolutions.", %w[Off On])

  insert_in_function(:pbEachNaturalMove, :TAIL,
   "if RELEARN_EGG_MOVES == 1
      prevo, cache = pbGetPreviousForm(pokemon.species,pokemon.form), $cache.pkmn
      until prevo[0].nil? or prevo[1].nil? or %w[Mega Primal].include?(name = cache[prevo[0]].forms[prevo[1]])
        ((prevo[1] == 0 || (cache[prevo[0]].formData.dig(name,:Moveset).nil? && (prevo[1] = 0) == 0)) ?
           cache[prevo[0]].Moveset : cache[prevo[0]].formData.dig(name,:Moveset)).each { |mv| yield mv[1], mv[0] }
        break if prevo == (tmp = pbGetPreviousForm(prevo[0],prevo[1]))
        prevo = tmp
      end
    end")

end unless mod_included?("Learn_PreEvo_Moves")

#==================================================== SNAPPY MENUS ====================================================#
#====================================================== SWM PORT ======================================================#

if ENABLE_SNAPPY_MENUS_OPTION

  SNAPPY_MENUS = UniStringOption.new("Snappy Menus", "Disables menu transitions.", %w[Off On])

  replace_in_function(:pbFadeOutIn, "Graphics.update", "Graphics.update unless SNAPPY_MENUS == 1")
  replace_in_function(:pbFadeOutIn, "Graphics.update", "Graphics.update unless SNAPPY_MENUS == 1", 1)
  replace_in_function(:pbFadeOutIn, "Input.update", "Input.update unless SNAPPY_MENUS == 1")
  replace_in_function(:pbFadeOutIn, "Input.update", "Input.update unless SNAPPY_MENUS == 1", 1)
  replace_in_function(:pbSetSpritesToColor, "Graphics.update", "Graphics.update unless SNAPPY_MENUS == 1")
  replace_in_function(:pbSetSpritesToColor, "Input.update", "Input.update unless SNAPPY_MENUS == 1")

  insert_in_function_before(:pbFadeOutIn, "pbPushFade", proc do
    if SNAPPY_MENUS == 1
      Graphics.update
      Input.update
    end
  end)

  insert_in_function_before(:pbFadeOutIn, "viewport.dispose", proc do
    if SNAPPY_MENUS == 1
      Graphics.update
      Input.update
    end
  end)

  trans = Graphics.method(:transition)
  define_method(:transition) { |i=0| trans.(SNAPPY_MENUS == 1 ? 0 : i) }

end unless mod_included?("SWM - SnappyMenus")

#======================================================================================================================#
#======================================================== FIXES =======================================================#
#======================================================================================================================#

#=================================================== FIX EGG MOVES ====================================================#
#===================================== BASED ON ALEMI AND MATT'S IMPLEMENTATION =======================================#

unless mod_included?("FixEggMoves")

  replace_in_method(:PokeBattle_Pokemon, :getEggMoveList, "movelist = $cache.pkmn[babyspecies[0]].formData.dig(formname,:EggMoves)", proc do |babyspecies, formname, movelist|
    movelist = $cache.pkmn[babyspecies[0]].formData.dig(formname, :EggMoves) unless $cache.pkmn[babyspecies[0]].formData.dig(formname, :EggMoves).nil?
  end)

end

#======================================================================================================================#
#====================================================== FEATURES ======================================================#
#======================================================================================================================#

#==================================================== MASS RELEASE ====================================================#

if ENABLE_MASS_RELEASE

  insert_in_method(:PokemonStorageScene, :pbSelectBox, "if @aMultiSelectedMons.include?(ret)", proc do |ret|
    case Kernel.pbMessage("What do you want to do?", ["Deselect", "Mass Release", "Cancel"], 3)
    when 0 then @screen.pbHold(ret, true)
    when 1
      if Kernel.pbMessage(_INTL("Are you sure you want to mass release {1} Pokémon?", @aMultiSelectedMons.length), %w[Yes No], 2) == 0
        @aMultiSelectedMons.each { |pkmn| @storage.pbDelete(pkmn[0], pkmn[1]) }
        pbHardRefresh
        pbDisplay(_INTL("Released {1} Pokémon.", @aMultiSelectedMons.length))
        @aMultiSelectedMons.clear
      end
    else return [-2,-1]
    end
    return [-2,-1]
  end)

end

#==================================================== UNREAL CLOCK ====================================================#

if ENABLE_UNREAL_CLOCK

  unilib_include "Options"

  UNREAL_CLOCK_BG = UniNumberOption.new("Unreal Clock BG", "One of 4 different backgrounds for Unreal Clock", 1, 4)

  UNI_DOW = %w[Mon Tue Wed Thu Fri Sat Sun]

  UNREAL_CLOCK_ASSETS = [unilib_resolve_asset("clockcontrolgui"), unilib_resolve_asset("cherry"), unilib_resolve_asset("antstroubled"), unilib_resolve_asset("texencringe")]

  insert_in_method(:Scene_Pokegear, :setup, "@buttons[@cmdScent=@buttons.length] = \"Spice Scent\"", proc do
    unless $Settings.unrealTimeDiverge == 0
      @cmdUnrealClock = -1
      @buttons[@cmdUnrealClock = @buttons.length] = "Unreal Clock"
    end
  end)

  insert_in_method_before(:Scene_Pokegear, :checkChoice, "if ($game_switches[:NotPlayerCharacter] == false ||  $game_switches[:InterceptorsWish] == true)", proc do
    if @cmdUnrealClock>=0 && @sprites["command_window"].index==@cmdUnrealClock
      pbPlayDecisionSE()
      $scene = Scene_UnrealClock.new
    end
  end)

  # modified from Scene_EncounterRate
  class Scene_UnrealClock

    def initialize(menu_index = 0)
      @menu_index = menu_index
    end

    def main
      @sprites={}
      @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
      @viewport.z=99999
      @sprites["background"] = IconSprite.new(0,0)
      @sprites["background"].setBitmap(UNREAL_CLOCK_ASSETS[UNREAL_CLOCK_BG.value])
      @sprites["background"].z = 255
      Graphics.transition

      time = $game_screen.gameTimeCurrent
      day, hours, minutes = time.day, time.hour, time.min
      cmd = Window_InputTime.new(day, hours, minutes)
      offset_y = [18, 32, -32, 32][UNREAL_CLOCK_BG.value]
      cmd.x, cmd.y, cmd.z, cmd.visible = Graphics.width / 2 - 80, Graphics.height / 2 - offset_y, 99999, true
      loop do
        [Graphics, Input].each(&:update)
        pbUpdateSceneMap
        cmd.update
        yield if block_given?
        if Input.trigger?(Input::C)
          day, hours, minutes = cmd.day, cmd.hours, cmd.minutes
          break
        elsif Input.trigger?(Input::B)
          pbPlayCancelSE()
          pbWait(2)
          break
        end
      end
      Kernel.pbMessage("#{day}")
      $game_screen.gameTimeCurrent = Time.unrealTime_oldTimeNew(time.year,time.month, day, hours, minutes, time.sec)
      cmd.dispose
      Input.update
      $scene = Scene_Pokegear.new
      Graphics.freeze
      pbDisposeSpriteHash(@sprites)
      @viewport.dispose
    end
  end

  class Window_InputTime < SpriteWindow_Base

    attr_accessor :day
    attr_accessor :hours
    attr_accessor :minutes

    def initialize(day, hours, minutes)
      super(0, 0, 32, 32)
      @day = day
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
      s=sprintf("%s%0*d%s%0*d",UNI_DOW[(@day - 2) % 7], 2, @hours, blink == 0 ? ":" : " ", 2, @minutes)
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
          when 0 then @day += diff; @day = 8 if @day < 2; @day = 2 if @day > 8
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

#================================================ HIDDEN POWER CHANGER ================================================#

if ENABLE_HP_CHANGER

  HP_TYPES = [:BUG, :DARK, :DRAGON, :ELECTRIC, :FAIRY, :FIGHTING, :FIRE, :FLYING, :GHOST, :GRASS, :GROUND, :ICE, :POISON, :PSYCHIC, :ROCK, :STEEL, :WATER, -1]

  def hp_type_change(mon)
    pbHiddenPower(mon) unless mon.hptype
    typechoices = [_INTL("Bug"),_INTL("Dark"),_INTL("Dragon"),_INTL("Electric"),_INTL("Fairy"),_INTL("Fighting"),_INTL("Fire"),_INTL("Flying"),_INTL("Ghost"),_INTL("Grass"),_INTL("Ground"),_INTL("Ice"),_INTL("Poison"),_INTL("Psychic"),_INTL("Rock"),_INTL("Steel"),_INTL("Water"),_INTL("Cancel")]
    choosetype = Kernel.pbMessage(_INTL("Which type should its move become?"),typechoices,18)
    if (choosetype >= 0) && (choosetype < 17) and HP_TYPES[choosetype].class == Symbol
      mon.hptype = HP_TYPES[choosetype]
      Kernel.pbMessage(_INTL("{1}'s hidden power type was changed to {2}!", mon.name, typechoices[choosetype]))
    end
  end

  insert_in_method(:PokemonScreen, :pbPokemonScreen, "cmdRename=-1", "cmdHP=-1")
  insert_in_method(:PokemonScreen, :pbPokemonScreen, "commands[cmdRename = commands.length] = _INTL(\"Rename\")", "commands[cmdHP = commands.length] = _INTL(\"Hidden Power\")")
  insert_in_method(:PokemonScreen, :pbPokemonScreen, "pbPokemonDebug(self, pkmn,pkmnid)", proc do |command, cmdHP, pkmn| if true
    elsif cmdHP >= 0 && command == cmdHP
      hp_type_change(pkmn)
  end end)

end