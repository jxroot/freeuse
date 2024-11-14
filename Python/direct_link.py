#https://github.com/jxroot/freeuse
from pyrogram import Client, filters
import os
import threading
import time
from urllib.parse import quote

# Telegram Bot API credentials
api_id = ''
api_hash = ''
bot_token = ''

# Initialize Pyrogram Client
app = Client("telegram_bot", api_id=api_id, api_hash=api_hash, bot_token=bot_token)

# Directory to store downloaded files
download_directory = "/var/www/html/"
os.makedirs(download_directory, exist_ok=True)

# File cleanup task that runs in the background
def cleanup_files():
    while True:
        # Current time
        now = time.time()
        # Iterate through files in download directory
        for filename in os.listdir(download_directory):
            file_path = os.path.join(download_directory, filename)
            # Check if the file is older than 24 hours (86400 seconds)
            if os.path.isfile(file_path) and (now - os.path.getmtime(file_path)) > 86400:
                print(f"Deleting file {file_path} - older than 24 hours")
                os.remove(file_path)
        # Sleep for an hour before checking again
        time.sleep(3600)

# Start the cleanup thread
threading.Thread(target=cleanup_files, daemon=True).start()

# Progress bar function
async def progress(current, total, message):
    percentage = current * 100 / total
    progress_bar = "[" + "=" * int(percentage // 5) + " " * (20 - int(percentage // 5)) + "]"
    status = f"Downloading: {progress_bar} {percentage:.2f}%"
    try:
        await message.edit_text(status)
    except:
        pass  # Ignore message update errors

# Automatically handle forwarded media messages
@app.on_message(filters.forwarded & filters.media)
async def download_media_on_forward(client, message):
    # Send an initial message to track progress
    progress_message = await message.reply("Starting download...")

    # Download the forwarded media with progress
    file_path = await client.download_media(
        message,
        file_name=download_directory,
        progress=progress,
        progress_args=(progress_message,)
    )
    file_name = os.path.basename(file_path)

    # Construct the direct link for the downloaded file
    encoded_file_name = quote(file_name)
    direct_link = f"http://localhost/{encoded_file_name}"  # Use your external IP address

    # Send the clickable link to the user for downloading
    await progress_message.edit_text(f"Download complete!\nHere is your direct link: {direct_link}")

@app.on_message(filters.command("start"))
async def start(client, message):
    await message.reply("Forward any media (image, video, audio, document, etc.) to get a direct download link with progress. Files are automatically deleted after 24 hours.")

app.run()
