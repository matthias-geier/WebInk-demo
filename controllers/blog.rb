
class Blog < Ink::Controller

  # index module
  def index
    # determine page or set to 1
    @page = (@params[:page]) ? @params[:page].to_i : 1

    # set the amount of entries on a page, this could also be
    # moved to a config database entry
    @steps = 4

    # retrieve (LIMIT @steps+1) entries from (OFFSET (@page-1) * @steps)
    # the database table is ordered by descending creation date
    # this limits the amount of entries and therefore letting the
    # database do the work (which is much faster  and memory efficient anyway)
    @posts = Entry.find do |s|
      s.order.by("created_at").desc.limit(@steps+1).offset((@page-1)*@steps)
    end

    # retrieve the users and comments attached to the entry.
    # there is only one author of the entry, yet find_references will
    # return an array of size 1 to be consistent
    @posts.each do |post|
      post.find_references(User)
      post.find_references(Comment)
    end

    # the database query earlier used LIMIT @steps+1, which we
    # use to check if there are more entries after this.
    # the additional entry is removed later.
    # also the page amount tells us if there are entries
    # before.
    @has_more = (@posts.length > @steps)
    @has_less = (@page > 1)
    @posts.delete_at(@posts.length-1) if @posts.length > @steps

    # render the template index.html.erb and pass a partial through
    # via :locals. The partial can be accessed inside the template
    # through locals[0].
    # The partial blog/_posts.html.erb is rendered inside the template
    # context, as it's not declared standalone.
    render :template => "index", :locals => [ render(:partial => "blog/posts") ]
  end

  # entry module
  def entry
    # check for an existing session for commentaries and save it to @u
    session = User.session_instance(@params)
    @u = User.auth_cookie(session)

    # abuse the page parameter from routes for our page id
    @id = @params[:page].to_i

    # retrieve the entry by id (i.e. the primary key that can conveniently
    # be retrieved by Modelname.primary_key)
    @post = Entry.find{ |s| s.where("#{Entry.primary_key}=#{@id}") }.first

    # retrieve the users attached to the entry (it's just the author)
    @post.find_references(User)

    # when a user sends a comment, this will be processed here
    if @params[:post] && @params[:post]["submit"] == "Add"
      # if there was no session, the user had to specify username and password,
      # that we authenticate here
      user = @u || User.authenticate(@params[:post]["user"],
        @params[:post]["pass"])

      # once the commenting user is found, determine if he is allowed to comment
      if user && user.can?("Comment")
        # create a new comment, set its relations to this entry and the
        # commenting user and save
        c = Comment.new(@params[:post].merge({ 'created_at' =>
          Ink::Database.format_date(Time.now) }))
        c.entry = @post
        c.user = user
        c.save
      end
    end

    # retrieve the comments from this entry in ascending order and
    # attach its author to each
    @post.comment = @post.find_references(Comment) do |s|
      s.order.by('created_at').asc
    end
    @post.comment.each do |comm|
      comm.find_references(User)
    end

    # rendering is similar to the one in the index module
    render :template => "index",
      :locals => [ render(:partial => "blog/single") ]
  end

end
