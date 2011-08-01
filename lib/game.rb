module Dominion
  class Game

    PHASES = [:init, :setup, :action, :buy, :cleanup]

    def initialize(options = {})
      @kingdom_cards = []
      @colony_game = false
      @players = []
      @current_player = nil
      @phase = :init
      @supply = {}
      
      init(options) unless options[:no_init]
    end
    
    def init(options = {})
      # Create players, then init supply, because supply depends on number of players
      # Then init the initial decks/hands for the players, drawing from the supply
      @phase = :init
      create_players options
      init_supply options
      init_players options
      @phase = :setup
    end
    
    def all_cards
      base_cards + kingdom_cards
    end
    
    def base_cards
      base_treasure_cards + base_victory_cards + [Curse]
    end
    
    def base_treasure_cards
      cards = [Copper, Silver, Gold]
      cards.push Platinum if colony_game?
      cards.push Potion if kingdom_cards.any? {|c| c.potion }
      cards
    end
    
    def base_victory_cards
      cards = [Estate, Duchy, Province]
      cards.push Colony if colony_game?
      cards
    end
    
    def kingdom_cards
      @kingdom_cards
    end
    
    def colony_game?
      @colony_game
    end
    
    def phase
      @phase
    end
    
    def in_progress?
      @phase != :init
    end
    
    def setup_phase?
      @phase == :setup
    end
    
    def action_phase?
      @phase == :action
    end
    
    def buy_phase?
      @phase == :buy
    end
    
    def cleanup_phase?
      @phase == :cleanup
    end
    
    def players
      @players
    end
    
    def num_players
      @players.length
    end
    
    def current_player
      @current_player
    end
    
    def other_players
      @players.reject { |p| p == current_player }
    end
    
    def supply
      @supply
    end
    
    def draw_from_supply(card, player = nil)
      raise "No cards of type #{card} available in supply" unless @supply[card]
      raise "No more cards of type #{card} available in supply" if @supply[card].empty?
      raise "Player is not playing this game!" if player && player.game != self
      
      result = @supply[card].shift
      result.player = player
      result
    end
    
    private
    
    def create_players(options)
      player_identities = options[:players]
      unless player_identities
        num_players = options[:num_players] || 2
        player_identities = Array.new num_players   # no identities
      end
      
      @players = []
      player_identities.each_with_index do |player_identity, position|
        @players.push Player.new(self, position, player_identity)
      end
      
      @current_player = @players.first
    end
    
    def init_players(options)
      @players.each do |player|
        player.init options
      end
    end
    
    def init_supply(options)
      @kingdom_cards = options[:kingdom_cards] || Setup.randomly_choose_kingdom(options)
      @colony_game = options[:colony_game?] || Setup.randomly_choose_if_colony_game(@kingdom_cards)
      
      @supply = {}
      @supply.extend PileSummary  # better to_s for supply
      
      all_cards.each do |card|
        count = Setup.initial_count_in_supply card, num_players
        pile = (1..count).collect { card.new self }
        @supply[card] = pile
      end
    end

  end
  
  # Is this not sick?  It makes the supply hash to_s display a count, rather than exploding the array
  module PileSummary
    def piles
      inject({}) {|h,v| h[v[0]] = v[1].size; h }
    end
      
    def inspect
      piles
    end
  end
  
end