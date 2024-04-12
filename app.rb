require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

enable :sessions

get('/login') do
    slim(:login)
end 


get('/register') do
    slim(:register)
end 

post('/register') do
	username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]

    if (password == password_confirm)
        password_digest = BCrypt::Password.create(password)
        db = SQLite3::Database.new('db/bokhylla.db')
        db.execute("INSERT INTO users (username,pwdigest) VALUES (?,?)", username, pwdigest)
        redirect('/welcome') #tillbaks till get-route
    else 
        "Lösernordet matchade ej!"
    end 
end

post('/login') do
	username = params[:username]
    password = params[:password]
    db = SQLite3::Database.new('db/bokhylla.db')
    db.results_as_hash = true
    result = db.execute("SELECT * FROM users WHERE username = ?",username).first
    pwdigest = result["pwdigest"]
    id = result["id"]

    if BCrypt::Password.new(pwdigest) == password
        session[:id] = id
        redirect('/welcome') #tillbaks till get-route
    else 
        "FEL LÖSENORD"
    end 
end

get('/welcome') do
    slim(:start)
end 

get('/bokhylla') do
    db = SQLite3::Database.new("db/bokhylla.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM bokhylla")
    p result
    slim(:"bokhylla/index",locals:{bokhylla:result})
end 

post('/bokhylla') do
    name = params[:name]
    author_id = params[:author_id].to_i
    p "Vi fick in datan #{name} och #{author_id}"
    db = SQLite3::Database.new("db/bokhylla.db")
    db.execute("DELETE FROM bokhylla WHERE Book_Id = ?",id)
    redirect('/bokhylla')
end 

post('/bokhylla/:id/delete') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/bokhylla.db")
    db.execute("DELETE FROM bokhylla WHERE Book_Id = ?",id)
    redirect('/bokhylla')
end 

get('/tbrs') do
    id = session[:id].to_i
    db = SQLite3::Database.new('db/bokhylla.db')
    db.results_as_hash = true
    tbrs_result = db.execute("SELECT * FROM tbrs WHERE user_id = ?", id)
    already_reading_result = db.execute("SELECT * FROM already_reading WHERE user_id = ?", id)
    finished_reading_result = db.execute("SELECT * FROM finished_reading WHERE user_id = ?", id)
    p "Alla to be read från tbrs_result #{tbrs_result}"
    slim(:"tbrs/index", locals: {tbrs: tbrs_result, already_reading: already_reading_result, finished_reading:finished_reading_result})
end 

post('/tbrs') do
    id = session[:id].to_i
    book_title = params[:book_title]
    author_name = params[:author_name]
    pages = params[:pages]
    p "Vi fick in datan #{book_title}, #{pages} och #{author_name}"
    db = SQLite3::Database.new("db/bokhylla.db")
    db.execute("SELECT FROM bokhylla WHERE Book_Id = ?",id)
    redirect('/tbrs')
end 

post('/tbrs/:id/delete') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/bokhylla.db")
    db.execute("DELETE FROM tbrs WHERE id = ?",id)
    redirect('/tbrs')
end 

post('/tbrs/:id/already_reading') do 
    id = params[:id].to_i
    db = SQLite3::Database.new("db/bokhylla.db")
    db.transaction do
        # Flytta innehåll från tbrs till already_reading
        db.execute("INSERT INTO already_reading (id, book_title, user_id, pages, author_name) SELECT id, book_title, user_id, pages, author_name FROM tbrs WHERE id = ?", id)

        # Ta bort innehållet från tbrs
        db.execute("DELETE FROM tbrs WHERE id = ?", id)
    end
    redirect('/tbrs')
end 

post('/tbrs/new') do
    id = session[:id].to_i
    user_id = session[:id].to_i
    book_title = params[:book_title]
    author_name = params[:author_name]
    pages = params[:pages].to_i
    p "Vi fick in boken #{book_title} skriven av #{author_name}"
    db = SQLite3::Database.new("db/bokhylla.db")
    db.execute("INSERT INTO tbrs (book_title, author_name, pages, user_id) VALUES (?,?,?,?)",book_title, author_name, pages, user_id)
    redirect('/tbrs')
end 

post('/already_reading/:id/delete') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/bokhylla.db")
    db.execute("DELETE FROM already_reading WHERE id = ?",id)
    redirect('/tbrs')
end 

post('/already_reading/:id/finished_books') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/bokhylla.db")
    db.transaction do
        # Flytta innehåll från tbrs till already_reading
        db.execute("INSERT INTO finished_reading (id, book_title, user_id, pages, author_name) SELECT id, book_title, user_id, pages, author_name FROM already_reading WHERE id = ?", id)

        # Ta bort innehållet från tbrs
        db.execute("DELETE FROM already_reading WHERE id = ?", id)
    end
    redirect ("rating/#{id}")
end 

get('/rating/:id') do 
    id = params[:id].to_i
    db = SQLite3::Database.new("db/bokhylla.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM finished_reading WHERE id = ?", id).first
    slim(:"tbrs/rating", locals:{result:result})
end 

post("/rating/:id") do
    id = params[:id].to_i
    rating = params[:rating].to_i
    review = params[:review]
    rated_date = Time.now.strftime("%Y-%m-%d") 
    db = SQLite3::Database.new("db/bokhylla.db")
    db.execute("UPDATE finished_reading SET rating = ?, review = ?, rated_date = ? WHERE id = ?", rating, review, rated_date, id)
    redirect "/tbrs"
end

get ("/finished_reading/:id") do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/bokhylla.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM finished_reading WHERE id = ?",id).first
    p "Result2 är #{result}"
    slim(:"tbrs/show_finished",locals:{result:result})
end
