class CheckNumber
  def self.is_number? str
    str.to_f.to_s == str.to_s || str.to_i.to_s == str.to_s
  end
end
