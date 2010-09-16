module Ink

  # = Model class
  # 
  # == Usage
  # 
  # Models are usually derived from. So let's assume there is a
  # class called Apple < Ink::Model
  #
  #   apple = Apple.new {:color => "red", :diameter => 4}
  # 
  # The constructor checks, if there are class methods 'fields'
  # and 'foreign' defined. If that check is positive, it will
  # match the parameter Hash to the fields, that are set for
  # the database, and thow an exception if fields is lacking
  # an entry (excluded the primary key). The other case just
  # creates an Apple with the Hash as instance variables.
  #
  #   puts apple.color
  #
  # This prints "red" to the stdout, since getter and setter
  # methods are automatically added for either the Hash, or
  # the fields and foreign keys.
  #
  #   apple.tree = nil
  #   apple.save
  #
  # You can save your apple by using the save method. New instances
  # will create a new row in the database, and update its primary
  # key. Old instances just update the fields. Relationships, like
  # in the sample below a tree, is set to nil by default, and therefore
  # the save method will not touch relationships.
  #
  #   treeinstance.apple = [1,2,myapple]
  #   treeinstance.save
  #
  # To insert relationship data, you can provide them by array, value
  # or reference, so setting treeinstance.apple to 1 is allowed, also
  # to myapple, or an array or a combination. An empty array [] will
  # remove all references. This works both ways, just consider the
  # relationship type, as an apple cannot have more than one tree.
  #
  #   treeinstance.delete
  #
  # The model provides a convenience method for deletion. It removes all
  # references from relationships, but does not remove the relationships
  # themselves, so you must fetch all related data, and delete them by
  # 'hand' if you will.
  #
  #
  # = Fields and foreign sample config
  # 
  #   class Apple < Ink::Model
  #     def self.fields
  #       fields = {
  #         :id => "PRIMARY KEY"
  #         :color => [ "VARCHAR", "NOT NULL" ],
  #         :diameter => [ "NUMERIC", "NOT NULL" ]
  #       }
  #       fields
  #     end
  #     def self.foreign
  #       foreign = {
  #         "Tree" => "one_many"
  #       }
  #       foreign
  #     end
  #   end
  #
  # Let's look at this construct.
  # The constructor is inherited from Ink::Model, so are its
  # methods. 'fields' defines a Hash of Arrays, that will
  # create the Database table for us. Be careful with the
  # primary key, since SQLite autoincrement is not identical
  # with MySQL autoincrement. Also the primary key has to be
  # autoincrementing.
  # 'foreign' handles the contraints to other classes, here
  # it reads: one "Tree" has many Apples, other constructs
  # could be: [one "Tree" has one Apple, many "Tree"s have
  # many Apples, many "Tree"s have one Apple] => [one_one,
  # many_many, many_one]
  # Obviously the Tree class requires a foreign with "Apple"
  # mapped to "many_one" to match this schema.
  #
  # 
  #
  class Model
    
    # Constructor
    # 
    # Keys from the data parameter will be converted into
    # instance variables with getters and setters in place.
    # The primary key has no setter, but adds a getter called
    # pk for convenience.
    # [param data:] Hash of String => Objects
    def initialize(data)
      if self.class.respond_to? :fields
        self.class.fields.each do |k,v|
          raise NameError.new("Model cannot use #{k} as field, it already exists") if self.class.respond_to? k or k.to_s.downcase == "pk"
          raise LoadError.new("Model cannot be loaded, argument missing") if not data[k.to_s] and self.class.primary_key[0] != k
          begin
            eval "@#{k} = #{(data[k.to_s].is_a?(Numeric)) ? data[k.to_s] : "\'#{data[k.to_s]}\'"}"
          rescue Exception => bang
            eval "@#{k} = #{(data[k.to_s].is_a?(Numeric)) ? data[k.to_s] : "\'#{data[k.to_s].gsub(/'/, '&#39;')}\'"}"
          end
          self.class.send(:define_method, k) do
            instance_variable_get "@#{k}"
          end
          if self.class.primary_key[0] != k
            self.class.send(:define_method, "#{k}=") do |val|
              instance_variable_set "@#{k}", val
            end
          else
            self.class.send(:define_method, "pk") do
              instance_variable_get "@#{k.to_s.downcase}"
            end
          end
        end
        if self.class.respond_to? :foreign
          self.class.foreign.each do |k,v|
            raise NameError.new("Model cannot use #{k} as foreign, it already exists") if self.class.respond_to? k.to_sym  or k.downcase == "pk"
            eval "@#{self.class.str_to_tablename(k)} = nil"
            self.class.send(:define_method, k.downcase) do
              instance_variable_get "@#{k.downcase}"
            end
            self.class.send(:define_method, "#{k.downcase}=") do |val|
              instance_variable_set "@#{k.downcase}", val
            end
          end
        end
      else
        data.each do |k,v|
          eval "@#{k} = #{(v.is_a?(Numeric)) ? v : "\'#{v}\'"}"
        end
      end
    end
    
    # Instance method
    # 
    # Save the instance to the database. Set all foreign sets to
    # nil if you do not want to change them. Old references are
    # automatically removed.
    def save
      raise NotImplementedError.new("Cannot save to Database without field definitions") if not self.class.respond_to? :fields
      string = Array.new
      keystring = Array.new
      valuestring = Array.new
      fields = self.class.fields
      pkvalue = nil
      for i in 0...fields.keys.length
        k = fields.keys[i]
        value = eval "@#{k}"
        value = "NULL" if not value
        if k != self.class.primary_key[0]
          string.push "`#{k}`=#{(value.is_a?(Numeric)) ? value : "\'#{value}\'"}"
          keystring.push "`#{k}`"
          valuestring.push "#{(value.is_a?(Numeric)) ? value : "\'#{value}\'"}"
        else
          pkvalue = "WHERE `#{self.class.primary_key[0]}`=#{(value.is_a?(Numeric)) ? value : "\'#{value}\'"}"
        end
      end
      if pkvalue
        response = Ink::Database.database.find self.class.name, pkvalue
        if response.length == 1
          Ink::Database.database.query "UPDATE #{Ink::Model.str_to_tablename(self.class.name)} SET #{string * ","} #{pkvalue}"
        elsif response.length == 0
          Ink::Database.database.query "INSERT INTO #{Ink::Model.str_to_tablename(self.class.name)} (#{keystring * ","}) VALUES (#{valuestring * ","});"
          pk = Ink::Database.database.last_inserted_pk
          eval "@#{self.class.primary_key[0]}=#{pk.is_a?(Numeric) ? pk : "\'#{pk}\'"}" if pk
        end
      end
      
      if self.class.respond_to? :foreign
        self.class.foreign.each do |k,v|
          value = eval "@#{self.class.str_to_tablename(k)}"
          if value
            Ink::Database.database.delete_all_links self, Ink::Model.classname(k), v
            Ink::Database.database.create_all_links self, Ink::Model.classname(k), v, value
          end
        end
      end
    end
    
    # Instance method
    # 
    # Deletes the data from the database, essentially making the instance
    # obsolete. Disregard from using the instance anymore.
    # All links between models will be removed also.
    def delete
      raise NotImplementedError.new("Cannot delete from Database without field definitions") if not self.class.respond_to? :fields
      if self.class.respond_to? :foreign
        self.class.foreign.each do |k,v|
          Ink::Database.database.delete_all_links self, Ink::Model.classname(k), v
        end
      end
      
      pkvalue = eval "@#{self.class.primary_key[0]}"
      Ink::Database.database.remove self.class.name, "WHERE `#{self.class.primary_key[0]}`=#{(pkvalue.is_a?(Numeric)) ? pkvalue : "\'#{pkvalue}\'"};"
    end
    
    # Class method
    # 
    # This will create SQL statements for creating the
    # database tables. 'fields' method is mandatory for
    # this, and 'foreign' is optional.
    # [returns:] Array of SQL statements
    def self.create
      result = Array.new
      raise NotImplementedError.new("Cannot create a Database without field definitions") if not self.respond_to? :fields
      
      string = "CREATE TABLE #{Model::str_to_tablename(self.name)} ("
      mfk = self.foreign_key
      fields = self.fields
      for i in 0...fields.keys.length
        k = fields.keys[i]
        string += "`#{k}` #{fields[k]*" "}" if k != self.primary_key[0]
        string += "#{Ink::Database.database.primary_key_autoincrement(k)*" "}" if k == self.primary_key[0]
        string += "," if i < fields.keys.length - 1
      end
      
      if self.respond_to? :foreign
        foreign = self.foreign
        for i in 0...foreign.keys.length
          k = foreign.keys[i]
          v = foreign[k]
          fk = eval "#{k}.foreign_key"
          string += ",`#{fk[0]}` #{fk[1]}" if fk.length > 0 and (v == "one_many" or (v == "one_one" and (self.name <=> k) < 0))
          
          if mfk.length > 0 and fk.length > 1 and v == "many_many" and (self.name <=> k) < 0
            result.push "CREATE TABLE #{Model::str_to_tablename(self.name)}_#{Model::str_to_tablename(k)} (#{Ink::Database.database.primary_key_autoincrement*" "}, `#{mfk[0]}` #{mfk[1]}, `#{fk[0]}` #{fk[1]});"
          end
        end
      end
      string += ");"
      result.push string
      result
    end
    
    # Class method
    # 
    # This will check the parent module for existing classnames
    # that match the input of the str parameter.
    # [param str:] some string
    # [returns:] valid classname or nil
    def self.str_to_classname(str)
      ((Module.const_get str.capitalize).is_a? Class) ? str.capitalize : nil
    end
    
    # Class method
    # 
    # This will check the parent module for existing classnames
    # that match the input of the str parameter. Once found, it
    # converts the string into the matching tablename.
    # [param str:] some string
    # [returns:] valid tablename or nil
    def self.str_to_tablename(str)
      ((Module.const_get str.capitalize).is_a? Class) ? str.downcase : nil
    end
    
    # Class method
    # 
    # This will check the parent module for existing classnames
    # that match the input of the str parameter. Once found, it
    # returns the class, not the string of the class.
    # [param str:] some string
    # [returns:] valid class or nil
    def self.classname(str)
      ((Module.const_get str.capitalize).is_a? Class) ? (eval "#{str.capitalize}") : nil
    end
    
    # Class method
    #
    # This will find the primary key, as defined in the fields class
    # method.
    # [returns:] Array of the form: key name, key type or empty
    def self.primary_key
      if self.respond_to? :fields
        pk = nil
        pktype = nil
        self.fields.each do |k,v|
          if v.is_a?(String) and v == "PRIMARY KEY"
            pk = k
            pktype = Ink::Database.database.primary_key_autoincrement(k)[1]
          end
        end
        return [pk, pktype]
      end
      return []
    end
    
    # Class method
    #
    # This will create the foreign key from the defined primary key
    # [returns:] Array of the form: key name, key type or empty
    def self.foreign_key
      pk = self.primary_key
      return (pk) ? ["#{self.str_to_tablename(self.name)}_#{pk[0]}", pk[1]] : []
    end
    
  end
  
end
