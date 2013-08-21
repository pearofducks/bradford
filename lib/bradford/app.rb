require 'sinatra'
require 'pry'
require 'haml'
require 'builder'

module Bradford
  class App < Sinatra::Base
    enable :sessions
    set :bind, '0.0.0.0'
    set :port, '8080'
    set :session_secret, 'ermagerd such a secret'
    set :username,'admin'
    set :token,'12345lookatmeimatokenCHANGEME'
    set :password,'adminPassword'
    set :environment, :production
    set :server, "thin"

    configure do
      mime_type :ttf, 'font/ttf'
      mime_type :otf, 'font/otf'
    end

    helpers do
      def protected! ; halt [ 401, 'Not Authorized' ] unless admin? ; end
      def admin? ; request.cookies[settings.username] == settings.token ; end
      def get_flash
        if session[:flash]
          flash = session[:flash]
          session[:flash] = nil
          return flash
        else
          return nil
        end
      end
    end

    not_found do
      haml :fourofour
    end

    get '/' do
      haml :index
    end

    get '/rss.xml' do
      builder :rss
    end

    get('/login') do
      @flash = get_flash
      @flash = "Already logged in as admin!" if admin?
      haml :login
    end

    get('/logout') do
      response.set_cookie(settings.username, false)
      session[:flash] = "Logged out!"
      redirect '/'
    end

    post '/login' do
      if params['username']==settings.username&&params['password']==settings.password
        response.set_cookie(settings.username,settings.token) 
        session[:flash] = "Logged in as admin!"
        redirect '/'
      else
        session[:flash] = "Username or Password incorrect"
        redirect '/login'
      end
    end

    get '/admin/new/?' do
      protected!
      session[:edit_id] = nil
      haml :post
    end

    get '/admin/edit/:id' do
      protected!
      session[:edit_id] = id = params[:id]
      @post_category = Post[id].category.name
      @post_content = Post[id].markdown
      haml :post
    end

    get '/admin/expire/:id' do
      protected!
      p = Post[params[:id]]
      success = p.expire
      if success
        session[:flash] = "Post set as expired!"
      else
        session[:flash] = "Something went wrong trying to expire this post."
      end
      redirect '/'
    end

    get '/admin/delete/:id' do
      protected!
      p = Post[params[:id]]
      success = p.delete
      if success
        session[:flash] = "Post deleted!"
      else
        session[:flash] = "Something went wrong trying to delete this post."
      end
    end

    post '/admin/post' do
      protected!
      case Post.add_edit_post(edit_id: session[:edit_id], copy: params[:copy], category: params[:category])
      when :no_category
        session[:flash] = "You must choose a post type!"
        @post_content = params[:copy]
        halt haml :post
      when :error
        session[:flash] = "Error saving post."
      else
        session[:flash] = "Post successful!"
      end
      session[:edit_id] = nil
      redirect '/'
    end
  end
end
