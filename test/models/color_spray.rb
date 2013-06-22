class ColorSpray < Ink::Model
  def self.fields
    {
      :color => [ "VARCHAR(255)", "NOT NULL" ],
      :ref => "PRIMARY KEY",
    }
  end
  def self.foreign
    {
      "AppleTree" => "many_many",
    }
  end
end
