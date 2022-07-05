#/bin/bash
file_input="result.txt"
while read -r i 
do
  file_name=$(awk '{print $2}' <<<"${i}")
  file_date=$(awk '{print $1}' <<<"${i}")
  #echo "$file_name"
  cp /SrcFiles/DBSS/CM/ready/"${file_name}" /Files/CRM_INCR/
  short_file_name=$(ls -Art | tail -n 1)
  mv /Files/CRM_INCR/${file_name} /Files/CRM_INCR/${file_date}_${short_file_name}
  
#  hdfs dfs -copyToLocal $($i | awk '{print $2}') /Files/CRM_INCR/
done <result.txt
