library("kernlab")
library("caret")
library("tm")
library("dplyr")
library("splitstackshape")

# step 1. ingest your corpus training data
corpus1 <- VCorpus(DirSource("Train", encoding = "UTF-8"), readerControl=list(language="English"))
corpus1 <- tm_map(corpus1, content_transformer(stripWhitespace))
corpus1 <- tm_map(corpus1, content_transformer(tolower))
corpus1 <- tm_map(corpus1, content_transformer(removeNumbers))
corpus1 <- tm_map(corpus1, removeWords, stopwords("English")) ## inspect your stopword lists
corpus1 <- tm_map(corpus1, content_transformer(removePunctuation))
corpus1 <- tm_map(corpus1, stemDocument, language = "english") # stem your words

corpus1.dtm<-DocumentTermMatrix(corpus1, control=list(wordLengths=c(1,Inf)))
#corpus1.matrix<-as.matrix(corpus1.dtm, stringsAsFactors=F)

#create your document term matrix
corpus2 <- VCorpus(DirSource("Predict", encoding = "UTF-8"), readerControl=list(language="English"))

corpus2 <- tm_map(corpus2, content_transformer(stripWhitespace))
corpus2 <- tm_map(corpus2, content_transformer(tolower))
corpus2 <- tm_map(corpus2, content_transformer(removeNumbers))
corpus2 <- tm_map(corpus2, removeWords, stopwords("English")) ## inspect your stopword lists
corpus2 <- tm_map(corpus2, content_transformer(removePunctuation))
corpus2 <- tm_map(corpus2, stemDocument, language = "english") # stem your words

#create your document term matrix
corpus2.dtm<-DocumentTermMatrix(corpus2, control=list(wordLengths=c(1,Inf)))
#corpus2.matrix<-as.matrix(corpus2.dtm, stringsAsFactors=F)




# convert to matrices for subsetting
c1 <- as.matrix(corpus1.dtm, stringsAsFactors= FALSE) # training
c2 <- as.matrix(corpus2.dtm, stringsAsFactors= FALSE) # testing

c1.df <- data.frame(c1[,intersect(colnames(c1), colnames(c2))])
c2.df <- data.frame(c2[,intersect(colnames(c2), colnames(c1))])


label.df<-data.frame(row.names(c1.df))
colnames(label.df)<-c("filenames")
label.df<-cSplit(label.df, 'filenames', sep="_", type.convert=FALSE)
c1.df$corpus<- label.df$filenames
c2.df$corpus <- c("Pos")


#first create folds
folds<-createFolds(c1.df$corpus, k=10) # k = number of folds (1-10) where 10 is best

#use this section to run 1x and inspect your confusion matrix
x<-folds$Fold01 #use this line of k = 10
# x<-folds$Fold1 #use this line if k is less than 10; change to Fold2 for the second fold etc.
df.train<- c1.df
df.test<-c1.df
df.model<-ksvm(corpus ~ ., data=df.train, kernel="rbfdot")
df.pred<-predict(df.model, df.test)
con.matrix<-confusionMatrix(df.pred, df.test$corpus)

con.matrix$byClass[[7]] #F1 score (combination of precision and recall)
con.matrix$overall[[6]] #pvalue

#run x-fold cross validation
cv.results<-lapply(folds, function(x){
  df.train<-df[-x,]
  df.test<-df[x,]
  df.model<-ksvm(corpus ~ ., data=df.train, kernel="rbfdot")
  df.pred<-predict(df.model, df.test)
  #con.matrix<-confusionMatrix(df.pred, df.test$corpus, positive = "Like")
  #f1<-con.matrix$byClass[[7]]
})
unlist(cv.results) #this shows you the F1 score for each fold
mean(unlist(cv.results)) #this is the average F1 score for all folds


mat <- as.data.frame(df.pred)
rownames(mat) <- rownames(c1.df)
write.csv(mat, "results.csv")

