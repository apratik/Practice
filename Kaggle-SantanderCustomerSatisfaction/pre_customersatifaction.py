# This Python 3 environment comes with many helpful analytics libraries installed
# It is defined by the kaggle/python docker image: https://github.com/kaggle/docker-python
# For example, here's several helpful packages to load in 
from __future__ import division

import numpy as np
import pandas as pd
import xgboost as xgb
from sklearn.cross_validation import train_test_split
from sklearn.metrics import roc_auc_score

# Input data files are available in the "../input/" directory.
# For example, running this (by clicking run or pressing Shift+Enter) will list the files in the input directory

#from subprocess import check_output
#print(check_output(["ls", "../input"]).decode("utf8"))

# Any results you write to the current directory are saved as output.

import os
os.chdir('/Users/ppj/Documents/Practice/SantanderCustomerSatisfaction')

# load data
df_train= pd.read_csv('/Users/ppj/Documents/Practice/SantanderCustomerSatisfaction/cache/df_train.csv')
df_test = pd.read_csv('/Users/ppj/Documents/Practice/SantanderCustomerSatisfaction/cache/df_test.csv')

# remove constant columns
#remove = []
#for col in df_train.columns:
#    if df_train[col].std() == 0:
#        remove.append(col)
#
#df_train.drop(remove, axis=1, inplace=True)
#df_test.drop(remove, axis=1, inplace=True)
#
## remove duplicated columns
#remove = []
#c = df_train.columns
#for i in range(len(c)-1):
#    v = df_train[c[i]].values
#    for j in range(i+1,len(c)):
#        if np.array_equal(v,df_train[c[j]].values):
#            remove.append(c[j])
#
#df_train.drop(remove, axis=1, inplace=True)
#df_test.drop(remove, axis=1, inplace=True)

y_train = df_train['TARGET'].values
X_train = df_train.drop(['ID','TARGET'], axis=1).values

id_test = df_test['ID']
X_test = df_test.drop(['ID'], axis=1).values

# length of dataset
len_train = len(X_train)
len_test  = len(X_test)

# classifier
clf = xgb.XGBClassifier(missing=np.nan, max_depth=5, n_estimators=560, learning_rate=0.02, nthread=4, subsample=0.7, colsample_bytree=0.7, seed=4242)

X_fit, X_eval, y_fit, y_eval= train_test_split(X_train, y_train, test_size=0.3)

# fitting
clf.fit(X_train, y_train, early_stopping_rounds=20, eval_metric="auc", eval_set=[(X_eval, y_eval)])

print('Overall AUC:', roc_auc_score(y_train, clf.predict_proba(X_train)[:,1]))  # 0.88539556507615758

# predicting
y_pred= clf.predict_proba(X_test)[:,1]

submission = pd.DataFrame({"ID":id_test, "TARGET":y_pred})
submission.to_csv("result/submission_xgb_v2.csv", index=False)

submission['TARGET'].describe()

print('Completed!')