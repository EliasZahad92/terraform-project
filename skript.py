import pandas as pd 
import matplotlib.pyplot as plt 
import numpy as np 

df = pd.read_csv("/home/ec2-user/monthly_csv.csv", parse_dates=["Date"])
df.dropna(subset=["Mean"], inplace=True)
print(df.head())

x = np.arange(len(df))
y = df["Mean"]

z = np.polyfit(x,y,2)
p = np.poly1d(z)

df["Trendlinie"] = p(x)

plt.plot(df["Date"], df["Mean"], linestyle="--", marker="o", color="blue", label="Dataset Temperature", alpha=0.4)
plt.plot(df["Date"], df["Trendlinie"], linestyle="-", marker="o", color="black", label="Trend", alpha=0.4, linewidth=0.5)
plt.xlabel("Jahr")
plt.ylabel("Mittlere Abweichung")
plt.title("Temperaturänderung über Jahr")
plt.legend()
plt.tight_layout()
plt.show()

