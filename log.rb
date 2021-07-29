# simple logger
class Log
  def self.info(msg)
    puts msg
  end

  def self.dump(*s)
    puts s.join(' ')
  end

  def self.error(msg)
    puts msg.red
  end
end
