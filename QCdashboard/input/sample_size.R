total_database_samples <- length(unique(atacseq$Sample_Name))+length(unique(chic$Sample_Name))+length(unique(ctp$Sample_Name))+
  length(unique(pdxrnaseqR2$Sample_Name))+length(unique(rnaseq$Sample_Name))+length(unique(rrbs$Sample_Name))+
  length(unique(wgbs$Sample_Name))+length(unique(chipseq$Sample_Name))+length(unique(pdxrnaseq$Sample_Name))+
  length(unique(pdxwgs$Sample_Name))+length(unique(rnaseqR2$Sample_Name))+length(unique(wes$Sample_Name))+
  length(unique(wgs$Sample_Name))+length(unique(basic$Sample_Name))
