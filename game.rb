require 'json'

module Json
  def save
    counter = 0
    hash = self.instance_variable_get(:@gamestate)

    while File.exist?("save_#{counter}")
      counter += 1
    end

    File.open("save_#{counter}", "w") { |file| JSON.dump(hash, file) }
  end

  def load(save_number)
    begin
      save = File.open("save_#{save_number}", "r")

      save.each do |line|
        hash = JSON.parse(line).transform_keys {|key| key.to_sym}
        self.gamestate.merge!(hash)
      end

      save.close
    rescue => error
      puts "ERROR: #{error}"
    end
  end
end

class Game
  include Json

  attr_reader :filtered_dictionary, :dictionary, :secret_word, :incorrect_guess, :correct_guess, :word_display, :guesses_left
  attr_accessor :gamestate

  def initialize (filtered_dictionary = [], secret_word = "", already_guessed = [], guesses_left = 8, word_array = [], gamestate = {})
    @filtered_dictionary = filtered_dictionary
    @secret_word = secret_word
    @already_guessed = already_guessed
    @guesses_left = guesses_left
    @word_array = word_array
    @gamestate = gamestate

    if @filtered_dictionary.empty?
      @dictionary = File.open("dictionary.txt", "r")
      filter_dictionary
      @dictionary.close
    end
    
    choose_word
    @word_array = Array.new(@secret_word.length, "_" )
    update_gamestate

    unless Dir.glob('save_*').empty?
      @save_list = []

      Dir.glob('save_*').each do |file|
        @save_list << file
      end

      puts "Input number after save to load."
      puts "Saves: #{@save_list.join(', ')}"
      puts ""
      load_answer = gets.chomp.downcase

      if load_answer.to_i >= 0
        load(load_answer)
        set_gamestate
        play_game
      end
    end

    play_game
  end

  def filter_dictionary
    @dictionary.each do |line|
      @filtered_dictionary << line.chomp if line.chomp.length.between?(5, 12)
    end
  end

  def choose_word
    random_index = rand(@filtered_dictionary.length + 1)
    @secret_word = @filtered_dictionary[random_index]
  end

  def guess_letter
    print "'exit' ", "'save' ", "'letter'"
    print "\nInput Guess: "
    answer = gets.chomp.downcase

    until answer.length == 1 && answer.between?("a", "z")
      puts "Invalid Input, Input Guess: " if answer != "save" && answer != "exit"
      print "Input Guess: " if answer == "save"
      save if answer == "save"
      exit if answer == "exit"
      answer = gets.chomp.downcase
    end

    if @already_guessed.include?(answer)
      puts "You already guessed that! Try again."
      return
    else
      if @secret_word.include?(answer)
        @word_array.each_index do |index|
          if @secret_word[index] == answer
            @word_array[index] = answer
          end
        end
      end
    end

    unless @secret_word.include?(answer)
      @guesses_left -= 1
      puts ""
      3.times {puts "###"}
      puts "Wrong Guess!"
      3.times {puts "###"}
    end

    @already_guessed << answer unless answer == 'exit' || answer == 'save'
  end

  def word_display
    puts "\nSecret Word: #{@secret_word}"
    puts @word_array.join(" ")
    puts "\nGuesses Left: #{@guesses_left}"
  end

  def update_gamestate
    self.instance_variables.each do |instance|
      @gamestate[instance] = self.instance_variable_get(instance) unless instance == :@gamestate || instance == :@save_list
    end
  end

  def set_gamestate
    self.instance_variables.each do |instance|
      self.instance_variable_set(instance, @gamestate[instance]) unless @gamestate[instance].nil?
    end
  end

  def restart
    choose_word
    @word_array = Array.new(secret_word.length, "_" )
    @already_guessed.clear
    @gamestate.clear
    play_game
  end

  def play_game
    while @word_array.include?("_")
      word_display
      guess_letter
      update_gamestate

      unless @word_array.include?("_")
        word_display
        puts "You win!"
        puts "Do you want to play again? Y or N"
        restart_answer = gets.chomp.downcase
        restart if restart_answer == "y" || restart_answer == "yes"
        break
      end

      if @guesses_left == 0
        puts "You Lose."
        break
      end

      # word_display
      # 3.times {puts "###"}
      # puts "Would you like to save?"
      # 3.times {puts "###"}
      # answer = gets.chomp.downcase
      # save if answer == "yes" || answer == "y"
    end
  end

end

game = Game.new