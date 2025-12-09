import psycopg2

host = 'localhost'
port = 5433

try:
    conn = psycopg2.connect(
                        host=host,
                        port=port,
                        user='postgres',
                        password='gsd7_923jeff3',
                        database='postgres',
                        connect_timeout=5
                    )
    cursor = conn.cursor()
    
    cursor.execute("""
                   CREATE TABLE IF NOT EXISTS test_table (
                       first_row int
                   );
                   COMMIT;
                   """)
    
    cursor.execute("""
                   INSERT INTO test_table (
                       first_row
                   ) VALUES (
                       5
                   );
                   COMMIT;
                   """)

    cursor.execute("""
                        SELECT * FROM test_table
                    """)
    
    result = cursor.fetchall()
    print(result)
except Exception as e:
    print(f"❌ {host}:{port} - ERROR: {e}")
