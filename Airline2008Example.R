

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
airline2008_h <- cas.read.csv(session, "~/2008.csv", tablename="Air2008", replace=TRUE)
cas.table.promote(session,table="AIR2008")

airline2008_h@computedVars = 'ArrDelay_x'
airline2008_h@computedVarsProgram = "ArrDelay_X = 'ArrDelay'n"
colnames(airline2008_h)
head(airline2008_h)

##CAS action way
cas.table.columnInfo(session,table ="AIR2008" )

cas.table.save(session,table ="AIR2008",name="AIR2008b",replace = TRUE)
cas.table.dropTable(session,name="AIR2008")

cas.table.fileInfo(session,caslib = "DemoData")
cas.table.loadTable(session,path='AIR2008b.sashdat',caslib="DemoData")
airline2008_b <- defCasTable(session,tablename = "AIR2008b",caslib = "DemoData")
##CAS Table handle way
colnames(airline2008_b)
# This makes it possible to go into Visual Data Builder to do transformations if desired
#TODO Open Data Builder, go to Column Profile and change Cancelled Data Type to Character and format to $1. then Save the table!!!
#TODO ADD column ceil(depdelay/1000)



#A delay is defined as 15 or more minutes after

##CAS action way
cas.table.columnInfo(session,table ="AIR2008" )
##CAS Table handle way
colnames(airline2008_h)

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

cas.simple.distinct(airline2008_h)$Distinct[,c('Column', 'NMiss')]

airline2008_h$ArrDelay

airline2008_h['newvar'] <- airline2008_h['ArrDelay']

airline2008_h@computedVars = c('pratio')
airline2008_h@computedVarsProgram <- "pratio = 'ArrDelay'n;"

newair <- as.casTable(session,airline2008_h,casOut=list(name="AIR2008b", replace=TRUE))

colnames(airline2008_h)
cas.table.columnInfo(session,table ="AIR2008" )

summary(airline2008_h$pratio)
cas.simple.summary(session,table="AIR2008")
# Load the sampling actionset
loadActionSet(session, 'sampling')

cas.sampling.srs(session, 
                 table="AIR2008",
                 sampPct=70, 
                 partind=TRUE, 
                 output=list(casOut=list(name='air_part', replace=TRUE), copyvars='ALL'))


# Verify the partitioning
# Load the fedsql actionset
loadActionSet(session, 'fedsql')

# Make sure the partition worked correctly using SQL
cas.fedsql.execDirect(session, query = paste0(
  "SELECT CASE WHEN _PartInd_ = 1 THEN 'Training' ELSE 'Validation' END AS name, ",
  "_PartInd_, COUNT(*) AS obs FROM air_part ",
  "GROUP BY CASE WHEN _PartInd_ = 1 THEN 'Training' ELSE 'Validation' END, _PartInd_;")
)$`Result Set`


# Create two CASTable instances
train <- defCasTable(session, 'air_part', where="_PartInd_=1")  # 1
valid <- defCasTable(session, 'air_part', where="_PartInd_=0")

# Confirm that filtered rows show the same counts
cat("\n")
cat("Rows in training table:", nrow(train), "\n")
cat("Rows in validation table:", nrow(valid), "\n")


cas.table.columnInfo(session,table ="AIR2008" )

target   = "Cancelled"

nominals = c("UniqueCarrier", "Origin", "Dest")

inputs   = c("UniqueCarrier", "Origin", "Dest","DayOfWeek","Month")


# Load the decsion tree actionset
loadActionSet(session, 'decisionTree')

# Train the decision tree model
cas.decisionTree.dtreeTrain(train,
                            target   = target, 
                            inputs   = inputs, 
                            nominals = nominals,
                            varImp   = TRUE,
                            casOut   = list(name = 'dt_model', replace = TRUE)
)

# Score the validation data
cas.decisionTree.dtreeScore(valid,
                            modelTable   = list(name = 'dt_model'),
                            copyVars     = list(target, '_PartInd_'),
                            assessonerow = TRUE,
                            casOut       = list(name = 'dt_scored', replace = T)
)


cas.table.columnInfo(session,table ="dt_scored" )
# Assess the decision tree model
results <- cas.percentile.assess(session,
                                 table="dt_scored",
                                 inputs   = c('_DT_P_1'),
                                 response = target,
                                 event    = '1'
)

# View the 50% cutoff rate
results$ROCInfo[results$ROCInfo$CutOff==0.26, 
                c('CutOff', 'TP','FP','FN','TN')]

# Plot the ROC curve
ggplot(data = results$ROCInfo[c('FPR', 'Sensitivity')],
       aes(x = as.numeric(FPR), y = as.numeric(Sensitivity))) + geom_line() +
  labs(x = 'False Positive Rate', y = 'True Positive Rate')
