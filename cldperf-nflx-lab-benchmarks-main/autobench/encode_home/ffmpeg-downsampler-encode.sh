#!/bin/bash

export LD_PRELOAD=/home/fake-cpu-count.so
START=$(date +%s)
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib 
/usr/local/bin/ffmpeg -y -threads 0 -f image2 -r 24000/1001 -start_number 57000 -i ./my_octopus_teacher_57000_57119/frame%08d.j2k -an -vsync 0 -r 24000/1001 -sws_flags lanczos+accurate_rnd  -vf select='gte(n\,0)*gte(69\,n)',nflx_color_metadata,format=yuv420p,crop=3840:1606:0:276,pad=iw+0:ih+554:0:277,scale=3840:2160,format=yuv420p,setrange=full,extractplanes=y+u+v[y][u][v],[y]progdown=w=1920:h=1080:force_cpu=1:dnn_backend=1[yd],[u]scale=960:540[ud],[v]scale=960:540[vd],[yd][ud][vd]mergeplanes=0x001020:yuv420p,setsar=1/1:max=65535,format=yuv420p -f rawvideo ./output.yuv
END=$(date +%s)
ELAPSED=$(( $END - $START ))
echo "ffmpeg-downsampler,$ELAPSED"
