

library(swat)
library(tidyr)
library(ggplot2)
library(reshape2)

# Connect to CAS, start a session using binary rather than REST transfer protocol
session <- CAS('localhost', 5570, authfile='~./authinfo')
# the session is the active connection that that ties all of the work togehter in to a logical unit


#set the default caslib. The caslib is a in memory folder used by CAS to compartmentalize data for organization and security
cas.sessionProp.setSessOpt(session,caslib='DemoData')
#enable code completion
options(cas.gen.function.sig=TRUE)

#upload the csv into CAS in-memory table directly
airline2008_h <- cas.read.csv(session, "~/2008.csv", tablenam="Air2008", replace=TRUE)
# load the cas table into local R = not always a good idea:)
airlocal_df <- to.casDataFrame(airline2008_h)

#compare local vs remote object 
object.size(airline2008_h)
object.size(airlocal_df)


cas.table.tableInfo(session,caslib='DemoData')

head(airline2008_h)

#Use CAS enabled R functions
cas.simple.summary(airline2008_h)
cas.simple.distinct(airline2008_h$UniqueCarrier)

#take a look at the in-memory tables
tables <- unnest(data.frame(cas.table.tableInfo(session,caslib='DemoData')))
tables[c(1,16)]

cas.table.columnInfo(session,table ="AIR2008" )


