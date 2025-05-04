import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from xgboost import XGBRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error

# === 1. Load data ===
df = pd.read_excel('output.xlsx')

# === 2. Basic preprocessing ===
df = df.dropna(subset=['generated_energy', 'radiant_quantity'])  # remove rows with missing key values
df['Time'] = pd.to_datetime(df['Time'])
df['hour'] = df['Time'].dt.hour
df['month'] = df['Time'].dt.month
df['date'] = df['Time'].dt.date

# === 3. Features and target ===
features = ['radiant_quantity', 'now_temp', 'wind_speed', 'humid', 'hour', 'month']
X = df[features]
y = df['generated_energy']

# === 4. Train model ===
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
model = XGBRegressor(n_estimators=100, max_depth=5, learning_rate=0.1, objective='reg:squarederror', random_state=42)
model.fit(X_train, y_train)

# === 5. Predict all data ===
df['predicted'] = model.predict(X)
df['residual'] = df['generated_energy'] - df['predicted']

# === 6. Daily residual mean ===
daily_error = df.groupby('date')['residual'].mean().reset_index()

# === 7. Detect cleaning events (spikes in actual generation) ===
# A cleaning is assumed when residual increases sharply
daily_error['delta'] = daily_error['residual'].diff()
threshold = daily_error['delta'].mean() + 2 * daily_error['delta'].std()
cleaning_days = daily_error[daily_error['delta'] > threshold]['date']

print("Possible cleaning days:")
print(cleaning_days)

# === 8. Plot ===
plt.figure(figsize=(12, 6))
plt.plot(daily_error['date'], daily_error['residual'], label='Daily Mean Residual')
plt.scatter(cleaning_days, daily_error[daily_error['date'].isin(cleaning_days)]['residual'], color='red', label='Cleaning Point')
plt.axhline(0, color='gray', linestyle='--')
plt.xlabel('Date')
plt.ylabel('Residual (Actual - Predicted)')
plt.title('Detecting PV Panel Cleaning Events by Residual Analysis')
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.show()




