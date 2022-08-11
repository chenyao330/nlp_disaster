library(tidyverse) 
library(quanteda)
library(quanteda.textplots)
library("quanteda.textmodels")
library(caret)
library(wordcloud)
library(doParallel)
library(caretEnsemble)

train_org <- read.csv("train.csv")
test_org <- read.csv("test.csv")

combine_org <- rbind(train_org %>% mutate(source = "train"), test_org %>% mutate(target = NA, source="test"))
str(combine_org)

# Exploring the training dataset.
# Generate some potential variable and only retain rows with text
train <- train_org %>% 
  mutate(target = as.factor(target),
         is_keyword = ifelse(keyword=="", 0, 1),
         is_location = ifelse(location=="", 0, 1),
         text_length = nchar(text)) %>%
  filter(!text=="") %>% 
  select(id, is_keyword, keyword, is_location, text, text_length, target)

nrow(train)

# Get the proportion of target
train %>% group_by(target) %>% summarise(cnt = n()) %>% mutate(pcnt = cnt/sum(cnt))

# Distribution of other variables against target
train %>% 
  ggplot() + 
  geom_density(aes(x=text_length, color = target)) + 
  ggtitle("text_length distribution within target")

train %>% 
  ggplot() + 
  geom_bar(aes(x=target, fill=as.factor(is_location)), position = "fill")

train %>% 
  ggplot() + 
  geom_bar(aes(x=target, fill=as.factor(is_keyword)), position = "fill")


# Create the document-feature matrix
quanteda_options("pattern_hashtag" = NULL) # Stop preserving the hashtag 
combine_corpus <- corpus(combine_org, text_field = "text")
combine_tokens <- combine_corpus %>% 
  tokens(what = "word",
         remove_numbers = TRUE, remove_punct = TRUE,
         remove_symbols = TRUE, remove_url = TRUE) %>% 
  tokens_remove(stopwords("english")) %>% 
  tokens_remove(pattern = "@.", valuetype = "regex") %>% 
  tokens_split(separator = "[[:digit:]]", valuetype = "regex") %>% 
  tokens_remove(pattern = c("?")) %>% 
  tokens_wordstem(language = quanteda_options("language_stemmer")) %>% 
  tokens_tolower()

combine_tokens_dfm <- dfm(combine_tokens)
dim(combine_tokens_dfm)

## Use LSA 
train_dfm <- combine_tokens_dfm %>% dfm_subset(source=="train")
dim(train_dfm)

trainlsa <- textmodel_lsa(dfm_tfidf(train_dfm), nd = 200)
train_df <- data.frame(target = as.factor(ifelse(train_dfm$target == 0, "No", "Yes")), trainlsa$docs, length = train$text_length)
names(train_df) <- make.names(names(train_df))

testlsa <- predict(trainlsa, newdata = dfm_tfidf(combine_tokens_dfm %>% dfm_subset(source=="test")))
test_df <- data.frame(as.matrix(testlsa$docs_newspace), length = nchar(test_org$text))

set.seed(1)
cv.folds <- createMultiFolds(train_df$target, k = 10, times = 5)
cv.cntrl <- trainControl(method = "repeatedcv", number = 10, repeats = 5, 
                         index = cv.folds, summaryFunction = twoClassSummary, classProbs = T,
                         allowParallel = TRUE, savePredictions = TRUE)#index specification takes priority over the resampling type specified by number/repeats


start_time <- Sys.time()

numCores <- detectCores()
cl <- makeCluster(numCores)
registerDoParallel(cl)

set.seed(1)

model_list <- caretList(target ~ ., data = train_df,
                        trControl = cv.cntrl, methodList = c("glmnet", "rf", "gbm"),
                        tuneList = NULL, continue_on_fail = F)

stopCluster(cl)

end_time <- Sys.time()
process_time <- end_time - start_time


# Check if the model correlated. The less correlated the better ensembled
#modelCor(resamples(model_list))

#https://cran.r-project.org/web/packages/caretEnsemble/vignettes/caretEnsemble-intro.html 
#Non-linear ensembles seem to work best when you have:
#Lots of data.
#Lots of models with similar accuracies.
#Your models are uncorrelated: each one seems to capture a different aspect of the data, and different models perform best on different subsets of the data.

set.seed(1)
ensemble_1 <- caretStack(model_list, method = "glmnet",
                         metric = "ROC", 
                         #DO NOT use the trainControl object you used to fit the training models to fit the ensemble. The re-sampling indexes will be wrong.
                         #trControl = cv.cntrl,
                         trControl = trainControl(
                           method="boot",
                           number=10,
                           savePredictions="final",
                           classProbs=TRUE,
                           summaryFunction=twoClassSummary
                         ))

# Check if ensemble model is better
summary(ensemble_1)

# Can also confirm the better model by using 'caTools'
#library("caTools")
#model_preds <- lapply(model_list, predict, newdata=testing, type="prob")
#model_preds <- lapply(model_preds, function(x) x[,"M"])
#model_preds <- data.frame(model_preds)
#ens_preds <- predict(greedy_ensemble, newdata=testing, type="prob")
#model_preds$ensemble <- ens_preds
#caTools::colAUC(model_preds, testing$Class)




pred <- predict(ensemble_1, test_df, type='raw')

submission <- read.csv("sample_submission.csv")
str(submission)
submission$target <- ifelse(pred == "Yes", 1, 0)
write_csv(submission, "submission.csv")








## Manually select variable

combine_tokens_dfm <- dfm_trim(combine_tokens_dfm,min_termfreq = 5, min_docfreq = 2)
dim(combine_tokens_dfm)

topfeatures(combine_tokens_dfm, n=20)
textplot_wordcloud(combine_tokens_dfm %>% dfm_subset(source=="train") %>% dfm_subset(target==1), min_count = 50, color = brewer.pal(10, "BrBG")) 
title("Most frequent words in disaster tweets", col.main = "grey14")

textplot_wordcloud(combine_tokens_dfm %>% dfm_subset(source=="train") %>% dfm_subset(target==0), min_count = 50, color = brewer.pal(10, "BrBG")) 
title("Most frequent words in non-disaster tweets", col.main = "grey14")

combine_tdm <- TermDocumentMatrix(combine_tokens)



## Create ngram tokens
combine_bigram <- tokens_ngrams(combine_tokens, n=2)
combine_bigram_dfm <- dfm(combine_bigram)
dim(combine_bigram_dfm)

topfeatures(combine_bigram_dfm, n=20)

textplot_wordcloud(combine_bigram_dfm %>% dfm_subset(source=="train") %>% dfm_subset(target==1), min_count = 10, color = brewer.pal(10, "BrBG")) 
title("Most frequent bigram in disaster tweets", col.main = "grey14")

textplot_wordcloud(combine_bigram_dfm %>% dfm_subset(source=="train") %>% dfm_subset(target==0), min_count = 10, color = brewer.pal(10, "BrBG")) 
title("Most frequent bigram in non-disaster tweets", col.main = "grey14")

# Creating training data as 70% of the dataset
set.seed(1)





