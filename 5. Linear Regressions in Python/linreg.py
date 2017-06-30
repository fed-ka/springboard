import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.linear_model import LinearRegression

data = pd.read_csv('lsd.csv')
data.head()

X = data['Tissue Concentration'].values[:,np.newaxis]
y = data['Test Score'].values

model = LinearRegression()
model.fit(X, y)

plt.scatter(X, y,color='r')
plt.plot(X, model.predict(X),color='k')
plt.show()
