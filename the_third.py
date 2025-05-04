import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from xgboost import XGBRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error
df = pd.read_excel('output.xlsx')
df = df.dropna(subset=['generated_energy', 'radiant_quantity'])  # remove rows with missing key values
df['Time'] = pd.to_datetime(df['Time'])
df['hour'] = df['Time'].dt.hour
df['month'] = df['Time'].dt.month
df['date'] = df['Time'].dt.date
features = ['radiant_quantity', 'now_temp', 'wind_speed', 'humid', 'hour', 'month']
X = df[features]
y = df['generated_energy']
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
model = XGBRegressor(n_estimators=100, max_depth=5, learning_rate=0.1, objective='reg:squarederror', random_state=42)
model.fit(X_train, y_train)
df['predicted'] = model.predict(X)
df['residual'] = df['generated_energy'] - df['predicted']
df['predicted_generation'] = model.predict(df[features])
daily = df.groupby('date')[['generated_energy', 'predicted_generation']].sum().reset_index()


# Parameters
electricity_price = 0.4  # yuan/kWh
cleaning_cost = 2.0      # yuan/kW
threshold = cleaning_cost  # Can be adjusted

# Initialize
cumulative_loss = 0
cleaning_days = []

for i, row in daily.iterrows():
    actual = row['generated_energy']
    predicted = row['predicted_generation']
    loss = max(predicted - actual, 0) * electricity_price
    cumulative_loss += loss
    
    if cumulative_loss >= threshold:
        cleaning_days.append(row['date'])
        cumulative_loss = 0  # reset after cleaning

# Output cleaning decision days
print("Recommended cleaning days:")
for day in cleaning_days:
    print(day)


# Plotting

plt.figure(figsize=(12,5))
plt.plot(daily['date'], daily['predicted_generation'], label='Predicted')
plt.plot(daily['date'], daily['generated_energy'], label='Actual')
for d in cleaning_days:
    plt.axvline(pd.to_datetime(d), color='red', linestyle='--', alpha=0.5)
plt.legend()
plt.title("Predicted vs Actual Generation with Cleaning Points")
plt.xlabel("Date")
plt.ylabel("kWh")
plt.grid(True)
plt.tight_layout()
plt.show()





# 假设模型预测值已有列，这里为了示例我们用实际值的7日滑动平均作为"预测"
df['predicted_energy'] = df['generated_energy'].rolling(window=7, min_periods=1, center=True).mean()

# 计算每天的损失（预测-实际），负值设为0表示未损失
df['loss_kWh'] = np.maximum(df['predicted_energy'] - df['generated_energy'], 0)

# 电价（元/kWh）和清洗成本（元/kW），容量4998.30kWp
electricity_price = 0.4  # 元/kWh
installed_capacity = 4998.3  # kWp

# 损失金额（元）
df['loss_cost'] = df['loss_kWh'] * electricity_price

# 模拟不同清洗价格下的清洗策略
cleaning_prices = [1.0, 2.0, 3.0, 4.0]  # 元/kW
results = {}

for cost_per_kw in cleaning_prices:
    cleaning_cost = installed_capacity * cost_per_kw
    total_loss = 0
    clean_dates = []

    temp_loss = 0
    for i in range(len(df)):
        temp_loss += df.iloc[i]['loss_cost']
        if temp_loss >= cleaning_cost:
            # 决策清洗
            clean_dates.append(df.iloc[i]['Time'])
            total_loss += cleaning_cost
            temp_loss = 0
        else:
            total_loss += df.iloc[i]['loss_cost']

    results[cost_per_kw] = {
        'clean_dates': clean_dates,
        'total_cost': total_loss,
        'clean_count': len(clean_dates)
    }

# 可视化：不同清洗价格下的清洗次数与总成本
plt.rcParams['font.sans-serif'] = ['SimHei']
costs = [v['total_cost'] for v in results.values()]
counts = [v['clean_count'] for v in results.values()]
labels = [f"{k}元/kW" for k in results.keys()]

fig, ax1 = plt.subplots(figsize=(10, 5))

ax2 = ax1.twinx()
ax1.plot(labels, counts, 'g-', marker='o', label='清洗次数')
ax2.plot(labels, costs, 'b-', marker='s', label='总成本')

ax1.set_xlabel('清洗价格')
ax1.set_ylabel('累计清洗次数', color='g')
ax2.set_ylabel('总损失/清洗成本（元）', color='b')

plt.title('不同清洗价格下的动态清洗决策影响')
fig.tight_layout()
plt.grid(True)
plt.show()

results




