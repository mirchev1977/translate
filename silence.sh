ffmpeg -f lavfi -i anullsrc=r=44100:cl=mono -t <seconds> -q:a 9 -acodec libmp3lame out.mp3

