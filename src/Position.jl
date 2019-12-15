module Position

"Individual data for positions (A Long or Short)"
struct posData
    pl # The profit / Loss
    resettablePL # Profit / Loss since last reset
    units # Number of units in the trade
    unrealizedPL # Unrealized profit / loss of position
end

"Detailed Position struct from Oanda"
struct position
    instrument # The instrument
    # I have both of the following to enable people with hedging enabled
    long::posData # Data for a Long trade on the position
    short::posData # Data for a Short trade on the position
    pl # The profit / loss for this position
    resettablePL # The profit / loss since last reset for this position
    unrealizedPL # The total unrealised profit / loss for this position
end

"Turns the raw dict data into positions"
function positionDictToStruct(posDict)
    positions = []
    # If the array is empty return and empty array
    if length(posDict) == 0
        return positions
    end
    for dict in posDict
        long = dict["long"]
        long = posData(long["pl"], long["resettablePL"], long["units"], long["unrealizedPL"])
        short = dict["short"]
        short = posData(short["pl"], short["resettablePL"], short["units"], short["unrealizedPL"])

        temp = position(dict["instrument"], long, short, dict["pl"], dict["resettablePL"],
        dict["unrealizedPL"])
        push!(positions, temp)
    end
    return positions
end

end
