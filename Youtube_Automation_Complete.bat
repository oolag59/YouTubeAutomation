@echo off
chcp 65001 >nul
title YouTube Automation - Complete System
color 0A
setlocal enabledelayedexpansion

echo ===============================================================================
echo                    YOUTUBE AUTOMATION - COMPLETE SYSTEM
echo ===============================================================================
echo.

:: ==============================================================================
:: STEP 1: CHOOSE DRIVE LOCATION
:: ==============================================================================
echo [1] Choose where to save videos:
echo.
echo Available drives:
for %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    vol %%d: >nul 2>&1
    if not errorlevel 1 echo   %%d:
)

echo.
set /p DRIVE="Enter drive letter (without colon, press Enter for C): "
if "!DRIVE!"=="" set "DRIVE=C"

:: Set main folder
set "MAIN_FOLDER=!DRIVE!:\YouTubeAutomation"
set "VIDEOS_FOLDER=!MAIN_FOLDER!\Videos"
set "CLIPS_FOLDER=!MAIN_FOLDER!\Clips"
set "LOGS_FOLDER=!MAIN_FOLDER!\Logs"
set "CONFIG_FOLDER=!MAIN_FOLDER!\Config"

echo.
echo Main folder: !MAIN_FOLDER!
echo.

:: ==============================================================================
:: STEP 2: CREATE FOLDER STRUCTURE
:: ==============================================================================
echo [2] Creating folder structure...
mkdir "!MAIN_FOLDER!" 2>nul
mkdir "!VIDEOS_FOLDER!" 2>nul
mkdir "!CLIPS_FOLDER!" 2>nul
mkdir "!LOGS_FOLDER!" 2>nul
mkdir "!CONFIG_FOLDER!" 2>nul

echo ? Folders created successfully
echo.

:: ==============================================================================
:: STEP 3: INSTALL REQUIRED SOFTWARE
:: ==============================================================================
echo [3] Installing required software...
echo.

:: Check Python
echo Checking Python...
python --version >nul 2>&1
if errorlevel 1 (
    echo ? Python not found! Please install Python 3.8+ from python.org
    echo   Make sure to check "Add Python to PATH" during installation
    echo.
    pause
    exit /b 1
)

echo ? Python found
echo.

:: Install Python packages
echo Installing Python packages...
echo (This may take a few minutes...)
echo.

:: Create requirements file
(
echo yt-dlp==2023.12.30
echo requests==2.31.0
echo schedule==1.2.0
echo python-dotenv==1.0.0
) > "!MAIN_FOLDER!\requirements.txt"

:: Install packages
for %%p in (yt-dlp requests schedule python-dotenv) do (
    echo Installing %%p...
    python -m pip install %%p --no-warn-script-location
    if errorlevel 1 (
        echo Trying alternative method...
        pip install %%p --user --no-warn-script-location
    )
)

echo ? Packages installed
echo.

:: ==============================================================================
:: STEP 4: CREATE CONFIGURATION FILES
:: ==============================================================================
echo [4] Creating configuration files...
echo.

:: Create .env file for API keys
(
echo # SOCIAL MEDIA API KEYS
echo # Get these from the respective developer portals
echo.
echo # Twitter/X API (get from developer.twitter.com)
echo TWITTER_API_KEY=your_twitter_api_key_here
echo TWITTER_API_SECRET=your_twitter_api_secret_here
echo TWITTER_ACCESS_TOKEN=your_twitter_access_token_here
echo TWITTER_ACCESS_SECRET=your_twitter_access_secret_here
echo.
echo # Instagram (optional - requires Facebook Developer account)
echo # INSTAGRAM_USERNAME=your_username
echo # INSTAGRAM_PASSWORD=your_password
echo.
echo # YouTube API (optional - for better search)
echo # YOUTUBE_API_KEY=your_youtube_api_key
echo.
echo # System Settings
echo PROJECT_ROOT=!MAIN_FOLDER!
echo VIDEO_QUALITY=720p
echo CLIP_DURATION=60
echo MAX_DAILY_POSTS=3
) > "!MAIN_FOLDER!\.env"

:: Create config.yaml
(
echo # YouTube Automation Configuration
echo system:
echo   name: "YouTube Automation System"
echo   version: "1.0.0"
echo   debug_mode: true
echo.
echo downloader:
echo   video_quality: "720p"
echo   max_duration: 600
echo   download_folder: "!VIDEOS_FOLDER!"
echo.
echo clipper:
echo   clip_duration: 60
echo   output_folder: "!CLIPS_FOLDER!"
echo   add_watermark: false
echo.
echo poster:
echo   platforms:
echo     - "twitter"
echo     # - "instagram"  # Uncomment when you have Instagram API keys
echo   post_times:
echo     - "09:00"
echo     - "13:00"
echo     - "17:00"
echo.
echo channels:
echo   # Add Creative Commons channels here
echo   - id: "UCsXVk37bltHxD1rDPwtNM8Q"
echo     name: "Kurzgesagt"
echo     license: "CC BY-NC"
echo   - id: "UC6nSFpj9HTCZ5t-N3Rm3-HA"
echo     name: "TED-Ed"
echo     license: "CC BY-NC-ND"
) > "!MAIN_FOLDER!\config.yaml"

echo ? Configuration files created
echo IMPORTANT: Edit .env file with your actual API keys!
echo.

:: ==============================================================================
:: STEP 5: CREATE THE MAIN AUTOMATION SCRIPT
:: ==============================================================================
echo [5] Creating main automation script...
echo.

(
echo import os
echo import sys
echo import time
echo import json
echo import schedule
echo import requests
echo import yt_dlp
echo from datetime import datetime
echo from pathlib import Path
echo.
echo # ===========================================================================
echo # CONFIGURATION
echo # ===========================================================================
echo.
echo # Load environment
echo from dotenv import load_dotenv
echo load_dotenv()
echo.
echo # Project paths
echo PROJECT_ROOT = os.getenv('PROJECT_ROOT', os.path.dirname(os.path.abspath(__file__)))
echo VIDEOS_DIR = os.path.join(PROJECT_ROOT, 'Videos')
echo CLIPS_DIR = os.path.join(PROJECT_ROOT, 'Clips')
echo LOGS_DIR = os.path.join(PROJECT_ROOT, 'Logs')
echo CONFIG_DIR = os.path.join(PROJECT_ROOT, 'Config')
echo.
echo # Create directories
echo for dir_path in [VIDEOS_DIR, CLIPS_DIR, LOGS_DIR, CONFIG_DIR]:
echo     os.makedirs(dir_path, exist_ok=True)
echo.
echo # ===========================================================================
echo # LOGGING SYSTEM
echo # ===========================================================================
echo.
echo def setup_logger():
echo     """Setup logging system"""
echo     log_file = os.path.join(LOGS_DIR, f"automation_{datetime.now().strftime('%%Y%%m%%d')}.log")
echo     
echo     def log(message, level="INFO"):
echo         timestamp = datetime.now().strftime("%%Y-%%m-%%d %%H:%%M:%%S")
echo         log_entry = f"[{timestamp}] [{level}] {message}"
echo         
echo         # Print to console
echo         print(log_entry)
echo         
echo         # Save to file
echo         with open(log_file, 'a', encoding='utf-8') as f:
echo             f.write(log_entry + '\\n')
echo     
echo     return log
echo.
echo log = setup_logger()
echo log("YouTube Automation System Started")
echo.
echo # ===========================================================================
echo # VIDEO DOWNLOADER
echo # ===========================================================================
echo.
echo class VideoDownloader:
echo     def __init__(self):
echo         self.quality = os.getenv('VIDEO_QUALITY', '720p')
echo         self.output_dir = VIDEOS_DIR
echo     
echo     def download_video(self, url):
echo         """Download YouTube video"""
echo         try:
echo             log(f"Downloading video: {url}")
echo             
echo             # Quality mapping
echo             quality_map = {
echo                 '360p': 'best[height<=360]',
echo                 '480p': 'best[height<=480]',
echo                 '720p': 'best[height<=720]',
echo                 '1080p': 'best[height<=1080]',
echo                 'best': 'best'
echo             }
echo             
echo             format_str = quality_map.get(self.quality, 'best[height<=720]')
echo             
echo             ydl_opts = {
echo                 'format': format_str,
echo                 'outtmpl': os.path.join(self.output_dir, '%%(title)s.%%(ext)s'),
echo                 'quiet': False,
echo                 'no_warnings': False,
echo                 'progress_hooks': [self._progress_hook],
echo             }
echo             
echo             with yt_dlp.YoutubeDL(ydl_opts) as ydl:
echo                 info = ydl.extract_info(url, download=True)
echo                 filename = ydl.prepare_filename(info)
echo                 
echo                 # Convert to MP4 if needed
echo                 if not filename.endswith('.mp4'):
echo                     new_filename = filename.rsplit('.', 1)[0] + '.mp4'
echo                     if os.path.exists(filename):
echo                         os.rename(filename, new_filename)
echo                         filename = new_filename
echo                 
echo                 log(f"Download complete: {os.path.basename(filename)}")
echo                 return filename
echo                 
echo         except Exception as e:
echo             log(f"Download failed: {str(e)}", "ERROR")
echo             return None
echo     
echo     def _progress_hook(self, d):
echo         """Show download progress"""
echo         if d['status'] == 'downloading':
echo             percent = d.get('_percent_str', '0%%')
echo             speed = d.get('_speed_str', 'N/A')
echo             print(f"\rDownloading: {percent} at {speed}", end='')
echo         elif d['status'] == 'finished':
echo             print()
echo.
echo # ===========================================================================
echo # VIDEO CLIPPER
echo # ===========================================================================
echo.
echo class VideoClipper:
echo     def __init__(self):
echo         self.clip_duration = int(os.getenv('CLIP_DURATION', 60))
echo         self.output_dir = CLIPS_DIR
echo     
echo     def create_clip(self, video_path, start_time=0):
echo         """Create clip from video using ffmpeg"""
echo         try:
echo             import subprocess
echo             
echo             # Generate output filename
echo             timestamp = datetime.now().strftime('%%Y%%m%%d_%%H%%M%%S')
echo             base_name = os.path.basename(video_path).rsplit('.', 1)[0]
echo             output_name = f"{base_name}_clip_{timestamp}.mp4"
echo             output_path = os.path.join(self.output_dir, output_name)
echo             
echo             log(f"Creating clip: {output_name}")
echo             
echo             # Check if ffmpeg is available
echo             try:
echo                 subprocess.run(['ffmpeg', '-version'], capture_output=True, check=True)
echo             except:
echo                 log("FFmpeg not found! Clips will not be created.", "WARNING")
echo                 return None
echo             
echo             # Create clip using ffmpeg
echo             cmd = [
echo                 'ffmpeg',
echo                 '-i', video_path,
echo                 '-ss', str(start_time),
echo                 '-t', str(self.clip_duration),
echo                 '-c:v', 'libx264',
echo                 '-c:a', 'aac',
echo                 '-preset', 'fast',
echo                 '-y',
echo                 output_path
echo             ]
echo             
echo             result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
echo             
echo             if result.returncode == 0:
echo                 log(f"Clip created: {output_path}")
echo                 return output_path
echo             else:
echo                 log(f"FFmpeg error: {result.stderr}", "ERROR")
echo                 return None
echo                 
echo         except Exception as e:
echo             log(f"Clip creation failed: {str(e)}", "ERROR")
echo             return None
echo.
echo # ===========================================================================
echo # SOCIAL MEDIA POSTER
echo # ===========================================================================
echo.
echo class SocialMediaPoster:
echo     def __init__(self):
echo         self.twitter_api_key = os.getenv('TWITTER_API_KEY')
echo         self.twitter_api_secret = os.getenv('TWITTER_API_SECRET')
echo         self.twitter_access_token = os.getenv('TWITTER_ACCESS_TOKEN')
echo         self.twitter_access_secret = os.getenv('TWITTER_ACCESS_SECRET')
echo     
echo     def post_to_twitter(self, video_path, caption):
echo         """Post video to Twitter/X"""
echo         try:
echo             # Check if API keys are configured
echo             if not all([self.twitter_api_key, self.twitter_api_secret, 
echo                         self.twitter_access_token, self.twitter_access_secret]):
echo                 log("Twitter API keys not configured. Skipping Twitter post.", "WARNING")
echo                 return False
echo             
echo             log(f"Posting to Twitter: {os.path.basename(video_path)}")
echo             
echo             # Try to import tweepy
echo             try:
echo                 import tweepy
echo             except ImportError:
echo                 log("tweepy not installed. Installing...", "INFO")
echo                 import subprocess
echo                 subprocess.run([sys.executable, "-m", "pip", "install", "tweepy"])
echo                 import tweepy
echo             
echo             # Authenticate with Twitter
echo             auth = tweepy.OAuthHandler(self.twitter_api_key, self.twitter_api_secret)
echo             auth.set_access_token(self.twitter_access_token, self.twitter_access_secret)
echo             api = tweepy.API(auth)
echo             
echo             # Upload video
echo             media = api.media_upload(video_path)
echo             
echo             # Post tweet with video
echo             tweet = api.update_status(status=caption, media_ids=[media.media_id])
echo             
echo             log(f"Tweet posted: https://twitter.com/user/status/{tweet.id}")
echo             return True
echo             
echo         except Exception as e:
echo             log(f"Twitter post failed: {str(e)}", "ERROR")
echo             return False
echo     
echo     def post_video(self, video_path, title):
echo         """Post video to all configured platforms"""
echo         # Create caption
echo         caption = f"{title}\\n\\n#YouTube #Video #Automation"
echo         
echo         # Post to Twitter
echo         if self.twitter_api_key and self.twitter_api_key != 'your_twitter_api_key_here':
echo             self.post_to_twitter(video_path, caption)
echo         
echo         # Add more platforms here (Instagram, Facebook, etc.)
echo         return True
echo.
echo # ===========================================================================
echo # MAIN AUTOMATION
echo # ===========================================================================
echo.
echo class YouTubeAutomation:
echo     def __init__(self):
echo         self.downloader = VideoDownloader()
echo         self.clipper = VideoClipper()
echo         self.poster = SocialMediaPoster()
echo         self.stats_file = os.path.join(LOGS_DIR, 'stats.json')
echo     
echo     def run_single_cycle(self):
echo         """Run one complete automation cycle"""
echo         log("=" * 60)
echo         log("Starting automation cycle")
echo         log("=" * 60)
echo         
echo         # Example: Download a test video
echo         test_url = "https://www.youtube.com/watch?v=jNQXAC9IVRw"
echo         
echo         # 1. Download video
echo         video_path = self.downloader.download_video(test_url)
echo         
echo         if video_path and os.path.exists(video_path):
echo             # 2. Create clip
echo             clip_path = self.clipper.create_clip(video_path, 0)
echo             
echo             if clip_path and os.path.exists(clip_path):
echo                 # 3. Post to social media
echo                 title = "Automated YouTube Clip"
echo                 self.poster.post_video(clip_path, title)
echo                 
echo                 log("Cycle completed successfully!")
echo                 return True
echo             else:
echo                 log("Clip creation failed", "ERROR")
echo                 return False
echo         else:
echo             log("Video download failed", "ERROR")
echo             return False
echo     
echo     def run_scheduled(self):
echo         """Run automation on schedule"""
echo         log("Starting scheduled automation")
echo         
echo         # Schedule tasks (every 6 hours)
echo         schedule.every(6).hours.do(self.run_single_cycle)
echo         
echo         # Run immediately
echo         self.run_single_cycle()
echo         
echo         # Keep running
echo         while True:
echo             schedule.run_pending()
echo             time.sleep(60)
echo.
echo # ===========================================================================
echo # MAIN EXECUTION
echo # ===========================================================================
echo.
echo if __name__ == "__main__":
echo     import argparse
echo     
echo     parser = argparse.ArgumentParser(description='YouTube Automation System')
echo     parser.add_argument('--mode', choices=['once', 'scheduled'], 
echo                         default='once', help='Run mode')
echo     
echo     args = parser.parse_args()
echo     
echo     automation = YouTubeAutomation()
echo     
echo     if args.mode == 'scheduled':
echo         automation.run_scheduled()
echo     else:
echo         automation.run_single_cycle()
echo     
echo     log("Automation finished")
) > "!MAIN_FOLDER!\automation.py"

echo ? Main automation script created
echo.

:: ==============================================================================
:: STEP 6: CREATE RUN SCRIPTS
:: ==============================================================================
echo [6] Creating run scripts...
echo.

:: Create run_automation.bat
(
@echo off
chcp 65001 >nul
title YouTube Automation
color 0A

echo ===============================================================================
echo                    YOUTUBE AUTOMATION SYSTEM
echo ===============================================================================
echo.
echo Location: !MAIN_FOLDER!
echo.
echo 1. Run automation once
echo 2. Run in scheduled mode
echo 3. Configure settings
echo 4. View logs
echo 5. Exit
echo.
set /p choice="Select [1-5]: "

if "%%choice%%"=="1" (
    cd /d "!MAIN_FOLDER!"
    python automation.py --mode once
    pause
    exit /b 0
)

if "%%choice%%"=="2" (
    echo Running in scheduled mode...
    echo Press Ctrl+C to stop when running.
    timeout /t 3
    cd /d "!MAIN_FOLDER!"
    python automation.py --mode scheduled
    pause
    exit /b 0
)

if "%%choice%%"=="3" (
    echo Opening configuration files...
    if exist "!MAIN_FOLDER!\.env" (
        notepad "!MAIN_FOLDER!\.env"
    )
    if exist "!MAIN_FOLDER!\config.yaml" (
        notepad "!MAIN_FOLDER!\config.yaml"
    )
    pause
    exit /b 0
)

if "%%choice%%"=="4" (
    echo Opening logs folder...
    explorer "!LOGS_FOLDER!"
    pause
    exit /b 0
)

if "%%choice%%"=="5" (
    exit /b 0
)

echo Invalid choice!
pause
) > "!MAIN_FOLDER!\run_automation.bat"

:: Create desktop shortcut
echo [Desktop Shortcut]
echo URL=file:///!MAIN_FOLDER!
echo IconIndex=0
(
[InternetShortcut]
URL=file:///!MAIN_FOLDER!
IconIndex=0
) > "%USERPROFILE%\Desktop\YouTube Automation.lnk" 2>nul

echo ? Run scripts created
echo.

:: ==============================================================================
:: STEP 7: CREATE SETUP COMPLETE MESSAGE
:: ==============================================================================
echo [7] Setup complete!
echo.
echo ===============================================================================
echo                    SETUP COMPLETE!
echo ===============================================================================
echo.
echo Your YouTube Automation system is ready!
echo.
echo LOCATION: !MAIN_FOLDER!
echo.
echo NEXT STEPS:
echo 1. Edit API keys in !MAIN_FOLDER!\.env
echo    - Get Twitter API keys from: https://developer.twitter.com
echo.
echo 2. Edit configuration in !MAIN_FOLDER!\config.yaml
echo    - Add more YouTube channels
echo    - Adjust settings
echo.
echo 3. Install FFmpeg for video clipping (optional)
echo    - Download from: https://ffmpeg.org/download.html
echo    - Add to PATH: C:\ffmpeg\bin
echo.
echo 4. Run the automation:
echo    - Double-click run_automation.bat in !MAIN_FOLDER!
echo    - Or use shortcut on Desktop
echo.
echo QUICK START:
echo   1. Get Twitter API keys
echo   2. Edit .env file with your keys
echo   3. Run automation once to test
echo   4. Add more channels to config.yaml
echo.
pause

:: Open the main folder
explorer "!MAIN_FOLDER!"