# xgboost_solar_forecast.py

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.model_selection import train_test_split
from xgboost import XGBRegressor
from sklearn.metrics import mean_squared_error, r2_score

# === 1. Load the dataset ===
# Replace with your actual filename
df = pd.read_excel('output.xlsx')
# Extract time-based features
df['generated_energy'] = df['generated_energy'].fillna(0)
df['hour'] = df['Time'].dt.hour
df['month'] = df['Time'].dt.month
df['Time'] = pd.to_datetime(df['Time'])
df['date'] = df['Time'].dt.date
# === 3. Select features and target ===
# Replace column names with your actual ones if different
features = [
    'radiant_quantity',     # solar irradiance
    'now_temp',   # ambient temperature
    'wind_speed',
    'humid',       # wind direction (categorical)        # weather condition (categorical)
    'hour',
    'month'
]
target = 'generated_energy'  # power generation

X = df[features]
y = df[target]

# === 4. Handle categorical features with one-hot encoding ===


# === 5. Split the data ===
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)

# === 6. Train XGBoost Regressor ===
model = XGBRegressor(
    n_estimators=100,
    max_depth=5,
    learning_rate=0.1,
    objective='reg:squarederror',
    random_state=42
)
model.fit(X_train, y_train)

# === 7. Make predictions ===
y_pred = model.predict(X_test)


# === 8. Evaluate model performance ===

mse = mean_squared_error(y_test, y_pred)
rmse = np.sqrt(mse)

r2 = r2_score(y_test, y_pred)

print(f'RMSE: {rmse:.2f}')
print(f'R² Score: {r2:.2f}')

# === 9. Visualize actual vs predicted generation ===
plt.figure(figsize=(10, 5))
plt.plot(np.arange(len(y_test)), y_test.values, label='Actual', alpha=0.7)
plt.plot(np.arange(len(y_pred)), y_pred, label='Predicted', alpha=0.7)
plt.xlabel('Sample Index')
plt.ylabel('Power Generation')
plt.title('XGBoost: Actual vs Predicted Generation')
plt.legend()
plt.tight_layout()
plt.show()

daily = df.groupby('date').agg({
    'generated_energy': 'sum',
    'radiant_quantity': 'sum'
}).reset_index()

# 计算每日效率（每单位辐射带来的发电量）
daily['efficiency'] = daily['generated_energy'] / (daily['radiant_quantity'] + 1e-6)

# 计算效率变化率
daily['eff_change'] = daily['efficiency'].pct_change()

# 判断是否清洗（效率提升显著，设定为30%阈值）
daily['is_cleaning'] = daily['eff_change'] > 0.3

# 输出疑似清洗日
cleaning_days = daily[daily['is_cleaning']]
print("Suspected cleaning dates:")
print(cleaning_days[['date', 'efficiency', 'eff_change']])






