import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import matplotlib.dates as mdates
# 步骤一：统一时间格式并按小时重采样
df['时间'] = pd.to_datetime(df['时间'])
df_hourly = df.set_index('时间').resample('1H').mean().reset_index()
df['发电量'] = df['发电量'].interpolate(method='linear')
df['天气'] = df['天气'].fillna(method='ffill')
from scipy.stats import zscore
df['zscore'] = zscore(df['发电量'])
df = df[df['zscore'].abs() < 3]
Q1 = df['发电量'].quantile(0.25)
Q3 = df['发电量'].quantile(0.75)
IQR = Q3 - Q1
df = df[(df['发电量'] >= Q1 - 1.5*IQR) & (df['发电量'] <= Q3 + 1.5*IQR)]
df_hourly.to_csv("cleaned_hourly_data.csv", index=False)
import pandas as pd
import xgboost as xgb
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_absolute_error, r2_score
from sklearn.preprocessing import LabelEncoder

# 1. 读取数据
df = pd.read_csv('your_data.csv', parse_dates=['时间'])

# 2. 特征构造
df['hour'] = df['时间'].dt.hour
df['month'] = df['时间'].dt.month
df['dayofweek'] = df['时间'].dt.dayofweek

# 3. 类别型变量编码
le = LabelEncoder()
df['天气编码'] = le.fit_transform(df['天气'])
df['风向编码'] = le.fit_transform(df['风向'])

# 4. 特征和标签
features = ['辐照强度', '环境温度', '风速', '湿度', '风向编码', '天气编码', 'hour', 'month']
X = df[features]
y = df['发电量']

# 5. 拆分训练集和测试集
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# 6. XGBoost建模
model = xgb.XGBRegressor(n_estimators=100, learning_rate=0.1, max_depth=5)
model.fit(X_train, y_train)

# 7. 模型评估
y_pred = model.predict(X_test)
print("MAE:", mean_absolute_error(y_test, y_pred))
print("R²:", r2_score(y_test, y_pred))
