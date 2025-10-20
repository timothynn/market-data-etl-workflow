import os
import pandas as pd
import psycopg2
from psycopg2.extras import execute_batch
from datetime import datetime
import logging
from azure.storage.blob import BlobServiceClient
import yfinance as yf

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class MarketDataETL:
    def __init__(self):
        self.db_config = {
            'host': os.getenv('POSTGRES_HOST', 'postgres'),
            'database': os.getenv('POSTGRES_DB', 'market_data'),
            'user': os.getenv('POSTGRES_USER', 'etl_user'),
            'password': os.getenv('POSTGRES_PASSWORD', 'etl_password')
        }
        self.azure_conn_str = os.getenv('AZURE_STORAGE_CONNECTION_STRING', '')
        self.container_name = os.getenv('AZURE_CONTAINER_NAME', 'market-data')
        
    def get_db_connection(self):
        """Create database connection with retry logic"""
        try:
            conn = psycopg2.connect(**self.db_config)
            return conn
        except Exception as e:
            logger.error(f"Database connection failed: {e}")
            raise

    def extract_market_data(self, symbols=['AAPL', 'GOOGL', 'MSFT', 'AMZN'], period='1mo'):
        """Extract market data from Yahoo Finance"""
        logger.info(f"Extracting data for symbols: {symbols}")
        
        all_data = []
        for symbol in symbols:
            try:
                ticker = yf.Ticker(symbol)
                hist = ticker.history(period=period)
                hist['symbol'] = symbol
                hist['extracted_at'] = datetime.now()
                all_data.append(hist)
                logger.info(f"Extracted {len(hist)} records for {symbol}")
            except Exception as e:
                logger.error(f"Failed to extract data for {symbol}: {e}")
                
        if all_data:
            df = pd.concat(all_data, ignore_index=True)
            df.reset_index(inplace=True)
            return df
        return pd.DataFrame()

    def transform_data(self, df):
        """Transform and enrich market data"""
        logger.info("Transforming data...")
        
        # Calculate technical indicators
        df['daily_return'] = df.groupby('symbol')['Close'].pct_change()
        df['volatility'] = df.groupby('symbol')['daily_return'].transform(
            lambda x: x.rolling(window=5, min_periods=1).std()
        )
        df['price_range'] = df['High'] - df['Low']
        df['price_range_pct'] = (df['price_range'] / df['Open']) * 100
        
        # Moving averages
        df['ma_5'] = df.groupby('symbol')['Close'].transform(
            lambda x: x.rolling(window=5, min_periods=1).mean()
        )
        df['ma_10'] = df.groupby('symbol')['Close'].transform(
            lambda x: x.rolling(window=10, min_periods=1).mean()
        )
        
        # Clean data
        df = df.dropna(subset=['Close', 'Volume'])
        df['Date'] = pd.to_datetime(df['Date'])
        
        # Rename columns for PostgreSQL
        df.columns = [col.lower().replace(' ', '_') for col in df.columns]
        
        logger.info(f"Transformed {len(df)} records")
        return df

    def load_to_postgres(self, df):
        """Load data to PostgreSQL using batch inserts"""
        logger.info("Loading data to PostgreSQL...")
        
        conn = self.get_db_connection()
        cur = conn.cursor()
        
        try:
            # Create staging table
            cur.execute("""
                CREATE TABLE IF NOT EXISTS market_data_staging (
                    date TIMESTAMP,
                    open NUMERIC,
                    high NUMERIC,
                    low NUMERIC,
                    close NUMERIC,
                    volume BIGINT,
                    dividends NUMERIC,
                    stock_splits NUMERIC,
                    symbol VARCHAR(10),
                    extracted_at TIMESTAMP,
                    daily_return NUMERIC,
                    volatility NUMERIC,
                    price_range NUMERIC,
                    price_range_pct NUMERIC,
                    ma_5 NUMERIC,
                    ma_10 NUMERIC
                )
            """)
            
            # Prepare data for batch insert
            cols = df.columns.tolist()
            values = [tuple(x) for x in df.to_numpy()]
            
            insert_query = f"""
                INSERT INTO market_data_staging ({','.join(cols)})
                VALUES ({','.join(['%s'] * len(cols))})
            """
            
            execute_batch(cur, insert_query, values, page_size=1000)
            
            # Merge into main table with conflict resolution
            cur.execute("""
                CREATE TABLE IF NOT EXISTS market_data (
                    id SERIAL PRIMARY KEY,
                    date TIMESTAMP,
                    open NUMERIC,
                    high NUMERIC,
                    low NUMERIC,
                    close NUMERIC,
                    volume BIGINT,
                    dividends NUMERIC,
                    stock_splits NUMERIC,
                    symbol VARCHAR(10),
                    extracted_at TIMESTAMP,
                    daily_return NUMERIC,
                    volatility NUMERIC,
                    price_range NUMERIC,
                    price_range_pct NUMERIC,
                    ma_5 NUMERIC,
                    ma_10 NUMERIC,
                    loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    UNIQUE(symbol, date)
                )
            """)
            
            # Create indexes for query optimization
            cur.execute("""
                CREATE INDEX IF NOT EXISTS idx_market_data_symbol 
                ON market_data(symbol)
            """)
            cur.execute("""
                CREATE INDEX IF NOT EXISTS idx_market_data_date 
                ON market_data(date)
            """)
            cur.execute("""
                CREATE INDEX IF NOT EXISTS idx_market_data_symbol_date 
                ON market_data(symbol, date DESC)
            """)
            
            # Merge staging to main table
            cur.execute("""
                INSERT INTO market_data (
                    date, open, high, low, close, volume, 
                    dividends, stock_splits, symbol, extracted_at,
                    daily_return, volatility, price_range, 
                    price_range_pct, ma_5, ma_10
                )
                SELECT * FROM market_data_staging
                ON CONFLICT (symbol, date) 
                DO UPDATE SET
                    open = EXCLUDED.open,
                    high = EXCLUDED.high,
                    low = EXCLUDED.low,
                    close = EXCLUDED.close,
                    volume = EXCLUDED.volume,
                    daily_return = EXCLUDED.daily_return,
                    volatility = EXCLUDED.volatility,
                    price_range = EXCLUDED.price_range,
                    price_range_pct = EXCLUDED.price_range_pct,
                    ma_5 = EXCLUDED.ma_5,
                    ma_10 = EXCLUDED.ma_10,
                    loaded_at = CURRENT_TIMESTAMP
            """)
            
            # Drop staging table
            cur.execute("DROP TABLE market_data_staging")
            
            conn.commit()
            logger.info(f"Successfully loaded {len(df)} records")
            
        except Exception as e:
            conn.rollback()
            logger.error(f"Failed to load data: {e}")
            raise
        finally:
            cur.close()
            conn.close()

    def upload_to_azure(self, df):
        """Upload data to Azure Blob Storage"""
        if not self.azure_conn_str:
            logger.warning("Azure connection string not configured, skipping upload")
            return
            
        try:
            logger.info("Uploading to Azure Blob Storage...")
            blob_service = BlobServiceClient.from_connection_string(self.azure_conn_str)
            container = blob_service.get_container_client(self.container_name)
            
            # Create container if not exists
            try:
                container.create_container()
            except:
                pass
            
            # Upload as parquet for efficiency
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            blob_name = f"market_data_{timestamp}.parquet"
            
            parquet_buffer = df.to_parquet(index=False)
            blob_client = container.get_blob_client(blob_name)
            blob_client.upload_blob(parquet_buffer, overwrite=True)
            
            logger.info(f"Uploaded to Azure: {blob_name}")
        except Exception as e:
            logger.error(f"Azure upload failed: {e}")

    def create_analytics_views(self):
        """Create optimized views for analytics"""
        logger.info("Creating analytics views...")
        
        conn = self.get_db_connection()
        cur = conn.cursor()
        
        try:
            # Daily summary view
            cur.execute("""
                CREATE OR REPLACE VIEW daily_summary AS
                SELECT 
                    date::date as trading_date,
                    symbol,
                    close,
                    volume,
                    daily_return,
                    volatility,
                    ma_5,
                    ma_10,
                    CASE WHEN ma_5 > ma_10 THEN 'Bullish' ELSE 'Bearish' END as trend
                FROM market_data
                WHERE date >= CURRENT_DATE - INTERVAL '30 days'
                ORDER BY date DESC, symbol
            """)
            
            # Top performers view
            cur.execute("""
                CREATE OR REPLACE VIEW top_performers AS
                SELECT 
                    symbol,
                    AVG(daily_return) as avg_return,
                    AVG(volatility) as avg_volatility,
                    MAX(close) as max_price,
                    MIN(close) as min_price,
                    SUM(volume) as total_volume
                FROM market_data
                WHERE date >= CURRENT_DATE - INTERVAL '30 days'
                GROUP BY symbol
                ORDER BY avg_return DESC
            """)
            
            conn.commit()
            logger.info("Analytics views created successfully")
            
        except Exception as e:
            logger.error(f"Failed to create views: {e}")
        finally:
            cur.close()
            conn.close()

    def run_pipeline(self):
        """Execute complete ETL pipeline"""
        logger.info("=== Starting ETL Pipeline ===")
        start_time = datetime.now()
        
        try:
            # Extract
            df = self.extract_market_data()
            if df.empty:
                logger.warning("No data extracted")
                return
            
            # Transform
            df_transformed = self.transform_data(df)
            
            # Load
            self.load_to_postgres(df_transformed)
            
            # Create analytics views
            self.create_analytics_views()
            
            # Upload to Azure (optional)
            self.upload_to_azure(df_transformed)
            
            duration = (datetime.now() - start_time).total_seconds()
            logger.info(f"=== Pipeline completed in {duration:.2f} seconds ===")
            
        except Exception as e:
            logger.error(f"Pipeline failed: {e}")
            raise

if __name__ == "__main__":
    etl = MarketDataETL()
    etl.run_pipeline()
