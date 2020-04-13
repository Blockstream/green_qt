root=$(pwd)/svg
dst=$(pwd)/dist_ios
rm -rf $dst && mkdir $dst
for filename in ${root}/*.svg; do
	cd $root
	basename=$(basename ${filename} .svg)
	folder=$dst/$basename.imageset
	mkdir $folder
	convert -background none -antialias -density 300 -gravity center -resize 75x75^ -crop 75x75+0+0  ${filename} ${folder}/${basename}_3x.png
	convert -background none -antialias -density 300 -gravity center -resize 50x50^ -crop 50x50+0+0  ${filename} ${folder}/${basename}_2x.png
	printf '%s\n' \
        '{' \
        '  "images" : [' \
        '    {' \
        '      "idiom" : "universal",' \
        '      "scale" : "1x"' \
        '    },' \
        '    {' \
        '      "idiom" : "universal",' \
        '      "filename" : "'${basename}'_2x.png",' \
        '      "scale" : "2x"' \
        '    },' \
        '    {' \
        '      "idiom" : "universal",' \
        '      "filename" : "'${basename}'_3x.png",' \
        '      "scale" : "3x"' \
        '    }' \
        '  ],' \
        '  "info" : {' \
        '  "version" : 1,' \
        '  "author" : "xcode"' \
        '  }' \
        '}' > ${folder}/Contents.json

done
