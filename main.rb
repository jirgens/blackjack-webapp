require 'rubygems'
require 'sinatra'

set :sessions, true

BLACKJACK = 21
DEALER_STAYS = 17

helpers do
	def calculate_total(cards) 
		arr = cards.map{|element| element[1]}
		total = 0
		arr.each do |a|
			if a == "Ace"
				total += 11
			else
				total += a.to_i == 0 ? 10 : a.to_i
			end
		end

		arr.select{|element| element == "Ace"}.count.times do
			break if total <= BLACKJACK
			total -= 10
		end
		total
	end

	def card_image(card)
		suit = case card[0]
			when 'Hearts' then 'hearts'
			when 'Diamonds' then 'diamonds'
			when 'Clubs' then 'clubs'
			when 'Spades' then 'spades'
		end

		value = card[1]
		if ['Jack', 'Queen', 'King', 'Ace'].include?(value) 
			value = case card[1]
				when 'Jack' then 'jack'
				when 'Queen' then 'queen'
				when 'King' then 'king'
				when 'Ace' then 'ace'
			end	
		end
		"<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'>"
	end

	def loser!(msg)
		@show_hit_or_stay_buttons = false
		@play_again = true
		session[:player_pot] = session[:player_pot].to_i - session[:player_bet].to_i
		@loser = "<strong>Sorry, #{session[:player_name]} lost. </strong> #{msg}"
	end

	def winner!(msg)
		@show_hit_or_stay_buttons = false
		@play_again = true
		session[:player_pot] = session[:player_pot].to_i + session[:player_bet].to_i
		@winner = "<strong>#{session[:player_name]} wins!</strong> #{msg}"
	end

	def tie!(msg)
		@show_hit_or_stay_buttons = false
		@play_again = true
		@winner = "<strong> Wow, #{session[:player_name]} tied the Dealer!</strong> #{msg}"
	end
end

before do
	@show_hit_or_stay_buttons = true
end

get '/' do 
	if session[:player_name]
		redirect '/game'
	else
		redirect '/new_player'
	end
end

get '/new_player' do
	session[:player_pot] = 500
	erb :new_player #renders the template 'new player'
end

post '/new_player' do
	if params[:player_name].empty?
		@error = "Please enter a name."
		halt erb(:new_player)
	end

	session[:player_name] = params[:player_name]
	redirect '/bet'
end

get '/bet' do
	session[:player_bet] = nil
	erb :bet
end

post '/bet' do
	if params[:bet_amount].nil? || params[:bet_amount].to_i == 0
		@error = "Please make a bet."
		halt erb(:bet)
	elsif params[:bet_amount].to_i > session[:player_pot]
		@error = "Bet amount should be within your budget ( $#{session[:player_pot]}"
			halt erb(:bet)
	else
		session[:player_bet] = params[:bet_amount].to_i
		redirect '/game'
	end
end


get '/game' do
	session[:turn] = session[:player_name]

	suits = ['Spades', 'Hearts', 'Clubs', 'Diamonds']
	values = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'Jack', 'Queen', 'King', 'Ace']
	session[:deck] = suits.product(values).shuffle!
	session[:dealer_cards] = []
	session[:player_cards] = []
	session[:dealer_cards] << session[:deck].pop
	session[:player_cards] << session[:deck].pop
	session[:dealer_cards] << session[:deck].pop
	session[:player_cards] << session[:deck].pop
	player_total = calculate_total(session[:player_cards])
	if player_total == 21
		winner!("#{session[:player_name]} hit Blackjack!!")
	end

	erb :game
end

post '/game/player/hit' do
	session[:player_cards] << session[:deck].pop
	player_total = calculate_total(session[:player_cards])
		if player_total == BLACKJACK
			@show_hit_or_stay_buttons = false
			winner!("#{session[:player_name]} hit Blackjack!!")
		elsif player_total > BLACKJACK
			loser!("#{session[:player_name]} busted!")
		end
	erb :game, layout: false
end

post '/game/player/stay' do
	@success = "#{session[:player_name]} has chosen to stay. Safe move."
	redirect '/game/dealer'
end

get '/game/dealer' do
	session[:turn] = 'dealer'
	@show_hit_or_stay_buttons = false

		dealer_total = calculate_total(session[:dealer_cards])
		if dealer_total == BLACKJACK
			loser!("The dealer hit Blackjack.")
		elsif dealer_total > BLACKJACK
			winner!("Dealer busted.")
		elsif dealer_total >= DEALER_STAYS
			redirect '/game/compare'
		else
			@show_dealer_hit_button = true
		end

		erb :game, layout: false
end

post '/game/dealer/hit' do
	session[:dealer_cards] << session[:deck].pop
	redirect '/game/dealer'
end

get '/game/compare' do
	@show_hit_or_stay_buttons = false
	player_total = calculate_total(session[:player_cards])
	dealer_total = calculate_total(session[:dealer_cards])

		if player_total < dealer_total
			loser!("#{session[:player_name]} with a total of #{player_total} & Dealer a total of #{dealer_total}")
		elsif player_total > dealer_total
			winner!("#{session[:player_name]} with a total of #{player_total} & Dealer a total of #{dealer_total}")
		else 
			tie!("Everyone finished with #{player_total}!")
		end
		erb :game
end

get '/game_over' do
	erb :game_over
end




