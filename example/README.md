# Remote Caching Example

This example demonstrates how to use the `remote_caching` package with the Agify.io API to predict ages based on names with intelligent caching.

## Features

- **Age Prediction**: Enter a name and get age predictions from Agify.io API
- **Smart Caching**: Results are cached for 30 minutes to reduce API calls
- **Cache Management**: View cache statistics and clear cache
- **Error Handling**: Proper error handling for network issues
- **Modern UI**: Material Design 3 interface

## How to Run

1. Navigate to the example directory:
   ```bash
   cd example
   ```

2. Get dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## How It Works

1. **Initialization**: The app initializes the RemoteCaching system with a 30-minute default cache duration
2. **API Call**: When you enter a name and tap "Predict Age", it calls the Agify.io API
3. **Caching**: The result is cached with the key `age_prediction_[name]` for 30 minutes
4. **Subsequent Calls**: If you search for the same name again within 30 minutes, it returns the cached result instead of making a new API call

## Cache Features

- **Cache Statistics**: Tap the analytics icon in the app bar to see cache statistics
- **Clear Cache**: Tap the clear icon to remove all cached data
- **Automatic Cleanup**: Expired entries are automatically cleaned up

## API Response

The Agify.io API returns:
```json
{
  "count": 21,
  "name": "meelad",
  "age": 35
}
```

Where:
- `count`: Number of occurrences of this name in the database
- `name`: The name that was searched
- `age`: Predicted age based on the name

## Benefits of Caching

- **Reduced API Calls**: Saves bandwidth and reduces load on the API
- **Faster Response**: Cached results return instantly
- **Better UX**: No loading delays for previously searched names
- **Cost Effective**: Reduces API usage costs 