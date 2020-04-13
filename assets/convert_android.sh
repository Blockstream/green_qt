root=$(pwd)/svg
dst=$(pwd)/dist_android

wget https://github.com/ravibhojwani86/Svg2VectorAndroid/blob/master/Svg2VectorAndroid-1.0.1.jar?raw=true Svg2VectorAndroid-1.0.1.jar
java -jar Svg2VectorAndroid-1.0.1.jar ${root}
rm -rf ${dst} 
mv ${root}/ProcessedSVG ${dst}
