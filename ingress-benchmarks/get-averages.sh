#!/bin/bash


echo "Nginx Inside the Mesh: "
echo -n " conn : "
cat nginx-inmesh.tsv | awk -v N=5 '{ sum += $N } END { if (NR > 0) print sum / NR }'
echo -n " pre  : "
cat nginx-inmesh.tsv | awk -v N=11 '{ sum += $N } END { if (NR > 0) print sum / NR }'
echo -n " start: "
cat nginx-inmesh.tsv | awk -v N=14 '{ sum += $N } END { if (NR > 0) print sum / NR }'
echo -n " total: "
cat nginx-inmesh.tsv | awk -v N=17 '{ sum += $N } END { if (NR > 0) print sum / NR }'

#########################

echo "Nginx Outside the Mesh: "
echo -n " conn : "
cat nginx-out.tsv | awk -v N=5 '{ sum += $N } END { if (NR > 0) print sum / NR }'
echo -n " pre  : "
cat nginx-out.tsv | awk -v N=11 '{ sum += $N } END { if (NR > 0) print sum / NR }'
echo -n " start: "
cat nginx-out.tsv | awk -v N=14 '{ sum += $N } END { if (NR > 0) print sum / NR }'
echo -n " total: "
cat nginx-out.tsv | awk -v N=17 '{ sum += $N } END { if (NR > 0) print sum / NR }'

#########################

echo "Contour Outside the Mesh: "
echo -n " conn : "
cat contour-out.tsv | awk -v N=5 '{ sum += $N } END { if (NR > 0) print sum / NR }'
echo -n " pre  : "
cat contour-out.tsv | awk -v N=11 '{ sum += $N } END { if (NR > 0) print sum / NR }'
echo -n " start: "
cat contour-out.tsv | awk -v N=14 '{ sum += $N } END { if (NR > 0) print sum / NR }'
echo -n " total: "
cat contour-out.tsv | awk -v N=17 '{ sum += $N } END { if (NR > 0) print sum / NR }'
