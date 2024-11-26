dir_InputFile="/srv/shiny-server/.InputDatabase"
#dir_InputFile="/Users/lawalr/Library/CloudStorage/Box-Box/GT-Analyses/Rshiny"
input_suffix=".metrics.txt"
setwd(dir_InputFile)
options(warn=-1) #Temporary turn off warnings
######################################################
#Quarterly metrics
#seqInputMetdata <- "/Users/lawalr/Library/CloudStorage/Box-Box/GT-Analyses/Rshiny/SequencingMetrics.csv"
seqInputMetdata <- "/srv/shiny-server/.InputDatabase/SequencingMetrics.csv"
seqMetdata <- read.csv(seqInputMetdata)
######################################################
#Main dashboard

#Function that read input file
InputFileReader <- function(input){
  read.table(input,
             header=TRUE, sep="\t", row.names=NULL) %>% tidyr::pivot_longer(
               cols=Reads_Total:Error_rate_PhiX_alignment_SD,
               values_transform = as.numeric)
}

atacseq <- InputFileReader("atacseq.metrics.txt")
chic <- InputFileReader("chic.metrics.txt")
ctp <- InputFileReader("ctp.metrics.txt")
pdxrnaseqR2 <- InputFileReader("pdxrnaseqR2.metrics.txt")
rnaseq <- InputFileReader("rnaseq.metrics.txt")
rrbs <- InputFileReader("rrbs.metrics.txt")
wgbs <- InputFileReader("wgbs.metrics.txt")
chipseq <- InputFileReader("chipseq.metrics.txt")
pdxrnaseq <- InputFileReader("pdxrnaseq.metrics.txt")
pdxwgs <- InputFileReader("pdxwgs.metrics.txt")
rnaseqR2 <- InputFileReader("rnaseqR2.metrics.txt")
wes <- InputFileReader("wes.metrics.txt")
wgs <- InputFileReader("wgs.metrics.txt")
basic <- InputFileReader("basic.metrics.txt")

