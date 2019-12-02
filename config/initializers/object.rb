class Object
  TRUE_VALUES  = Set.new [:true,  true,  1, '1', 't', 'T', 'true',  'TRUE',  'on',  'ON']
  FALSE_VALUES = Set.new [:false, false, 0, '0', 'f', 'F', 'false', 'FALSE', 'off', 'OFF']

  def to_b
    if self.is_a?(String) && self.blank?
      false
    else
      TRUE_VALUES.include?(self)
    end
  end
  
end
