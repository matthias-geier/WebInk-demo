require "cgi/session"

class User < Ink::Model
  
  # Instance method
  # Determines user roles by looking them up in the database
  # A possible optimization could be to store the user-roles
  # in this instance from the start
  def can?(str)
    result = Ink::Database.database.find_union "user", self.pk, "role", "AND role.role=\"#{str}\""
    result[0]
  end
  
  # Class method
  # Return a random string of length: len
  def self.random_string(len)
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    newpass = ""
    1.upto(len) { |i| newpass << chars[rand chars.size-1] }
    return newpass
  end
  
  # Instance method
  # Encrypt the password and store it. This is a convenience method
  # to prevent code relocation
  def password=(pass)
    @salt = User.random_string(12) if not @salt or @salt.length == 0
    @pass = User.encrypt(pass, @salt)
  end
  
  # Class method
  # Encrypt the pass with a salt by utilizing Digest::SHA1
  def self.encrypt(pass, salt)
    Digest::SHA1.hexdigest pass+salt
  end
  
  # Class method
  # Determine if a user is logged in with this hash. Hash
  # is the cookie session_id. If more users are returned,
  # unset the hashes with those users.
  def self.auth_cookie(hash)
    user = Ink::Database.database.find "user", "WHERE cookie_hash=\"#{hash}\""
    if user.length > 1
      user.each do |u| u.cookie_hash = nil; u.save end
      return nil
    end
    return nil if not hash or hash.length == 0
    user[0]
  end
  
  # Class method
  # Return a new session instance with a given cgi object.
  # If a cookie exists, or the cgi.params include a _session_id
  # key, then the existing session is retrieved instead.
  def self.session_instance(cgi)
    CGI::Session.new(cgi, 'database_manager' => CGI::Session::MemoryStore, 'session_expires' => Time.now + 60*60, 'session_path' => "/rblog/")
  end
  
  # Class method
  # Return a session id and close the session
  def self.cookie_session_id(session)
    cookie_hash = session.session_id
    session.close
    cookie_hash
  end
  
  # Class method
  # Determine if a user is logged in with a session and
  # return the user instance.
  def self.logged_in_user(session)
    cookie_hash = self.cookie_session_id session
    self.auth_cookie cookie_hash
  end
  
  # Class method
  # Try to authenticate a user with a given password.
  def self.authenticate(login, pass)
    user = Ink::Database.database.find "user", "WHERE loginname=\"#{login}\""
    return nil if user.length != 1
    return user[0] if User.encrypt(pass, user[0].salt) == user[0].pass
    nil
  end

  def self.fields
    fields = {
      :ref => "PRIMARY KEY",
      :loginname => [ "VARCHAR(200)", "NOT NULL", "UNIQUE" ],
      :pass => [ "VARCHAR(200)", "NOT NULL" ],
      :signup_date => [ "DATETIME", "NOT NULL" ],
      :salt => [ "VARCHAR(255)", "NOT NULL" ],
      :cookie_hash => [ "VARCHAR(255)", "NOT NULL" ],
    }
    fields
  end
  
  def self.foreign
    foreign = {
      "Role" => "many_many",
      "Entry" => "many_one",
      "Comment" => "many_one",
    }
    foreign
  end
end
