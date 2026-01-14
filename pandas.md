# Pandas

## Handling NaN Values

### Delete rows with NaN

```python
# Drop rows with any NaN
df.dropna()

# Drop rows where all values are NaN
df.dropna(how='all')

# Drop rows with NaN in specific columns
df.dropna(subset=['col1', 'col2'])
```

### Fill NaN with constant

```python
# Fill all NaN with a value
df.fillna(0)

# Fill NaN in specific column
df['col'].fillna(0)

# Fill with different values per column
df.fillna({'col1': 0, 'col2': 'unknown'})

# Fill with column mean
df.fillna(df.mean())

# Fill specific column with its mean
df['col'].fillna(df['col'].mean())

# Fill with row mean
df.apply(lambda row: row.fillna(row.mean()), axis=1)
```

## GroupBy

```python
# Basic groupby with single aggregation
df.groupby('category').sum()

# Multiple aggregations on all columns
df.groupby('category').agg(['sum', 'mean', 'count'])

# Different aggregations per column
df.groupby('category').agg({
    'sales': 'sum',
    'price': 'mean',
    'quantity': ['min', 'max']
})

# Named aggregations (cleaner output)
df.groupby('category').agg(
    total_sales=('sales', 'sum'),
    avg_price=('price', 'mean'),
    num_orders=('order_id', 'count')
)
```

## Apply Functions

```python
# Apply function to column
df['col'].apply(str.upper)

# Lambda on column
df['col'].apply(lambda x: x * 2)

# Apply to entire row (axis=1)
df.apply(lambda row: row['a'] + row['b'], axis=1)

# Create new column from multiple columns
df['total'] = df.apply(lambda row: row['price'] * row['qty'], axis=1)

# Apply with named function
def categorize(value):
    return 'high' if value > 100 else 'low'

df['tier'] = df['sales'].apply(categorize)

# Check if column contains a word
df['has_col'] = df['text'].apply(lambda x: 'col' in x)

# Using str.contains (vectorized, faster)
df['has_col'] = df['text'].str.contains('col')
```
