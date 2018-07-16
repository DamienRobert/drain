module DR
  module Bool
    extend(self)
    def to_bool(el, default=nil, allow_nil: true, string_fallback: true)
      case el
      when String
        string=el.chomp
        return true if string =~ (/(true|t|yes|y|1)$/i)
        return false if string.empty? || string =~ (/(false|f|no|n|0)$/i)
        return el if string_fallback
      when Integer
        return ! (el == 0)
      when ::Process::Status
        exitstatus=el.exitstatus
        return exitstatus == 0
      else
        return true if el == true
        return false if el == false
        #we don't return !!el because we don't want nil to be false but to
        #give an error
      end
      return el if string_fallback and el.is_a?(Symbol)
      return default unless default.nil?
      return nil if el.nil? and allow_nil
      raise ArgumentError.new("Invalid value for Boolean: \"#{el}\"")
    end
  end
end
