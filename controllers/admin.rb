
# note: code will be commented on first occurence
# please look through the blog controller first

class Admin < Ink::Controller
  
  # Instance method
  # @session_key and @session_id are used by the controller
  # to pass the session through GET requests instead of
  # cookies. Call this in every module that requires a
  # session and set the _session_id key on login in either
  # GET or POST and the session will never depend on cookies.
  def set_session_data!
    if @params[:get] and @params[:get].has_key? "_session_id"
      @session_key = "_session_id"
      @session_id = @params[:get]["_session_id"]
    elsif @params[:post] and @params[:post].has_key? "_session_id"
      @session_key = "_session_id"
      @session_id = @params[:post]["_session_id"]
    end
  end
  
  # index module
  def index
    # fetch the session, if one exists and set the logged in
    # user to u, if he exists too.
    session = User.session_instance @params[:cgi]
    self.set_session_data!
    u = User.logged_in_user session
    
    # differ between logged in user and otherwise
    # redirect to login if there is no session
    if u
      @user = u
      render :template => "admin", :locals => [ "kekse" ]
    else
      render :template => "admin", :locals => [ render :partial => "admin/login" ]
    end
    
  end
  
  # compose module
  def compose
    session = User.session_instance @params[:cgi]
    self.set_session_data!
    u = User.logged_in_user session
    
    # prevent access to this page without necessary user role
    if u and not u.can? "Post new"
      render :template => "admin", :locals => [ "Access forbidden" ]
    elsif u
      # handle a new entry that is provided through POST
      if @params[:post] and @params[:post]["submit"] == "Create"
        e = Entry.new "title" => @params[:post]["title"], "text" => @params[:post]["text"], "tags" => @params[:post]["tags"], "created_at" => Ink::Database.format_date(Time.now)
        e.user = u
        e.save
        
        # this message is displayed in admin.html.erb if set
        @message = "Post #{e.title} successfully created."
      end
      
      @user = u
      render :template => "admin", :locals => [ render :partial => "admin/a_compose" ]
    else
      render :template => "admin", :locals => [ render :partial => "admin/login" ]
    end
  end
  
  # list module
  def list
    session = User.session_instance @params[:cgi]
    self.set_session_data!
    u = User.logged_in_user session
    if u and not (u.can?("Post edit") or u.can?("Post delete"))
      render :template => "admin", :locals => [ "Access forbidden" ]
    elsif u
      # retrieve all entries of the logged in user
      @posts = Ink::Database.database.find_references "user", u.pk, "entry", "ORDER BY entry.created_at DESC"
      
      # prevent restricted users to edit or delete posts
      if u.can?("Post edit") and @params[:post] and @params[:post]["submit"] == "Edit"
        ref = @params[:post]["ref"]
        editpost = Ink::Database.database.find "entry", "WHERE #{Entry.primary_key[0]}=#{ref}"
        edituser = Ink::Database.database.find_references "entry", editpost[0].pk, "user" if editpost[0]
        
        # make sure the logged in user is also the author
        if editpost[0] and edituser and edituser[0] and edituser[0].pk == u.pk
          editpost[0].title = @params[:post]["title"]
          editpost[0].text = @params[:post]["text"]
          editpost[0].tags = @params[:post]["tags"]
          editpost[0].save
          @message = "Post #{editpost[0].title} successfully updated."
        end
      elsif u.can?("Post delete") and @params[:post] and @params[:post]["submit"] == "Delete"
        ref = @params[:post]["ref"]
        post = Ink::Database.database.find "entry", "WHERE #{Entry.primary_key[0]}=#{ref}"
        comments = Ink::Database.database.find_references "entry", ref, "comment"
        edituser = Ink::Database.database.find_reference "entry", editpost[0].pk, "user" if editpost[0]
        
        # comments need to be deleted before the post is gone, or
        # they will linger inside the database without reference
        if post[0] and edituser and edituser[0] and edituser[0].pk == u.pk
          comments.each do |c| c.delete end
          post[0].delete
          @message = "Post #{post[0].title} with all comments successfully deleted."
        end
      end
      
      @user = u
      render :template => "admin", :locals => [ render :partial => "admin/a_posts" ]
    else
      render :template => "admin", :locals => [ render :partial => "admin/login" ]
    end
  end
  
  def a_posts
    session = User.session_instance @params[:cgi]
    self.set_session_data!
    u = User.logged_in_user session
    if u and not u.can? "Post administrate"
      render :template => "admin", :locals => [ "Access forbidden" ]
    elsif u
      @posts = Ink::Database.database.find "entry", "ORDER BY created_at DESC"
      
      if @params[:post] and @params[:post]["submit"] == "Edit"
        ref = @params[:post]["ref"]
        editpost = Ink::Database.database.find "entry", "WHERE #{Entry.primary_key[0]}=#{ref}"
        if editpost[0]
          editpost[0].title = @params[:post]["title"]
          editpost[0].text = @params[:post]["text"]
          editpost[0].tags = @params[:post]["tags"]
          editpost[0].save
          @message = "Post #{editpost[0].title} successfully updated."
        end
      elsif @params[:post] and @params[:post]["submit"] == "Delete"
        ref = @params[:post]["ref"]
        post = Ink::Database.database.find "entry", "WHERE #{Entry.primary_key[0]}=#{ref}"
        comments = Ink::Database.database.find_references "entry", ref, "comment"
        if post[0]
          comments.each do |c| c.delete end
          post[0].delete
          @message = "Post #{post[0].title} with all comments successfully deleted."
        end
      end
      
      @user = u
      render :template => "admin", :locals => [ render :partial => "admin/a_posts" ]
    else
      render :template => "admin", :locals => [ render :partial => "admin/login" ]
    end
  end
  
  def a_comments
    session = User.session_instance @params[:cgi]
    self.set_session_data!
    u = User.logged_in_user session
    if u and not u.can? "Comment administrate"
      render :template => "admin", :locals => [ "Access forbidden" ]
    elsif u
      @comments = Ink::Database.database.find "comment", "ORDER BY created_at DESC"
      
      if @params[:post] and @params[:post]["submit"] == "Edit"
        ref = @params[:post]["ref"]
        editcomment = Ink::Database.database.find "comment", "WHERE #{Comment.primary_key[0]}=#{ref}"
        if editcomment[0]
          editcomment[0].title = @params[:post]["title"]
          editcomment[0].text = @params[:post]["text"]
          editcomment[0].save
          @message = "Comment #{editcomment[0].title} successfully updated."
        end
      elsif @params[:post] and @params[:post]["submit"] == "Delete"
        ref = @params[:post]["ref"]
        comment = Ink::Database.database.find "comment", "WHERE #{Comment.primary_key[0]}=#{ref}"
        if comment[0]
          comment[0].delete
          @message = "Comment #{comment[0].title} successfully deleted."
        end
      end
      
      @user = u
      render :template => "admin", :locals => [ render :partial => "admin/a_comments" ]
    else
      render :template => "admin", :locals => [ render :partial => "admin/login" ]
    end
  end
  
  def a_users
    session = User.session_instance @params[:cgi]
    self.set_session_data!
    u = User.logged_in_user session
    if u and not u.can? "User administrate"
      render :template => "admin", :locals => [ "Access forbidden" ]
    elsif u
      @roles = Ink::Database.database.find "role"
      
      if @params[:post] and @params[:post]["submit"]
        ref = @params[:post]["ref"]
        pass = @params[:post]["pass"]
        roles = Array.new
        @roles.each do |r| roles.push(r.pk) if @params[:post]["ref#{r.pk}"] end
        edituser = Ink::Database.database.find "user", "WHERE #{User.primary_key[0]}=#{ref}"
        if edituser[0]
          edituser[0].password = pass if pass.length > 0
          edituser[0].role = roles
          edituser[0].save
          @message = "User #{edituser[0].loginname} successfully updated."
        end
      end
      
      @user = u
      @users = Ink::Database.database.find "user", "WHERE #{User.primary_key[0]}<>#{@user.pk}"
      render :template => "admin", :locals => [ render :partial => "admin/a_users" ]
    else
      render :template => "admin", :locals => [ render :partial => "admin/login" ]
    end
  end
  
  def a_roles
    session = User.session_instance @params[:cgi]
    self.set_session_data!
    u = User.logged_in_user session
    if u and not u.can? "Role administrate"
      render :template => "admin", :locals => [ "Access forbidden" ]
    elsif u
      if @params[:post] and @params[:post]["submit"] == "Edit"
        ref = @params[:post]["ref"]
        rolet = @params[:post]["role"]
        role = Ink::Database.database.find "role", "WHERE #{User.primary_key[0]}=#{ref}"
        if role[0]
          role[0].role = rolet
          role[0].save
          @message = "Role #{role[0].role} successfully updated."
        end
      elsif @params[:post] and @params[:post]["submit"] == "Delete"
        ref = @params[:post]["ref"]
        role = Ink::Database.database.find "role", "WHERE #{User.primary_key[0]}=#{ref}"
        if role[0]
          role[0].delete
          @message = "Role #{role[0].role} successfully deleted."
        end
      elsif @params[:post] and @params[:post]["submit"] == "Create"
        role = Role.new "role" => @params[:post]["role"]
        role.save
        @message = "Role #{role.role} successfully created."
      end
      @user = u
      @roles = Ink::Database.database.find "role"
      render :template => "admin", :locals => [ render :partial => "admin/a_roles" ]
    else
      render :template => "admin", :locals => [ render :partial => "admin/login" ]
    end
  end
  
  # login module
  def login
    if @params[:post] and @params[:post]["submit"]
      # authenticate the user with provided pass
      u = User.authenticate @params[:post]["user"], @params[:post]["pass"]
      if u
        # create a session and save the session_id to the user
        session = User.session_instance @params[:cgi]
        u.cookie_hash = User.cookie_session_id session
        u.save
        
        # if a user has no cookies enabled, or simply does not
        # wish to use them, he mentioned it through a checkbox
        # provide enough for self.set_session_data! to set the
        # necessary variables
        # only use path_to and link_to for generating URIs
        if not @params[:post].has_key? "cookies_enabled"
          @params[:cgi].params["_session_id"] = [session.session_id]
          @params[:post]["_session_id"] = session.session_id
        end
      end
    end
    
    # redirect to index module, since login does not require its own space
    redirect_to :controller => @params[:controller], :module => "index"
  end
  
  def logout
    @params[:get].delete "_session_id"
    @params[:cgi].params.delete "_session_id"
    session = User.session_instance @params[:cgi]
    self.set_session_data!
    u = User.logged_in_user session
    if u
      u.cookie_hash = nil
      u.save
    end
    redirect_to :controller => @params[:controller], :module => "index"
  end
  
  def register
    if @params[:post] and @params[:post]["submit"]
      user = @params[:post]["user"]
      pass = @params[:post]["pass"]
      
      u = User.new "loginname" => user, "signup_date" => Ink::Database.format_date(Time.now), "cookie_hash" => User.cookie_session_id(User.session_instance(@params[:cgi])), "pass" => "", "salt" => ""
      u.password = pass
      u.role = Array.new
      allusers = Ink::Database.database.query "SELECT count(*) as `count` FROM user;"
      allroles = Ink::Database.database.query "SELECT count(*) as `count` FROM role;"
      # if there are no users, make a user superadmin, or just
      # allow Comments
      if allusers.length > 0 and allusers[0]["count"] == 0
        # make superadmin
        if allroles.length > 0 and allroles[0]["count"] == 0
          r1 = Role.new "role" => "Post new"
          r1.save
          r2 = Role.new "role" => "Post edit"
          r2.save
          r3 = Role.new "role" => "Post delete"
          r3.save
          r4 = Role.new "role" => "Comment"
          r4.save
          r5 = Role.new "role" => "Comment administrate"
          r5.save
          r6 = Role.new "role" => "User administrate"
          r6.save
          r7 = Role.new "role" => "Role administrate"
          r7.save
          r8 = Role.new "role" => "Post administrate"
          r8.save
        end
        
        roles = Ink::Database.database.find "role"
        roles.each do |r| u.role.push r end
      else
        r = Ink::Database.database.find "role", "WHERE role=\"Comment\""
        u.role.push r[0] if r[0]
      end
      
      u.save
      @message = "User successfully created."
      
      return render :template => "admin", :locals => [ "kekse" ]
    end
    render :template => "admin", :locals => [ render :partial => "admin/register" ]
  end
  
end
