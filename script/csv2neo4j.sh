#!/bin/bash

#create netstat.csv from input files
dos2unix import/*
cat import/* | grep TCP | grep -v "\[\:\:\]" | grep -v 127.0.0.1 | grep -v 0.0.0.0 | tr -s ' ' | cut -f 3,4 -d " " | sed 's/:.* / /' | sed 's/ /;/' | sed 's/:/;/'| grep -v "\[" | grep -v "(" > netstat.csv

# Create nodes for every IP in the list
# Template: CREATE (name:label {attribute1: 'foo', attribute2: 'bar'}) 
echo "creating objects file"
if [[ -f "objects.txt" ]]; then rm -f objects.txt; fi
cat netstat.csv | tr ";" "\n" | sort | uniq | grep '\.' | while read IP; do
   #read additional sources for attributes or label
   if [[ -f "names.csv" ]]; then
      name=$(grep "$IP;" names.csv | cut -f2 -d ";")
   fi
   if [[ -f "labels.csv" ]]; then
      label=$(grep "$IP;" labels.csv | cut -f2 -d ";")
   fi

   # if no name or label has been found -> set default
   if [[ -z "$name" ]]; then
     name=$IP 
   fi
   if [[ -z "$label" ]]; then
     label="host" 
   fi
   echo "CREATE (IP_$IP:$label {ip:'$IP', name:'$name'})" >> objects.txt

   # clear variables - clean slate for the next loop
   name=""
   label=""
done

# Create relationships between nodes
# Template: CREATE (name)-[:relationshp_type {attribute: 'foo'}]->(name)"
echo "creating connections file"
if [[ -f "connections.txt" ]]; then rm -f connections.txt; fi
cat netstat.csv | sort | uniq | while read line; do
   src=$(echo $line | cut -f1 -d ";")
   dst=$(echo $line | cut -f2 -d ";")
   port=$(echo $line | cut -f3 -d ";")
   echo "CREATE (IP_$src)-[:DEPENDS_ON {port: '$port'}]->(IP_$dst)" >> connections.txt
done

# combine file
cat objects.txt connections.txt > output.txt
rm -f objects.txt connections.txt

# replace dot with underscore. Neo4j cannot use dots in names
sed 's/\./_/g' output.txt > create_database.txt
rm -f output.txt
