
class Role < Ink::Model
  
  def self.fields
    fields = {
      :ref => "PRIMARY KEY",
      :role => [ "VARCHAR(200)", "NOT NULL", "UNIQUE" ],
    }
    fields
  end
  
  def self.foreign
    foreign = {
      "User" => "many_many",
    }
    foreign
  end
  
end
