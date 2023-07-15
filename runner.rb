module Runner
  def self.included(base)
    base.extend ExtendHook
  end

  def initialize(*params); end

  def call
    process
  end

  def run(runner)
    self.class.run(runner, :append)
    runner.process
  end

  module ExtendHook
    def process
      new.process
      @@runners.each(&:process)
    end

    def run(runner, method = :prepend)
      @@runners ||= []
      @@runners.send(method, runner.new)
    end
  end
end
