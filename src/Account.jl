module Account
export account

"The account struct given by Oanda"
struct account
    NAV::Float64 # The Net Asset Value of an account
    alias::String # User defined alias if one exists
    balance::Float64 # Current Account Balance
end

end
