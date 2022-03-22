library(tidyverse) 
library(quanteda)
library(quanteda.textplots)
library("quanteda.textmodels")
library(caret)
library(wordcloud)
library(doParallel)
library(caretEnsemble)
library(sparklyr)
library(dbplot)

sc <- spark_connect(master = "local", version = "2.3")

train_org <- spark_read_csv(sc, "train.csv", escape = "\"", options = list(multiline = TRUE))
test_org <- spark_read_csv(sc, "test.csv", escape = "\"", options = list(multiline = TRUE))

combine_org <- rbind(train_org %>% mutate(source = "train"), test_org %>% mutate(target = NA, source="test"))
combine_org

# Exploring the training dataset.
# Generate some potential variable and only retain rows with text
train <- train_org %>% 
  mutate(target = as.character(target),
         is_keyword = as.character(ifelse(is.na(keyword), 0, 1)),
         is_location = as.character(ifelse(is.na(location), 0, 1)),
         text_length = nchar(text)) %>%
  filter(!is.na(text)) %>% 
  select(id, is_keyword, keyword, is_location, text, text_length, target)

count(train)

# Get the proportion of target
train %>% group_by(target) %>% summarise(cnt = n()) %>% mutate(pcnt = cnt/sum(cnt))

# Distribution of other variables against target
train %>% 
  ggplot() + 
  geom_density(aes(x=text_length, color = target)) + 
  ggtitle("text_length distribution within target")

train %>% 
  ggplot() + 
  geom_bar(aes(x=target, fill=as.factor(is_keyword)), position = "fill")

train %>% 
  ggplot() + 
  geom_bar(aes(x=target, fill=as.factor(is_keyword)), position = "fill")


# Create pipeline
pipeline <- ml_pipeline(sc) %>%  
  mutate(cleaned=lower(text))%>%
  mutate(cleaned = regexp_replace(text, "(@|http)[^ ]*", " ")) %>%
  mutate(cleaned = regexp_replace(cleaned, "[^a-z]", " ")) %>% 
  ft_tokenizer(input_col = "cleaned", output_col = "words") %>% 
  ft_stop_words_remover(input_col = "words", output_col = "cleaned_words") %>% 
  ft_count_vectorizer(input_col = "cleaned_words", output_col="terms",
                      min_df=5, binary=TRUE) %>% 
  ft_vector_assembler(input_cols = "terms",output_col="features") %>% 
  
  
## Use LSA 
train_dfm <- combine_tokens_dfm %>% dfm_subset(source=="train")
dim(train_dfm)

trainlsa <- textmodel_lsa(dfm_tfidf(train_dfm), nd = 200)
testlsa <- predict(trainlsa, newdata = dfm_tfidf(combine_tokens_dfm %>% dfm_subset(source=="test")))


train_df <- data.frame(target = as.factor(ifelse(train_dfm$target == 0, "No", "Yes")), trainlsa$docs)
names(train_df) <- make.names(names(train_df))

test_df <- data.frame(as.matrix(testlsa$docs_newspace))

set.seed(1)
cv.folds <- createMultiFolds(train_df$target, k = 10, times = 3)
cv.cntrl <- trainControl(method = "repeatedcv", number = 5, repeats = 3, 
                         index = cv.folds, summaryFunction = twoClassSummary, classProbs = T,
                         allowParallel = TRUE, savePredictions = TRUE)

cl <- makeCluster(3)
registerDoParallel(cl)
getDoParWorkers()

set.seed(1)
model_list <- caretList(target ~ ., data = train_df,
                        trControl = cv.cntrl, methodList = c("glmnet", "rf", "gbm"),
                        tuneList = NULL, continue_on_fail = F)


set.seed(1)
ensemble_1 <- caretStack(model_list, method = "glmnet",
                         metric = "ROC", 
                         trControl = cv.cntrl)
ensemble_1

stopCluster(cl)


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





