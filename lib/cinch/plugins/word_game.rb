require 'cinch'

module Cinch::Plugins
  class WordGame
    include Cinch::Plugin

    def initialize(*)
      super
      if config[:words]
        @dict = Dictionary.new config[:words]
      else
        dictionary_file = config[:dictionary_file] || "/etc/dictionaries-common/words"
        @dict = Dictionary.from_file dictionary_file
      end
    end

    match(/word help/, method: :help)
    def help(m)
      m.reply <<-HELP
Play a simple but addictive game, using words in the dictionary.
 
The bot will pick a random word, and you have to work out which word by making guesses. For every guess you make, the bot will tell you whether the word comes before or after (by alphabetic sorting).
 
Commands:
!word start   - Start a new game, with the bot picking a word
!guess <word> - Guess a word
!word cheat   - If you simply can't carry on, use this to find out the word (and end the game)
 
Have fun!
      HELP
    end

    match(/word start/, method: :start)
    def start(m)
      m.reply "Starting a new word game"
      @word = Word.new @dict.random_word
    end

    match(/word cheat/, method: :cheat)
    def cheat(m)
      m.reply "#{m.user}: really? You're giving up? Fine, the word is #{@word.word}"
      @word = nil
    end

    match(/guess (\S+)/, method: :guess)
    def guess(m, guessed_word)
      if @word
        if @dict.word_valid? guessed_word
          if @word == guessed_word
            m.reply "#{m.user}: congratulations, that's the word! You win!"
            @word = nil
          else
            m.reply "My word comes #{@word.before_or_after?(guessed_word)} #{guessed_word}."
          end
        else
          m.reply "#{m.user}: sorry, #{guessed_word} isn't a word. At least, as far as I know"
        end
      else
        m.reply "You haven't started a game yet. Use `!word start` to do that."
      end
    end

    class Dictionary
      def initialize(words)
        @words = words
      end

      def self.from_file(filename)
        words = []
        File.foreach(filename) do |word|
          if word[0] == word[0].downcase && !word.include?("'")
            words << word.strip
          end
        end
        self.new(words)
      end

      def initialize(words)
        @words = words
      end

      def random_word
        @words.sample
      end

      def word_valid?(word)
        @words.include? word
      end
    end

    class Word < Struct.new(:word)
      def before_or_after?(other_word)
        word < other_word ? "before" : "after"
      end

      def ==(other_word)
        word == other_word
      end
    end
  end
end
