class AppleTree < Ink::Model
  def self.fields
    {
      :color => [ "VARCHAR(255)", "NOT NULL" ],
      :id => "PRIMARY KEY",
      :note => [ "VARCHAR(255)" ],
      :height => [ "INTEGER" ],
    }
  end

  def self.foreign
    {
      "Wig" => "many_one",
      "ColorSpray" => "many_many",
    }
  end
end
