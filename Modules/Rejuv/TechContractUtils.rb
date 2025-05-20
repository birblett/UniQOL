#============================================================= CONTRACT UTILS =============================================================#

if UniLib.current_config("tech_contract_utils")

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

  CONTRACT_PENALTY = UniStringOption.new("Contract Penalty", "Tech contract 50% catchrate penalty.", %w[Off On], nil, 1)

  UniLib.replace_in_method(:PokeBattle_BattleCommon, :pbThrowPokeBall, "rareness /= 2 if $game_variables[:LuckMoves] != 0",
    "rareness /= 2 if $game_variables[:LuckMoves] != 0 unless CONTRACT_PENALTY == 0")

  CONTRACT_INFO = UniStringOption.new("Contract Info", "Tech contract-related info in battle inspector.", %w[None Count Moves])

  UniLib.insert_in_function_before(:pbShowBattleStats, "report.push(_INTL(\"Level: {1}\",pkmn.level))",
    "if $game_variables[:LuckMoves] != 0 and !$game_switches[:Raid] and !@battle.opponent and pkmn != @battle.battlers[0] and pkmn != @battle.battlers[2]
      report.push(_INTL(\"Contract Encounters: {1}\", $game_variables[:LuckMoves])) if CONTRACT_INFO >= 1
      report.push(_INTL(\"Contract Move: {1}\", pkmn.moves[pkmn.moves.length - 1].name)) if CONTRACT_INFO == 2
    end unless [95, 98, 100, 120, 128, 129].include?($game_variables[:WildMods])")

end