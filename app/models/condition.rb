require 'digest/md5'

class Condition < ApplicationRecord
    has_many :symptoms

    def symptoms_hash
        return Digest::MD5.hexdigest(symptoms.map{|x| [x.name, x.float_value, x.bool_value, x.int_value]}.to_s.chars.sort.join)
    end
end
