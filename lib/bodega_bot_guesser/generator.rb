require 'bodega_bot_guesser'
require 'yaml'

module BodegaBotGuesser
  class Generator
    attr_reader :source_tweet_text, :config

    def initialize(source_tweet_text, config = Config.default)
      @source_tweet_text = source_tweet_text
      @config = config
    end

    # Generates tweet text, or nil if there's not enough data
    # @return [String, nil]
    def generate_tweet_text
      parsed = parse_tweet
      return nil if parsed.nil?
      return nil if parsed.company != 'Square'

      employees = config.lookup(parsed.job_title)
      return nil if employees.count < 2

      guesses = employees.sample(2).map { |username| "@#{username}" }
      'Hey %s and %s, was this you?' % guesses
    end

    # Parses a tweet via regex
    # @return [ParsedTweet, nil] struct containing matched parts, or nil if it does not match
    def parse_tweet
      match = source_tweet_text.match(/ex-(?<company>[^ ]+) (?<job_title>.+) want/)
      if match
        ParsedTweet.new.tap do |parsed|
          parsed.company = match[:company]
          parsed.job_title = match[:job_title]
        end
      end
    end

    ParsedTweet = Struct.new(:company, :job_title)

    class Config
      DEFAULT_PATH = File.join(BodegaBotGuesser.root, 'config', 'employees.yml')

      def self.default
        new(YAML.safe_load(File.read(DEFAULT_PATH), [], [], true))
      end

      attr_reader :yaml

      def initialize(yaml)
        @yaml = yaml
      end

      # @return [Array<String>] list of employees (could be empty)
      def lookup(employee_type)
        yaml[employee_type] || []
      end
    end
  end
end
