def RubyVM.icmType()
  if Module.constants.include?(:WSApplication)
    begin
      if WSApplication.current_database
        return :UI
      else
        return :Exchange
      end
    rescue Exception => e
      return :Exchange
    end
  else
    return :None
  end
end