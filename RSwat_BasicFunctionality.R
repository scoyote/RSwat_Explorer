
library(swat)
library(tidyr)

# Connect to CAS, start a session using binary rather than REST transfer protocol
session <- CAS('localhost', 5570, authfile='~./authinfo')
# the session is the active connection that that ties all of the work togehter in to a logical unit


#set the default caslib. The caslib is a in memory folder used by CAS to compartmentalize data for organization and security
cas.sessionProp.setSessOpt(session,caslib='DemoData')
#enable code completion
options(cas.gen.function.sig=TRUE)

# take a look at the file system under the CAS in memory space - These files in DemoData are located in the local
# filesystem, but could just as easily be in other datastores as defined by the caslib
files <- unnest(data.frame(cas.table.fileInfo(session)))
#list them according to size
files[order(-files[7]),c(4,7)]

# One of the advantages of using R SWAT is that you get to choose location of execution. If the 
# data sizes are small, it makes sense to use the regular R core for execution. However, if the data
# sizes are extensive, it may be impossible to load the data into a local R data frame depending on 
# available memory and resources.

#Check status of the SAS Viya cluster. This command lists many statustes related to the cluster.
res <- cas.builtins.serverStatus(session) 
#This returns an R list object that can be queried in the normal R way
res$server

