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
    @request = Rack::Request.new(env) # This is a convenient wrapper of env, by passing env to the @app below
    @session = @request.session       # we can initialize a new request object and access the same env variable
                                    # In the env variable is session data as well. This extracts the session data
                                    # from the env variable
    board = Board.new
    player = Player.new("You", :human, "X")
    computer = Player.new("Computer", :computer, "O")

    @session['board'] = board unless @session['board']
    @session['player'] = player unless @session['player']
    @session['computer'] = computer unless @session['computer']

#---------------------------------------------------------
    add_route("get", "/new_game") do
      clear_board if @session['result']
      erb "game", {board: @session['board'], player: @session['player'], computer: @session['computer']}, "layout"
    end
#---------------------------------------------------------

    route_info = get_requested_route(env)
    route(route_info, env) # This is how game-loader middleware acts as middleware; the route method
  end                         # executes @app.call(env) if env is passed into it && if
                                # the requested route is not find in the game_loader's stored @routes
                                  # Remember: Rack apps MUST call the app below them in the middleware stack
  def clear_board                   # if they are to act as middleware! Otherwise how can env be passed from one app
    @session['board'] = Board.new    # to another?
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
    @board = @session['board']
    @player = @session['player']
    @computer = @session['computer']

    game_parts = {:board => @board,
                  :player => @player,
                  :computer => @computer,
                  :result => nil
                
    }

#---------------------------------------------------------

    add_route("get", "/", location: "/new_game") do
    
    end
#---------------------------------------------------------


    add_route("get", "/play") do

      erb "game", game_parts, "layout"
    end

#---------------------------------------------------------
    add_route("post", "/play", location: "/playing") do

      square_num = @request.params.keys[0].to_i
      player_marker = @session['player'].marker
      computer_marker = @session['computer'].marker
      

      # Human move

      @board.squares[square_num].mark(player_marker)


      erb "game", game_parts, "layout"
    end

#---------------------------------------------------------
    add_route("get", "/playing", location: "/players_moved") do

      computer_move unless @board.result


      erb "game", game_parts, "layout"
    end
#---------------------------------------------------------

    add_route("get", "/players_moved") do

      if @board.result && !game_parts[:result] # Negation required, otherwise code executed even if player already won
       @session['result'] = @board.result       # Which gives the win to the computer
       game_parts[:result] = @session['result']
       erb "game", game_parts, "layout"
      end

      erb "game", game_parts, "layout"
    end
#---------------------------------------------------------

    route_info = get_requested_route(env)

    route(route_info)
  end

  def computer_move
    computer_marker = @computer.marker
    squares = @board.squares
    available_squares = @board.free_squares

    computer_choice = available_squares.keys.sample

    squares[computer_choice].mark(computer_marker)
  end

  # defensive_play. Sometimes raises an error by returning nil if used to make computer choice.
  # Requires debugging

  def defensive_play(squares)
    selection = squares.select{|num, square| square.unmarked?}

    WINNING_LINES.each do |line|
      if squares.values_at(*line).count{|square| square.human_marker?} == 2
        selection = squares.select{|num, square| line.include?(num) && square.unmarked?}.keys[0]
      end
    end

    selection
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
  WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9]] + # rows
                  [[1, 4, 7], [2, 5, 8], [3, 6, 9]] + # columns
                  [[1, 5, 9], [3, 5, 7]]
  attr_accessor :squares

  def initialize
    @squares = {}
    1.upto(9) do |num|
      @squares[num] = Square.new
    end
  end

  def free_squares
    squares.select{|number, square| square.unmarked?}
  end

  def tie?
     (free_squares.size) == 0 && (winner == nil)
  end

 def winner
    #return winner if there is a winner on the board, else nil
    winning_marker = nil
    winner = nil
    WINNING_LINES.each do |line|  
      line_squares = squares.values_at(*line)
      if same_markers(line_squares) && squares_marked?(line_squares)
        winning_marker = line_squares[0].marker
        winning_marker == "X" ? winner = "Player" : winner = "Computer"
      end
    end
    winner
  end

  def tie?
     (free_squares.size == 0) && (winner == nil)
  end

  def result
    if winner
      winner
    elsif tie?
      "Tie"
    else
      false
    end
  end

  def same_markers(squares) # Looks like variable shadowing but isn't because method doesn't use
    standard_marker = squares[0].marker  # the @squares of the board
    squares.each do |square|
      return false if square.marker != standard_marker
    end
    true
  end

  def squares_marked?(squares) # Same here... would be variable shadowing if I was trying to call board.squares
    squares.each do |square|    # while also using a local method variable 'square' but I'm not.
      return false unless square.marked?
    end
    true
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