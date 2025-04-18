Sys.time()
# Input folder
InputFolderName = "./Step1_Output/"
#Create an outer folder to collect all images.
ThisStep_OutputFolderName <- "./Step4_Output"
if (file.exists(ThisStep_OutputFolderName)){
    unlink(ThisStep_OutputFolderName, recursive=TRUE)  #delete the folder if already exists.
} 
dir.create(ThisStep_OutputFolderName)

FolderName_0 <- paste0(ThisStep_OutputFolderName, "/ImageCollection/")
dir.create(FolderName_0)


#Create an inner folder for each image. The order is based on the "ImageNameList.txt".
ImageNameList <- read.csv(paste(c("./", InputFolderName, "ImagePatchNameList.txt"), collapse = ''), header = FALSE)
for (k in 1:nrow(ImageNameList)) {
  FolderName_1 <- paste(c(FolderName_0, ImageNameList[k, 1]), collapse = '')
  if (file.exists(FolderName_1)) {
    
    cat("The folder already exists!")
    
  } else {
    
    dir.create(FolderName_1)
    
  }
  
}


#Find all subfolder names with "Run".
dirs <- list.dirs(recursive = TRUE)
Run_FolderName <- grep("Run", dirs, value = TRUE)

for (p in 1:length(Run_FolderName)) {
  print(paste(c("This is Run", p, "/", length(Run_FolderName)), collapse = '')) #12s/model.
  
  for (q in 1:nrow(ImageNameList)) {
    ClusterAssignMatrix1_FileName <- paste(c(Run_FolderName[p], "/ClusterAssignMatrix1_", q-1, ".csv"), collapse = '') #"q-1" is for 0-based Python indexing.
    NodeMask_FileName <- paste(c(Run_FolderName[p], "/NodeMask_", q-1, ".csv"), collapse = '') #"q-1" is for 0-based Python indexing.
    
    ImageName <- ImageNameList[q, 1]
    
    #Extract the useful string for renaming.
    ImpStr <- strsplit(Run_FolderName[p], "/")
    RunName <- ImpStr[[1]][3]
    
    #Copy the "ClusterAssignMatrix1_xx.csv" file and "NodeMask_xx.csv" file and rename them in the collected image folder.
    ImageName_FolderName <- paste(c(FolderName_0, ImageName), collapse = '')
    
    file.copy(ClusterAssignMatrix1_FileName, ImageName_FolderName)
    OldName <- paste(c(ImageName_FolderName, "/ClusterAssignMatrix1_", q-1, ".csv"), collapse = '')
    NewName <- paste(c(ImageName_FolderName, "/ClusterAssignMatrix1_", RunName, ".csv"), collapse = '')
    file.rename(OldName, NewName)
    
    file.copy(NodeMask_FileName, ImageName_FolderName)
    OldName <- paste(c(ImageName_FolderName, "/NodeMask_", q-1, ".csv"), collapse = '')
    NewName <- paste(c(ImageName_FolderName, "/NodeMask_", RunName, ".csv"), collapse = '')
    file.rename(OldName, NewName)
    
  }
  
}


Sys.time()
rm(list = ls())
library(diceR)
ThisStep_OutputFolderName <- "./Step4_Output/"
Image_dirs <- list.dirs(path = paste0(ThisStep_OutputFolderName, "ImageCollection"), recursive = FALSE)

for (kk in 1:length(Image_dirs)) {
  print(paste(c("This is Patch", kk, "/", length(Image_dirs)), collapse = '')) #10s/Patch.
  
  #Import data.
  NodeMask_FileName <- paste(c(Image_dirs[kk], "/NodeMask_Run1.csv"), collapse = '')
  NodeMask <- read.csv(NodeMask_FileName, header = FALSE)
  nonzero_ind <- which(NodeMask$V1 == 1)
  
  #Find the file names of all soft clustering results.
  allSoftClustFile <- list.files(path = Image_dirs[kk], pattern = "ClusterAssignMatrix1", recursive = TRUE)
  allHardClustLabel <- vector()
  
  for (i in 1:length(allSoftClustFile)) {
    
    SoftClust_FileName <- paste(c(Image_dirs[kk], "/", allSoftClustFile[i]), collapse = '')
    ClustMatrix <- read.csv(SoftClust_FileName, header = FALSE, sep = ",")
    ClustMatrix <- ClustMatrix[nonzero_ind,]
    HardClustLabel <- apply(as.matrix(ClustMatrix), 1, which.max)
    rm(ClustMatrix)
    
    allHardClustLabel <- cbind(allHardClustLabel, as.vector(HardClustLabel))
    
  } #end of for.
  
  
  finalClass <- diceR::majority_voting(allHardClustLabel, is.relabelled = FALSE)
  finalClass_FileName <- paste(c(Image_dirs[kk], "/TCNLabel_MajorityVoting.csv"), collapse = '')
  write.table(finalClass, file = finalClass_FileName, append = FALSE, quote = FALSE, row.names = FALSE, col.names = FALSE)

}

print("Step4 done!")
Sys.time()


