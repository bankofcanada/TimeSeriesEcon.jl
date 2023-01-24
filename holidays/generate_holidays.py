import holidays
from datetime import date, timedelta, datetime
import numpy as np
import toml

## get weekdays
vectorized_weekdays = np.vectorize(datetime.isoweekday)
all_dates = np.arange(datetime(1970,1,1), datetime(2050,1,1), timedelta(days=1)).astype(datetime)
daysofweeks = vectorized_weekdays(all_dates)
weekdays = all_dates[np.where(daysofweeks < 6)] # length of this is divisible by 8

## helper function
def generate_holidays_vector(days_function, filename):
    def nonholiday(x):
            return days_function.get(x) == None
    vectorized_nonholidays = np.vectorize(nonholiday)
    holidays_vector = vectorized_nonholidays(weekdays)
    return holidays_vector

# get number of  combinations
combinations_count = 0
for country, subs in holidays.list_supported_countries().items():
    if len(subs):
        for sub in subs:
            combinations_count += 1
            # combinations.append(f"{country}_{sub.replace(' ', '_')}")
    else:
        combinations_count += 1
        # combinations.append(f"{country}")

# allocate output matrix
locations_dict = {}
output_array = np.empty((combinations_count + combinations_count % 8, weekdays.size), bool) # padded to a multiple of 8 for packaging


# populate output matrix
print("Processing countries.")
counter = 0
for country, subs in holidays.list_supported_countries().items():
    if len(subs):
        country_dict= {}
        for sub in subs:
            country_dict[sub] = counter + 1
            days_function = holidays.country_holidays(country, subdiv=sub)
            output_array[counter,:] = generate_holidays_vector(days_function, f"holidays_{country}_{sub.replace(' ', '_')}")
            counter += 1
        locations_dict[country] = country_dict
    else:
        days_function = holidays.country_holidays(country)
        output_array[counter, :] = generate_holidays_vector(days_function, f"holidays_{country}")
        locations_dict[country] = counter + 1
        counter += 1

# store metadata
locations_dict["Metadata"] = {
    "output_height": output_array.shape[0],
    "Defaults": {
        "AU": "ACT",
        "AT": "9",
        "CA": "ON",
        "FR": "Métropole",
        "NI": "MN",
        "GB": "UK"
    }
}


# compress and write to binary
print("Saving outputs.")
np.packbits(output_array, axis=1, bitorder='little').tofile(f"data/holidays.bin")
print("    data/holidays.bin")

# write locations to toml file
with open("data/holidays.toml", "w") as toml_file:
    toml.dump(locations_dict, toml_file)
print("    data/holidays.toml")

print("done.")