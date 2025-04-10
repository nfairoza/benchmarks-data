#!/bin/bash

# DIR is exported from the run-benchmarks script
cd $DIR
#export LD_PRELOAD=/home/fake-cpu-count.so
#export LD_PRELOAD=/home/fake-cpu-4count.so
START=$(date +%s)
#time /apps/transcoder/bin/ffmpeg -y -threads 0 -hide_banner -f image2 -r 24/1 -start_number 33745 -strict strict -i ./10426881257_33745_33965_frames/frame%08d.j2k -an -profile:v high -vsync 0 -r 24/1 -sws_flags lanczos+accurate_rnd -vf "select='gte(n\,0)*gte(220\,n)',nflx_color_metadata,format=yuv420p,scale=1920:1080,setsar=1/1:max=65535,format=yuv420p" -vcodec libx264 -x264opts 8x8dct=1:aq-mode=1:aq-strength=0.8:b-adapt=2:b-bias=0:b-pyramid=normal:bframes=16:cplxblur=10:crf=23:direct=auto:force-cfr=1:fps=24/1:init-idr-id=62180:ipratio=1.4:keyint=240:level=40:me=umh:merange=120:min-keyint=240:mvrange=510:nal-hrd=vbr:partitions=p8x8,b8x8,i4x4:pbratio=1.3:psy-rd=1.00:qblur=0.5:qcomp=0.5:qpmax=51:qpmin=6:qpstep=4:ratetol=1.0:rc-lookahead=240:ref=4:scenecut=0:ssim=1:stitchable=1:subme=10:threads=0:trellis=2:vbv-bufsize=25000:vbv-init=0.9:vbv-maxrate=20000:weightp=2:lookahead_threads=2 -f rawvideo -force_key_frames "expr:eq(n,0)" -aud 1 -psnr 266_x264_split.264
#
time /apps/transcoder/bin/ffmpeg -y -threads 0 -hide_banner -f image2 -r 24/1 -start_number 33745 -strict strict -i $HOME/encode_home/10426881257_33745_33965_frames/frame%08d.j2k -an -profile:v high -vsync 0 -r 24/1 -sws_flags lanczos+accurate_rnd -vf "select='gte(n\,0)*gte(220\,n)',nflx_color_metadata,format=yuv420p,scale=1920:1080,setsar=1/1:max=65535,format=yuv420p" -vcodec libx264 -x264opts 8x8dct=1:aq-mode=1:aq-strength=0.8:b-adapt=2:b-bias=0:b-pyramid=normal:bframes=16:cplxblur=10:crf=23:direct=auto:force-cfr=1:fps=24/1:init-idr-id=62180:ipratio=1.4:keyint=240:level=40:me=umh:merange=120:min-keyint=240:mvrange=510:nal-hrd=vbr:partitions=p8x8,b8x8,i4x4:pbratio=1.3:psy-rd=1.00:qblur=0.5:qcomp=0.5:qpmax=51:qpmin=6:qpstep=4:ratetol=1.0:rc-lookahead=240:ref=4:scenecut=0:ssim=1:stitchable=1:subme=10:threads=0:trellis=2:vbv-bufsize=25000:vbv-init=0.9:vbv-maxrate=20000:weightp=2:lookahead_threads=2 -f rawvideo -force_key_frames "expr:eq(n,0)" -aud 1 -psnr 266_x264_split.264
END=$(date +%s)
ELAPSED=$(( $END - $START ))
echo "ffmpeg-encode-j2k,$ELAPSED" > $DIR/ffmpeg-encode-j2k.csv

