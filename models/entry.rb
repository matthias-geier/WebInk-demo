
class Entry < Ink::Model
  
  def self.fields
    fields = {
      :ref => "PRIMARY KEY",
      :title => [ "VARCHAR(200)", "NOT NULL" ],
      :text => [ "TEXT", "NOT NULL" ],
      :tags => [ "TEXT", "NOT NULL" ],
      :created_at => [ "DATETIME", "NOT NULL" ],
    }
    fields
  end
  
  def self.foreign
    foreign = {
      "User" => "one_many",
      "Comment" => "many_one",
    }
    foreign
  end
end
