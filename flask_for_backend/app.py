from flask import Flask, request, jsonify
from flask_mysqldb import MySQL
from flask_cors import CORS
import config
import re
from datetime import datetime

app = Flask(__name__)
CORS(app)

# MySQL Config
app.config['MYSQL_HOST'] = config.MYSQL_HOST
app.config['MYSQL_USER'] = config.MYSQL_USER
app.config['MYSQL_PASSWORD'] = config.MYSQL_PASSWORD
app.config['MYSQL_DB'] = config.MYSQL_DB

app.config['JSONIFY_PRETTYPRINT_REGULAR'] = False

# Initialize MySQL
db = MySQL(app)

@app.route('/fetch-users', methods=['GET'])
def fetch_users():
    try:
        cursor = db.connection.cursor()
        cursor.execute("SELECT full_name, email, country_code, phone, dob, gender FROM users")
        rows = cursor.fetchall()
        cursor.close()

        users = []
        for row in rows:
            users.append({
                'full_name': row[1],             # <-- renamed
                'email': row[2],
                'country_code': row[3],          # <-- renamed
                'phone': row[4],                 # <-- renamed
                'dob': row[5].strftime('%Y-%m-%d') if row[5] else None,
                'gender': row[6]
            })

        return jsonify(users), 200

    except Exception as err:
        print('Error fetching data:', err)
        return jsonify({'error': 'Database error'}), 500

@app.route('/submit-form', methods=['POST'])
def submit_form():
    data = request.get_json()
    fullname = data.get('fullname')
    email = data.get('email')
    code = data.get('code')
    phonenumber = data.get('phonenumber')
    dob = data.get('dob')
    gender = data.get('gender')

    if not all([fullname, email, code, phonenumber, dob, gender]):
        return jsonify({'error': 'Missing required fields'}), 400

    # Validate email
    if not re.match(r'^\S+@\S+\.\S+$', email):
        return jsonify({'error': 'Invalid email format'}), 400

    # Validate date format
    try:
        datetime.strptime(dob, '%Y-%m-%d')
    except ValueError:
        return jsonify({'error': 'Invalid DOB format. Use YYYY-MM-DD'}), 400

    try:
        cursor = db.connection.cursor()
        sql = """
            INSERT INTO users (full_name, email, country_code, phone, dob, gender)
            VALUES (%s, %s, %s, %s, %s, %s)
        """
        values = (fullname, email, code, phonenumber, dob, gender)
        cursor.execute(sql, values)
        db.connection.commit()
        cursor.close()

        return jsonify({'message': 'Data inserted successfully'}), 200

    except Exception as err:
        print(f'[DB ERROR] {err}')
        return jsonify({'error': 'Database error'}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
