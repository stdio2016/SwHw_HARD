read -p "Really want to delete this project?" yn
if [ $yn == "y" ]
then
  cat .gitignore | sed 's/\r$//' | while read line
  do
    echo $line
    rm -rf $line
  done
  echo finished
fi
