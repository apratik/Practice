# copyright from airbnb winner's scripts
Folds <- 10
xgb_cv <- createFolds(1:nrow(df_train), k = Folds)
xgb_stack <- data.frame()
xgb_test_stack <- data.frame()
for(i in 1:Folds){ 
  # i <- 1
  set.seed(123 * i)
  xgb_id_ <- df_train[-xgb_cv[[i]], "ID"]
  xgb_fold_id_ <- df_train[xgb_cv[[i]], "ID"]
  xgb_sp_ <- df_train[-xgb_cv[[i]], ]
  xgb_fold_sp_ <- df_train[xgb_cv[[i]], ]
  xgb_y_ <- df_train_y[-xgb_cv[[i]],c("TARGET")]
  xgb_fold_y_ <- df_train_y[xgb_cv[[i]],c("TARGET")]
  
  dx_xgb <- sparse.model.matrix(TARGET ~ ., data = xgb_sp_)
  dx_xgb_fold <- sparse.model.matrix(TARGET ~ ., data = xgb_fold_sp_)
  
  dX_xgb_ <- xgb.DMatrix(dx_xgb, label = xgb_y_)
  dX_xgb_fold_ <- xgb.DMatrix(dx_xgb_fold, label = xgb_fold_y_)

  # watchlist <- list(train=dtrain_, eval = dtrain_cv_)
  param <- list(  objective           = "binary:logistic", 
                  booster             = "gbtree",
                  eval_metric         = "auc",
                  eta                 = 0.02,
                  max_depth           = 5,
                  subsample           = 0.7,
                  colsample_bytree    = 0.7, # auc0.842956 
                  min_child_weight    = 1,
                  nthread             = 24)
  if (i == 1){
    # Run Cross Valication
    cv.nround = 1200
    bst.cv = xgb.cv(param = param,
                    data = dX_xgb_, 
                    label = xgb_y_,
                    nfold = Folds,
                    nrounds = cv.nround,
                    verbose = 1,
                    early.stop.round = 20,
                    maximize = T)
    saveRDS(bst.cv, paste0("cache/train/xgb_bst_cv.RData"))
    print(paste0("best test-auc" , max(bst.cv$test.auc.mean),"\n"))
  }

  # train the finnal model
  xgb.stack <- xgb.train(params= param, 
                                    data = dX_xgb_, 
                                    nrounds = which.max(bst.cv$test.auc.mean), 
                                    verbose = 1,
                                    # watchlist  = watchlist,
                                    maximize = T)
# 存储结果；
# saveRDS(xgb.clf.impact.train, file = "cache/xgb.clf.full.impact.train.Rdata")

  # predict test result
  y_xgb_fold_ <- predict(xgb.stack, dX_xgb_fold_)
  y_xgb_fold_pred <- as.data.frame(cbind(pred = y_xgb_fold_ , id = xgb_fold_id_))
  xgb_stack <- rbind(xgb_stack, y_xgb_fold_pred)
  
  y_xgb_test_ <- predict(xgb.stack, dtest_)
  y_xgb_test_df_ <- as.data.frame(y_xgb_test_)
  y_xgb_test_df_$id <- df_test$ID
  xgb_test_stack <- rbind(y_xgb_test_df_,
                              xgb_test_stack)
  print(paste0(i, "folds finished\n"))
}

xgb_test_stack <- xgb_test_stack %>%
  group_by(id) %>%
  summarise_each(funs(mean))


pred_stack <- xgb_test_stack%>%mutate(pred = (y_xgb_test_-min(y_xgb_test_))/(max(y_xgb_test_)-min(y_xgb_test_)))
summary(pred_stack$pred)
summary(pred_stack$y_xgb_test_)

# xgb_stack <- melt.data.table(as.data.table(xgb_stack))
# xgb_stack <- data.frame(xgb_stack)
# names(xgb_stack) <- c("id", "feature", "value")

tmp_train <- dplyr::inner_join(x= df_train_y, xgb_stack, by =c("ID" = "ID"))
glm_fit <- glmnet::glmnet(x= tmp_train$pred, y = tmp_train$TARGET, family = "binomial")

# xgb_test_stack <- melt.data.table(as.data.table(xgb_test_stack))
# xgb_test_stack <- data.frame(xgb_test_stack)
# names(xgb_test_stack) <- c("id", "feature", "value")

saveRDS(xgb_stack, paste0("cache/train/xgb_stack.RData"))
saveRDS(xgb_test_stack, paste0("cache/train/xgb_test_stack.RData"))
gc()

summary(xgb_test_stack$y_xgb_test_)

# 查看变量重要性；
feature.names <-  dtrain@Dimnames[[2]]
imp.feature <- xgb.importance(feature_names = feature.names, model = xgb.clf.impact)
xgb.plot.importance(imp.feature[1:30,])

# pred test result
preds_test <- predict(xgb.clf.impact.full, dtest_)
preds_cv <- predict(xgb.clf.impact.full, dtrain_cv_)
print(paste0("auc=",gbm::gbm.roc.area(dtrain_cv$TARGET, preds_cv))) # 0.854782178707523
summary(df_test$preds_test)
summary(first$TARGET)

# stacked the model
preds_test_cv <- predict(xgb.clf.impact.cv, dtest_)
preds_test_x <- predict(xgb.clf.impact.train, dtest_)
preds_test <- 0.5*(preds_test_cv+preds_test_x)

df_train_x$preds_train <- predict(xgb.clf.impact.full.cv, dtest_)
# ***********************************************************
# eval the result
# **********************************************************
# look at PR Curve
pred.result <- ROCR::prediction(preds_cv, dtrain_cv$TARGET)
perf.result <- ROCR::performance(pred.result, "prec", "rec")
plot(perf.result)
title("Precision&Recall curve in submissionv8")

ggplot()+geom_line(data = perf.result, aes(x= perf.result@x.values, y = perf.result@y.values))

first <- read.csv(file = 'result/submission.csv')
ggplot()+geom_histogram(data = first, aes(x=TARGET))+geom_histogram(aes(x=pred_stack$pred), color = "red")
# submission result
submissionv_stackv1 <- data.frame(ID=xgb_test_stack$id, TARGET=xgb_test_stack$y_xgb_test_)
cat("saving the submission file\n")
write.csv(submissionv_stackv1, "result/submissionv_stackv1.csv", row.names = F)

stack1 <- read.csv(file = 'result/submission_stack_v1.csv')
summary(stack1)
summary(first$TARGET)

