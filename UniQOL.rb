if Reborn
  require "patch/Mods/UniLib/StandardAPI"
else
  require "Data/Mods/UniLib/StandardAPI"
end

UniLib.verify_version(0.6, __FILE__)
UniLib.include "Options"
UniLib.include "Asset"

# Debug
ENABLE_DEBUG_TOGGLE_OPTION = true

# Encounter Options
ENABLE_PRISM_CHANCE_OPTION = true
ENABLE_CONTRACT_MODE_OPTION = true
ENABLE_CONTRACT_PENALTY_OPTION = true
ENABLE_CONTRACT_INFO_OPTION = true
ENABLE_ENCOUNTER_LURE_OPTION = true
ENABLE_FULL_PARTY_ENCOUNTER_EFFECT = true
ENABLE_AUTO_HOOK_OPTION = true
ENABLE_INSTANT_HOOK_OPTION = true

# Eggs
ENABLE_EGG_COUNT_OPTION = true
ENABLE_EGG_DESTINATION_OPTION = true
ENABLE_HATCH_ANIMATION_OPTION = true
ENABLE_HATCH_NICKNAME_OPTION = true
ENABLE_ITEM_REPLENISH_OPTION = true
ENABLE_EGG_RELEARN_OPTION = true
ENABLE_PREEVO_RELEARN_OPTION = true

# Optimization and Visuals
ENABLE_SHADOW_CACHE = true
ENABLE_SNAPPY_MENUS_OPTION = true
ENABLE_TRANSPARENT_MINING_TILES = true
ENABLE_TMX_ANIMATION_OPTION = true

# Gameplay
ENABLE_MAX_BAG_ITEM_OPTION = true
ENABLE_HP_CHANGER = true
ENABLE_ITEM_RADAR = true
ENABLE_MOVE_RELEARNER = true
ENABLE_MASS_RELEASE = true
ENABLE_STORAGE_MODIFIER = true
ENABLE_STAT_BOOST_DISPLAY = true
ENABLE_TYPE_BATTLE_ICONS = true
ENABLE_UNREAL_CLOCK = true
ENABLE_QUICK_ACCESS = true

NESTED = true

def uniqol_asset(path)
  UniLib.path "#{NESTED ? "UniQOL/" : ""}UniQOLAssets/#{path}"
end

#==========================================================================================================================================#
#================================================================ OPTIONS =================================================================#
#==========================================================================================================================================#

#================================================================= DEBUG ==================================================================#

if ENABLE_DEBUG_TOGGLE_OPTION

  DEBUG_ENABLED = UniStringOption.new("Debug", "Debug mode toggle.", %w[Off On], proc { |value| $DEBUG = value == 1})

end

#=========================================================== BLACK PRISM CHANCE ===========================================================#

if ENABLE_PRISM_CHANCE_OPTION and Rejuv

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

if ENABLE_CONTRACT_MODE_OPTION and Rejuv

  CONTRACT_MODE = UniStringOption.new("Contract Mode", "Tech contract restrictions for the given move type.", %w[All TM UTM Tutor Egg])
  ALL_TM_MOVES = []

  def get_tm_moves(_)
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

if ENABLE_CONTRACT_PENALTY_OPTION and Rejuv

  CONTRACT_PENALTY = UniStringOption.new("Contract Penalty", "Tech contract 50% catchrate penalty.", %w[Off On], nil, 1)

  UniLib.replace_in_method(:PokeBattle_BattleCommon, :pbThrowPokeBall, "rareness /= 2 if $game_variables[:LuckMoves] != 0", "rareness /= 2 if $game_variables[:LuckMoves] != 0 unless CONTRACT_PENALTY == 0")

end

#============================================================= CONTRACT INFO ==============================================================#

if ENABLE_CONTRACT_INFO_OPTION and Rejuv

  CONTRACT_INFO = UniStringOption.new("Contract Info", "Tech contract-related info in battle inspector.", %w[None Count Moves])

  UniLib.insert_in_function_before(:pbShowBattleStats, "report.push(_INTL(\"Level: {1}\",pkmn.level))",
    "if $game_variables[:LuckMoves] != 0 and !$game_switches[:Raid] and !@battle.opponent and pkmn != @battle.battlers[0] and pkmn != @battle.battlers[2]
      report.push(_INTL(\"Contract Encounters: {1}\", $game_variables[:LuckMoves])) if CONTRACT_INFO >= 1
      report.push(_INTL(\"Contract Move: {1}\", pkmn.moves[pkmn.moves.length - 1].name)) if CONTRACT_INFO == 2
    end unless [95, 98, 100, 120, 128, 129].include?($game_variables[:WildMods])")

end

#====================================================== FULL PARTY ENCOUNTER EFFECT =======================================================#

if ENABLE_FULL_PARTY_ENCOUNTER_EFFECT and Rejuv

  UniLib.include "Multibility"

  FULL_PARTY_ENCOUNTER_EFFECT = UniStringOption.new("Full Party Enc.", "Abilities in the party all apply to encounters.", %w[Off On])

  class PokeBattle_Pokemon

    FULL_PARTY_ABILITY_METHOD = instance_method(:ability) unless defined? FULL_PARTY_ABILITY_METHOD
    def ability
      multi = caller[0].include?("pbGenerateEncounter") || caller[0].include?("pbGenerateWildPokemon")
      if FULL_PARTY_ENCOUNTER_EFFECT == 1 and multi
        added_abilities = []
        $Trainer.party.each_with_index { |pkmn, i| added_abilities += AbilityContainer.new(pkmn, pkmn.ability).abilities unless i == 0 }
        AbilityContainer.new(self, @ability, added_abilities)
      else
        FULL_PARTY_ABILITY_METHOD.bind(self).(multi)
      end
    end

  end

end

#=========================================================== DAYCARE EGG COUNT ============================================================#

if ENABLE_EGG_COUNT_OPTION

  DAYCARE_EGG_COUNT = UniNumberOption.new("Daycare Egg Count", "Number of eggs to generate when picking up from the daycare.", 1, 30, 1)

  target = Reborn ? "pokemon0 = $PokemonGlobal.daycare[0][0]" : "pokemon0=$PokemonGlobal.daycare[0][0]"
  UniLib.insert_in_function_before(:pbDayCareGenerateEgg, target,
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

  target = Reborn ? "time = 2 + rand(10)" : "time=2+rand(10)"
  UniLib.replace_in_function(:pbFishing, target, "time = INSTANT_HOOK == 0 ? 2 + rand(10) : 0")

  target = Reborn ? "if !pbWaitForInput(msgwindow, message + _INTL(\"\\r\\nOh!  A bite!\"), frames)" : "if !pbWaitForInput(msgwindow,message+_INTL(\"\\r\\nOh!  A bite!\"),frames)"
  UniLib.replace_in_function(:pbFishing, target,
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

  UniLib.insert_in_method(:PokeBattle_Pokemon, :setItem, :HEAD, "@itemInitial = value")

end unless UniLib.mod_included?("ItemReplaceRestore")

#============================================================ RELEARN EGG MOVES ===========================================================#
#================================================================ AMB PORT ================================================================#

if ENABLE_EGG_RELEARN_OPTION

  RELEARN_EGG_MOVES = UniStringOption.new("Egg Relearn", "Egg moves in move relearner before Fly.", %w[Off On])

  target = Reborn ? "moves = tmoves + pokemon.getEggMoveList(true) + moves if Rejuv && $PokemonBag.pbHasItem?(:HM02)" : "moves= tmoves+pokemon.getEggMoveList(true)+moves if Rejuv && $PokemonBag.pbHasItem?(:HM02)"
  UniLib.replace_in_function(:pbGetRelearnableMoves, target,
    "eggs = RELEARN_EGG_MOVES == 1 or Rejuv && $PokemonBag.pbHasItem?(:HM02)
    moves = tmoves + pokemon.getEggMoveList(true) + moves if eggs", 0)

end unless UniLib.mod_included?("Learn_Egg_moves")

#=========================================================== RELEARN_PREEVO_MOVES =========================================================#
#================================================================ AMB PORT ================================================================#

if ENABLE_PREEVO_RELEARN_OPTION

  PREVO_RELEARN_OPTION = UniStringOption.new("PreEvo Relearn", "Learn moves from pre-evolutions.", %w[Off On])

  UniLib.insert_in_function(:pbEachNaturalMove, :TAIL,
    "if PREVO_RELEARN_OPTION == 1
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
  Graphics.define_singleton_method(:transition) { |i=0| S_TRANS.(SNAPPY_MENUS == 1 ? 0 : i) }

end unless UniLib.mod_included?("SWM - SnappyMenus")

#============================================================== SHADOW CACHE ==============================================================#

if ENABLE_SHADOW_CACHE and Rejuv

  SHADOW_ICON_CACHE = {} unless defined? SHADOW_ICON_CACHE
  SHADOW_SPECIES_CACHE = {} unless defined? SHADOW_SPECIES_CACHE

  UniLib.insert_in_function(:pbPokemonIconBitmap, "species = $cache.pkmn[pokemon.species].dexnum",
    "return SHADOW_ICON_CACHE[pokemon] if (SHADOW_ICON_CACHE[pokemon] and pokemon.isShadow?)")

  UniLib.insert_in_function_before(:pbPokemonIconBitmap, "return bitmap",
    "SHADOW_ICON_CACHE[pokemon] = bitmap if pokemon.isShadow?")

  UniLib.insert_in_function(:pbLoadPokemonBitmapSpecies, :HEAD,
  "shadow_cache = pokemon.isShadow? && !back
  if shadow_cache
    key = [pokemon.species, pokemon.form, pokemon.isShiny?, pokemon.gender, pokemon.isEgg?]
    return SHADOW_SPECIES_CACHE[pokemon][1] if SHADOW_SPECIES_CACHE[pokemon] and SHADOW_SPECIES_CACHE[pokemon][0] == key
  end")

  UniLib.insert_in_function_before(:pbLoadPokemonBitmapSpecies, "return bitmap",
    "SHADOW_SPECIES_CACHE[pokemon] = [key, bitmap] if shadow_cache")

  UniLib.insert_in_function_before(:pbLoadPokemonBitmapSpecies, "return bitmap",
    "SHADOW_SPECIES_CACHE[pokemon] = [key, bitmap] if shadow_cache", 1)

end

#======================================================== TRANSPARENT MINING TILES ========================================================#

if ENABLE_TRANSPARENT_MINING_TILES

  Assets.redirect(:BMP, "Graphics/Pictures/Mining/tiles", "UniQOLAssets/mining_tiles")

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

#================================================================ ITEM RADAR ==============================================================#
#================================================================= SWM PORT ===============================================================#

if ENABLE_ITEM_RADAR



end

#============================================================== MOVE RELEARNER ============================================================#

if ENABLE_MOVE_RELEARNER

  MOVE_RELEARN_COMMAND = UniStringOption.new("Move Relearner", "Allows relearning moves in the PC or party.", %w[Off PC Party Both])

  MOVE_RELEARN_FREE = UniStringOption.new("Free Relearning", "Party/PC relearn without costing a heart scale", %w[Off On])

  MOVE_RELEARN_BEFORE_TUTOR = Reborn ? 1 : UniStringOption.new("Relearn Any Time", "Allows party relearning before unlocking the move relearner.", %w[Off On])

  def relearn_from_menu(pkmn)
    if MOVE_RELEARN_FREE == 1 or ($PokemonBag.pbHasItem?(:HEARTSCALE) and Kernel.pbConfirmMessage("This will consume a Heart Scale. Continue?"))
      pbFadeOutIn(99999) { $has_relearned = MoveRelearnerScreen.new(MoveRelearnerScene.new).pbStartScreen(pkmn); pbUpdateSceneMap }
      $updateFLHUD = true
      $PokemonBag.pbDeleteItem(:HEARTSCALE) if $has_relearned
    elsif !$PokemonBag.pbHasItem?(:HEARTSCALE)
      Kernel.pbMessage("You need a Heart Scale to relearn moves!")
    end
  end

  UniLib.add_party_command("move_relearner", "Relearn", proc { |pkmn| relearn_from_menu(pkmn) }, proc { ($game_switches[1444] || MOVE_RELEARN_BEFORE_TUTOR == 1) and MOVE_RELEARN_COMMAND >= 2 })
  UniLib.add_box_command("move_relearner", "Relearn", proc { |pkmn| relearn_from_menu(pkmn) }, proc { ($game_switches[1444] || MOVE_RELEARN_BEFORE_TUTOR == 1) and MOVE_RELEARN_COMMAND & 1 == 1 })

end

#============================================================== MASS RELEASE ==============================================================#

if ENABLE_MASS_RELEASE and Rejuv

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

#============================================================ STAT BOOST DISPLAY ==========================================================#
#================================================================= SWM PORT ===============================================================#

if ENABLE_STAT_BOOST_DISPLAY and Rejuv

  STAT_BOOST_DISPLAY = UniStringOption.new("Stat Boost Disp.", "Stat change display while in battle.", %w[Off Reborn Compact], nil, 1)
  STAT_DISPLAY_POSITION_ARRAY = [[-24, 6], [220, 10]]
  STAT_DISPLAY_POSITION_ARRAY_DOUBLE = [[-14, 2], [224, 2]]
  STAT_DISPLAY_TYPES = [PBStats::ACCURACY, PBStats::ATTACK, PBStats::SPATK, PBStats::SPEED, PBStats::DEFENSE, PBStats::SPDEF, PBStats::EVASION]
  STAT_DISPLAY_POSITION_MAP = [[14,0], [2,10], [26,10], [14,20], [2,30], [26,30], [14,40]]

  ALT_STAT_DISPLAY_POSITION_ARRAY = [[4, 10], [218, 13]]
  ALT_STAT_DISPLAY_POSITION_ARRAY_DOUBLE = [[10, -0.5], [226, 0]]

  DISPLAY_BITMAPS.each { |b| b.dispose } if defined? DISPLAY_BITMAPS
  DISPLAY_BITMAPS = [
    AnimatedBitmap.new(uniqol_asset("StatIcons/main.png")),
    AnimatedBitmap.new(uniqol_asset("StatIcons/stages.png")),
    AnimatedBitmap.new(uniqol_asset("StatIcons/main_alt.png")),
    AnimatedBitmap.new(uniqol_asset("StatIcons/words_alt.png")),
    AnimatedBitmap.new(uniqol_asset("StatIcons/stages_alt.png"))
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

  if Rejuv
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

end

#============================================================ TYPE BATTLE ICONS ===========================================================#

if ENABLE_TYPE_BATTLE_ICONS

  TYPE_ICONS = UniStringOption.new("Type Icons", "Type display in-battle.", %w[Off On], nil, 1)
  TYPE_ICON_X = UniNumberOption.new("Type Icon X", "Horizontal offset of type battle icons.", 0, 200, 1, 12)
  TYPE_ICON_Y = UniNumberOption.new("Type Icon Y", "Vertical offset of type battle icons.", 0, 80, 1, 10)

  TYPE_ICON_BITMAPS.each { |_, bmp| bmp.dispose } if defined? TYPE_ICON_BITMAPS
  TYPE_ICON_BITMAPS = [:NORMAL, :BUG, :DARK, :DRAGON, :ELECTRIC, :FAIRY, :FIGHTING, :FIRE, :FLYING, :GHOST, :GRASS, :GROUND, :ICE, :POISON, :PSYCHIC, :ROCK, :STEEL, :WATER, :SHADOW, :QMARKS].to_h { |type| [type, AnimatedBitmap.new(uniqol_asset("Types/#{type.to_s}.png"))] }

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

#============================================================== UNREAL CLOCK ==============================================================#

if ENABLE_UNREAL_CLOCK

  UniLib.include "Options"

  UNREAL_CLOCK_BG = UniNumberOption.new("Unreal Clock BG", "One of 4 different backgrounds for Unreal Clock", 1, 4)

  UNI_DOW = %w[Mon Tue Wed Thu Fri Sat Sun]

  UNREAL_CLOCK_ASSETS = [uniqol_asset("clockcontrolgui"), uniqol_asset("cherry"), uniqol_asset("antstroubled"), uniqol_asset("texencringe")]

  UniLib.insert_in_method(:Scene_Pokegear, :setup, "@buttons[@cmdScent=@buttons.length] = \"Spice Scent\"",
    "unless $Settings.unrealTimeDiverge == 0
      @cmdUnrealClock = -1
      @buttons[@cmdUnrealClock = @buttons.length] = \"Unreal Clock\"
    end")

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

#============================================================== QUICK ACCESS ==============================================================#

if ENABLE_QUICK_ACCESS

  QUICK_ACCESS_ENABLED = UniStringOption.new("Quick Access Menu", "Adds a convenience menu bound to the A key.", %w[Off On])
  QUICK_ACCESS_OPTIONS = ["Heal Party", "Add Item", "Add Pokémon", "Use PC", "Set Money", "Jukebox", "Spice Scent", "Move Tutor"]
  QUICK_ACCESS_OPTIONS.insert(QUICK_ACCESS_OPTIONS.index("Move Tutor"), "Unreal Clock") if ENABLE_UNREAL_CLOCK

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

    def menu
      pbSEPlay("menu")
      $qol_quick_access = UniLib.restore_data("quick_access_settings", [])
      @scene.start(($qol_quick_access.clone.select { |e| QUICK_ACCESS_OPTIONS.include? e }) + ["Add/Remove"])
      loop do
        if (command = @scene.show_commands) == -1
          pbSEPlay("menuclose")
          break
        end
        case command[1]
        when "Heal Party"
          $Trainer.party.each { |pkmn| pkmn.heal }
          Kernel.pbMessage("Your Pokémon were healed.")
        when "Add Item" then
          @scene.hide_and_execute do
            if (item = pbListScreen(_INTL("ADD ITEM"),ItemLister.new(0)))
              if (qty = Kernel.pbMessageChooseNumber("Choose the number of items.", create_number_param(range: [1, BAGMAXPERSLOT], initial: 1, cancel: 0))) == 1
                Kernel.pbReceiveItem(item)
              elsif qty > 1
                Kernel.pbMessage(_INTL("The item was added."))
                $PokemonBag.pbStoreItem(item, qty)
              end
            end
          end
        when "Add Pokémon" then
          @scene.hide_and_execute do
            if (species = pbChooseSpeciesOrdered(1))
              level = Kernel.pbMessageChooseNumber("Set the Pokémon's level.", create_number_param(range: [0, MAXIMUMLEVEL], initial: 5, cancel: 0))
              form = Kernel.pbMessageChooseNumber("Set the Pokémon's form.", create_number_param(range: [0, $cache.pkmn[species].forms.length], initial: 0))
              pbAddPokemon(species, level, true, form) if level > 0
            end
          end
        when "Use PC" then @scene.hide_and_execute { pbPokeCenterPC }
        when "Set Money" then
          @scene.hide_and_execute do
            $Trainer.money=Kernel.pbMessageChooseNumber("Set the player's money.", create_number_param(initial: $Trainer.money, max_digits: 6))
            Kernel.pbMessage(_INTL("You now have ${1}.",$Trainer.money))
          end
        when "Jukebox" then @scene.hide_and_execute { QuickAccessJukeboxScene.new.main }
        when "Spice Scent" then @scene.hide_and_execute { QuickAccessEncounterRateScene.new.main }
        when "Unreal Clock" then @scene.hide_and_execute {
          if $Settings.unrealTimeDiverge == 1
            Scene_UnrealClock.new.main(false)
          else
            Kernel.pbMessage("This requires Unreal Time to be active!")
          end
        }
        when "Move Tutor" then @scene.hide_and_execute { pbRelearnMoveTutorScreen }
        when "Add/Remove"
          @scene.hide_and_execute { QuickAccessSelectorMenu.new(QuickAccessMenuScene.new).menu }
          @scene.commands = $qol_quick_access.clone + ["Add/Remove"]
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
      @sprites["background"].setBitmap(uniqol_asset("spicescentbg.png"))
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
    "if Input.trigger?(14) and ENABLE_QUICK_ACCESS and QUICK_ACCESS_ENABLED == 1
      $PokemonTemp.quick_access = true
    end unless pbMapInterpreterRunning?")

  UniLib.replace_in_method(:Scene_Map, :update, "if $game_temp.battle_calling",
    "if $PokemonTemp.quick_access
      $PokemonTemp.quick_access = false
      quick_access_menu
    elsif $game_temp.battle_calling")

end