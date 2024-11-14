import os
import subprocess
from pyrogram import Client, filters

# Your API credentials
api_id = ''
api_hash = ''
bot_token = ''

app = Client("my_bot", api_id=api_id, api_hash=api_hash, bot_token=bot_token)

# Function to download the track using scdl
def download_soundcloud_track(url, chat_id):
    try:
        print(f"Attempting to download track from: {url}")

        # Run scdl to download the SoundCloud track with output captured
        output = subprocess.Popen(["scdl", "-l", url], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

        # Send an initial message to the user
        progress_message = app.send_message(chat_id, "Downloading the track...")

        output.wait()  # Wait for the process to finish

        if output.returncode != 0:
            print(f"Error downloading track: {output.stderr.read()}")
            app.edit_message_text(progress_message.chat.id, progress_message.message_id, "Error downloading the track.")
            return None

        # Check for .mp3 file in the current directory
        for file in os.listdir():
            if file.endswith(".mp3"):
                print(f"Track downloaded: {file}")
                return file

        print("No .mp3 file found after download.")
        return None
    
    except Exception as e:
        print(f"An error occurred: {e}")
        app.edit_message_text(progress_message.chat.id, progress_message.message_id, "An error occurred while downloading the track.")
        return None

# Handler for incoming messages
@app.on_message(filters.text)
def handle_message(client, message):
    print(f"Received message: {message.text}")  # Log the received message

    # Check if the message contains a SoundCloud URL
    if message.text.startswith("https://soundcloud.com/"):
        track_url = message.text
        track_file = download_soundcloud_track(track_url, message.chat.id)

        if track_file:
            try:
                # Send the downloaded track to the user directly using the file path
                app.send_document(message.chat.id, track_file)
                print(f"Sent track: {track_file}")
                
                # Delete the file after sending it to the user
                os.remove(track_file)
                print(f"Deleted track: {track_file}")
            except Exception as e:
                print(f"Error sending track: {e}")
                app.send_message(message.chat.id, "An error occurred while sending the track.")
        else:
            app.send_message(message.chat.id, "Failed to download the track. Please check the URL.")
    else:
        print("No SoundCloud URL found in message.")

# Start the bot
if __name__ == "__main__":
    print("Bot is running...")  # Log to indicate the bot is running
    app.run()
