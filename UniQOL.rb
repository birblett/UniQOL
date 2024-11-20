require "Data/Mods/UniLib/StandardAPI"
require "Scripts/Rejuv/typetext"

UniLib.include "Options"
UniLib.verify_version(0.6, __FILE__)

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
ENABLE_SHADOW_CACHE = true

ENABLE_HP_CHANGER = true
ENABLE_MOVE_RELEARNER = true
ENABLE_MASS_RELEASE = true
ENABLE_STORAGE_MODIFIER = true
ENABLE_STAT_BOOST_DISPLAY = true
ENABLE_TYPE_BATTLE_ICONS = true
ENABLE_UNREAL_CLOCK = true

#==========================================================================================================================================#
#================================================================ OPTIONS =================================================================#
#==========================================================================================================================================#

#================================================================= DEBUG ==================================================================#

if ENABLE_DEBUG_TOGGLE_OPTION

  DEBUG_ENABLED = UniStringOption.new("Debug", "Debug mode toggle.", %w[Off On], proc { |value|$DEBUG = value == 1})

end

#=========================================================== BLACK PRISM CHANCE ===========================================================#

if ENABLE_PRISM_CHANCE_OPTION

  BLACK_PRISM_CHANCE = UniNumberOption.new("Black Prism Chance", "Black Prism chance, as a percentage", 1, 100, 1)

  Events.onWildPokemonCreate.instance_variable_get(:@callbacks)[6] = proc {|_, e|
    pokemon=e[0]
    check = rand(100)
    check = rand(20) if $game_variables[:LuckShinies] < 0
    if BLACK_PRISM_CHANCE > check
      pokemon.item = :BLKPRISM
      unless $cache.pkmn[pokemon.species].EggGroups.include?(:Undiscovered) || pokemon.species == :MANAPHY
        stat1, stat2, stat3 = [0, 1, 2, 3, 4, 5].sample(3)
        (0..5).each { |i| pokemon.iv[i] = 31 if [stat1, stat2, stat3].include?(i) }
      end
    end
  }

end

#============================================================= CONTRACT UTILS =============================================================#

if ENABLE_CONTRACT_MODE_OPTION

  CONTRACT_MODE = UniStringOption.new("Contract Mode", "Tech contract restrictions for the given move type.", %w[All TM UTM Tutor Egg])
  ALL_TM_MOVES = []

  def get_tm_moves
    $cache.items.each { |_, data| ALL_TM_MOVES.push(data.checkFlag?(:tm)) if data.checkFlag?(:tm) }
  end

  UniLib.add_play_event(:get_tm_moves)

  TECH_CONTRACT_EVENT = proc do |_,e|
    pokemon=e[0]
    if CONTRACT_MODE > 0 and $game_variables[:LuckMoves] > 0
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
      pokemon.moves.reverse!
      pokemon.moves[0] = PBMove.new(move) unless move.nil?
      pokemon.moves.reverse!
    end unless [95, 98, 100, 120, 128, 129].include?($game_variables[:WildMods])
  end

  Events.onWildPokemonCreate += TECH_CONTRACT_EVENT

end

#============================================================ CONTRACT PENALTY ============================================================#

if ENABLE_CONTRACT_PENALTY_OPTION

  CONTRACT_PENALTY = UniStringOption.new("Contract Penalty", "Tech contract 50% catchrate penalty.", %w[Off On], nil, 1)

  UniLib.replace_in_method(:PokeBattle_BattleCommon, :pbThrowPokeBall, "rareness /= 2 if $game_variables[:LuckMoves] != 0", "rareness /= 2 if $game_variables[:LuckMoves] != 0 unless CONTRACT_PENALTY == 0")

end

#============================================================= CONTRACT INFO ==============================================================#

if ENABLE_CONTRACT_INFO_OPTION

  CONTRACT_INFO = UniStringOption.new("Contract Info", "Tech contract-related info in battle inspector.", %w[None Count Moves])

  UniLib.insert_in_function_before(:pbShowBattleStats, "report.push(_INTL(\"Level: {1}\",pkmn.level))",
    "if $game_variables[:LuckMoves] != 0 and !$game_switches[:Raid] and !@battle.opponent and pkmn != @battle.battlers[0] and pkmn != @battle.battlers[2]
      report.push(_INTL(\"Contract Encounters: {1}\", $game_variables[:LuckMoves])) if CONTRACT_INFO >= 1
      report.push(_INTL(\"Contract Move: {1}\", pkmn.moves[pkmn.moves.length - 1].name)) if CONTRACT_INFO == 2
    end unless [95, 98, 100, 120, 128, 129].include?($game_variables[:WildMods])")

end

#============================================================ DAYCARE EGG COUNT ===========================================================#

if ENABLE_EGG_COUNT_OPTION

  DAYCARE_EGG_COUNT = UniNumberOption.new("Daycare Egg Count", "Number of eggs to generate when picking up from the daycare.", 1, 30, 1)

  UniLib.insert_in_function_before(:pbDayCareGenerateEgg, "pokemon0=$PokemonGlobal.daycare[0][0]",
    "egg_count = 0
    sent = 0
    boxes = []
    loop do
      egg_count += 1")

  UniLib.insert_in_function(:pbDayCareGenerateEgg, "addPkmnToPartyOrPC(egg)",
    "break if $Trainer.party.length >= 6 or DAYCARE_EGG_COUNT <= egg_count
    end
    if sent > 0
      if sent == 1
        Kernel.pbMessage(_INTL(\"Egg was sent to {1}.\", $PokemonStorage[boxes[0]].name))
      elsif boxes.length == 1
        Kernel.pbMessage(_INTL(\"Sent {1} eggs to {2}.\", sent, $PokemonStorage[boxes[0]].name))
      else
        Kernel.pbMessage(_INTL(\"Sent {1} eggs from {2} to {3}.\", sent, $PokemonStorage[boxes[0]].name, $PokemonStorage[boxes[-1]].name))
      end
    elsif sent == -1
      Kernel.pbMessage(\"No space left in the PC\")
    end")

end

#========================================================= DAYCARE EGG DESTINATION ========================================================#

if ENABLE_EGG_DESTINATION_OPTION

  EGG_DESTINATION_OPTION = UniStringOption.new("Daycare Egg Dest.", "Where eggs are sent when picking up from the daycare.", %w[Party Box])

  UniLib.replace_in_function(:pbDayCareGenerateEgg, "addPkmnToPartyOrPC(egg)",
    "if EGG_DESTINATION_OPTION == 0
      addPkmnToPartyOrPC(egg)
    else
      (box = $PokemonStorage.pbStoreCaught(egg)) >= 0 ? sent += 1 : (sent = -1; break)
      boxes.push(box) unless boxes.include?(box)
    end")

end

#=========================================================== EGG HATCH ANIMATION ==========================================================#

if ENABLE_HATCH_ANIMATION_OPTION

  NO_HATCH_SCENE = UniStringOption.new("Egg Hatch Anim.", "Egg hatch animation.", %w[Off On], nil, 1)

  UniLib.replace_in_function(:pbHatch, "val=pbHatchAnimation(pokemon)", "val = NO_HATCH_SCENE == 0 or pbHatchAnimation(pokemon)")

  UniLib.insert_in_function(:pbHatch, "puts val",
    "if NO_HATCH_SCENE == 0
      Kernel.pbMessage(_INTL(\"{1} hatched from the Egg!\", speciesname))
      if Kernel.pbConfirmMessage(_INTL(\"Would you like to nickname the newly hatched {1}?\", speciesname))
        nickname=pbEnterPokemonName(_INTL(\"{1}'s nickname?\", speciesname),0,12,\"\", pokemon)
        pokemon.name=nickname if nickname!=\"\"
      end unless defined? HATCH_NICKNAME and HATCH_NICKNAME == 0
    end")

end

#======================================================== EGG HATCH NICKNAME PROMPT =======================================================#

if ENABLE_HATCH_NICKNAME_OPTION

  HATCH_NICKNAME = UniStringOption.new("Egg Name Prompt", "Prompt for nickname when an egg hatches.", %w[Off On], nil, 1)

  UniLib.replace_in_method(:PokemonEggHatchScene, :pbMain, "if Kernel.pbConfirmMessage(_INTL(\"Would you like to nickname the newly hatched {1}?\",@pokemon.name))", "if HATCH_NICKNAME == 1 and Kernel.pbConfirmMessage(_INTL(\"Would you like to nickname the newly hatched {1}?\",@pokemon.name))")

end

#============================================================= ENCOUNTER LURE =============================================================#

if ENABLE_ENCOUNTER_LURE_OPTION

  ENCOUNTER_LURE = UniStringOption.new("Encounter Lure", "Always-active magnetic or mirror lure.", %w[Off Magnetic Mirror])

  UniLib.insert_in_method_before(:PokemonEncounters, :pbShouldFilterKnownPkmnFromEncounter?, "return false", "return true if ENCOUNTER_LURE == 1")
  UniLib.insert_in_method_before(:PokemonEncounters, :pbShouldFilterOtherPkmnFromEncounter?, "return false", "return true if ENCOUNTER_LURE == 2")

end

#=========================================================== FISHING AUTO HOOK ============================================================#

if ENABLE_AUTO_HOOK_OPTION

  AUTO_HOOK = UniStringOption.new("Auto Hook", "Fishing hook triggers automatically.", %w[Off On], proc { |value| FISHINGAUTOHOOK = value == 1 })

end unless UniLib.mod_included?("FISHINGAUTOHOOK")

#========================================================== FISHING INSTANT HOOK ==========================================================#

if ENABLE_INSTANT_HOOK_OPTION

  INSTANT_HOOK = UniStringOption.new("Instant Hook", "Fishing hook triggers instantly.", %w[Off On])

  UniLib.replace_in_function(:pbFishing, "time=2+rand(10)", "time = INSTANT_HOOK == 0 ? 2 + rand(10) : 0")

  UniLib.replace_in_function(:pbFishing, "if !pbWaitForInput(msgwindow,message+_INTL(\"\\r\\nOh!  A bite!\"),frames)",
    "unless INSTANT_HOOK == 1 ? pbWaitForInput(msgwindow, _INTL(\"Oh!  A bite!\"), frames) : pbWaitForInput(msgwindow, message + _INTL(\"\\r\\nOh!  A bite!\"), frames)")

end

#=========================================================== MAX BAG ITEM COUNT ===========================================================#

if ENABLE_MAX_BAG_ITEM_OPTION

  MAX_BAG_COUNT = UniNumberOption.new("Bag Item Max", "Maximum number to be held in bag per item.", 99, 9999, 9, 999, proc { |value| BAGMAXPERSLOT = value })

end

#============================================================= TMX ANIMATIONS =============================================================#
#================================================================ SWM PORT ================================================================#

if ENABLE_TMX_ANIMATION_OPTION

  NO_TMX_ANIM = UniStringOption.new("Disable TMX Anim.", "Disables TMX animations.", %w[Off On])

  UniLib.insert_in_function(:pbHiddenMoveAnimation, :HEAD, "return false if NO_TMX_ANIM")

end unless UniLib.mod_included?("SWM - NoTMXAnimations")

#========================================================== ITEM REPLACE/RESTORE ==========================================================#
#================================================================ SWM PORT ================================================================#

if ENABLE_ITEM_REPLENISH_OPTION

  ITEM_REPLACE_RESTORE = UniStringOption.new("Item Replenish", "Replace used items from the bag or restore them without consumption.", %w[Off Replace Restore])

  class PokeBattle_Pokemon

    def itemInitial=(other)
      @itemInitial = other unless other.nil? and (ITEM_REPLACE_RESTORE == 2 || ITEM_REPLACE_RESTORE == 1 && $PokemonBag.pbDeleteItem(self.item))
    end

  end

end unless UniLib.mod_included?("ItemReplaceRestore")

#============================================================ RELEARN EGG MOVES ===========================================================#
#================================================================ AMB PORT ================================================================#

if ENABLE_EGG_RELEARN_OPTION

  RELEARN_EGG_MOVES = UniStringOption.new("Egg Relearn", "Egg moves in move relearner before Fly.", %w[Off On])

  UniLib.replace_in_function(:pbGetRelearnableMoves, "moves= tmoves+pokemon.getEggMoveList(true)+moves if Rejuv && $PokemonBag.pbHasItem?(:HM02)",
    "moves = tmoves + pokemon.getEggMoveList(true) + moves if RELEARN_EGG_MOVES == 1 or Rejuv && $PokemonBag.pbHasItem?(:HM02)", 0)

end unless UniLib.mod_included?("Learn_Egg_moves")

#=========================================================== RELEARN_PREEVO_MOVES =========================================================#
#================================================================ AMB PORT ================================================================#

if ENABLE_PREEVO_RELEARN_OPTION

  RELEARN_EGG_MOVES = UniStringOption.new("PreEvo Relearn", "Learn moves from pre-evolutions.", %w[Off On])

  UniLib.insert_in_function(:pbEachNaturalMove, :TAIL,
    "if RELEARN_EGG_MOVES == 1
      prevo, cache = pbGetPreviousForm(pokemon.species,pokemon.form), $cache.pkmn
      until prevo[0].nil? or prevo[1].nil? or %w[Mega Primal].include?(name = cache[prevo[0]].forms[prevo[1]])
        ((prevo[1] == 0 || (cache[prevo[0]].formData.dig(name,:Moveset).nil? && (prevo[1] = 0) == 0)) ?
           cache[prevo[0]].Moveset : cache[prevo[0]].formData.dig(name,:Moveset)).each { |mv| yield mv[1], mv[0] }
        break if prevo == (tmp = pbGetPreviousForm(prevo[0],prevo[1]))
        prevo = tmp
      end
    end")

end unless UniLib.mod_included?("Learn_PreEvo_Moves")

#============================================================== SNAPPY MENUS ==============================================================#
#================================================================ SWM PORT ================================================================#

if ENABLE_SNAPPY_MENUS_OPTION

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

  UniLib.insert_in_method(:QuestList_Scene, :fadeContent, :HEAD, proc do
    "if SNAPPY_MENUS == 1
      Graphics.update
      @sprites[\"itemlist\"].contents_opacity -= 255
      @sprites[\"overlay1\"].opacity -= 255; @sprites[\"overlay_control\"].opacity -= 255
      @sprites[\"page_icon1\"].opacity -= 255; @sprites[\"pageIcon\"].opacity -= 255
      return
    end"
  end)

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

  trans = Graphics.method(:transition)
  Graphics.define_method(:transition) { |i=0| trans.(SNAPPY_MENUS == 1 ? 0 : i) }

end unless UniLib.mod_included?("SWM - SnappyMenus")

#============================================================== SHADOW CACHE ==============================================================#

if ENABLE_SHADOW_CACHE

  SHADOW_ICON_BMP_CACHE = {}
  SHADOW_SPECIES_BMP_CACHE = {}

  CACHE_SHADOWS = UniStringOption.new("Cache Shadows", "Caches shadow pokemon to mitigate box/storage lagspikes.", %w[Off On])

  UniLib.insert_in_function(:pbPokemonIconBitmap, "species = $cache.pkmn[pokemon.species].dexnum",
    "return SHADOW_ICON_BMP_CACHE[pokemon] if CACHE_SHADOWS == 1 and SHADOW_ICON_BMP_CACHE[pokemon] and pokemon.isShadow?")

  UniLib.insert_in_function_before(:pbPokemonIconBitmap, "return bitmap",
    "SHADOW_ICON_BMP_CACHE[pokemon] = bitmap if CACHE_SHADOWS == 1 and pokemon.isShadow?")

  UniLib.insert_in_function(:pbLoadPokemonBitmapSpecies, "formname = $cache.pkmn[species].forms[pokemon.form]",
  "shadow_cache = CACHE_SHADOWS == 1 and pokemon.isShadow? and !back
  if shadow_cache
    key = [dexnum, formname, pokemon.isShiny?, pokemon.gender, pokemon.isEgg?]
    return SHADOW_SPECIES_BMP_CACHE[pokemon][1] if SHADOW_SPECIES_BMP_CACHE[pokemon] and SHADOW_SPECIES_BMP_CACHE[pokemon][0] == key
  end")

  UniLib.insert_in_function_before(:pbLoadPokemonBitmapSpecies, "return bitmap",
    "SHADOW_SPECIES_BMP_CACHE[pokemon] = [key, bitmap] if shadow_cache")

end

#==========================================================================================================================================#
#================================================================== FIXES =================================================================#
#==========================================================================================================================================#

#============================================================= FIX EGG MOVES ==============================================================#
#=============================================== BASED ON ALEMI AND MATT'S IMPLEMENTATION =================================================#

unless UniLib.mod_included?("FixEggMoves")

  UniLib.replace_in_method(:PokeBattle_Pokemon, :getEggMoveList, "movelist = $cache.pkmn[babyspecies[0]].formData.dig(formname,:EggMoves)",
    "movelist = $cache.pkmn[babyspecies[0]].formData.dig(formname, :EggMoves) unless $cache.pkmn[babyspecies[0]].formData.dig(formname, :EggMoves).nil?")

end

#==========================================================================================================================================#
#================================================================ FEATURES ================================================================#
#==========================================================================================================================================#

#========================================================== HIDDEN POWER CHANGER ==========================================================#

if ENABLE_HP_CHANGER

  HIDDEN_POWER_CHANGER = UniStringOption.new("HP Type Changer", "Allows changing hidden power type in the PC or party.", %w[Off PC Party Both])

  HP_TYPES = [:BUG, :DARK, :DRAGON, :ELECTRIC, :FAIRY, :FIGHTING, :FIRE, :FLYING, :GHOST, :GRASS, :GROUND, :ICE, :POISON, :PSYCHIC, :ROCK, :STEEL, :WATER, -1]

  def hp_type_change(mon)
    pbHiddenPower(mon) unless mon.hptype
    typechoices = [_INTL("Bug"),_INTL("Dark"),_INTL("Dragon"),_INTL("Electric"),_INTL("Fairy"),_INTL("Fighting"),_INTL("Fire"),_INTL("Flying"),_INTL("Ghost"),_INTL("Grass"),_INTL("Ground"),_INTL("Ice"),_INTL("Poison"),_INTL("Psychic"),_INTL("Rock"),_INTL("Steel"),_INTL("Water"),_INTL("Cancel")]
    choosetype = Kernel.pbMessage(_INTL("Which type should its move become? (currently {1})", typechoices[HP_TYPES.find_index(mon.hptype)]), typechoices,18)
    if (choosetype >= 0) && (choosetype < 17) and HP_TYPES[choosetype].class == Symbol
      mon.hptype = HP_TYPES[choosetype]
      Kernel.pbMessage(_INTL("{1}'s hidden power type was changed to {2}!", mon.name, typechoices[choosetype]))
    end
  end

  UniLib.add_party_command("hidden_power", "HP Type", proc { |pkmn| hp_type_change(pkmn) }, proc { |pkmn| !pkmn.isEgg? and HIDDEN_POWER_CHANGER >= 2 })
  UniLib.add_box_command("hidden_power", "HP Type", proc { |pkmn| hp_type_change(pkmn) }, proc { |pkmn, _| !pkmn.isEgg? and HIDDEN_POWER_CHANGER & 1 == 1 })

end

#============================================================= MOVE RELEARNER =============================================================#

if ENABLE_MOVE_RELEARNER

  MOVE_RELEARN_COMMAND = UniStringOption.new("Move Relearner", "Allows relearning moves in the PC or party.", %w[Off PC Party Both])

  MOVE_RELEARN_FREE = UniStringOption.new("Free Relearning", "Party/PC relearn without costing a heart scale", %w[Off On])

  MOVE_RELEARN_BEFORE_TUTOR = UniStringOption.new("Relearn Any Time", "Allows party relearning before unlocking the move relearner.", %w[Off On])

  def relearn_from_menu(pkmn)
    if MOVE_RELEARN_FREE == 1 or $PokemonBag.pbHasItem?(:HEARTSCALE) and Kernel.pbConfirmMessage("This will consume a Heart Scale. Continue?")
      pbFadeOutIn(99999) { $has_relearned = MoveRelearnerScreen.new(MoveRelearnerScene.new).pbStartScreen(pkmn); pbUpdateSceneMap }
      $updateFLHUD = true
      $PokemonBag.pbDeleteItem(:HEARTSCALE) if $has_relearned
    elsif !$PokemonBag.pbHasItem?(:HEARTSCALE)
      Kernel.pbMessage("You need a Heart Scale to relearn moves!")
    end
  end

  UniLib.add_party_command("move_relearner", "Relearn", proc { |pkmn| relearn_from_menu(pkmn) }, proc { ($game_switches[1444] || MOVE_RELEARN_BEFORE_TUTOR == 1) && MOVE_RELEARN_COMMAND >= 2 })
  UniLib.add_box_command("move_relearner", "Relearn", proc { |pkmn| relearn_from_menu(pkmn) }, proc { ($game_switches[1445] || MOVE_RELEARN_BEFORE_TUTOR == 1) && MOVE_RELEARN_COMMAND & 1 })

end

#============================================================== MASS RELEASE ==============================================================#

if ENABLE_MASS_RELEASE

  UniLib.insert_in_method(:PokemonStorageScene, :pbSelectBox, "if @aMultiSelectedMons.include?(ret)",
    "case Kernel.pbMessage(\"What do you want to do?\", [\"Deselect\", \"Mass Release\", \"Cancel\"], 3)
    when 0 then @screen.pbHold(ret, true)
    when 1
      if Kernel.pbMessage(_INTL(\"Are you sure you want to mass release {1} Pokémon?\", @aMultiSelectedMons.length), %w[Yes No], 2) == 0
        @aMultiSelectedMons.each { |pkmn| @storage.pbDelete(pkmn[0], pkmn[1]) }
        pbHardRefresh
        pbDisplay(_INTL(\"Released {1} Pokémon.\", @aMultiSelectedMons.length))
        @aMultiSelectedMons.clear
      end
    else return [-2,-1]
    end
    return [-2,-1]")

end

#============================================================= STORAGE MODIFIER ===========================================================#

if ENABLE_STORAGE_MODIFIER

  STORAGE_MODIFIER = UniStringOption.new("Storage Mod Key", "Hold Next Page keybind to withdraw/store without having to go through a menu.", %w[Off On], nil, 1)

  UniLib.insert_in_method_before(:PokemonStorageScreen, :pbStartScreen, "if @scene.quickswap",
    "if STORAGE_MODIFIER == 1 and Input.press?(Input::PAGEDOWN)
      if selected[0]==-1
        pbStore(selected,@heldpkmn)
      else
        pbWithdraw(selected,@heldpkmn)
      end
      next
    end")

end

#============================================================ STAT BOOST DISPLAY ==========================================================#
#================================================================ REBORN PORT =============================================================#

if ENABLE_STAT_BOOST_DISPLAY

  STAT_BOOST_DISPLAY = UniStringOption.new("Stat Boost Disp.", "Stat change display while in battle.", %w[Off Reborn Compact], nil, 1)
  STAT_DISPLAY_POSITION_ARRAY = [[-24, 6], [220, 10]]
  STAT_DISPLAY_POSITION_ARRAY_DOUBLE = [[-14, 2], [224, 2]]
  STAT_DISPLAY_TYPES = [PBStats::ACCURACY, PBStats::ATTACK, PBStats::SPATK, PBStats::SPEED, PBStats::DEFENSE, PBStats::SPDEF, PBStats::EVASION]
  STAT_DISPLAY_POSITION_MAP = [[14,0], [2,10], [26,10], [14,20], [2,30], [26,30], [14,40]]

  ALT_STAT_DISPLAY_POSITION_ARRAY = [[4, 10], [218, 13]]
  ALT_STAT_DISPLAY_POSITION_ARRAY_DOUBLE = [[10, -0.5], [226, 0]]

  DISPLAY_BITMAPS.each { |b| b.dispose } if defined? DISPLAY_BITMAPS
  DISPLAY_BITMAPS = [
    AnimatedBitmap.new(UniLib.resolve_asset("StatIcons/main.png")),
    AnimatedBitmap.new(UniLib.resolve_asset("StatIcons/stages.png")),
    AnimatedBitmap.new(UniLib.resolve_asset("StatIcons/main_alt.png")),
    AnimatedBitmap.new(UniLib.resolve_asset("StatIcons/words_alt.png")),
    AnimatedBitmap.new(UniLib.resolve_asset("StatIcons/stages_alt.png"))
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
    "TRACKED_BMPS.each { |bmp| bmp.dispose }
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
        x_offset, y_offset = x_offset - 30, y_offset if @battler.issossmon
        @stat_boost_bmp.x, @stat_boost_bmp.y = self.x + x_offset, self.y + y_offset
        stats.push([0, 0, 0, 0, 0, -1, -1])
        STAT_DISPLAY_TYPES.map { |type| @battler.stages[type]}.each_with_index { |stage, i| stats.push([1, STAT_DISPLAY_POSITION_MAP[i][0], STAT_DISPLAY_POSITION_MAP[i][1], stage > 0 ? 0 : 22, (stage.abs - 1) * 22, 22, 22]) unless stage == 0 }
      else
        @double = @battler.battle.doublebattle unless defined? @double
        x_offset, y_offset = @double ? ALT_STAT_DISPLAY_POSITION_ARRAY_DOUBLE[@battler.index & 1] : ALT_STAT_DISPLAY_POSITION_ARRAY[@battler.index & 1]
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

  UniLib.insert_in_method(:PokemonDataBox, :refresh, "if @battler.hasCrest?(illusion) || (@battler.crested && !illusion)", "megaX, megaY = megaX - 1, megaY + 20 if STAT_BOOST_DISPLAY > 0")

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

#============================================================ TYPE BATTLE ICONS ===========================================================#

if ENABLE_TYPE_BATTLE_ICONS

  TYPE_ICONS = UniStringOption.new("Type Icons", "Type display in-battle.", %w[Off On], nil, 1)
  TYPE_ICON_X = UniNumberOption.new("Type Icon X", "Horizontal offset of type battle icons.", 0, 200, 1, 12)
  TYPE_ICON_Y = UniNumberOption.new("Type Icon Y", "Vertical offset of type battle icons.", 0, 80, 1, 10)

  TYPE_ICON_BITMAPS.each { |_, bmp| bmp.dispose } if defined? TYPE_ICON_BITMAPS
  TYPE_ICON_BITMAPS = [:NORMAL, :BUG, :DARK, :DRAGON, :ELECTRIC, :FAIRY, :FIGHTING, :FIRE, :FLYING, :GHOST, :GRASS, :GROUND, :ICE, :POISON, :PSYCHIC, :ROCK, :STEEL, :WATER, :SHADOW, :QMARKS].to_h { |type| [type, AnimatedBitmap.new(UniLib.resolve_asset("Types/#{type.to_s}.png"))] }

  def draw_types(bitmap, textpos)
    textpos.each { |i|
      srcbitmap = TYPE_ICON_BITMAPS[i[0]]
      width = i[5] >= 0 ? i[5] : srcbitmap.width
      height = i[6] >= 0 ? i[6] : srcbitmap.height
      srcrect = Rect.new(i[3], i[4], width, height)
      bitmap.blt(i[1], i[2], srcbitmap.bitmap, srcrect)
    }
  end

  UniLib.insert_in_method(:PokemonDataBox, :refresh, "aShowStatBoosts if $DEV",
    "@double = @battler.battle.doublebattle unless defined? @double
    offset_x, offset_y = TYPE_ICON_X - 36, TYPE_ICON_Y + (@double ? -10 : 0)
    offset_y = offset_y + 3 if @battler.index & 1 == 1
    offset_x, offset_y = offset_x - 4, offset_y + 40 if @battler.issossmon
    draw_types(self.bitmap, (@battler.effects[:Illusion].nil? ? [@battler.type1, @battler.type2] : [@battler.effects[:Illusion].type1, @battler.effects[:Illusion].type2]).reduce([]) { |types, type| type.nil? ? types : types << [type, sbX + (offset_x += 32), offset_y, 0, 0, -1, -1]}) if TYPE_ICONS == 1")

end

#============================================================== UNREAL CLOCK ==============================================================#

if ENABLE_UNREAL_CLOCK

  UniLib.include "Options"

  UNREAL_CLOCK_BG = UniNumberOption.new("Unreal Clock BG", "One of 4 different backgrounds for Unreal Clock", 1, 4)

  UNI_DOW = %w[Mon Tue Wed Thu Fri Sat Sun]

  UNREAL_CLOCK_ASSETS = [UniLib.resolve_asset("clockcontrolgui"), UniLib.resolve_asset("cherry"), UniLib.resolve_asset("antstroubled"), UniLib.resolve_asset("texencringe")]

  UniLib.insert_in_method(:Scene_Pokegear, :setup, "@buttons[@cmdScent=@buttons.length] = \"Spice Scent\"",
    "unless $Settings.unrealTimeDiverge == 0
      @cmdUnrealClock = -1
      @buttons[@cmdUnrealClock = @buttons.length] = \"Unreal Clock\"
    end")

  UniLib.insert_in_method_before(:Scene_Pokegear, :checkChoice, "if ($game_switches[:NotPlayerCharacter] == false ||  $game_switches[:InterceptorsWish] == true)",
    "if @cmdUnrealClock>=0 && @sprites[\"command_window\"].index==@cmdUnrealClock
      pbPlayDecisionSE()
      $scene = Scene_UnrealClock.new
    end")

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
      $game_screen.gameTimeCurrent = Time.unrealTime_oldTimeNew(time.year,time.month, time.day, hours, minutes, time.sec) + day_offset * 86400
      cmd.dispose
      Input.update
      $scene = Scene_Pokegear.new
      Graphics.freeze
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