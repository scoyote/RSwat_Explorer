

library(swat)
library(tidyr)

# Connect to CAS, start a session using binary rather than REST transfer protocol
session <- CAS('localhost', 5570, authfile='~./authinfo')
# the session is the active connection that that ties all of the work togehter in to a logical unit


#set the default caslib. The caslib is a in memory folder used by CAS to compartmentalize data for organization and security
cas.sessionProp.setSessOpt(session,caslib='DemoData')
#enable code completion
options(cas.gen.function.sig=TRUE)

