module Binance

using PyCall, DataFrames

export 
    set_auth_token, 
    parsekeyfile, 
    Client, 
    get_all_tickers, 
    get_order_book, 
    get_symbol_info, 
    get_exchange_info,
    get_ticker,
    get_symbol_ticker,
    get_symbols,
    base_symbols,
    split_symbols,
    get_symbol_map,
    get_order_book


@pyimport binance.client as bn

const KEYFILE = joinpath(@__DIR__, "auth_token.txt")

const BASE_SYMBOLS = ["BTC", "ETH", "BNB", "USDT"]

Client() = Client(parsekeyfile()...)
Client(api_key::AbstractString, api_secret::AbstractString) = bn.Client(api_key, api_secret)

function set_auth_token(api_key::AbstractString, api_secret::AbstractString, keyfile::AbstractString=KEYFILE)
    f = open(keyfile, "w")
    println(f, api_key)
    println(f, api_secret)
    close(f)
end

function parsekeyfile(keyfile::AbstractString=KEYFILE)
    f = open(keyfile)
    api_key = readline(f)
    api_secret = readline(f)
    close(f)
    (api_key, api_secret)
end

get_all_tickers(client) = client[:get_all_tickers]()
get_order_book(client, sym::Union{Symbol,String}) = client[:get_order_book](symbol=sym)
get_symbol_info(client, sym::Union{Symbol,String}) = client[:get_symbol_info](sym)
get_exchange_info(client) = client[:get_exchange_info]()
get_ticker(client,sym::Union{Symbol,String}) = client[:get_ticker](symbol=sym)
get_symbol_ticker(client,sym::Union{Symbol,String}) = client[:get_symbol_ticker](symbol=sym)

function get_symbols(client)
    resp = get_all_tickers(client)
    [d[] for d in resp]
end

base_symbols() = BASE_SYMBOLS

function get_all_tickers(::Type{DataFrame}, client; verbose::Bool=false)
    df = DataFrame([String, Float64],[:symbol, :price], 0)
    for x in get_all_tickers(client)
        verbose && @show x["symbol"]
        push!(df, [x["symbol"], parse(Float64,x["price"])])
    end
    df 
end
function get_all_tickers(::Type{Dict}, client,
                         df::DataFrame=get_all_tickers(DataFrame, client); 
                         verbose::Bool=false)
    d = Dict{String,Float64}()
    for x in eachrow(df) 
        verbose && @show x[:symbol]
        d[x[:symbol]] = x[:price]
    end
    d 
end

function get_symbol_map(::Type{DataFrame}, client; verbose::Bool=false)
    df = DataFrame([String, String, String],[:symbol, :from_symbol, :to_symbol], 0)
    for x in get_all_tickers(client)
        verbose && @show x["symbol"]
        from_symbol, to_symbol = split_symbol(client, x["symbol"])
        push!(df, [x["symbol"], from_symbol, to_symbol])
    end
    df 
end
function get_symbol_map(::Type{Dict}, client,
                        df::DataFrame=get_symbol_map(DataFrame, client); 
                        verbose::Bool=false)
    d = Dict{String,Tuple{String,String}}()
    for x in eachrow(df)
        d[x[:symbol]] = (x[:from_symbol],x[:to_symbol])
    end
    d
end
function split_symbol(client, s::String)
    d = get_symbol_info(client, s)
    (d["quoteAsset"], d["baseAsset"]) #from_symbol, to_symbol
end



end # module
