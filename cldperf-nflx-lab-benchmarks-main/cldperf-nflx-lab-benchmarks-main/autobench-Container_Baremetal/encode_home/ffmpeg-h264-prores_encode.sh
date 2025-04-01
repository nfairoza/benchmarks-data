#!/bin/bash
export LD_PRELOAD=/home/fake-cpu-count.so
START=$(date +%s)
time /apps/transcoder/bin/ffmpeg -y -threads 3 -hide_banner -f image2 -r 25/1 -vcodec netflixprores -strict strict -start_number 1000 -i ./prores_1727108648197266176_req2_1000_1499/frame%08d.icpf -an -profile:v high -vsync 0 -r 25/1 -sws_flags lanczos+accurate_rnd -vf "select='gte(n\,0)*gte(1499\,n)',nflx_color_metadata,format=yuv420p,crop=3840:1920:0:120,pad2=iw+0:ih+240:0:120,scale=1920:1080,setsar=1/1:max=65535,format=yuv420p" -vcodec libx264 -x264opts 8x8dct=1:aq-mode=1:aq-strength=0.8:b-adapt=2:b-bias=0:b-pyramid=normal:bframes=16:cplxblur=10:crf=16:direct=auto:force-cfr=1:fps=25/1:ipratio=1.4:keyint=50:level=40:me=umh:merange=120:min-keyint=50:mvrange=510:nal-hrd=vbr:partitions=p8x8,b8x8,i4x4:pbratio=1.3:psy-rd=1.00:qblur=0.5:qcomp=0.5:qpmax=51:qpmin=6:qpstep=4:ratetol=1.0:rc-lookahead=250:ref=4:scenecut=0:ssim=1:stitchable=1:subme=10:threads=3:trellis=2:vbv-bufsize=25000:vbv-init=0.9:vbv-maxrate=20000:weightp=2 -f rawvideo -aud 1 -psnr ./out.264
END=$(date +%s)
ELAPSED=$(( $END - $START ))
echo "ffmpeg-encode-prores,$ELAPSED"

