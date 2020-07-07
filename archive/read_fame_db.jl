using FAME
using TSeries


# AEBS function
function load_db(db::FameDatabase, wildcard::String="?", numbobj::Integer=10000)
    varlist = listdb(db, wildcard, maxobj=numbobj);
    dictdb = Dict(varlist[i].name => fame_read(db,varlist[i].name) for i=1:length(varlist))
    return dictdb;
end

# open and loadb
begin
    conn = opendb("finalforecast.db")
    db_ff = load_db(conn)
    closedb!(conn)
end;

db_ff = opendb("finalforecast.db") do conn
    load_db(conn)
end

# filter out quarterly series
db_ff_precision = filter( (k, v) -> v.class == FAME.HSERIE, db_ff)
db_ff_quarterly = filter( (k, v) -> v.freq == FameFreq(160) ||
                                    v.freq == FameFreq(161) ||
                                    v.freq == FameFreq(162), db_ff_precision)



# convert to TSeries
ts_db = Dict{String, Series}()

for (k, v) in db_ff_quarterly

    year   = v.first_period.year
    period = v.first_period.period
    data   = replace(v.data, missing=>NaN)

    ts_db[k] = Series(qq(year, period), data)
end



[ts_db["R1N"] ts_db["R1N_SHK"]]

ts_db["R1N_SHK"][qq(2010, 1):qq(2011, 4)] = 0;
ts_db["R1N_SHK"][qq(2010, 1):qq(2011, 4)]

ts_db["R1N_SHK"][qq(1980, 1):qq(2000, 1)] = 0;ts_db["R1N_SHK"]

db_ff["R1N_SHK"]


db_ff_non_precision = filter( (k, v) -> v.class != FameClass(1), db_ff)


# filter(p -> p.first == "P_DISC_MC", db_ff_non_precision)
