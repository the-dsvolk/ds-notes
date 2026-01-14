# Pandas Visualization

Using Plotly with pandas.

```python
import plotly.express as px
```

## Line Plot

```python
px.line(df, x='date', y='value')

# Multiple lines
px.line(df, x='date', y='value', color='category')
```

## Histogram

```python
px.histogram(df, x='value')

# With bins
px.histogram(df, x='value', nbins=20)

# Grouped
px.histogram(df, x='value', color='category')
```

## Box Plot

```python
px.box(df, y='value')

# Grouped by category
px.box(df, x='category', y='value')
```

## Scatter Plot

```python
px.scatter(df, x='col1', y='col2')

# With color and size
px.scatter(df, x='col1', y='col2', color='category', size='value')
```
