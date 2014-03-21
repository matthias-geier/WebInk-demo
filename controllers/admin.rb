
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
    if @session_key and @session_id
      @params[:header].delete("Set-Cookie")
    end
  end

  # index module
  def index
    # fetch the session, if one exists and set the logged in
    # user to u, if he exists too.
    session = User.session_instance(@params)
    self.set_session_data!
    u = User.auth_cookie(session)

    # differ between logged in user and otherwise
    # redirect to login if there is no session
    if u
      @user = u
      render :template => "admin", :locals => [ "Logged in, apparently" ]
    else
      render :template => "admin",
        :locals => [ render(:partial => "admin/login") ]
    end

  end

  # compose module
  def compose
    session = User.session_instance(@params)
    self.set_session_data!
    u = User.auth_cookie(session)

    # prevent access to this page without necessary user role
    if u && !u.can?("Post new")
      render :template => "admin", :locals => [ "Access forbidden" ]
    elsif u
      # handle a new entry that is provided through POST
      if @params[:post] and @params[:post]["submit"] == "Create"
        e = Entry.new(@params[:post].merge({ 'created_at' =>
          Ink::Database.format_date(Time.now) }))
        e.user = u
        e.save

        # this message is displayed in admin.html.erb if set
        @message = "Post #{e.title} successfully created."
      end

      @user = u
      render :template => "admin",
        :locals => [ render(:partial => "admin/a_compose") ]
    else
      render :template => "admin",
        :locals => [ render(:partial => "admin/login") ]
    end
  end

  # list module
  def list
    session = User.session_instance(@params)
    self.set_session_data!
    u = User.auth_cookie(session)
    if u && !(u.can?("Post edit") || u.can?("Post delete"))
      render :template => "admin", :locals => [ "Access forbidden" ]
    elsif u
      # retrieve all entries of the logged in user
      @posts = u.find_references(Entry) do |s|
        s.order.by('entry.created_at').desc
      end

      # prevent restricted users to edit or delete posts
      if u.can?("Post edit") && @params[:post] &&
          @params[:post]["submit"] == "Edit"
        ref = Ink::SqlAdapter.transform_to_sql(@params[:post]["ref"])
        editpost = Entry.find{ |s| s.where("`#{Entry.primary_key}`=#{ref}") }.
          first
        if editpost
          edituser = editpost.find_references(User)
        end

        # make sure the logged in user is also the author
        if editpost && edituser && edituser.pk == u.pk
          editpost.update_fields(@params[:post])
          editpost.save
          @message = "Post #{editpost.title} successfully updated."
        end
      elsif u.can?("Post delete") && @params[:post] &&
          @params[:post]["submit"] == "Delete"
        ref = Ink::SqlAdapter.transform_to_sql(@params[:post]["ref"])
        post = Entry.find{ |s| s.where("`#{Entry.primary_key}`=#{ref}") }.
          first
        if post
          comments = post.find_references(Comment)
          edituser = post.find_references(User)
        end

        # comments need to be deleted before the post is gone, or
        # they will linger inside the database without reference
        if post && edituser && edituser.pk == u.pk
          comments.each{ |c| c.delete }
          post.delete
          @message =
            "Post #{post.title} with all comments successfully deleted."
        end
      end

      @user = u
      render :template => "admin",
        :locals => [ render(:partial => "admin/a_posts") ]
    else
      render :template => "admin",
        :locals => [ render(:partial => "admin/login") ]
    end
  end

  def a_posts
    session = User.session_instance(@params)
    self.set_session_data!
    u = User.auth_cookie(session)
    if u && !u.can?("Post administrate")
      render :template => "admin", :locals => [ "Access forbidden" ]
    elsif u
      @posts = u.find_references(Entry) do |s|
        s.order.by('entry.created_at').desc
      end

      if @params[:post] && @params[:post]["submit"] == "Edit"
        ref = Ink::SqlAdapter.transform_to_sql(@params[:post]["ref"])
        editpost = Entry.find{ |s| s.where("`#{Entry.primary_key}`=#{ref}") }.
          first
        if editpost
          editpost.update_fields(@params[:post])
          editpost.save
          @message = "Post #{editpost.title} successfully updated."
        end
      elsif @params[:post] && @params[:post]["submit"] == "Delete"
        ref = Ink::SqlAdapter.transform_to_sql(@params[:post]["ref"])
        post = Entry.find{ |s| s.where("`#{Entry.primary_key}`=#{ref}") }.
          first
        if post
          comments = post.find_references(Comment)
          comments.each{ |c| c.delete }
          post.delete
          @message =
            "Post #{post.title} with all comments successfully deleted."
        end
      end

      @user = u
      render :template => "admin",
        :locals => [ render(:partial => "admin/a_posts") ]
    else
      render :template => "admin",
        :locals => [ render(:partial => "admin/login") ]
    end
  end

  def a_comments
    session = User.session_instance(@params)
    self.set_session_data!
    u = User.auth_cookie(session)
    if u && !u.can?("Comment administrate")
      render :template => "admin", :locals => [ "Access forbidden" ]
    elsif u
      @comments = u.find_references(Comment) do |s|
        s.order.by('comment.created_at').desc
      end

      if @params[:post] and @params[:post]["submit"] == "Edit"
        ref = Ink::SqlAdapter.transform_to_sql(@params[:post]["ref"])
        editcomment = Comment.find do |s|
          s.where("`#{Comment.primary_key}`=#{ref}")
        end.first
        if editcomment
          editcomment.update_fields(@params[:post])
          editcomment.save
          @message = "Comment #{editcomment.title} successfully updated."
        end
      elsif @params[:post] && @params[:post]["submit"] == "Delete"
        ref = Ink::SqlAdapter.transform_to_sql(@params[:post]["ref"])
        comment = Comment.find do |s|
          s.where("`#{Comment.primary_key}`=#{ref}")
        end.first
        if comment
          comment.delete
          @message = "Comment #{comment.title} successfully deleted."
        end
      end

      @user = u
      render :template => "admin",
        :locals => [ render(:partial => "admin/a_comments") ]
    else
      render :template => "admin",
        :locals => [ render(:partial => "admin/login") ]
    end
  end

  def a_users
    session = User.session_instance(@params)
    self.set_session_data!
    u = User.auth_cookie(session)
    if u && !u.can?("User administrate")
      render :template => "admin", :locals => [ "Access forbidden" ]
    elsif u
      @roles = Role.find

      if @params[:post] && @params[:post]["submit"]
        roles = @roles.select{ |r| @params[:post]["ref#{r.pk}"] }
        pass = @params[:post]["pass"]
        ref = Ink::SqlAdapter.transform_to_sql(@params[:post]["ref"])
        edituser = User.find{ |s| s.where("`#{User.primary_key}`=#{ref}") }.
          first
        if edituser
          edituser.password = pass if pass.length > 0
          edituser.role = roles
          edituser.save
          @message = "User #{edituser.loginname} successfully updated."
        end
      end

      @user = u
      @users = User.find{ |s| s.where("#{User.primary_key}<>#{@user.pk}") }
      render :template => "admin",
        :locals => [ render(:partial => "admin/a_users") ]
    else
      render :template => "admin",
        :locals => [ render(:partial => "admin/login") ]
    end
  end

  def a_roles
    session = User.session_instance(@params)
    self.set_session_data!
    u = User.auth_cookie(session)
    if u && !u.can?("Role administrate")
      render :template => "admin", :locals => [ "Access forbidden" ]
    elsif u
      if @params[:post] && @params[:post]["submit"] == "Edit"
        ref = Ink::SqlAdapter.transform_to_sql(@params[:post]["ref"])
        role = Role.find{ |s| s.where("#{Role.primary_key}=#{ref}") }.first
        if role
          role.role = @params[:post]["role"]
          role.save
          @message = "Role #{role.role} successfully updated."
        end
      elsif @params[:post] && @params[:post]["submit"] == "Delete"
        ref = Ink::SqlAdapter.transform_to_sql(@params[:post]["ref"])
        role = Role.find{ |s| s.where("#{Role.primary_key}=#{ref}") }.first
        if role
          role.delete
          @message = "Role #{role.role} successfully deleted."
        end
      elsif @params[:post] and @params[:post]["submit"] == "Create"
        role = Role.new(@params[:post]["role"])
        role.save
        @message = "Role #{role.role} successfully created."
      end
      @user = u
      @roles = Role.find
      render :template => "admin",
        :locals => [ render(:partial => "admin/a_roles") ]
    else
      render :template => "admin",
        :locals => [ render(:partial => "admin/login") ]
    end
  end

  # login module
  def login
    if @params[:post] and @params[:post]["submit"]
      # authenticate the user with provided pass
      u = User.authenticate(@params[:post]["user"], @params[:post]["pass"])
      if u
        # create a session and save the session_id to the user
        session = User.session_instance @params
        u.cookie_hash = session
        u.save

        # if a user has no cookies enabled, or simply does not
        # wish to use them, he mentioned it through a checkbox
        # provide enough for self.set_session_data! to set the
        # necessary variables
        # only use path_to and link_to for generating URIs
        if not @params[:post].has_key?("cookies_enabled")
          @params[:cookie].delete("_session_id")
          @params[:header].delete("_session_id")
          @params[:post]["_session_id"] = session
        end
      end
    end

    # redirect to index module, since login does not require its own space
    redirect_to :controller => @params[:controller], :module => "index"
  end

  def logout
    session = User.session_instance(@params)
    @params[:get].delete("_session_id")
    @params[:cookie].delete("_session_id")
    @params[:header].delete("Set-Cookie")
    self.set_session_data!
    u = User.auth_cookie(session)
    if u
      u.cookie_hash = nil
      u.save
    end
    redirect_to :controller => @params[:controller], :module => "index"
  end

  def register
    if @params[:post] && @params[:post]["submit"]
      user = @params[:post]["user"]
      pass = @params[:post]["pass"]

      u = User.new(
        "loginname" => user,
        "signup_date" => Ink::Database.format_date(Time.now),
        "cookie_hash" => User.session_instance(@params),
        "pass" => "",
        "salt" => ""
      )
      u.password = pass

      allusers = Ink::R.select.count!('*').from(User.table_name).to_a.first
      allroles = Ink::R.select.count!('*').from(Role.table_name).to_a.first
      # if there are no users, make a user superadmin, or just
      # allow Comments
      if allusers && allusers[0] == 0
        # make superadmin
        if allroles && allroles[0] == 0
          ["Post new", "Post edit", "Post delete", "Comment",
            "Comment administrate", "User administrate", "Role administrate",
            "Post administrate"].each do |name|

            r = Role.new(name)
            r.save
          end
        end

        roles = Role.find
        u.role = roles
      else
        r = Role.find{ |s| s.where('role="Comment"') }.first
        u.role = r if r
      end

      u.save
      @message = "User successfully created."

      return render :template => "admin", :locals => [ "kekse" ]
    end
    render :template => "admin",
      :locals => [ render(:partial => "admin/register") ]
  end

end
