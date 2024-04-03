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
        db.execute("INSERT INTO users (username,pwdigest) VALUES (?,?)", username, password_digest)
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
    result = db.execute("SELECT * FROM tbrs WHERE user_id = ?",id)
    p "Alla to be read frå¨n result #{result}"
    slim(:"tbrs/index",locals:{tbrs:result})
end 

