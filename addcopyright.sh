#!/bin/bash
# (c) Crown Owned Copyright, 2016. Dstl.
dot="$(cd "$(dirname "$0")"; pwd)"
result=0
copyright_text_raw="(c) Crown Owned Copyright, 2016. Dstl."

function insertAfter # file_name line_number text_to_insert
{
	local file_name="$1" line_number="$2" text_to_insert="$3"
	tmp_file_name=$file_name.tmp

	# echo "Inserting $text_to_insert into $file_name using $tmp_file_name at line $line_number"
	cp $file_name $tmp_file_name
	awk -v n=$line_number \
		-v s="$text_to_insert" 'NR == n {print s} {print}' \
		$file_name > $tmp_file_name
	if [ ! -f $tmp_file_name ]; then
		echo "Couldn't create temporary file $tmp_file_name"
		exit 1
	fi
	mv $tmp_file_name $file_name
}

# TODO: This needs to be made more argumentative. Specifically, specifying which
# file extensions to use per list of files to comment.
function findRelevantFiles
{
	find . -not \( -path ./ansible/.vagrant -prune \) \
		-not \( -path ./ansible/roles/geerlingguy.java -prune \) \
		-not \( -path ./ansible/roles/geerlingguy.git -prune \) \
		-not \( -path ./ansible/roles/bennojoy.openldap_server -prune \) \
		-not \( -path ./ansible/roles/geerlingguy.jenkins -prune \) \
		-not \( -path ./ansible/roles/octarine.postgresql -prune \) \
		-not \( -path ./ansible/roles/openstack.jenkins-job-builder -prune \) \
		-not \( -path ./secrets -prune \) \
		-not \( -path ./.git -prune \) \
		"$@"
}

# Python files or shell files
for file in $(findRelevantFiles -name '*.py' -o -name '*.sh' -o -name '*.yml' -o -name '*.tf')
do
	copyright_text='# '$copyright_text_raw
	tmp_file_name=$file.tmp
	insert_onto_line=1
	# It should be in the first two lines to account for the shebang
	# (which should be first) and the encoding comment (which should be second)
	# However if it's found we'll assume it's in the right place
	if head -n1 $file | grep -q "#!"
	then
		# echo "Found a shebang in $file"
		insert_onto_line=$(( insert_onto_line + 1 ))
	fi
	if head -n2 $file | grep -q "\-\*\-"
	then
		# echo "Found encoding in $file"
		insert_onto_line=$(( insert_onto_line + 1 ))
	fi
	if ! head -n3 $file | grep -q '^#.*Copyright'
	then
		# echo "Did not find a copyright notice in $file"
		insertAfter "$file" $insert_onto_line "$copyright_text"
	fi
done

# SCSS files and JS files
for file in $(findRelevantFiles -name '*.scss' -o -name '*.js')
do
	copyright_text='// '$copyright_text_raw
	tmp_file_name=$file.tmp
	insert_onto_line=1
	if head -n1 $file | grep -q "#!"
	then
		# echo "Found a shebang in $file"
		insert_onto_line=$(( insert_onto_line + 1 ))
	fi
	if ! head -n3 $file | grep -q '^//.*Copyright'
	then
		# echo "Did not find a copyright notice in $file"
		insertAfter "$file" $insert_onto_line "$copyright_text"
	fi
done

# CSS files
for file in $(findRelevantFiles -name '*.css')
do
	copyright_text='/* '$copyright_text_raw' */'
	tmp_file_name=$file.tmp
	insert_onto_line=1
	if ! head -n3 $file | grep -q '^/*.*Copyright'
	then
		# echo "Did not find a copyright notice in $file"
		insertAfter "$file" $insert_onto_line "$copyright_text"
	fi
done

# HTML Template files
for file in $(findRelevantFiles -name '*.html' -o -name '*.htm')
do
	copyright_text='{# '$copyright_text_raw' #}'
	tmp_file_name=$file.tmp
	insert_onto_line=1
	if ! head -n3 $file | grep -q '^{#.*Copyright'
	then
		# echo "Did not find a copyright notice in $file"
		insertAfter "$file" $insert_onto_line "$copyright_text"
	fi
done
