require "rack"
require "erb"
require "./framework"


# This simple app shows examples of how to use the 
# following features of the framework:
# 1. Setting routes
# 2. Rendering templates
# 3. Setting redirects
# 4. Rendering a template within a layout
# 5. Grabbing the route being requested
# 6. Comparing the requested route against the set routes
#   and executing the matching route

# Any app built with this framework should have a call method, 
# within which the following is done in the order listed below:
# First, routes are added
# Second, logic is added to routes, as are view templates
# Third, grab the requested route with 'get_requested_route(env)'
# Fourth, pass the requested route into the 'route' method

# The framework makes the following assumptions:
# That you are using ERB as your templating engine
# That your templates are stored in a directory called 'views'
# That you are using routes to generate responses


# The following UserRouter is added to test functions as I integrate user capability into the
# application
class GameLoader < Hatchet::CustomFrame

  def initialize(app)
    super()
    @app = app
  end

  def call(env)
    @request = Rack::Request.new(env)
    @session = @request.session

    board = Board.new
    player = Player.new("You", :human, "X")
    computer = Player.new("Computer", :computer, "O")

    @session['board'] = board unless @session['board']
    @session['player'] = player unless @session['player']
    @session['computer'] = computer unless @session['computer']

    add_route("get", "/new_game") do
      clear_board if @session['result']
      erb "game", {board: @session['board'], player: @session['player'], computer: @session['computer']}, "layout"
    end


    route_info = get_requested_route(env)
    route(route_info, env)
  end

  def clear_board
    @session['board'] = Board.new
  end
end

class GameExecuter < Hatchet::CustomFrame
  WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9]] + # rows
                  [[1, 4, 7], [2, 5, 8], [3, 6, 9]] + # columns
                  [[1, 5, 9], [3, 5, 7]]

  def initialize()
    super()
  end
  
  def call(env)
    @request = Rack::Request.new(env)
    @session = @request.session

    game_parts = {:board => @session['board'],
                  :player => @session['player'],
                  :computer => @session['computer'],
                  :result => nil
                
    }



    add_route("get", "/", location: "/new_game") do
    
    end



    add_route("get", "/play") do

      erb "game", game_parts, "layout"
    end

    # need to implement:
    # checks if spot already taken in board
    # if yes, redirect with error
    # else get the square number
    # mark square number with marker
    # re-display board

    add_route("post", "/play") do

      square_num = @request.params.keys[0].to_i
      player_marker = @session['player'].marker
      computer_marker = @session['computer'].marker
      

      # Human move

      @session['board'].squares[square_num].mark(player_marker)

      # If human won:

      if result(@session['board'])
       @session['result'] = result(@session['board'])
       game_parts[:result] = @session['result']
       erb "game", game_parts, "layout"
      end

      game_parts[:computer_move] = true
      erb "game", game_parts, "layout"

    end

    add_route("get", "/playing") do

      # Computer move

      computer_marker = @session['computer'].marker
      squares = @session['board'].squares
      available_squares = free_squares(squares)
      computer_choice = available_squares.keys.sample

      squares[computer_choice].mark(computer_marker)


      # If Computer won or a tie

      if result(@session['board']) && !game_parts[:result] # Negation required, otherwise code executed even if player already won
       @session['result'] = result(@session['board'])       # Which gives the win to the computer
       game_parts[:result] = @session['result']
       erb "game", game_parts, "layout"
      end

      erb "game", game_parts, "layout"


    end

    route_info = get_requested_route(env)

    route(route_info)
  end

  def tie?(board)
     free_squares(board.squares).size == 0 && winner(board) == nil
  end

  def result(board)
    if winner(board)
      winner(board)
    elsif tie?(board)
      "Tie"
    else
      false
    end
  end

  def winner(board)
    #return winner if there is a winner on the board, else nil
    winning_marker = nil
    winner = nil
    WINNING_LINES.each do |line|
      squares = board.squares.values_at(*line)
      if same_markers(squares) && squares_marked?(squares)
        winning_marker = squares[0].marker
        winning_marker == "X" ? winner = "Player" : winner = "Computer"
      end
    end
    winner
  end

  # defensive_play Sometimes raises an error by returning nil if used to make computer choice.
  # Requires debugging
  def defensive_play(squares)
    counter = 0
    selection = squares.select{|num, square| square.unmarked?}

    WINNING_LINES.each do |line|
      if squares.values_at(*line).count{|square| square.human_marker?} == 2
        selection = squares.select{|num, square| line.include?(num) && square.unmarked?}
      end
    end
    selection.keys
  end

  def same_markers(squares)
    standard_marker = squares[0].marker
    squares.each do |square|
      return false if square.marker != standard_marker
    end
    true
  end

  def squares_marked?(squares)
    squares.each do |square|
      return false unless square.marked?
    end
    true
  end

  def free_squares(squares)
    squares.select{|number, square| square.unmarked?}
  end

  def choose(board)
    if two_human_squares_in_a_row(board)
     two_human_squares_in_a_row(board)
    else
      board.squares.select{|number, square| square.unmarked?}.keys.sample
    end
  end
end


class Player
  attr_accessor :name, :marker

  def initialize(name, type, marker)
    @name = name
    @type = type
    @marker = marker
  end

  def make_move(square)
    square.mark(@marker)
  end
end

class Board
  attr_accessor :squares

  def initialize
    @squares = {}
    1.upto(9) do |num|
      @squares[num] = Square.new
    end
  end
end


class Square
  attr_reader :marker
  def initialize()
    @marker = ''
  end

  def unmarked?
    @marker == ''
  end

  def human_marker?
    @marker == "X"
  end

  def marked?
    unmarked? == false
  end

  def mark(mark)
    @marker = mark
  end

  def to_s
    @marker
  end
end



# explicit returns only work within the context of methods
# If you write  amodule in a class you still have to include it in the subclass