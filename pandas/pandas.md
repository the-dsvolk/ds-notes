# Pandas

## Selecting Data: loc and iloc

### iloc - Integer Location (position-based)

```python
# Select single row by position
df.iloc[0]          # First row (as Series)
df.iloc[-1]         # Last row

df.iloc[[0, 2], [1, 3]]  # Rows 0,2 and columns 1,3
```

### loc - Label-based (uses index/column names)

```python
# Select single row by label
df.loc['row_a']           # Row with index 'row_a'

# Select multiple rows
df.loc['row_a':'row_c']   # Rows from 'row_a' to 'row_c' (inclusive!)
df.loc[['row_a', 'row_c']]

# Boolean selection (filtering)
df.loc[df['age'] > 30]                        # Rows where age > 30

```

### Key Differences

| Feature | iloc | loc |
|---------|------|-----|
| Index type | Integer position | Label/name |
| Slicing | Excludes end (`0:3` → 0,1,2) | Includes end (`'a':'c'` → a,b,c) |
| Boolean | Not supported | Supported |

### Common Patterns

```python
# Get last N rows
df.iloc[-5:]

# Get first value of a column
df['col'].iloc[0]

# Update values with loc
df.loc[df['status'] == 'pending', 'status'] = 'complete'

# Filter and select columns
df.loc[(df['age'] > 25) & (df['city'] == 'NYC'), ['name', 'age']]
```

## Handling NaN Values

### Select rows with NaN

```python
# Rows where any column is NaN
df[df.isna().any(axis=1)]

# Rows where specific column is NaN
df[df['col'].isna()]

# Rows where specific column is NOT NaN
df[df['col'].notna()]
```

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

## DateTime Operations

### Convert to DateTime

```python
# Convert column to datetime
df['timestamp'] = pd.to_datetime(df['timestamp'])

# Parse with specific format (faster)
df['date'] = pd.to_datetime(df['date_str'], format='%Y-%m-%d')

# Set datetime column as index
df = df.set_index('timestamp')
```

### Extract Date Components

```python
# From column
df['year'] = df['timestamp'].dt.year
df['month'] = df['timestamp'].dt.month
df['day'] = df['timestamp'].dt.day
df['hour'] = df['timestamp'].dt.hour
df['day_of_week'] = df['timestamp'].dt.dayofweek  # 0=Monday

# From index
df['date'] = df.index.date
df['hour'] = df.index.hour
```

### normalize() - Strip Time, Keep Date

`normalize()` sets the time component to midnight (00:00:00), keeping only the date. Useful for grouping by day.

```python
# Before: 2025-01-24 14:35:22
# After:  2025-01-24 00:00:00

# On a DatetimeIndex
df.index = df.index.normalize()

# On a column
df['date'] = df['timestamp'].dt.normalize()
```

### GroupBy with DateTime

```python
# Group by date (using normalize)
daily_totals = df.groupby(df.index.normalize()).agg({
    'value': 'sum',
    'count': 'count'
})

# Group by date from column
df.groupby(df['timestamp'].dt.normalize())['sales'].sum()

# Alternative: use dt.date (returns date objects, not datetime)
df.groupby(df['timestamp'].dt.date)['sales'].sum()

# Group by hour of day
df.groupby(df['timestamp'].dt.hour)['requests'].mean()

# Group by day of week
df.groupby(df['timestamp'].dt.dayofweek)['traffic'].sum()
```

### Resample (Time-based GroupBy)

```python
# Requires DatetimeIndex
df = df.set_index('timestamp')

# Resample to hourly and assign back
hourly_df = df.resample('H').sum().reset_index()

# Resample to daily and assign back
daily_df = df.resample('D').mean().reset_index()

# Multiple aggregations with named columns
daily_stats = df.resample('D').agg(
    total=('value', 'sum'),
    average=('value', 'mean'),
    count=('value', 'count')
).reset_index()

# Common frequencies: 'min'=minute, 'h'=hour, 'D'=day, 'W'=week, 'ME'=month-end
```

### Example: Daily Summary from Timestamped Logs

```python
logs = pd.DataFrame({
    'timestamp': pd.to_datetime([
        '2025-01-24 10:15:00', '2025-01-24 14:30:00',
        '2025-01-24 18:45:00', '2025-01-25 09:00:00'
    ]),
    'duration': [120, 45, 90, 60]
})

# Group by day using normalize()
daily = logs.groupby(logs['timestamp'].dt.normalize()).agg(
    total_duration=('duration', 'sum'),
    job_count=('duration', 'count'),
    avg_duration=('duration', 'mean')
)

#                      total_duration  job_count  avg_duration
# timestamp
# 2025-01-24 00:00:00            255          3          85.0
# 2025-01-25 00:00:00             60          1          60.0
```
