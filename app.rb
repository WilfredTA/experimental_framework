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

    board = Board.new
    player = Player.new("You", :human, "X")
    computer = Player.new("Computer", :computer, "O")

    add_route("get", "/new_game") do
      

      erb "game", {board: board, player: player, computer: computer}, "layout"
    end


    route_info = get_requested_route(env)
    route(route_info, env, [board, player, computer])
  end
end

class GameExecuter < Hatchet::CustomFrame
  WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9]] + # rows
                  [[1, 4, 7], [2, 5, 8], [3, 6, 9]] + # columns
                  [[1, 5, 9], [3, 5, 7]]

  def initialize()
    super()
  end
  
  def call(env, game_info)
    
    request = Rack::Request.new(env)
    

    game_parts = {board: game_info[0], 
                  player: game_info[1],
                  computer: game_info[2]}


    add_route("get", "/", location: '/new_game') do

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
     square_num = request.params.keys[0].to_i
     game_parts[:board].squares[square_num].mark(game_parts[:player].marker)

      
     erb "game", game_parts, "layout"

    end


    route_info = get_requested_route(env)

    route(route_info)
  end

  def winner(board)
    #return winner if there is a winner on the board, else nil

    WINNING_LINES.each do |line|
      squares = board.squares.values_at(*line)
      if same_markers(squares) && squares_marked?(squares)
        return squares[0].marker
      end
    end
    nil
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

  def draw
     "Drawn board"
  end
end


class Square
  attr_accessor :marker
  def initialize()
    @marker = ''
  end

  def marked?
    @marker != ''
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