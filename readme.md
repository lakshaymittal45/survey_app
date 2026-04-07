# Longitudinal Survey Application

A comprehensive Flask-based survey management system designed for longitudinal research studies. This application enables administrators to create and manage multi-section questionnaires while allowing users to complete surveys with hierarchical question structures, session management, and offline support.

**Status:** ✅ Production Ready

---

## Table of Contents

- [Overview](#overview)
- [Workflow (Mentor-Friendly)](#workflow-mentor-friendly)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Database Setup](#database-setup)
- [Configuration](#configuration)
- [Running the Application](#running-the-application)
- [Creating Admin & User Accounts](#creating-admin--user-accounts)
- [Project Structure](#project-structure)
- [API Documentation](#api-documentation)
- [Screenshots](#screenshots)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

The Longitudinal Survey Application is a complete survey management solution built with Flask and MySQL. It supports:

- **Multi-section questionnaires** with customizable question types
- **Hierarchical questions** with parent-child relationships and trigger conditions
- **Session-based authentication** for users and administrators
- **Geographic location management** (States → Districts → Blocks → Sub-centers → Villages)
- **Household management** with location-based tracking
- **Response persistence** with offline support via localStorage
- **Aadhaar encryption at rest** for sensitive personal data
- **CSV exports** for data analysis
- **Role-based access control** (User, Admin)

---

## Workflow (Mentor-Friendly)

For a full end-to-end explanation of the system (UI → Flask routes → database), including Mermaid diagrams for:

- User survey lifecycle (draft → submit → individual questionnaire → complete)
- Admin management (locations/questionnaire/accounts/exports)
- Conceptual data model

See: [WORKFLOW.md](WORKFLOW.md)

## Features

### Admin Dashboard

- ✅ Create and manage questionnaire sections
- ✅ Add questions with multiple answer types (text, number, MCQ, checkbox)
- ✅ Set up hierarchical questions with trigger conditions
- ✅ Manage geographic locations (states, districts, blocks, sub-centers, villages)
- ✅ View household records and user responses
- ✅ Create/delete user and admin accounts
- ✅ Export survey data in multiple formats

### User Dashboard

- ✅ Create household profiles with location hierarchy
- ✅ Complete multi-section surveys with progress tracking
- ✅ Resume incomplete surveys
- ✅ Offline response saving with auto-sync
- ✅ Navigate between sections easily
- ✅ Per-section response submission

### Security

- ✅ Password hashing with Werkzeug
- ✅ Session-based authentication
- ✅ Role-based access control (RBAC)
- ✅ Aadhaar encryption using AES-GCM
- ✅ SQL injection prevention with parameterized queries

---

## Tech Stack

| Component        | Technology              | Version |
| ---------------- | ----------------------- | ------- |
| Backend          | Flask                   | 3.0.0+  |
| Database         | MySQL                   | 8.0+    |
| ORM              | SQLAlchemy              | 2.0.45+ |
| Authentication   | Werkzeug                | 3.0.1+  |
| Frontend         | HTML5, CSS3, Vanilla JS | -       |
| Containerization | Docker                  | Latest  |
| Database Admin   | phpMyAdmin              | Latest  |

---

## Prerequisites

Before you begin, ensure you have the following installed:

- **Python 3.8+** ([Download](https://www.python.org/downloads/))
- **WSL2 (Windows Subsystem for Linux 2)** (for Windows users)
- **Docker & Docker Compose** ([Install](https://docs.docker.com/install/))
- **Git** ([Download](https://git-scm.com/downloads))

### System Requirements

- RAM: 2GB minimum (4GB recommended)
- Storage: 500MB for application + database
- Network: Internet connection for initial setup

---

## Installation

### Step 1: Clone the Repository

```bash
git clone https://github.com/yourusername/longitudinal-survey-app.git
cd longitudinal-survey-app
```

### Step 2: Set Up Python Environment

#### On Linux/WSL:

```bash
# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip
```

#### On Windows (PowerShell):

```powershell
# Create virtual environment
python -m venv venv

# Activate virtual environment
.\venv\Scripts\Activate.ps1

# Upgrade pip
python -m pip install --upgrade pip
```

### Step 3: Install Python Dependencies

```bash
pip install -r requirements.txt
```

**Expected output:**

```
Successfully installed Flask-3.0.0 SQLAlchemy-2.0.45 ...
```

### Step 4: Verify Installation

```bash
python -c "import flask; print('Flask:', flask.__version__)"
python -c "import sqlalchemy; print('SQLAlchemy:', sqlalchemy.__version__)"
```

---

## Database Setup

### Option A: Using Docker Compose (Recommended)

#### Step 1: Configure Database Environment

Create a `.env` file in the project root:

```bash
# .env
DB_ROOT_PASSWORD=root_password_123
DB_NAME=survey_1
DB_USER=survey_user
DB_PASSWORD=survey_password_123
DB_LOCAL_PORT=3306
PMA_LOCAL_PORT=8081
```

**Security Note:** Use strong passwords in production. Never commit `.env` to version control.

#### Step 2: Start Docker Containers

```bash
# Start MySQL and phpMyAdmin
docker-compose up -d

# Verify containers are running
docker-compose ps
```

**Expected output:**

```
CONTAINER ID   IMAGE          STATUS
abc123...      mysql:8.0      Up 2 minutes   127.0.0.1:3306->3306/tcp
xyz789...      phpmyadmin     Up 2 minutes   127.0.0.1:8081->80/tcp
```

#### Step 3: Wait for MySQL to Be Ready

```bash
# Check MySQL logs
docker-compose logs db

# Wait ~30 seconds for MySQL to initialize
sleep 30
```
cd "d:\Projects\Survey\survey_app"; 
#### Step 4: Access phpMyAdmin (Optional)

```
URL: http://127.0.0.1:8081
Username: root
Password: <DB_ROOT_PASSWORD from .env>
```

### Option B: Manual MySQL Installation

If you prefer to use a local MySQL installation:

```bash
# On Windows (using MySQL installer)
# On Linux
sudo apt-get install mysql-server

# On macOS
brew install mysql

# Start MySQL
mysql -u root -p

# Create database
CREATE DATABASE survey_1;
CREATE USER 'survey_user'@'localhost' IDENTIFIED BY 'survey_password_123';
GRANT ALL PRIVILEGES ON survey_1.* TO 'survey_user'@'localhost';
FLUSH PRIVILEGES;
```

---

## Configuration

### Step 1: Create .env File

Create `.env` in the `app` (or project root) directory:

```bash
# Flask Configuration
FLASK_SECRET_KEY=your_secret_key_change_this_to_something_random
FLASK_ENV=development
DEBUG=True

# Database Configuration
PRIMARY_DB_URI=mysql+pymysql://survey_user:survey_password_123@127.0.0.1:3306/survey_1

# Aadhaar Encryption (Optional but Recommended)
AADHAR_ENC_KEY=cba2a59bf20d05cce92f6fc1bccbdd6b
AADHAR_HASH_KEY=your_32_byte_hex_key_here

# Application Settings
APP_PORT=5000
APP_HOST=127.0.0.1
```

### Step 2: Generate Secret Key

```bash
python -c "import secrets; print(secrets.token_hex(16))"
```

Copy the output and paste it as `FLASK_SECRET_KEY`.

### Step 3: Verify Database Connection

```bash
# From the project root
python -c "from app import db; print('✓ Database connection successful')" 2>&1 | grep -q "✓" && echo "Connection OK" || echo "Connection Failed"
```

---

## Running the Application

### Step 1: Activate Virtual Environment

#### On Linux/WSL:

```bash
source venv/bin/activate
```

#### On Windows (PowerShell):

```powershell
.\venv\Scripts\Activate.ps1
```

### Step 2: Start Flask Server

From the `app` directory:

```bash
cd app
python app.py
OR
.\.venv\Scripts\python.exe app.py
```

**Expected output:**

```
 * Running on http://127.0.0.1:5000
 * Debug mode: on
WARNING in app.run_with_reloader (...)
```

### Step 3: Access Application

Open your browser and navigate to:

```
URL: http://127.0.0.1:5000
```

**Landing Page:** Shows login options for users and administrators

---

## Creating Admin & User Accounts

### Using the Setup Script (Recommended)

We provide convenient setup scripts in the `app/scripts` folder.

#### Step 1: Run Admin Creation Script

```bash
cd app
python scripts/create_admin_and_user.py
```

**What it does:**

- Creates default admin account (username: `admin`, password: `admin123`)
- Creates default user account (username: `user`, password: `user123`)
- Both use bcrypt password hashing

**Output:**

```
--- Starting Account Creation ---
✅ SUCCESS: Admin account created.
✅ SUCCESS: User account created.
```

#### Step 2: Verify Accounts Created

```bash
# Access phpMyAdmin at http://127.0.0.1:8081
# Navigate to survey_1 > admins and users tables
# You should see:
# - admin user in admins table
# - user account in users table
```

### Manual Account Creation (via phpMyAdmin)

If the script doesn't work, create accounts manually:

```sql
-- Connect to survey_1 database

-- Create Admin
INSERT INTO admins (username, password, password_hash)
VALUES ('admin', SHA2('admin123', 256), SHA2('admin123', 256));

-- Create User
INSERT INTO users (username, password_hash)
VALUES ('user', SHA2('user123', 256));
```

### Changing Default Passwords (Production)

```sql
UPDATE admins
SET password_hash = SHA2('new_strong_password', 256)
WHERE username = 'admin';

UPDATE users
SET password_hash = SHA2('new_strong_password', 256)
WHERE username = 'user';
```

---

## Project Structure

```
longitudinal-survey-app/
├── app/
│   ├── app.py                          # Main Flask application
│   ├── requirements.txt                # Python dependencies
│   ├── .env                            # Environment variables (create this)
│   │
│   ├── scripts/
│   │   └── create_admin_and_user.py   # Account creation script
│   │
│   ├── templates/                      # HTML templates
│   │   ├── home.html                  # Landing page
│   │   ├── user_login.html            # User login page
│   │   ├── admin_login.html           # Admin login page
│   │   ├── user_dashboard.html        # Household creation form
│   │   ├── admin_dashboard.html       # Admin control panel
│   │   ├── questionnaire.html         # Survey form
│   │   ├── survey_locations.html      # Location management
│   │   └── [other templates...]
│   │
│   └── static/
│       ├── css/
│       │   └── style.css              # Application styles
│       └── js/
│           ├── locations.js           # Location management module
│           └── admin.js               # Admin dashboard logic
│
├── docker-compose.yml                  # Docker container configuration
├── README.md                           # This file
└── .gitignore                          # Git ignore file
```

---

## API Documentation

### Authentication Endpoints

#### User Login

```http
POST /user-login
Content-Type: application/x-www-form-urlencoded

username=user&password=user123
```

**Response:** Redirects to `/user-dashboard` with session set

#### Admin Login

```http
POST /admin-login
Content-Type: application/x-www-form-urlencoded

username=admin&password=admin123
```

**Response:** Redirects to `/admin-dashboard` with session set

#### Logout

```http
GET /logout
```

### User APIs

#### Get States

```http
GET /api/states
```

**Response:**

```json
[
  { "state_id": 1, "name": "Punjab" },
  { "state_id": 2, "name": "Haryana" }
]
```

#### Create Household

```http
POST /api/household
Content-Type: application/json

{
  "household_name": "Smith Family",
  "state_id": 1,
  "district_id": 2,
  "block_id": 3,
  "sub_center_id": 4,
  "village_id": 5
}
```

**Response:**

```json
{
  "success": true,
  "household_id": 1,
  "main_questionnaire_id": 1
}
```

#### Get Questionnaire Data

```http
GET /api/questionnaire-data
```

**Response:**

```json
[
  {
    "section_id": 1,
    "section_title": "Demographics",
    "section_order": 1,
    "questions": [
      {
        "question_id": 1,
        "question_text": "What is your name?",
        "question_type": "open_ended",
        "answer_type": "text"
      }
    ]
  }
]
```

#### Save Responses

```http
POST /api/responses
Content-Type: application/json

{
  "section_id": 1,
  "responses": {
    "1": "John Doe",
    "2": "30"
  }
}
```

### Admin APIs

#### Get All Sections

```http
GET /api/admin/sections
```

#### Create Section

```http
POST /api/admin/section
Content-Type: application/json

{
  "section_title": "Health Information"
}
```

#### Create Question

```http
POST /api/admin/question
Content-Type: application/json

{
  "section_id": 1,
  "question_text": "Do you have health insurance?",
  "question_type": "single_choice",
  "answer_type": "text",
  "options": "Yes,No,Not Sure"
}
```

---

## Common Workflow

### For Administrators

1. **Login:** http://127.0.0.1:5000/admin-login
2. **Create Locations:**
   - Navigate to "Location Management" tab
   - Add State, District, Block, Sub-center, Village
3. **Create Questionnaire:**
   - Navigate to "Questionnaire" tab
   - Add Section (e.g., "Demographics")
   - Add Questions to the section
4. **Manage Accounts:**
   - Navigate to "Accounts" tab
   - Create user and admin accounts
5. **View Responses:**
   - Navigate to "Households" tab
   - Export data as CSV

### For Users

1. **Login:** http://127.0.0.1:5000/user-login
2. **Create Household:**
   - Select State → District → Block → Sub-center → Village
   - Enter household name
   - Click "Create Household & Start Survey"
3. **Fill Survey:**
   - Answer questions section by section
   - Click "Save & Next" to proceed
   - Click "Submit" when complete
4. **Resume Later:**
   - Login again
   - Create/select same household
   - Previous answers are restored

---

## Troubleshooting

### Issue: "ModuleNotFoundError: No module named 'flask'"

**Solution:**

```bash
# Ensure virtual environment is activated
source venv/bin/activate  # Linux/WSL
.\venv\Scripts\Activate.ps1  # Windows

# Reinstall requirements
pip install -r requirements.txt
```

### Issue: "Access Denied" when connecting to database

**Solution:**

```bash
# Check Docker container is running
docker-compose ps

# Verify database variables in .env
cat .env | grep DB_

# Test connection
mysql -h 127.0.0.1 -P 3306 -u survey_user -p survey_1
```

### Issue: "ModuleNotFoundError: No module named 'cryptography'"

**Solution:**

```bash
# Install optional dependencies
pip install cryptography openpyxl python-dotenv

# Or reinstall all requirements
pip install -r requirements.txt --force-reinstall
```

### Issue: "Port 3306 already in use"

**Solution:**

```bash
# Change port in docker-compose.yml
# Change this line:
# - "3306:3306"
# To:
# - "3307:3306"

# And update PRIMARY_DB_URI in .env:
# mysql+pymysql://survey_user:password@127.0.0.1:3307/survey_1
```

### Issue: MySQL container won't start

**Solution:**

```bash
# Remove and restart containers
docker-compose down -v
docker-compose up -d

# Check logs
docker-compose logs db

# Wait 30-60 seconds for MySQL to initialize
sleep 60
```

### Issue: "Survey already completed for this household"

**Solution:**
This is by design—each household can only be submitted once. To test again:

1. Create a new household with a different name
2. Or delete the household from admin panel

---

## Performance Tips

### Database Optimization

```sql
-- Index frequently queried columns
CREATE INDEX idx_households_user_id ON households(user_id);
CREATE INDEX idx_main_responses_household ON main_questionnaire_responses(household_id);
```

### Application Optimization

- Enable query caching in MySQL
- Use CDN for static files in production
- Implement response pagination for large datasets
- Cache location data in frontend

---

## Security Best Practices

### For Production Deployment

```bash
# 1. Change all default passwords
# 2. Set strong secret keys
FLASK_SECRET_KEY=$(python -c "import secrets; print(secrets.token_hex(32))")

# 3. Use HTTPS/SSL
# 4. Enable CORS only for trusted domains
# 5. Set secure session cookies
# 6. Enable database user permissions properly
# 7. Regularly backup database
# 8. keep dependencies updated
```

### Database User Permissions (Recommended)

```sql
-- Create limited user for Flask app
CREATE USER 'app_user'@'localhost' IDENTIFIED BY 'app_strong_password';

-- Grant only necessary privileges
GRANT SELECT, INSERT, UPDATE, DELETE ON survey_1.* TO 'app_user'@'localhost';

-- No file/process/reload/shutdown permissions
FLUSH PRIVILEGES;
```

---

## Stopping the Application

### Stop Flask Server

```bash
# Press Ctrl+C in the terminal where Flask is running
```

### Stop Docker Containers

```bash
# Stop containers
docker-compose stop

# Or stop and remove
docker-compose down
```

### Stop and Clean (Remove Everything)

```bash
# CAUTION: This removes all data!
docker-compose down -v
```

---

## Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/AmazingFeature`
3. Commit changes: `git commit -m 'Add AmazingFeature'`
4. Push to branch: `git push origin feature/AmazingFeature`
5. Open a Pull Request

### Code Style

- Follow PEP 8 for Python code
- Use meaningful variable names
- Add docstrings to functions
- Comment complex logic

---

## Support

For issues, questions, or suggestions:

1. **Check Troubleshooting section** above
2. **Review API Documentation** for endpoint details
3. **Check Project Status** files in documentation folder
4. **Open an Issue** on GitHub with:
   - Clear description of problem
   - Steps to reproduce
   - Error messages/logs
   - Your system info (OS, Python version, etc.)

---

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## Changelog

### Version 1.0.0 (Current)

- ✅ Initial release
- ✅ Multi-section questionnaire support
- ✅ Hierarchical questions with triggers
- ✅ Geographic location management
- ✅ Household management
- ✅ Response persistence and exports
- ✅ Aadhaar encryption
- ✅ Docker support

---

## Acknowledgments

- Flask team for excellent web framework
- SQLAlchemy for ORM
- Docker team for containerization
- Community contributors

---

## Quick Reference

| Task             | Command                                   |
| ---------------- | ----------------------------------------- |
| Activate venv    | `source venv/bin/activate`                |
| Install packages | `pip install -r requirements.txt`         |
| Start Docker     | `docker-compose up -d`                    |
| Check containers | `docker-compose ps`                       |
| View logs        | `docker-compose logs db`                  |
| Create accounts  | `python scripts/create_admin_and_user.py` |
| Start Flask      | `python app.py`                           |
| Stop Flask       | `Ctrl+C`                                  |
| Stop Docker      | `docker-compose stop`                     |

---

**Last Updated:** January 2025  
**Maintained By:** Your Team  
**Repository:** https://github.com/yourusername/longitudinal-survey-app

---

## Happy Surveying! 🎉

For detailed documentation, please refer to the files in the `documentation/` folder.
