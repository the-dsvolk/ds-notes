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

## Merge DataFrames

### Merge on Single Column

```python
# Inner join (default) - only matching rows
df_merged = pd.merge(df1, df2, on='user_id')

# Left join - keep all rows from df1
df_merged = pd.merge(df1, df2, on='user_id', how='left')

# Right join - keep all rows from df2
df_merged = pd.merge(df1, df2, on='user_id', how='right')

# Outer join - keep all rows from both
df_merged = pd.merge(df1, df2, on='user_id', how='outer')
```

### Merge on Multiple Columns

```python
# Match on two columns
df_merged = pd.merge(df1, df2, on=['user_id', 'date'])

# Different column names in each DataFrame
df_merged = pd.merge(
    df1, df2, 
    left_on=['user_id', 'order_date'], 
    right_on=['customer_id', 'purchase_date']
)
```

### Handle Duplicate Column Names

```python
# Columns with same name get suffixes
df_merged = pd.merge(df1, df2, on='user_id', suffixes=('_left', '_right'))
# Results in: amount_left, amount_right

# Rename columns before merge
df2_renamed = df2.rename(columns={'amount': 'order_amount', 'date': 'order_date'})
df_merged = pd.merge(df1, df2_renamed, on='user_id')

# Rename columns after merge
df_merged = df_merged.rename(columns={
    'amount_x': 'original_amount',
    'amount_y': 'new_amount'
})
```

### Rename Columns

```python
# Rename specific columns
df = df.rename(columns={'old_name': 'new_name', 'col1': 'column_one'})

# Rename all columns
df.columns = ['id', 'name', 'value']

# Rename with function (e.g., lowercase all)
df = df.rename(columns=str.lower)

# Add prefix/suffix to all columns
df = df.add_prefix('tbl1_')
df = df.add_suffix('_raw')
```

### Merge Example

```python
# Example DataFrames
orders = pd.DataFrame({
    'order_id': [1, 2, 3],
    'user_id': [101, 102, 101],
    'amount': [50, 75, 30]
})

users = pd.DataFrame({
    'user_id': [101, 102, 103],
    'name': ['Alice', 'Bob', 'Charlie']
})

# Merge to get user names on orders
result = pd.merge(orders, users, on='user_id', how='left')

#    order_id  user_id  amount   name
# 0         1      101      50  Alice
# 1         2      102      75    Bob
# 2         3      101      30  Alice
```
