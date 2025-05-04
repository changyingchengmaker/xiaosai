import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.model_selection import train_test_split
from xgboost import XGBRegressor
from sklearn.metrics import mean_squared_error, r2_score
plt.rcParams['font.sans-serif'] = ['SimHei']

#1. Load the dataset 
df = pd.read_excel('output.xlsx')
df['generated_energy'] = df['generated_energy'].fillna(0)
df['hour'] = df['Time'].dt.hour
df['month'] = df['Time'].dt.month
df['date'] = df['Time'].dt.date

#2. Select features and target =
features = ['radiant_quantity','now_temp', 'wind_speed','humid','hour','month']
target = 'generated_energy' 
X = df[features]
y = df[target]
#3. Split the data 
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

#4. Train XGBoost Regressor
model = XGBRegressor(n_estimators=100,max_depth=5,learning_rate=0.1,objective='reg:squarederror',random_state=42)
model.fit(X_train, y_train)

#5. Make predictions
y_pred = model.predict(X_test)
#6. Evaluate model performance

mse = mean_squared_error(y_test, y_pred)
rmse = np.sqrt(mse)
r2 = r2_score(y_test, y_pred)
print(f'RMSE: {rmse:.2f}')
print(f'R² Score: {r2:.2f}')

#7. Visualize actual vs predicted generation
plt.figure(figsize=(10, 5))
plt.plot(np.arange(len(y_test)), y_test.values, label='实际', alpha=0.7)
plt.plot(np.arange(len(y_pred)), y_pred, label='预测', alpha=0.7)
plt.xlabel('样本索引')
plt.ylabel('发电量')
plt.title('XGBoost: 实际 vs 预测发电量')
plt.legend()
plt.tight_layout()
plt.show()

df['predicted'] = model.predict(X)
df['residual'] = df['generated_energy'] - df['predicted']

# === 6. Daily residual mean ===
daily_error = df.groupby('date')['residual'].mean().reset_index()

# === 7. Detect cleaning events (spikes in actual generation) ===
# A cleaning is assumed when residual increases sharply
daily_error['delta'] = daily_error['residual'].diff()
threshold = daily_error['delta'].mean() + 2 * daily_error['delta'].std()
cleaning_days = daily_error[daily_error['delta'] > threshold]['date']
daily_error['is_cleaning'] = daily_error['delta'] > threshold

# daily_error.to_excel('daily_error.xlsx', index=False)
print(cleaning_days)
daily_error.to_excel('daily.xlsx', index=False)
# === 8. Plot ===
plt.figure(figsize=(12, 6))
plt.plot(daily_error['date'], daily_error['delta'], label='日平均残差')
plt.scatter(cleaning_days, daily_error[daily_error['date'].isin(cleaning_days)]['residual'], color='red', label='清洗点')
plt.axhline(0, color='gray', linestyle='--')
plt.xlabel('日期')
plt.ylabel('残差（实际-理论）')
plt.title('通过残差分析检测光伏板清洁事件')
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.show()






