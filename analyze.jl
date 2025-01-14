using titanic, DataFrames, MethodChains, Deneb, DataSkimmer, UnicodePlots, StatsBase, Statistics
MethodChains.init_repl()

filepath = "./titanic.csv"

df = readtitanic(filepath)

# the size of the dataframe is 2207 x 11, so there were 2207 passengers
size(df)

# look at all types of ticket class 
# includes upper, middle, lower, engineering crew, victualling crew, restaurant staff, deck crew
# victualling means provide for food...
unique(df.class)

# look at general information
# 4 embarked locations though metadata said 3?...
# 49 countries
# 916 missing fare prices, how many are workers? max was 512!
# max family sizes of 8/9
describe(df, :eltype, :nuniqueall, :nmissing, :min, :max)

# C = Cherbourg, Q = Queenstown, S = Southampton , what does B mean?
unique(df.embarked)

# Length:         2207
# Missing Count:  916
# Mean:           33.404762
# Std. Deviation: 52.227592
# Minimum:        3.030500
# 1st Quartile:   7.180600
# Median:         14.090200
# 3rd Quartile:   31.060749
# Maximum:        512.060730
describe(df.fare)

# most tickets are from 0 to 50 pounds
# quick wiki check, most expensive were 870 pounds (modern day 109,000 pounds)
# so some tickets are actually missing
readtitanic(filepath).{
	dropmissing(it)
	histogram(it.fare, title = "Ticket Fares")
}

# there are 1317 counted passengers
count(row -> row.class in ["1st", "2nd", "3rd"], eachrow(df))

# 890 workers
count(row -> row.class in ["engineering crew", "victualling crew", "restaurant staff", "deck crew"], eachrow(df))

# 916 missing fares, so only 26 passengers are not accounted for
count(ismissing, df.fare)

# total ticket fares were 43111.15f0
# so ~5 mill pounds in today's currency
df.{
	dropmissing(it)
	sum(it.fare)
}

# gender stats
# 1718 male, 489 female
countmap(df.gender)

# 867 male, 23 female workers
df.{
	filter(row -> (row.class ∉ ["1st", "2nd", "3rd"]), it)
	groupby(it, :gender)
	#count(it)
}

# age stats
# most are 20-30 years old
df.{
	dropmissing(it)
	histogram(it.age, title = "Age")
}

# country stats
# how to sort by values?...
show(stdout, "text/plain", unique(df.country))
country_count = df.{
						dropmissing(it)
						countmap(it.country)
					}

df.{
	groupby(it, :country)
	combine(it, nrow, proprow)
	sort(it, :nrow, rev=true)
}

# England, US, Ireland, Sweden (NA with 76)
show(stdout, "text/plain", country_count)

# embarked
# "Q" => 123
# "S" => 898
# "C" => 268
countmap(df.embarked)

# fare column has weird types of values
# those whow survived, their ticket fares were twice as more expensive
df.{
	dropmissing(it)
	combine(groupby(it, :survived), :fare => mean => :average_fare)
}

# this doesn't work...
# df.{
# 	dropmissing!(it)
# 	groupby(it, :survived)
# 	mean(it.fare)
# }

# ticket price by country, Canadians had by far, most expensive tickets

country_ticket = df.{
	dropmissing(it)
	combine(groupby(it, :country),
		:fare => mean => :average_fare,
		nrow => :passengers,)
}
sort(country_ticket, :average_fare)

# survival by class
class_survival = df.{
	combine(groupby(it, :class),
    :survived => (x -> count(x .== "yes")) => :count_alive,
    :survived => (x -> count(x .== "no")) => :count_dead)
}

# survival rate by class (deck crew and 1st class highest survival rates)
class_survival
transform!(class_survival, :, [:count_alive,:count_dead] => ((x, y) -> x ./ (x+y)) => :survival_rate)
transform!(class_survival, :, [:count_alive,:count_dead] => ((x, y) -> x + y) => :total)
sort(class_survival, :survival_rate)

# survival by gender (females overwhelming survival rate)
df.{
	combine(groupby(it, :gender),
    :survived => (x -> count(x .== "yes")) => :count_alive,
    :survived => (x -> count(x .== "no")) => :count_dead)
}

# by country
country_survival = df.{
	combine(groupby(it, :country),
    :survived => (x -> count(x .== "yes")) => :count_alive,
    :survived => (x -> count(x .== "no")) => :count_dead)
}

# create survival rate and total people columns
transform!(country_survival, :, [:count_alive,:count_dead] => ((x, y) -> x ./ (x+y)) => :survival_rate)
transform!(country_survival, :, [:count_alive,:count_dead] => ((x, y) -> x + y) => :total)

# find countries with 10+ passengers survival rates, Switzerland has highest survival rate
country_survival.{
	filter(row -> (row.total > 10), it)
	sort(it, :survival_rate)
}

# try with groupby and nrow

# age boxplot by survival status, why doesn't this work?
df.{
	dropmissing(it)
	Data(it) * Mark(:boxplot, size=30) * Encoding(
		y=(field="age", type=:quantitative, scale=(;zero=false)),
		x=:survived
		)
}

#something wrong with data?... is it with survived variable and string type?

# boxplot of fares by survival status
df.{
	dropmissing(it)
	Data(it) * Mark(:boxplot) * Encoding(
    	x=:survived,
    	y=(field="fare", type=:quantitative)
    )
} 


# by country and fare
country_survival_fare = df.{
	dropmissing(it)
	combine(groupby(it, :country),
    :survived => (x -> count(x .== "yes")) => :count_alive,
    :survived => (x -> count(x .== "no")) => :count_dead,
    :fare => (x -> mean(x)) => :avg_fare)
}

transform!(country_survival_fare, :, [:count_alive,:count_dead] => ((x, y) -> x ./ (x+y)) => :survival_rate)
transform!(country_survival_fare, :, [:count_alive,:count_dead] => ((x, y) -> x + y) => :total)

# axis should be switched and line spacing should be uniform (using vega)
country_survival_fare.{
	Data(it) * Mark(:point) * Encoding(
		x=field("avg_fare"),
		y=field("survival_rate"),
		tooltip=field("country")
		)
}

# using deneb...
country_survival_fare.{
	Data(it) * Mark(:point) * Encoding(
		"avg_fare:q",
    	"survival_rate:q",
    	tooltip=field("country")
		)
}

#what happened with the cabin variable?

# family stuff; this is also empty
df.{
	dropmissing(it)
	Data(it) * Mark(:histogram) * Encoding(
		x=field(:parch, bin=true),
    	y="count()"
    )
}

# anything with names?




