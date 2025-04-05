#!/bin/bash

export LD_PRELOAD=/home/fake-cpu-count.so
START=$(date +%s)
time /apps/transcoder/bin/ffmpeg -r 1 -start_number 2689 -i vqs_benchmark_1609689_source_9714813912_encode_10446905637_2689_3348/source/frame%08d.j2k -r 1 -c:v hevc -i vqs_benchmark_1609689_source_9714813912_encode_10446905637_2689_3348/gop00002689.265 -lavfi "[0:v]format=yuv420p10le,crop=3840:2076:0:42,pad2=iw+0:ih+84:0:42,setsar=1/1:max=65535,format=yuv420p10le,scale=3840:2160:flags=bicubic,format=yuv420p,setpts=PTS-STARTPTS[refFiltered];[1:v]format=yuv420p,scale=3840:2160:flags=bicubic,setpts=PTS-STARTPTS[disFiltered];[refFiltered][disFiltered]libvmaf='log_fmt=xml:log_path=./temp.xml:models=path=/apps/transcoder/conf/VMAF_OSS_LTS/vmafplus_v0.5.0.json_2160,name=vmaf_plus'" -an -f null -

time /apps/transcoder/bin/ffmpeg -r 1 -start_number 7794 -i vqs_benchmark_1609689_source_9714813912_encode_10446905637_7794_8481/source/frame%08d.j2k -r 1 -c:v hevc -i vqs_benchmark_1609689_source_9714813912_encode_10446905637_7794_8481/gop00007794.265 -lavfi "[0:v]format=yuv420p10le,crop=3840:2076:0:42,pad2=iw+0:ih+84:0:42,setsar=1/1:max=65535,format=yuv420p10le,scale=3840:2160:flags=bicubic,format=yuv420p,setpts=PTS-STARTPTS[refFiltered];[1:v]format=yuv420p,scale=3840:2160:flags=bicubic,setpts=PTS-STARTPTS[disFiltered];[refFiltered][disFiltered]libvmaf='log_fmt=xml:log_path=./temp.xml:models=path=/apps/transcoder/conf/VMAF_OSS_LTS/vmafplus_v0.5.0.json_2160,name=vmaf_plus'" -an -f null -

END=$(date +%s)
ELAPSED=$(( $END - $START ))
echo "ffmpeg-vmaf,$ELAPSED"

